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

  /// Build a [HttpClient] that accepts self-signed certs (typical on NAS).
  HttpClient _buildClient() {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = (cert, host, port) => true;
    return client;
  }

  Future<Map<String, dynamic>> _get(
    String endpoint,
    Map<String, String> params,
  ) async {
    if (_sid != null) params['_sid'] = _sid!;

    final uri = Uri.parse(
      '$baseUrl/$endpoint',
    ).replace(queryParameters: params);

    final ioClient = _buildClient();
    try {
      final request = await ioClient.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json;
    } finally {
      ioClient.close();
    }
  }

  /// POST helper for write operations (create, edit, delete).
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, String> params,
  ) async {
    if (_sid != null) params['_sid'] = _sid!;

    final uri = Uri.parse('$baseUrl/$endpoint');

    final ioClient = _buildClient();
    try {
      final request = await ioClient.postUrl(uri);
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
    } finally {
      ioClient.close();
    }
  }

  // ── Authentication ───────────────────────────────────────────────

  /// Login and obtain a session id.
  /// Returns the full API response map. Throws on network / parse errors.
  /// Pass [otpCode] for accounts with 2-step verification enabled.
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
    final resp = await _get('auth.cgi', params);

    if (resp['success'] == true) {
      _sid = resp['data']?['sid'] as String?;
    }
    return resp;
  }

  /// Logout and clear the session.
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

  /// List all installed packages and their running status.
  Future<Map<String, dynamic>> getPackages() async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.Package',
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
  Future<Map<String, dynamic>> getLogs({
    int offset = 0,
    int limit = 50,
    String logType = 'general',
  }) async {
    // Try SYNO.Core.SyslogClient.Log first (DSM 7+)
    try {
      final resp = await _get('entry.cgi', {
        'api': 'SYNO.Core.SyslogClient.Log.List',
        'version': '1',
        'method': 'get',
        'offset': '$offset',
        'limit': '$limit',
        'log_type': logType,
      });
      if (resp['success'] == true) return resp;
    } catch (_) {}

    // Fallback: older log API
    return _get('entry.cgi', {
      'api': 'SYNO.SyslogClient.Log',
      'version': '2',
      'method': 'list',
      'offset': '$offset',
      'limit': '$limit',
    });
  }

  /// Fetch connection logs (login history).
  Future<Map<String, dynamic>> getConnectionLogs({
    int offset = 0,
    int limit = 50,
  }) async {
    return _get('entry.cgi', {
      'api': 'SYNO.Core.SyslogClient.Log.List',
      'version': '1',
      'method': 'get',
      'offset': '$offset',
      'limit': '$limit',
      'log_type': 'connection',
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

    final ioClient = _buildClient();
    try {
      final request = await ioClient.postUrl(uri);

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
    } finally {
      ioClient.close();
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
}
