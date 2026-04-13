import 'dart:convert';

/// Represents a saved NAS connection profile.
class NasProfile {
  final String id;
  String nickname;
  String host;
  int port;
  String protocol; // 'http' or 'https'
  String username;
  String password;
  String? model; // detected after login, e.g. "DS923+"
  String? dsmVersion;
  DateTime? lastConnected;
  bool isOnline;

  NasProfile({
    required this.id,
    required this.nickname,
    required this.host,
    required this.port,
    this.protocol = 'https',
    required this.username,
    required this.password,
    this.model,
    this.dsmVersion,
    this.lastConnected,
    this.isOnline = false,
  });

  bool get useHttps => protocol == 'https';

  String get displayAddress => '$host:$port';

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'host': host,
    'port': port,
    'protocol': protocol,
    'username': username,
    'password': password,
    'model': model,
    'dsmVersion': dsmVersion,
    'lastConnected': lastConnected?.toIso8601String(),
  };

  factory NasProfile.fromJson(Map<String, dynamic> json) => NasProfile(
    id: json['id'] as String,
    nickname: json['nickname'] as String? ?? '',
    host: json['host'] as String,
    port: json['port'] as int? ?? 5001,
    protocol: json['protocol'] as String? ?? 'https',
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    model: json['model'] as String?,
    dsmVersion: json['dsmVersion'] as String?,
    lastConnected: json['lastConnected'] != null
        ? DateTime.tryParse(json['lastConnected'] as String)
        : null,
  );

  static String encodeList(List<NasProfile> profiles) =>
      jsonEncode(profiles.map((p) => p.toJson()).toList());

  static List<NasProfile> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list
        .map((e) => NasProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
