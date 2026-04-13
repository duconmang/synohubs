import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'synology_api.dart';
import '../main.dart' show NasCertOverrides;

/// Parsed snapshot of NAS information, refreshed after login and on demand.
class NasInfo {
  final String model;
  final String dsmVersion;
  final String serial;
  final String hostname;
  final int uptimeSeconds;
  final int temperatureC;

  // CPU / RAM
  final double cpuLoad; // 0‥1
  final int ramTotalMb;
  final int ramUsedMb;

  // Storage
  final int storageTotalGb;
  final int storageUsedGb;

  // Volumes
  final List<VolumeInfo> volumes;

  // Disks
  final List<DiskInfo> disks;

  // Network
  final String lanIp;

  // Packages / services
  final List<PackageInfo> packages;

  const NasInfo({
    required this.model,
    required this.dsmVersion,
    required this.serial,
    required this.hostname,
    required this.uptimeSeconds,
    required this.temperatureC,
    required this.cpuLoad,
    required this.ramTotalMb,
    required this.ramUsedMb,
    required this.storageTotalGb,
    required this.storageUsedGb,
    required this.volumes,
    required this.disks,
    required this.lanIp,
    required this.packages,
  });

  double get ramUsage => ramTotalMb > 0 ? ramUsedMb / ramTotalMb : 0;
  double get storageUsage =>
      storageTotalGb > 0 ? storageUsedGb / storageTotalGb : 0;
  String get uptimeFormatted {
    final d = uptimeSeconds ~/ 86400;
    final h = (uptimeSeconds % 86400) ~/ 3600;
    if (d > 0) return '$d Days, $h Hours';
    return '$h Hours';
  }
}

class VolumeInfo {
  final String id;
  final String status;
  final String raidType;
  final int totalSizeGb;
  final int usedSizeGb;

  const VolumeInfo({
    required this.id,
    required this.status,
    required this.raidType,
    required this.totalSizeGb,
    required this.usedSizeGb,
  });
}

class DiskInfo {
  final String id;
  final String name;
  final String model;
  final String status;
  final int temperatureC;
  final int sizeGb;

  const DiskInfo({
    required this.id,
    required this.name,
    required this.model,
    required this.status,
    required this.temperatureC,
    required this.sizeGb,
  });
}

class PackageInfo {
  final String id;
  final String name;
  final String version;
  final bool isRunning;

  const PackageInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.isRunning,
  });
}

/// Singleton that holds login state and real NAS data.
/// Notifies listeners on login / logout / refresh.
class SessionManager extends ChangeNotifier {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  SynologyApi? _api;
  NasInfo? _nasInfo;
  String? _lastError;
  bool _isAdmin = false;

  // Connection params (persisted in memory for reconnect)
  String _host = '';
  int _port = 5001;
  bool _useHttps = true;
  String _account = '';
  String _password = '';
  String? _otpCode;

  SynologyApi? get api => _api;
  NasInfo? get nasInfo => _nasInfo;
  String? get lastError => _lastError;
  bool get isLoggedIn => _api?.isAuthenticated ?? false;
  bool get isAdmin => _isAdmin;

  String get host => _host;
  int get port => _port;
  bool get useHttps => _useHttps;
  String get account => _account;
  String get password => _password;

  /// Authenticate and fetch initial NAS data.
  /// Returns null on success, or an error string.
  /// Returns '2FA_REQUIRED' when 2-step verification is needed
  /// (caller should prompt for OTP and call [login] again with [otpCode]).
  Future<String?> login({
    required String host,
    required int port,
    required bool useHttps,
    required String account,
    required String password,
    String? otpCode,
  }) async {
    _host = host;
    _port = port;
    _useHttps = useHttps;
    _account = account;
    _password = password;
    _otpCode = otpCode;
    _lastError = null;

    _api = SynologyApi(host: host, port: port, useHttps: useHttps);
    NasCertOverrides.trustHost(host);

    try {
      final resp = await _api!.login(account, password, otpCode: otpCode);
      if (resp['success'] != true) {
        final code = resp['error']?['code'];
        // 2FA / OTP required — signal caller to prompt for code
        if (code == 403 || code == 406) {
          _api = null;
          notifyListeners();
          return '2FA_REQUIRED';
        }
        _lastError = _authErrorMessage(code);
        _api = null;
        notifyListeners();
        return _lastError;
      }

      // Login succeeded → detect admin status then fetch NAS information
      await _detectAdmin();
      await refreshData();
      notifyListeners();
      return null;
    } catch (e) {
      _lastError = e.toString();
      _api = null;
      notifyListeners();
      return _lastError;
    }
  }

  /// Detect if the logged-in user is an admin.
  /// Uses the current authenticated session to call an admin-only API.
  Future<void> _detectAdmin() async {
    if (_api == null || !_api!.isAuthenticated) return;
    _isAdmin = await _api!.checkAdmin(_account, _password);
  }

  /// Fetch / refresh all NAS data from the API.
  /// Admin users get full system info; regular users get basic info only.
  Future<void> refreshData() async {
    if (_api == null || !_api!.isAuthenticated) return;
    try {
      if (_isAdmin) {
        // Admin: fetch full system data in parallel
        final results = await Future.wait([
          _api!.getDsmInfo(),
          _api!.getSystemUtilization(),
          _api!.getStorageInfo(),
          _api!.getPackages(),
        ]);

        final dsmData = results[0]['data'] as Map<String, dynamic>? ?? {};
        final utilData = results[1]['data'] as Map<String, dynamic>? ?? {};
        final storageData = results[2]['data'] as Map<String, dynamic>? ?? {};
        final pkgData = results[3]['data'] as Map<String, dynamic>? ?? {};

        _nasInfo = _parseNasInfo(dsmData, utilData, storageData, pkgData);
      } else {
        // Non-admin: only getDsmInfo (usually accessible to all users)
        // Other admin-only APIs are skipped to avoid permission errors
        Map<String, dynamic> dsmData = {};
        try {
          final dsmResp = await _api!.getDsmInfo();
          if (dsmResp['success'] == true) {
            dsmData = dsmResp['data'] as Map<String, dynamic>? ?? {};
          }
        } catch (_) {}

        _nasInfo = _parseNasInfo(dsmData, {}, {}, {});
      }
      _lastError = null;
    } catch (e) {
      _lastError = 'Refresh failed: $e';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api?.logout();
    } catch (_) {}
    _api = null;
    _nasInfo = null;
    _lastError = null;
    _isAdmin = false;
    _password = '';
    // Clear saved credentials so auto-login doesn't re-trigger
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await storage.delete(key: 'nas_host');
      await storage.delete(key: 'nas_port');
      await storage.delete(key: 'nas_user');
      await storage.delete(key: 'nas_pass');
      await storage.delete(key: 'nas_https');
    } catch (_) {}
    notifyListeners();
  }

  // ── Parsing helpers ──────────────────────────────────────────────

  NasInfo _parseNasInfo(
    Map<String, dynamic> dsm,
    Map<String, dynamic> util,
    Map<String, dynamic> storage,
    Map<String, dynamic> pkg,
  ) {
    // DSM Info
    final model = dsm['model'] as String? ?? 'Unknown';
    final dsmVersion = _formatDsmVersion(dsm);
    final serial = dsm['serial'] as String? ?? '';
    final hostname = dsm['hostname'] as String? ?? '';
    final uptime = dsm['uptime'] as int? ?? 0;
    final temp = dsm['temperature'] as int? ?? 0;

    // CPU
    final cpu = util['cpu'] as Map<String, dynamic>? ?? {};
    final cpuUser = (cpu['user_load'] as num?)?.toDouble() ?? 0;
    final cpuSys = (cpu['system_load'] as num?)?.toDouble() ?? 0;
    final cpuLoad = (cpuUser + cpuSys) / 100.0;

    // Memory
    final mem = util['memory'] as Map<String, dynamic>? ?? {};
    final ramTotalKb = (mem['total_real'] as num?)?.toInt() ?? 0;
    final ramAvail = (mem['avail_real'] as num?)?.toInt() ?? 0;
    final ramBuffer = (mem['buffer'] as num?)?.toInt() ?? 0;
    final ramCached = (mem['cached'] as num?)?.toInt() ?? 0;
    // DSM Info reports physical DIMM capacity in MB (ram_size),
    // which is more accurate than kernel's total_real on some NAS models.
    final physicalRamMb = (dsm['ram_size'] as num?)?.toInt() ?? 0;
    final ramTotalMb = physicalRamMb > 0 ? physicalRamMb : ramTotalKb ~/ 1024;
    // Actual used = total - free - buffer - cached (matches DSM Resource Monitor)
    final ramUsedKb = ramTotalKb - ramAvail - ramBuffer - ramCached;
    final ramUsedMb = ramTotalKb > 0 ? ramUsedKb ~/ 1024 : 0;

    // Volumes
    final volumesList = storage['volumes'] as List? ?? [];
    int totalStorageBytes = 0;
    int usedStorageBytes = 0;
    final volumes = <VolumeInfo>[];
    for (final v in volumesList) {
      final vMap = v as Map<String, dynamic>;
      final totalBytes = _parseSizeBytes(vMap['size']?['total']);
      final usedBytes = _parseSizeBytes(vMap['size']?['used']);
      totalStorageBytes += totalBytes;
      usedStorageBytes += usedBytes;

      volumes.add(
        VolumeInfo(
          id: vMap['id'] as String? ?? vMap['vol_path'] as String? ?? '',
          status: vMap['status'] as String? ?? 'normal',
          raidType: vMap['fs_type'] as String? ?? '',
          totalSizeGb: totalBytes ~/ (1024 * 1024 * 1024),
          usedSizeGb: usedBytes ~/ (1024 * 1024 * 1024),
        ),
      );
    }

    // Disks
    final disksList = storage['disks'] as List? ?? [];
    final disks = <DiskInfo>[];
    for (final d in disksList) {
      final dMap = d as Map<String, dynamic>;
      final sizeBytes = _parseSizeBytes(dMap['size_total']);
      disks.add(
        DiskInfo(
          id: dMap['id'] as String? ?? '',
          name: dMap['name'] as String? ?? dMap['id'] as String? ?? '',
          model: dMap['model'] as String? ?? 'Unknown',
          status: dMap['status'] as String? ?? 'normal',
          temperatureC: dMap['temp'] as int? ?? 0,
          sizeGb: sizeBytes ~/ (1024 * 1024 * 1024),
        ),
      );
    }

    // Packages
    final pkgList = pkg['packages'] as List? ?? [];
    final packages = <PackageInfo>[];
    for (final p in pkgList) {
      final pMap = p as Map<String, dynamic>;
      final additional = pMap['additional'] as Map<String, dynamic>? ?? {};
      final isRunning =
          additional['status'] == 'running' ||
          additional['running_status'] == 'running' ||
          pMap['status'] == 'running' ||
          additional['is_running'] == true ||
          pMap['is_running'] == true;
      packages.add(
        PackageInfo(
          id: pMap['id'] as String? ?? '',
          name: pMap['name'] as String? ?? pMap['dname'] as String? ?? '',
          version: pMap['version'] as String? ?? '',
          isRunning: isRunning,
        ),
      );
    }

    return NasInfo(
      model: model,
      dsmVersion: dsmVersion,
      serial: serial,
      hostname: hostname,
      uptimeSeconds: uptime,
      temperatureC: temp,
      cpuLoad: cpuLoad.clamp(0, 1),
      ramTotalMb: ramTotalMb,
      ramUsedMb: ramUsedMb,
      storageTotalGb: totalStorageBytes ~/ (1024 * 1024 * 1024),
      storageUsedGb: usedStorageBytes ~/ (1024 * 1024 * 1024),
      volumes: volumes,
      disks: disks,
      lanIp: _host, // use the connected host
      packages: packages,
    );
  }

  String _formatDsmVersion(Map<String, dynamic> dsm) {
    final major = dsm['version_string'] as String?;
    if (major != null && major.isNotEmpty) return major;
    final minor = dsm['minor_ver'] as String? ?? '';
    return 'DSM ${dsm['version'] ?? ''}$minor';
  }

  int _parseSizeBytes(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  String _authErrorMessage(dynamic code) {
    switch (code) {
      case 400:
        return 'No such account or incorrect password';
      case 401:
        return 'Account is disabled';
      case 402:
        return 'Permission denied';
      case 403:
        return '2-step verification required';
      case 404:
        return 'Authentication failed — 2-step verification failed';
      case 406:
        return 'OTP enforcement required';
      case 407:
        return 'Max login attempts reached — try later';
      case 408:
        return 'IP blocked — too many failed attempts';
      case 409:
        return 'SynoHub insufficient permissions';
      case 410:
        return 'Password change required';
      default:
        return 'Login failed (error $code)';
    }
  }
}
