import 'dart:convert';
import 'dart:io';

/// Low-level Synology DSM Web API client.
///
/// Uses the official API documented at
/// https://global.synologydownload.com/download/Document/Software/DeveloperGuide/
///
/// All calls go through [_get] which appends the sid (session token) once
/// authenticated. HTTPS certificate validation is intentionally relaxed because
/// consumer NAS boxes use self-signed certs.
class SynologyApi {
  final String host;
  final int port;
  final bool useHttps;

  String? _sid;
  String? _resolvedIp; // Cached IP from DoH fallback
  HttpClient? _persistentClient;

  SynologyApi({required this.host, required this.port, this.useHttps = true});

  String get _effectiveHost => _resolvedIp ?? host;
  String get baseUrl =>
      '${useHttps ? 'https' : 'http'}://$_effectiveHost:$port/webapi';

  bool get isAuthenticated => _sid != null;

  // ── DNS resolution with DoH fallback ─────────────────────────────

  /// Resolve [host] using system DNS first; if that fails, try
  /// Cloudflare/Google DNS-over-HTTPS. Stores result in [_resolvedIp].
  Future<void> _ensureHostResolved() async {
    // Skip if host is already an IP address
    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) return;
    // Skip if already resolved
    if (_resolvedIp != null) return;

    // Try system DNS
    try {
      await InternetAddress.lookup(host);
      return; // Works → no override needed
    } catch (_) {}

    // Fallback: DNS-over-HTTPS (Cloudflare, then Google)
    for (final dohHost in ['cloudflare-dns.com', 'dns.google']) {
      try {
        final ioClient = HttpClient()
          ..connectionTimeout = const Duration(seconds: 5);
        final uri = Uri.https(dohHost, '/dns-query', {
          'name': host,
          'type': 'A',
        });
        final request = await ioClient.getUrl(uri);
        request.headers.set('Accept', 'application/dns-json');
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        ioClient.close();

        final json = jsonDecode(body) as Map<String, dynamic>;
        final answers = json['Answer'] as List?;
        if (answers != null) {
          for (final a in answers) {
            final aMap = a as Map<String, dynamic>;
            if (aMap['type'] == 1) {
              // A-record
              _resolvedIp = aMap['data'] as String;
              return;
            }
          }
        }
      } catch (_) {}
    }
    // All failed → will use original hostname and let caller handle error
  }

  // ── HTTP helper ──────────────────────────────────────────────────

  /// Get or create a persistent [HttpClient] that accepts self-signed certs.
  /// Reuses TCP connections across requests for better performance on Android.
  HttpClient _getClient() {
    _persistentClient ??= HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 30)
      ..badCertificateCallback = (cert, host, port) => true;
    return _persistentClient!;
  }

  /// Close the persistent client (call on logout).
  void closeClient() {
    _persistentClient?.close();
    _persistentClient = null;
  }

  Future<Map<String, dynamic>> _get(
    String endpoint,
    Map<String, String> params,
  ) async {
    if (_sid != null) params['_sid'] = _sid!;

    final uri = Uri.parse(
      '$baseUrl/$endpoint',
    ).replace(queryParameters: params);

    final request = await _getClient().getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json;
  }

  /// POST helper for write operations (create, edit, delete).
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, String> params,
  ) async {
    if (_sid != null) params['_sid'] = _sid!;

    final uri = Uri.parse('$baseUrl/$endpoint');

    final request = await _getClient().postUrl(uri);
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    final body = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    request.write(body);
    final response = await request.close();
    final respBody = await response.transform(utf8.decoder).join();
    final json = jsonDecode(respBody) as Map<String, dynamic>;
    return json;
  }

  // ── Authentication ───────────────────────────────────────────────

  /// Login and obtain a session id.
  /// Returns the full API response map. Throws on network / parse errors.
  /// Pass [otpCode] for accounts with 2-step verification enabled.
  /// Uses POST to avoid credentials appearing in URL/logs.
  Future<Map<String, dynamic>> login(
    String account,
    String passwd, {
    String? otpCode,
  }) async {
    // Resolve domain → IP via DoH if system DNS fails
    await _ensureHostResolved();
    final params = {
      'api': 'SYNO.API.Auth',
      'version': '6',
      'method': 'login',
      'account': account,
      'passwd': passwd,
      'session': 'FileStation',
      'format': 'sid',
    };
    if (otpCode != null && otpCode.isNotEmpty) {
      params['otp_code'] = otpCode;
    }
    final resp = await _post('auth.cgi', params);

    if (resp['success'] == true) {
      _sid = resp['data']?['sid'] as String?;
    }
    return resp;
  }

  /// Logout, clear the session, and close the HTTP client.
  Future<void> logout() async {
    if (_sid == null) return;
    try {
      await _get('auth.cgi', {
        'api': 'SYNO.API.Auth',
        'version': '6',
        'method': 'logout',
        'session': 'FileStation',
      });
    } finally {
      _sid = null;
      closeClient();
    }
  }

  /// Check if the current authenticated user is an admin.
  ///
  /// Strategy: try calling an admin-only API (SYNO.Core.System.Utilization).
  /// If it succeeds, the user is admin. If it returns a permission error,
  /// the user is a regular user. This avoids a second login (which would
  /// fail with 2FA since the OTP code is single-use).
  Future<bool> checkAdmin(
    String account,
    String passwd, {
    String? otpCode,
  }) async {
    if (_sid == null) return false;
    try {
      // SYNO.Core.System.Utilization is admin-only on most DSM versions
      final resp = await _get('entry.cgi', {
        'api': 'SYNO.Core.System.Utilization',
        'version': '1',
        'method': 'get',
      });
      // success=true → admin; error 105 (permission denied) → not admin
      return resp['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── DSM Info ─────────────────────────────────────────────────────

  /// Get basic DSM / NAS information (model, version, serial, temperature …).
  Future<Map<String, dynamic>> getDsmInfo() async {
    return _get('entry.cgi', {
      'api': 'SYNO.DSM.Info',
      'version': '2',
      'method': 'getinfo',
    });
  }

  // ── System Utilisation ───────────────────────────────────────────

  /// CPU, memory, network usage snapshot.
  Future<Map<String, dynamic>> getSystemUtilization() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.System.Utilization',
      'version': '1',
      'method': 'get',
    });
  }

  // ── Storage / Volume ─────────────────────────────────────────────

  /// Volumes, disks, RAID info.
  Future<Map<String, dynamic>> getStorageInfo() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Storage.CGI.Storage',
      'version': '1',
      'method': 'load_info',
    });
  }

  // ── Network ──────────────────────────────────────────────────────

  /// Network interface configuration (LAN IPs etc.).
  Future<Map<String, dynamic>> getNetworkInfo() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.System',
      'version': '1',
      'method': 'info',
      'type': 'network',
    });
  }

  // ── Running packages (services) ──────────────────────────────────

  /// List all installed packages with status, startable, install_type.
  Future<Map<String, dynamic>> getPackages() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Package',
      'version': '2',
      'method': 'list',
      'additional': '["status","startable","install_type","ctl_uninstall","description"]',
    });
  }

  /// List all available packages from Synology's package server.
  Future<Map<String, dynamic>> packageListServer() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Package.Server',
      'version': '2',
      'method': 'list',
    });
  }

  /// Start a package by its id.
  Future<Map<String, dynamic>> packageStart(String id) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Package.Control',
      'version': '1',
      'method': 'start',
      'id': id,
    });
  }

  /// Stop a package by its id.
  Future<Map<String, dynamic>> packageStop(String id) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Package.Control',
      'version': '1',
      'method': 'stop',
      'id': id,
    });
  }

  /// Uninstall a package by its id.
  Future<Map<String, dynamic>> packageUninstall(String id) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Package.Uninstallation',
      'version': '1',
      'method': 'uninstall',
      'id': id,
    });
  }

  /// Step 1 of package install: trigger download.
  /// DSM requires JSON-quoted string values for name/url/operation.
  Future<Map<String, dynamic>> packageInstallDownload(
      String id, String url, int size, String md5) async {
    // Build raw POST body with JSON-quoted values (matches desktop Rust)
    final sid = _sid ?? '';
    final body = 'api=SYNO.Core.Package.Installation&version=1&method=install'
        '&name="$id"&url="$url"&filesize=$size&type=0&blqinst=false'
        '&operation="install"'
        '${md5.isNotEmpty ? '&checksum="$md5"' : ''}'
        '&_sid=$sid';

    final uri = Uri.parse('$baseUrl/entry.cgi');
    final request = await _getClient().postUrl(uri);
    request.headers.contentType = ContentType(
        'application', 'x-www-form-urlencoded', charset: 'utf-8');
    request.write(body);
    final response = await request.close();
    final respBody = await response.transform(utf8.decoder).join();
    return jsonDecode(respBody) as Map<String, dynamic>;
  }

  /// Step 2: Poll download status until finished.
  Future<Map<String, dynamic>> packageInstallStatus(String taskId) async {
    final sid = _sid ?? '';
    final body = 'api=SYNO.Core.Package.Installation.Download&version=1'
        '&method=check&taskid="$taskId"&_sid=$sid';

    final uri = Uri.parse('$baseUrl/entry.cgi');
    final request = await _getClient().postUrl(uri);
    request.headers.contentType = ContentType(
        'application', 'x-www-form-urlencoded', charset: 'utf-8');
    request.write(body);
    final response = await request.close();
    final respBody = await response.transform(utf8.decoder).join();
    return jsonDecode(respBody) as Map<String, dynamic>;
  }

  /// Step 3: Install the downloaded package file with path + volume.
  /// [filename] comes from Step 2's `data.filename` field.
  /// [volume] is the target volume (e.g., "/volume1").
  Future<Map<String, dynamic>> packageInstallFinal(String filename, String volume) async {
    final sid = _sid ?? '';
    final body = 'api=SYNO.Core.Package.Installation&version=1&method=install'
        '&path="$filename"&volume="$volume"&_sid=$sid';

    final uri = Uri.parse('$baseUrl/entry.cgi');
    final request = await _getClient().postUrl(uri);
    request.headers.contentType = ContentType(
        'application', 'x-www-form-urlencoded', charset: 'utf-8');
    request.write(body);
    final response = await request.close();
    final respBody = await response.transform(utf8.decoder).join();
    return jsonDecode(respBody) as Map<String, dynamic>;
  }

  // ── Docker / Container Manager ──────────────────────────────────

  /// List all Docker containers.
  Future<Map<String, dynamic>> dockerList() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Docker.Container',
      'version': '1',
      'method': 'list',
      'limit': '-1',
      'offset': '0',
      'type': 'all',
    });
  }

  /// Get resource usage for running containers.
  Future<Map<String, dynamic>> dockerGetResources() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Docker.Container.Resource',
      'version': '1',
      'method': 'get',
    });
  }

  /// Start a Docker container by name.
  Future<Map<String, dynamic>> dockerStart(String name) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Docker.Container',
      'version': '1',
      'method': 'start',
      'name': name,
    });
  }

  /// Stop a Docker container by name.
  Future<Map<String, dynamic>> dockerStop(String name) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Docker.Container',
      'version': '1',
      'method': 'stop',
      'name': name,
    });
  }

  /// Restart a Docker container by name.
  Future<Map<String, dynamic>> dockerRestart(String name) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Docker.Container',
      'version': '1',
      'method': 'restart',
      'name': name,
    });
  }

  // ── System Power ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> reboot() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.System',
      'version': '1',
      'method': 'reboot',
    });
  }

  Future<Map<String, dynamic>> shutdown() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.System',
      'version': '1',
      'method': 'shutdown',
    });
  }

  Future<Map<String, dynamic>> findMe() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.System',
      'version': '1',
      'method': 'info',
      'type': 'identify',
    });
  }

  // ── User & Group ──────────────────────────────────────────────

  /// List all local users.
  Future<Map<String, dynamic>> listUsers({
    int offset = 0,
    int limit = 200,
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.User',
      'version': '1',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
      'additional':
          '["email","description","expired","cannot_chg_passwd","is_manager"]',
    });
  }

  /// Get info for a specific user.
  Future<Map<String, dynamic>> getUserInfo(String name) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.User',
      'version': '1',
      'method': 'get',
      'name': name,
      'additional':
          '["email","description","expired","cannot_chg_passwd","is_manager","groups"]',
    });
  }

  /// Create a new user.
  Future<Map<String, dynamic>> createUser({
    required String name,
    required String password,
    String description = '',
    String email = '',
    bool sendNotification = false,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.User',
      'version': '1',
      'method': 'create',
      'name': name,
      'password': password,
      'description': description,
      'email': email,
      'send_notification_mail': sendNotification ? 'true' : 'false',
    });
  }

  /// Edit an existing user (description, email).
  Future<Map<String, dynamic>> editUser({
    required String name,
    String? description,
    String? email,
    String? password,
  }) async {
    final params = <String, String>{
      'api': 'SYNO.Core.User',
      'version': '1',
      'method': 'set',
      'name': name,
    };
    if (description != null) params['description'] = description;
    if (email != null) params['email'] = email;
    if (password != null) params['password'] = password;
    return _post('entry.cgi', params);
  }

  /// Enable or disable a user.
  Future<Map<String, dynamic>> setUserEnabled({
    required String name,
    required bool enabled,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.User',
      'version': '1',
      'method': 'set',
      'name': name,
      'expired': enabled ? 'false' : 'true',
    });
  }

  /// Delete a user.
  Future<Map<String, dynamic>> deleteUser(String name) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.User',
      'version': '1',
      'method': 'delete',
      'name': name,
    });
  }

  /// List all local groups.
  Future<Map<String, dynamic>> listGroups({
    int offset = 0,
    int limit = 200,
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Group',
      'version': '1',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
      'additional': '["description","members"]',
    });
  }

  /// Create a new group.
  Future<Map<String, dynamic>> createGroup({
    required String name,
    String description = '',
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.Group',
      'version': '1',
      'method': 'create',
      'name': name,
      'description': description,
    });
  }

  /// Edit a group.
  Future<Map<String, dynamic>> editGroup({
    required String name,
    String? description,
  }) async {
    final params = <String, String>{
      'api': 'SYNO.Core.Group',
      'version': '1',
      'method': 'set',
      'name': name,
    };
    if (description != null) params['description'] = description;
    return _post('entry.cgi', params);
  }

  /// Delete a group.
  Future<Map<String, dynamic>> deleteGroup(String name) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.Group',
      'version': '1',
      'method': 'delete',
      'name': name,
    });
  }

  /// Add members to a group.
  Future<Map<String, dynamic>> addGroupMembers({
    required String group,
    required List<String> members,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.Group.Member',
      'version': '1',
      'method': 'add',
      'group': group,
      'member': jsonEncode(members),
    });
  }

  /// Remove members from a group.
  Future<Map<String, dynamic>> removeGroupMembers({
    required String group,
    required List<String> members,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.Group.Member',
      'version': '1',
      'method': 'remove',
      'group': group,
      'member': jsonEncode(members),
    });
  }

  // ── Resource Monitor ───────────────────────────────────────────

  /// Current connected users / sessions.
  Future<Map<String, dynamic>> getCurrentConnections() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.CurrentConnection',
      'version': '1',
      'method': 'list',
      'offset': '0',
      'limit': '50',
    });
  }

  /// Running services with resource usage.
  Future<Map<String, dynamic>> getServices() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Service',
      'version': '1',
      'method': 'get',
    });
  }

  // ── Log Center ───────────────────────────────────────────────────

  /// Fetch recent logs from Log Center.
  /// Uses SYNO.Core.SyslogClient.Log (DSM 7+) with method "list".
  Future<Map<String, dynamic>> getLogs({
    int offset = 0,
    int limit = 50,
    String logType = '',
  }) async {
    final params = <String, String>{
      'api': 'SYNO.Core.SyslogClient.Log',
      'version': '1',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
    };
    // Only include logtype if specified (empty = all logs)
    if (logType.isNotEmpty) {
      params['logtype'] = logType;
    }
    return _get('entry.cgi', params);
  }

  /// Fetch Log Center overview statistics (log count, latest logs).
  /// Uses SYNO.Core.SyslogClient.Status methods.
  Future<Map<String, dynamic>> getLogStatusCount() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.SyslogClient.Status',
      'version': '1',
      'method': 'cnt_get',
    });
  }

  /// Fetch latest log entries (for overview).
  Future<Map<String, dynamic>> getLatestLogs() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.SyslogClient.Status',
      'version': '1',
      'method': 'latestlog_get',
    });
  }

  /// Fetch current active connections (who is logged in).
  /// Uses SYNO.Core.CurrentConnection (confirmed available).
  Future<Map<String, dynamic>> getConnectionLogs({
    int offset = 0,
    int limit = 50,
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.CurrentConnection',
      'version': '1',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
    });
  }

  // ── FileStation ──────────────────────────────────────────────────

  /// List shared folders (root level).
  Future<Map<String, dynamic>> listSharedFolders({
    int offset = 0,
    int limit = 100,
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.FileStation.List',
      'version': '2',
      'method': 'list_share',
      'offset': '$offset',
      'limit': '$limit',
      'additional': '["size","time","perm"]',
    });
  }

  /// List files and folders in a specific path.
  Future<Map<String, dynamic>> listFiles({
    required String folderPath,
    int offset = 0,
    int limit = 500,
    String sortBy = 'name',
    String sortDirection = 'asc',
    String fileType = 'all',
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.FileStation.List',
      'version': '2',
      'method': 'list',
      'folder_path': folderPath,
      'offset': '$offset',
      'limit': '$limit',
      'sort_by': sortBy,
      'sort_direction': sortDirection,
      'filetype': fileType,
      'additional': '["size","time","type"]',
    });
  }

  /// Get file/folder information.
  Future<Map<String, dynamic>> getFileInfo(String path) async {
    return _get('entry.cgi', {
      'api': 'SYNO.FileStation.List',
      'version': '2',
      'method': 'getinfo',
      'path': path,
      'additional': '["size","time","type"]',
    });
  }

  /// Build a thumbnail URL for a file (images/videos).
  String getThumbnailUrl(String path, {String size = 'small'}) {
    final params = {
      'api': 'SYNO.FileStation.Thumb',
      'version': '2',
      'method': 'get',
      'path': path,
      'size': size,
      if (_sid != null) '_sid': _sid!,
    };
    final uri = Uri.parse(
      '$baseUrl/entry.cgi',
    ).replace(queryParameters: params);
    return uri.toString();
  }

  /// Build a download URL for a file.
  String getDownloadUrl(String path, {String mode = 'download'}) {
    final params = {
      'api': 'SYNO.FileStation.Download',
      'version': '2',
      'method': 'download',
      'path': path,
      'mode': mode,
      if (_sid != null) '_sid': _sid!,
    };
    final uri = Uri.parse(
      '$baseUrl/entry.cgi',
    ).replace(queryParameters: params);
    return uri.toString();
  }

  /// Create one or more folders.
  Future<Map<String, dynamic>> createFolder({
    required String folderPath,
    required String name,
    bool forceParent = true,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.FileStation.CreateFolder',
      'version': '2',
      'method': 'create',
      'folder_path': folderPath,
      'name': name,
      'force_parent': forceParent.toString(),
    });
  }

  /// Rename a file or folder.
  Future<Map<String, dynamic>> rename({
    required String path,
    required String name,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.FileStation.Rename',
      'version': '2',
      'method': 'rename',
      'path': path,
      'name': name,
    });
  }

  /// Delete files/folders (non-blocking start).
  Future<Map<String, dynamic>> deleteItem(String path) async {
    return _post('entry.cgi', {
      'api': 'SYNO.FileStation.Delete',
      'version': '2',
      'method': 'start',
      'path': path,
      'recursive': 'true',
    });
  }

  /// Copy or move files/folders.
  Future<Map<String, dynamic>> copyMove({
    required String path,
    required String destFolderPath,
    bool overwrite = false,
    bool removeSource = false,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.FileStation.CopyMove',
      'version': '3',
      'method': 'start',
      'path': path,
      'dest_folder_path': destFolderPath,
      'overwrite': overwrite.toString(),
      'remove_src': removeSource.toString(),
    });
  }

  /// Start a file search.
  Future<Map<String, dynamic>> searchStart({
    required String folderPath,
    required String pattern,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.FileStation.Search',
      'version': '2',
      'method': 'start',
      'folder_path': folderPath,
      'pattern': pattern,
    });
  }

  /// Get search results.
  Future<Map<String, dynamic>> searchList({
    required String taskId,
    int offset = 0,
    int limit = 200,
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.FileStation.Search',
      'version': '2',
      'method': 'list',
      'taskid': taskId,
      'offset': '$offset',
      'limit': '$limit',
      'additional': '["size","time","type"]',
    });
  }

  /// Stop and clean up a search task.
  Future<Map<String, dynamic>> searchStop(String taskId) async {
    return _post('entry.cgi', {
      'api': 'SYNO.FileStation.Search',
      'version': '2',
      'method': 'stop',
      'taskid': taskId,
    });
  }

  /// Create a file sharing link.
  Future<Map<String, dynamic>> createShareLink({required String path}) async {
    return _post('entry.cgi', {
      'api': 'SYNO.FileStation.Sharing',
      'version': '3',
      'method': 'create',
      'path': path,
    });
  }

  /// Upload a file (multipart).
  Future<Map<String, dynamic>> uploadFile({
    required String destFolderPath,
    required String fileName,
    required List<int> fileBytes,
    bool createParents = true,
    bool overwrite = true,
  }) async {
    // _sid goes on the URL, not inside form fields
    final queryParams = <String, String>{
      'api': 'SYNO.FileStation.Upload',
      'version': '2',
      'method': 'upload',
      if (_sid != null) '_sid': _sid!,
    };
    final uri = Uri.parse(
      '$baseUrl/entry.cgi',
    ).replace(queryParameters: queryParams);

    final request = await _getClient().postUrl(uri);

    final boundary = '----SynoHub${DateTime.now().millisecondsSinceEpoch}';
    request.headers.set(
      'Content-Type',
      'multipart/form-data; boundary=$boundary',
    );

    // Form fields (path, create_parents, overwrite)
    final fields = <String, String>{
      'path': destFolderPath,
      'create_parents': createParents.toString(),
      'overwrite': overwrite.toString(),
    };

    final buffer = StringBuffer();
    for (final entry in fields.entries) {
      buffer.write('--$boundary\r\n');
      buffer.write(
        'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n',
      );
      buffer.write('${entry.value}\r\n');
    }

    // File part — MUST be last for Synology API
    buffer.write('--$boundary\r\n');
    buffer.write(
      'Content-Disposition: form-data; name="file"; '
      'filename="$fileName"\r\n',
    );
    buffer.write('Content-Type: application/octet-stream\r\n\r\n');

    final headerBytes = utf8.encode(buffer.toString());
    final tailBytes = utf8.encode('\r\n--$boundary--\r\n');

    request.contentLength =
        headerBytes.length + fileBytes.length + tailBytes.length;
    request.add(headerBytes);
    request.add(fileBytes);
    request.add(tailBytes);

    final response = await request.close();
    final respBody = await response.transform(utf8.decoder).join();
    try {
      return jsonDecode(respBody) as Map<String, dynamic>;
    } catch (_) {
      // Synology sometimes returns HTML on error
      return <String, dynamic>{
        'success': false,
        'error': {'code': -1, 'detail': respBody},
      };
    }
  }

  // ── Synology Photos (SYNO.Foto / SYNO.FotoTeam) ─────────────

  /// Build the correct API name for personal or shared space.
  String _fotoApi(String suffix, {bool shared = false}) =>
      shared ? 'SYNO.FotoTeam.$suffix' : 'SYNO.Foto.$suffix';

  /// List photos/videos, optionally filtered by album.
  Future<Map<String, dynamic>> listPhotos({
    int offset = 0,
    int limit = 100,
    String sortBy = 'takentime',
    String sortDirection = 'desc',
    bool shared = false,
    int? albumId,
  }) async {
    final params = <String, String>{
      'api': _fotoApi('Browse.Item', shared: shared),
      'version': '1',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
      'sort_by': sortBy,
      'sort_direction': sortDirection,
      'additional':
          '["thumbnail","resolution","orientation","video_convert","video_meta"]',
    };
    if (albumId != null) params['album_id'] = '$albumId';
    return _post('entry.cgi', params);
  }

  /// Count all items in personal or shared space.
  Future<Map<String, dynamic>> countPhotos({bool shared = false}) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Browse.Item', shared: shared),
      'version': '1',
      'method': 'count',
    });
  }

  /// List user-created (normal) albums.
  Future<Map<String, dynamic>> listAlbums({
    int offset = 0,
    int limit = 100,
    bool shared = false,
  }) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Browse.NormalAlbum', shared: shared),
      'version': '1',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
    });
  }

  /// Create a normal album.
  Future<Map<String, dynamic>> createPhotoAlbum(String name) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Foto.Browse.NormalAlbum',
      'version': '1',
      'method': 'create',
      'name': name,
    });
  }

  /// Add items to an album.
  Future<Map<String, dynamic>> addItemsToAlbum({
    required int albumId,
    required List<int> itemIds,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Foto.Browse.NormalAlbum',
      'version': '1',
      'method': 'add_item',
      'id': '$albumId',
      'item': jsonEncode(itemIds),
    });
  }

  /// Remove items from an album.
  Future<Map<String, dynamic>> removeItemsFromAlbum({
    required int albumId,
    required List<int> itemIds,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Foto.Browse.NormalAlbum',
      'version': '1',
      'method': 'remove_item',
      'id': '$albumId',
      'item': jsonEncode(itemIds),
    });
  }

  /// Delete an album (does not delete the photos themselves).
  Future<Map<String, dynamic>> deletePhotoAlbum(int id) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Foto.Browse.NormalAlbum',
      'version': '1',
      'method': 'delete',
      'id': jsonEncode([id]),
    });
  }

  /// Delete photos/videos permanently.
  Future<Map<String, dynamic>> deletePhotos({
    required List<int> ids,
    bool shared = false,
  }) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Browse.Item', shared: shared),
      'version': '1',
      'method': 'delete',
      'id': jsonEncode(ids),
    });
  }

  /// Search photos by keyword.
  Future<Map<String, dynamic>> searchPhotos({
    required String keyword,
    int offset = 0,
    int limit = 100,
    bool shared = false,
  }) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Search.Filter', shared: shared),
      'version': '2',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
      'keyword': keyword,
      'additional':
          '["thumbnail","resolution","orientation","video_convert","video_meta"]',
    });
  }

  /// List folders in Synology Photos personal space.
  Future<Map<String, dynamic>> listPhotoFolders({
    int folderId = 0,
    int offset = 0,
    int limit = 100,
    bool shared = false,
  }) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Browse.Folder', shared: shared),
      'version': '1',
      'method': 'list',
      'id': '$folderId',
      'offset': '$offset',
      'limit': '$limit',
    });
  }

  /// Build thumbnail URL for a Synology Photos item.
  String getPhotoThumbUrl(
    int id,
    String cacheKey, {
    String size = 'm',
    bool shared = false,
  }) {
    final api = shared ? 'SYNO.FotoTeam.Thumbnail' : 'SYNO.Foto.Thumbnail';
    final params = {
      'api': api,
      'version': '2',
      'method': 'get',
      'id': '$id',
      'cache_key': cacheKey,
      'size': size,
      'type': 'unit',
      if (_sid != null) '_sid': _sid!,
    };
    return Uri.parse(
      '$baseUrl/entry.cgi',
    ).replace(queryParameters: params).toString();
  }

  /// Build download URL for Synology Photos items.
  String getPhotoDownloadUrl(List<int> ids, {bool shared = false}) {
    final api = shared ? 'SYNO.FotoTeam.Download' : 'SYNO.Foto.Download';
    final params = {
      'api': api,
      'version': '2',
      'method': 'download',
      'unit_id': jsonEncode(ids),
      if (_sid != null) '_sid': _sid!,
    };
    return Uri.parse(
      '$baseUrl/entry.cgi',
    ).replace(queryParameters: params).toString();
  }

  /// Upload a photo to Synology Photos via FileStation (auto-indexed).
  /// [destFolder] is the target path inside /photo, e.g. "/photo/Backup".
  Future<Map<String, dynamic>> uploadPhotoViaFS({
    required String destFolder,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    return uploadFile(
      destFolderPath: destFolder,
      fileName: fileName,
      fileBytes: fileBytes,
    );
  }

  /// Get detailed photo info including EXIF, tags, and description.
  Future<Map<String, dynamic>> getPhotoInfo({
    required List<int> ids,
    bool shared = false,
  }) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Browse.Item', shared: shared),
      'version': '1',
      'method': 'get',
      'id': jsonEncode(ids),
      'additional':
          '["thumbnail","resolution","orientation","exif","video_meta","tag","description"]',
    });
  }

  /// Set rating for a photo/video (0‐5). Rating ≥ 1 = "favorited".
  Future<Map<String, dynamic>> setPhotoRating({
    required int id,
    required int rating,
    bool shared = false,
  }) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Browse.Item', shared: shared),
      'version': '1',
      'method': 'set',
      'id': jsonEncode([id]),
      'rating': '$rating',
    });
  }

  /// Create a sharing link for Synology Photos items.
  Future<Map<String, dynamic>> createPhotoShareLink({
    required List<int> itemIds,
    bool shared = false,
  }) async {
    return _post('entry.cgi', {
      'api': _fotoApi('Sharing.Passphrase', shared: shared),
      'version': '1',
      'method': 'set',
      'item_id': jsonEncode(itemIds),
    });
  }

  /// Rename an album.
  Future<Map<String, dynamic>> renamePhotoAlbum({
    required int id,
    required String name,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Foto.Browse.NormalAlbum',
      'version': '1',
      'method': 'set',
      'id': jsonEncode([id]),
      'name': name,
    });
  }

  // ── Quota Management ─────────────────────────────────────────────

  /// List user quota settings for all volumes.
  Future<Map<String, dynamic>> listQuota() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Quota',
      'version': '1',
      'method': 'get',
    });
  }

  /// Set quota for a user on a specific volume.
  /// [quota] is in MB. Set to 0 for unlimited.
  Future<Map<String, dynamic>> setUserQuota({
    required String user,
    required String volume,
    required int quotaMB,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.Quota',
      'version': '1',
      'method': 'set',
      'user': user,
      'volume': volume,
      'quota': '${quotaMB * 1024 * 1024}', // Convert MB to bytes
    });
  }

  // ── Share / Folder Permissions ────────────────────────────────────

  /// List shared folder permissions.
  Future<Map<String, dynamic>> listSharePermissions({
    required String name,
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Share.Permission',
      'version': '1',
      'method': 'list',
      'name': name,
    });
  }

  /// Set permission for a user/group on a shared folder.
  /// [permission] can be: "rw" (read-write), "ro" (read-only), "no" (no access).
  Future<Map<String, dynamic>> setSharePermission({
    required String name,
    required String userOrGroup,
    required String permission,
    bool isGroup = false,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.Share.Permission',
      'version': '1',
      'method': 'set',
      'name': name,
      'user_group_type': isGroup ? 'local_group' : 'local_user',
      'user_group': userOrGroup,
      'permission': permission,
    });
  }

  /// Set share permission via compound GET (bypasses DSM 7 CSRF).
  /// [perm]: "rw" | "ro" | "deny" | "none"
  Future<bool> setSharePermissionDsm({
    required String shareName,
    required String userName,
    required String perm,
  }) async {
    final bool writable, readonly, deny;
    switch (perm) {
      case 'rw':
        writable = true; readonly = false; deny = false;
      case 'ro':
        writable = false; readonly = true; deny = false;
      case 'deny':
        writable = false; readonly = false; deny = true;
      default: // 'none' = inherit from group
        writable = false; readonly = false; deny = false;
    }

    final results = await _compoundGet([
      {
        'api': 'SYNO.Core.Share.Permission',
        'version': 1,
        'method': 'set',
        'name': shareName,
        'user_group_type': 'local_user',
        'permissions': [
          {
            'name': userName,
            'is_writable': writable,
            'is_deny': deny,
            'is_readonly': readonly,
          }
        ],
      },
    ]);
    return results.isNotEmpty && results[0]['success'] == true;
  }

  // ── User Home Directory ──────────────────────────────────────────

  /// Get status of user home service.
  Future<Map<String, dynamic>> getUserHomeStatus() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.User.Home',
      'version': '1',
      'method': 'get',
    });
  }

  /// Enable or disable user home service.
  Future<Map<String, dynamic>> setUserHomeEnabled({
    required bool enabled,
  }) async {
    return _post('entry.cgi', {
      'api': 'SYNO.Core.User.Home',
      'version': '1',
      'method': 'set',
      'enable': enabled ? 'true' : 'false',
    });
  }

  // ── DSM Admin Session ───────────────────────────────────────────
  //
  // Some admin-only APIs (Share.Permission, AppPriv, Quota) require
  // a session created with session=DSM + X-SYNO-TOKEN header.
  // These are accessed via SYNO.Entry.Request compound requests.

  String? _dsmSid;
  String? _synoToken;

  /// Login with DSM session type for admin APIs.
  /// Falls back to the existing _sid if DSM login fails.
  Future<void> ensureDsmSession(String account, String passwd) async {
    if (_dsmSid != null && _synoToken != null) return;
    await _ensureHostResolved();
    final resp = await _get('entry.cgi', {
      'api': 'SYNO.API.Auth',
      'version': '7',
      'method': 'login',
      'account': account,
      'passwd': passwd,
      'session': 'DSM',
      'format': 'sid',
      'enable_syno_token': 'yes',
    });
    if (resp['success'] == true) {
      _dsmSid = resp['data']?['sid'] as String?;
      _synoToken = resp['data']?['synotoken'] as String?;
    }
  }

  /// Clear DSM admin session (call on logout).
  void clearDsmSession() {
    _dsmSid = null;
    _synoToken = null;
  }

  /// Send a compound GET request via SYNO.Entry.Request.
  /// [items] is a list of API call descriptors (maps).
  /// Returns the list of results.
  Future<List<Map<String, dynamic>>> _compoundGet(
    List<Map<String, dynamic>> items,
  ) async {
    final sid = _dsmSid ?? _sid;
    if (sid == null) return [];

    final compoundJson = jsonEncode(items);
    final params = {
      'api': 'SYNO.Entry.Request',
      'version': '1',
      'method': 'request',
      'stop_when_error': 'false',
      'compound': compoundJson,
      '_sid': sid,
    };

    final uri = Uri.parse('$baseUrl/entry.cgi').replace(
      queryParameters: params,
    );

    final request = await _getClient().getUrl(uri);
    if (_synoToken != null) {
      request.headers.set('X-SYNO-TOKEN', _synoToken!);
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['success'] == true) {
      final resultList = json['data']?['result'] as List? ?? [];
      return resultList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// GET with DSM session + X-SYNO-TOKEN header.
  Future<Map<String, dynamic>> _dsmGet(
    String endpoint,
    Map<String, String> params,
  ) async {
    final sid = _dsmSid ?? _sid;
    if (sid != null) params['_sid'] = sid;

    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: params,
    );

    final request = await _getClient().getUrl(uri);
    if (_synoToken != null) {
      request.headers.set('X-SYNO-TOKEN', _synoToken!);
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ── Shared Folder Permissions ───────────────────────────────────

  /// List all shared folders via DSM session (names, volumes, descriptions).
  Future<Map<String, dynamic>> listDsmSharedFolders() async {
    return _dsmGet('entry.cgi', {
      'api': 'SYNO.Core.Share',
      'version': '1',
      'method': 'list',
    });
  }

  /// Get a user's permissions on all shared folders.
  /// Returns share list with is_writable, is_readonly, is_deny, inherit.
  /// Requires DSM session. Uses compound request.
  Future<Map<String, dynamic>> getSharePermissionsByUser(String userName) async {
    final results = await _compoundGet([
      {
        'api': 'SYNO.Core.Share.Permission',
        'version': 1,
        'method': 'list_by_user',
        'name': userName,
        'user_group_type': 'local_user',
      },
    ]);
    if (results.isNotEmpty && results[0]['success'] == true) {
      return {'success': true, 'data': results[0]['data']};
    }
    final err = results.isNotEmpty ? results[0]['error'] : null;
    final errCode = err is Map ? err['code'] : null;
    return {'success': false, 'error': {'code': errCode ?? -1}};
  }

  // ── Application Privileges ─────────────────────────────────────

  /// List all applications that can have privileges set.
  Future<Map<String, dynamic>> listAppPrivApps() async {
    return _dsmGet('entry.cgi', {
      'api': 'SYNO.Core.AppPriv.App',
      'version': '2',
      'method': 'list',
    });
  }

  /// Get privilege rules for a specific application.
  /// Returns rules with entity_name, entity_type, allow_ip, deny_ip.
  Future<List<Map<String, dynamic>>> getAppPrivRules(String appId) async {
    final results = await _compoundGet([
      {
        'api': 'SYNO.Core.AppPriv.Rule',
        'version': 1,
        'method': 'list',
        'app_id': appId,
      },
    ]);
    if (results.isNotEmpty && results[0]['success'] == true) {
      final rules = results[0]['data']?['rules'] as List? ?? [];
      return rules.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Get privilege rules for ALL apps in one compound batch.
  /// Returns a map of appId → list of rules.
  Future<Map<String, List<Map<String, dynamic>>>> getAllAppPrivRules(
    List<String> appIds,
  ) async {
    final items = appIds
        .map((id) => {
              'api': 'SYNO.Core.AppPriv.Rule',
              'version': 1,
              'method': 'list',
              'app_id': id,
            })
        .toList();

    final results = await _compoundGet(items);
    final map = <String, List<Map<String, dynamic>>>{};
    for (var i = 0; i < results.length && i < appIds.length; i++) {
      if (results[i]['success'] == true) {
        final rules = results[i]['data']?['rules'] as List? ?? [];
        map[appIds[i]] = rules.cast<Map<String, dynamic>>();
      } else {
        map[appIds[i]] = [];
      }
    }
    return map;
  }

  /// Set app privilege rules (allow/deny).
  Future<bool> setAppPrivRules(List<Map<String, dynamic>> rules) async {
    final results = await _compoundGet([
      {
        'api': 'SYNO.Core.AppPriv.Rule',
        'version': 1,
        'method': 'set',
        'rules': rules,
      },
    ]);
    return results.isNotEmpty && results[0]['success'] == true;
  }

  /// Set app privilege for a single user: "allow", "deny", or "remove".
  Future<bool> setAppPrivForUser({
    required String appId,
    required String userName,
    required String action, // "allow" | "deny" | "remove"
  }) async {
    if (action == 'remove') {
      final results = await _compoundGet([
        {
          'api': 'SYNO.Core.AppPriv.Rule',
          'version': 1,
          'method': 'delete',
          'app_id': appId,
          'entity_name': userName,
          'entity_type': 'user',
        },
      ]);
      return results.isNotEmpty && results[0]['success'] == true;
    }

    final allowIp = action == 'allow' ? ['all'] : [];
    final denyIp = action == 'deny' ? ['all'] : [];
    return setAppPrivRules([
      {
        'app_id': appId,
        'entity_name': userName,
        'entity_type': 'user',
        'allow_ip': allowIp,
        'deny_ip': denyIp,
      }
    ]);
  }

  // ── Storage Quota ──────────────────────────────────────────────

  /// Get a user's storage quotas via DSM session.
  Future<Map<String, dynamic>> getDsmUserQuota(String userName) async {
    return _dsmGet('entry.cgi', {
      'api': 'SYNO.Core.Quota',
      'version': '1',
      'method': 'get',
      'name': userName,
    });
  }

  /// Set a user's storage quotas via DSM session.
  /// [quotas] is a list of {share_name, quota_value} maps.
  /// Pass empty list to remove all quotas (unlimited).
  Future<bool> setDsmUserQuota(
    String userName,
    List<Map<String, dynamic>> quotas,
  ) async {
    final results = await _compoundGet([
      {
        'api': 'SYNO.Core.Quota',
        'version': 1,
        'method': 'set',
        'name': userName,
        'user_quota': quotas,
      },
    ]);
    return results.isNotEmpty && results[0]['success'] == true;
  }

  // ── Group Members (admin query) ────────────────────────────────

  /// List members of a specific group (uses DSM session).
  Future<Map<String, dynamic>> listGroupMembers(String groupName) async {
    return _dsmGet('entry.cgi', {
      'api': 'SYNO.Core.Group.Member',
      'version': '1',
      'method': 'list',
      'group': groupName,
      'offset': '0',
      'limit': '200',
    });
  }
}
