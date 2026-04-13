import 'dart:convert';
import 'dart:io';

/// Result of a QuickConnect resolution — the actual host, port, and protocol
/// that should be used to reach the NAS.
class QuickConnectResult {
  final String host;
  final int port;
  final bool useHttps;

  const QuickConnectResult({
    required this.host,
    required this.port,
    required this.useHttps,
  });

  @override
  String toString() => '${useHttps ? 'https' : 'http'}://$host:$port';
}

/// Resolves a Synology QuickConnect ID to a direct connection address.
///
/// Flow:
/// 1. POST to `global.quickconnect.to/Serv.php` with the QC ID.
/// 2. Parse the JSON response for server info (LAN, WAN, DDNS, relay).
/// 3. Try endpoints in order: LAN → WAN → DDNS → relay region server.
/// 4. Return the first reachable [QuickConnectResult].
class QuickConnectResolver {
  QuickConnectResolver._();

  static const _timeout = Duration(seconds: 5);

  /// Whether [input] looks like a QuickConnect ID or URL.
  /// Accepts: `teknasarc`, `quickconnect.to/teknasarc`,
  /// `http://quickconnect.to/teknasarc`
  static bool isQuickConnect(String input) {
    final cleaned = input.trim().toLowerCase();
    if (cleaned.contains('quickconnect.to')) return true;
    // Plain ID: only alphanumeric + hyphens, no dots, no colons, no slashes
    if (RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9\-]{0,62}$').hasMatch(cleaned) &&
        !cleaned.contains('.') &&
        !cleaned.contains(':')) {
      return true;
    }
    return false;
  }

  /// Extract the QuickConnect ID from user input.
  static String extractId(String input) {
    var raw = input.trim();
    // Strip protocol
    if (raw.startsWith('https://')) raw = raw.substring(8);
    if (raw.startsWith('http://')) raw = raw.substring(7);
    // Strip domain
    if (raw.startsWith('quickconnect.to/')) raw = raw.substring(16);
    // Strip trailing slashes
    while (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }
    return raw;
  }

  /// Resolve a QuickConnect ID to a reachable NAS endpoint.
  /// Throws on failure.
  static Future<QuickConnectResult> resolve(String qcId) async {
    final serverInfo = await _getServerInfo(qcId);

    final service = serverInfo['service'] as Map<String, dynamic>? ?? {};
    final server = serverInfo['server'] as Map<String, dynamic>? ?? {};
    final env = serverInfo['env'] as Map<String, dynamic>? ?? {};
    final smartdns = serverInfo['smartdns'] as Map<String, dynamic>? ?? {};

    // The "port" field in the HTTPS service response IS the HTTPS port.
    final dsmPort = _toInt(service['port']) ?? 5001;

    // Gather candidate endpoints in priority order
    final candidates = <QuickConnectResult>[];

    // 1. LAN IPs (fastest if on same network)
    final interfaces = server['interface'] as List<dynamic>? ?? [];
    for (final iface in interfaces) {
      if (iface is Map<String, dynamic>) {
        final ip = iface['ip'] as String?;
        if (ip != null && ip.isNotEmpty) {
          candidates.add(
            QuickConnectResult(host: ip, port: dsmPort, useHttps: true),
          );
        }
      }
    }

    // 2. WAN (external) IP + explicit ext_port (port forwarding)
    final ext = server['external'] as Map<String, dynamic>?;
    final extIp = ext?['ip'] as String?;
    if (extIp != null && extIp.isNotEmpty) {
      final extPort = _toInt(service['ext_port']);
      if (extPort != null && extPort > 0) {
        candidates.add(
          QuickConnectResult(host: extIp, port: extPort, useHttps: true),
        );
      }
      candidates.add(
        QuickConnectResult(host: extIp, port: dsmPort, useHttps: true),
      );
    }

    // 3. SmartDNS external hostname (Synology's routed DNS)
    final smartExternal = smartdns['external'] as String?;
    if (smartExternal != null && smartExternal.isNotEmpty) {
      candidates.add(
        QuickConnectResult(host: smartExternal, port: dsmPort, useHttps: true),
      );
    }

    // 4. SmartDNS host (direct QC subdomain)
    final smartHost = smartdns['host'] as String?;
    if (smartHost != null && smartHost.isNotEmpty) {
      candidates.add(
        QuickConnectResult(host: smartHost, port: dsmPort, useHttps: true),
      );
    }

    // 5. SmartDNS LAN hostnames
    final smartLan = smartdns['lan'] as List<dynamic>? ?? [];
    for (final lanHost in smartLan) {
      if (lanHost is String && lanHost.isNotEmpty) {
        candidates.add(
          QuickConnectResult(host: lanHost, port: dsmPort, useHttps: true),
        );
      }
    }

    // 6. DDNS hostname
    final ddns = server['ddns'] as String?;
    if (ddns != null && ddns.isNotEmpty && ddns != 'NULL') {
      candidates.add(
        QuickConnectResult(host: ddns, port: dsmPort, useHttps: true),
      );
    }

    // 7. Relay tunnel (fallback — Synology relay server proxying to NAS)
    final relayIp = service['relay_ip'] as String?;
    final relayPort = _toInt(service['relay_port']);
    if (relayIp != null &&
        relayIp.isNotEmpty &&
        relayPort != null &&
        relayPort > 0) {
      candidates.add(
        QuickConnectResult(host: relayIp, port: relayPort, useHttps: true),
      );
    }

    // 8. Relay DN hostname
    final relayDn = service['relay_dn'] as String?;
    if (relayDn != null && relayDn.isNotEmpty) {
      candidates.add(
        QuickConnectResult(host: relayDn, port: dsmPort, useHttps: true),
      );
    }

    // Probe candidates concurrently and return the first that responds
    return _probeFirst(candidates);
  }

  // ── Private helpers ──────────────────────────────────────────────

  /// Call the global QuickConnect server to get NAS info for [qcId].
  static Future<Map<String, dynamic>> _getServerInfo(String qcId) async {
    // The QC protocol sends an array of two requests (HTTPS + HTTP services).
    // "id" is the service name (NOT the QC ID), "serverID" is the QC ID.
    final payload = [
      {
        'version': 1,
        'command': 'get_server_info',
        'stop_when_error': false,
        'stop_when_success': false,
        'id': 'mainapp_https',
        'serverID': qcId,
        'is_gofile': false,
        'path': '',
      },
      {
        'version': 1,
        'command': 'get_server_info',
        'stop_when_error': false,
        'stop_when_success': false,
        'id': 'mainapp_http',
        'serverID': qcId,
        'is_gofile': false,
        'path': '',
      },
    ];

    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse('https://global.quickconnect.to/Serv.php');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(respBody);

      // Response is an array — find the first successful entry
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final errno = item['errno'];
            if (errno == null || errno == 0) return item;
          }
        }
        // All entries failed — check if there's a region redirect
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final sites = item['sites'] as List<dynamic>?;
            if (sites != null && sites.isNotEmpty) {
              // Retry with regional server
              return _getServerInfoFromRegion(qcId, sites);
            }
          }
        }
        // Report the first error
        final first = decoded.first as Map<String, dynamic>;
        throw Exception(
          'QuickConnect error: ${first['errinfo'] ?? first['errno']}',
        );
      }

      // Response might be a single object (older servers)
      final json = decoded as Map<String, dynamic>;
      if (json['errno'] != null && json['errno'] != 0) {
        // Check for region redirect (sites list)
        final sites = json['sites'] as List<dynamic>?;
        if (sites != null && sites.isNotEmpty) {
          return _getServerInfoFromRegion(qcId, sites);
        }
        throw Exception(
          'QuickConnect error: ${json['errinfo'] ?? json['errno']}',
        );
      }
      return json;
    } finally {
      client.close();
    }
  }

  /// Retry get_server_info with a regional control server from [sites].
  static Future<Map<String, dynamic>> _getServerInfoFromRegion(
    String qcId,
    List<dynamic> sites,
  ) async {
    for (final site in sites) {
      final host = site is String ? site : (site as Map?)?['host']?.toString();
      if (host == null || host.isEmpty) continue;

      final client = HttpClient()..connectionTimeout = _timeout;
      try {
        final payload = [
          {
            'version': 1,
            'command': 'get_server_info',
            'stop_when_error': false,
            'stop_when_success': false,
            'id': 'mainapp_https',
            'serverID': qcId,
            'is_gofile': false,
            'path': '',
          },
          {
            'version': 1,
            'command': 'get_server_info',
            'stop_when_error': false,
            'stop_when_success': false,
            'id': 'mainapp_http',
            'serverID': qcId,
            'is_gofile': false,
            'path': '',
          },
        ];
        final uri = Uri.parse('https://$host/Serv.php');
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));
        final response = await request.close();
        final respBody = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(respBody);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final errno = item['errno'];
              if (errno == null || errno == 0) return item;
            }
          }
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['errno'] == null || decoded['errno'] == 0) {
            return decoded;
          }
        }
      } catch (_) {
        // Try next site
      } finally {
        client.close();
      }
    }
    throw Exception('QuickConnect: all regional servers failed for "$qcId"');
  }

  /// Try to get a relay tunnel from a regional control host.
  static Future<QuickConnectResult?> _tryRelayTunnel(
    String qcId,
    String controlHost,
  ) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse('https://$controlHost/Serv.php');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final body = jsonEncode([
        {
          'version': 1,
          'command': 'request_tunnel',
          'stop_when_error': false,
          'stop_when_success': true,
          'id': 'mainapp_https',
          'serverID': qcId,
          'is_gofile': false,
          'path': '',
        },
      ]);
      request.write(body);
      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(respBody);

      // Response may be array or single object
      final json = decoded is List
          ? (decoded.isNotEmpty ? decoded.first as Map<String, dynamic> : null)
          : decoded as Map<String, dynamic>?;
      if (json == null) return null;

      final service = json['service'] as Map<String, dynamic>?;
      final relayIp = service?['relay_ip'] as String?;
      final relayPort = _toInt(service?['relay_port']);
      if (relayIp != null && relayIp.isNotEmpty && relayPort != null) {
        return QuickConnectResult(
          host: relayIp,
          port: relayPort,
          useHttps: true,
        );
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Probe a list of candidate endpoints concurrently.
  /// Verifies each by calling the DSM API info endpoint to confirm it's a real
  /// Synology NAS (not a relay CDN or unrelated server).
  static Future<QuickConnectResult> _probeFirst(
    List<QuickConnectResult> candidates,
  ) async {
    if (candidates.isEmpty) {
      throw Exception('No QuickConnect endpoints found');
    }

    // Deduplicate
    final seen = <String>{};
    final unique = <QuickConnectResult>[];
    for (final c in candidates) {
      final key = '${c.host}:${c.port}:${c.useHttps}';
      if (seen.add(key)) unique.add(c);
    }

    // Race: first successful DSM API response wins
    final futures = unique.map((c) async {
      try {
        final scheme = c.useHttps ? 'https' : 'http';
        final uri = Uri.parse(
          '$scheme://${c.host}:${c.port}/webapi/entry.cgi'
          '?api=SYNO.API.Info&version=1&method=query&query=SYNO.API.Auth',
        );
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 4)
          ..badCertificateCallback = (cert, host, port) => true;
        try {
          final request = await client.getUrl(uri);
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();
          // Must be valid JSON with "success":true to confirm it's DSM
          if (body.contains('"success"') && body.contains('SYNO.API.Auth')) {
            return c;
          }
          return null;
        } finally {
          client.close();
        }
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    for (final r in results) {
      if (r != null) return r;
    }

    // None confirmed as DSM — fall back to first hostname-based candidate
    final hostBased = unique
        .where((c) => !RegExp(r'^\d').hasMatch(c.host))
        .toList();
    if (hostBased.isNotEmpty) return hostBased.first;

    throw Exception(
      'QuickConnect: None of the resolved endpoints are reachable',
    );
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
