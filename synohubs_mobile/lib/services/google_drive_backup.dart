import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'google_auth_service.dart';

/// Backup/restore NAS configs to the user's own Google Drive.
/// Uses the appDataFolder scope — files are hidden and only accessible
/// by this app. No server involvement whatsoever.
class GoogleDriveBackup {
  GoogleDriveBackup._();
  static final GoogleDriveBackup instance = GoogleDriveBackup._();

  static const _fileName = 'synohub_nas_profiles.enc';
  static const _keyFileName = 'synohub_backup_key.dat';
  static const _keyStorageKey = 'backup_encryption_key';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Get or generate a 256-bit AES key stored in secure storage.
  Future<enc.Key> _getEncryptionKey() async {
    var keyBase64 = await _storage.read(key: _keyStorageKey);
    if (keyBase64 == null || keyBase64.isEmpty) {
      final random = Random.secure();
      final keyBytes = Uint8List.fromList(
        List.generate(32, (_) => random.nextInt(256)),
      );
      keyBase64 = base64Encode(keyBytes);
      await _storage.write(key: _keyStorageKey, value: keyBase64);
    }
    return enc.Key.fromBase64(keyBase64);
  }

  /// AES-CBC encrypt with random IV prepended to output.
  Future<String> _encrypt(String plaintext) async {
    final key = await _getEncryptionKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // Prepend IV so we can decrypt later: base64(iv + ciphertext)
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    return base64Encode(combined);
  }

  /// AES-CBC decrypt with a specific key, reading IV from first 16 bytes.
  String _decryptWithKey(String cipherBase64, enc.Key key) {
    final combined = base64Decode(cipherBase64.trim());
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipherBytes = combined.sublist(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt(
      enc.Encrypted(Uint8List.fromList(cipherBytes)),
      iv: iv,
    );
  }

  /// AES-CBC decrypt, reading IV from first 16 bytes.
  Future<String> _decrypt(String cipherBase64) async {
    final key = await _getEncryptionKey();
    return _decryptWithKey(cipherBase64, key);
  }

  Future<drive.DriveApi> _getDriveApi() async {
    final authClient = await GoogleAuthService.instance.googleSignIn
        .authenticatedClient();
    if (authClient == null) {
      throw Exception('Not authenticated with Google');
    }
    return drive.DriveApi(authClient);
  }

  // ── Drive-backed encryption key ──────────────────────────────────

  /// Read the encryption key backup from Google Drive.
  Future<String?> _readKeyFromDrive(drive.DriveApi driveApi) async {
    try {
      final result = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_keyFileName'",
        $fields: 'files(id)',
      );
      if (result.files == null || result.files!.isEmpty) return null;

      final fileId = result.files!.first.id!;
      final response =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      final key = utf8.decode(bytes).trim();
      return key.isNotEmpty ? key : null;
    } catch (_) {
      return null;
    }
  }

  /// Persist the encryption key to Google Drive for recovery.
  Future<void> _saveKeyToDrive(
    drive.DriveApi driveApi,
    String keyBase64,
  ) async {
    try {
      final existing = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_keyFileName'",
        $fields: 'files(id)',
      );
      final bytes = utf8.encode(keyBase64);
      final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

      if (existing.files != null && existing.files!.isNotEmpty) {
        await driveApi.files.update(
          drive.File(),
          existing.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        final file = drive.File()
          ..name = _keyFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(file, uploadMedia: media);
      }
    } catch (_) {
      // Best-effort — don't fail the backup if key save fails
    }
  }

  // ── Backup / Restore ────────────────────────────────────────────

  /// Backup JSON string to Google Drive appDataFolder (AES encrypted).
  Future<void> backup(String jsonData) async {
    final driveApi = await _getDriveApi();
    final encrypted = await _encrypt(jsonData);

    // Check if file already exists
    final existing = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      $fields: 'files(id)',
    );

    final bytes = utf8.encode(encrypted);
    final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);

    if (existing.files != null && existing.files!.isNotEmpty) {
      // Update existing file
      await driveApi.files.update(
        drive.File(),
        existing.files!.first.id!,
        uploadMedia: media,
      );
    } else {
      // Create new file in appDataFolder
      final file = drive.File()
        ..name = _fileName
        ..parents = ['appDataFolder'];

      await driveApi.files.create(file, uploadMedia: media);
    }

    // Also persist encryption key to Drive for recovery
    final keyBase64 = await _storage.read(key: _keyStorageKey);
    if (keyBase64 != null) {
      await _saveKeyToDrive(driveApi, keyBase64);
    }
  }

  /// Restore JSON string from Google Drive appDataFolder (AES decrypted).
  /// Returns null if no backup found.
  Future<String?> restore() async {
    final driveApi = await _getDriveApi();

    final result = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      $fields: 'files(id)',
    );

    if (result.files == null || result.files!.isEmpty) {
      return null;
    }

    final fileId = result.files!.first.id!;
    final response =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }

    final raw = utf8.decode(bytes).trim();

    // 1) Try decrypting with local key
    try {
      return await _decrypt(raw);
    } catch (_) {}

    // 2) Local key may be lost — try recovering key from Drive
    final recoveredKey = await _readKeyFromDrive(driveApi);
    if (recoveredKey != null) {
      try {
        final key = enc.Key.fromBase64(recoveredKey);
        final decrypted = _decryptWithKey(raw, key);
        // Restore key to local storage for future use
        await _storage.write(key: _keyStorageKey, value: recoveredKey);
        return decrypted;
      } catch (_) {}
    }

    // 3) Check if raw is valid JSON (old unencrypted backup)
    try {
      jsonDecode(raw);
      return raw;
    } catch (_) {
      throw FormatException(
        'Cannot decrypt backup — encryption key was lost. '
        'Please back up again from a device that still has your profiles.',
      );
    }
  }
}
