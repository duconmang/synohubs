import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/nas_profile.dart';

/// Manages NAS profiles with encrypted storage via flutter_secure_storage.
/// Profiles are scoped per Google account email.
/// No data ever stored on any external server — 100% on-device encrypted.
class NasProfileStore {
  NasProfileStore._();
  static final NasProfileStore instance = NasProfileStore._();

  static const _legacyKey = 'nas_profiles_v1';
  static const _keyPrefix = 'nas_profiles_';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _storageKey = _legacyKey;
  List<NasProfile> _profiles = [];
  bool _loaded = false;

  List<NasProfile> get profiles => List.unmodifiable(_profiles);

  /// Set the current user and derive a per-user storage key.
  /// Must be called before [load]. Resets in-memory state so [load] re-reads.
  Future<void> setUser(String email) async {
    final normalized = email.toLowerCase().trim();
    _storageKey = normalized.isEmpty
        ? _legacyKey
        : '${_keyPrefix}${base64Url.encode(utf8.encode(normalized))}';
    _profiles = [];
    _loaded = false;
  }

  /// Migrate legacy (unscoped) profiles to a per-user key if needed.
  /// Call once after first successful sign-in.
  Future<void> _migrateIfNeeded() async {
    final legacy = await _storage.read(key: _legacyKey);
    if (legacy != null && legacy.isNotEmpty && _storageKey != _legacyKey) {
      final existing = await _storage.read(key: _storageKey);
      if (existing == null || existing.isEmpty) {
        // Move legacy data to this user's key
        await _storage.write(key: _storageKey, value: legacy);
      }
      await _storage.delete(key: _legacyKey);
    }
  }

  /// Load all saved NAS profiles from encrypted storage.
  Future<void> load() async {
    if (_loaded) return;
    await _migrateIfNeeded();
    final raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      _profiles = NasProfile.decodeList(raw);
    }
    _loaded = true;
  }

  Future<void> _save() async {
    await _storage.write(
      key: _storageKey,
      value: NasProfile.encodeList(_profiles),
    );
  }

  /// Add a new NAS profile.
  Future<void> add(NasProfile profile) async {
    _profiles.add(profile);
    await _save();
  }

  /// Update an existing profile (matched by id).
  Future<void> update(NasProfile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      _profiles[idx] = profile;
      await _save();
    }
  }

  /// Remove a profile by id.
  Future<void> remove(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _save();
  }

  /// Find a profile by id.
  NasProfile? find(String id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Export all profiles as encrypted JSON string (for Google Drive backup).
  Future<String> exportJson() async {
    await load();
    return NasProfile.encodeList(_profiles);
  }

  /// Import profiles from JSON string (Google Drive restore).
  Future<void> importJson(String json) async {
    _profiles = NasProfile.decodeList(json);
    await _save();
  }

  /// Clear all stored data for current user.
  Future<void> clear() async {
    _profiles.clear();
    await _storage.delete(key: _storageKey);
    _loaded = false;
  }
}
