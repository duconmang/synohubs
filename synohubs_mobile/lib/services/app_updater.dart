import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Handles checking for app updates and installing them.
class AppUpdater {
  AppUpdater._();

  static const _versionUrl = 'https://synohubs.com/releases/version.json';

  /// Check for updates and show a dialog if a new version is available.
  /// Call this from the main screen after login.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "1.0.0"
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final resp = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final latestVersion = json['version'] as String? ?? currentVersion;
      final latestBuild = json['buildNumber'] as int? ?? currentBuild;
      final apkUrl = json['apkUrl'] as String? ?? '';
      final releaseNotes = json['releaseNotes'] as String? ?? '';

      if (!_isNewer(currentVersion, latestVersion, currentBuild, latestBuild)) {
        return; // Already up to date
      }

      if (!context.mounted) return;

      _showUpdateDialog(
        context,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseNotes: releaseNotes,
        apkUrl: apkUrl,
      );
    } catch (_) {
      // Silently fail — update check should never block the app
    }
  }

  /// Compare versions. Returns true if latest > current.
  static bool _isNewer(
    String current,
    String latest,
    int currentBuild,
    int latestBuild,
  ) {
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final lParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to same length
    while (cParts.length < 3) cParts.add(0);
    while (lParts.length < 3) lParts.add(0);

    for (var i = 0; i < 3; i++) {
      if (lParts[i] > cParts[i]) return true;
      if (lParts[i] < cParts[i]) return false;
    }
    // Same version string → compare build numbers
    return latestBuild > currentBuild;
  }

  /// Show update dialog.
  static void _showUpdateDialog(
    BuildContext context, {
    required String currentVersion,
    required String latestVersion,
    required String releaseNotes,
    required String apkUrl,
  }) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101624),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.system_update,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.updateAvailable,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v$currentVersion → v$latestVersion',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l.whatsNew,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                releaseNotes,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l.later,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _downloadAndInstall(context, apkUrl);
            },
            icon: const Icon(Icons.download, size: 18),
            label: Text(
              l.updateNow,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Download APK and trigger Android install.
  static Future<void> _downloadAndInstall(
    BuildContext context,
    String apkUrl,
  ) async {
    final l = AppLocalizations.of(context)!;

    // Show download progress
    final progressNotifier = ValueNotifier<double>(0.0);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Persistent snackbar with progress
    final snackBar = SnackBar(
      duration: const Duration(minutes: 5),
      backgroundColor: const Color(0xFF101624),
      content: ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (_, progress, __) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.downloading,
              style: GoogleFonts.inter(
                color: AppColors.onSurface,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.surfaceContainerLowest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.jetBrainsMono(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
    scaffoldMessenger.showSnackBar(snackBar);

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/synohub-update.apk';
      final file = File(filePath);

      // Download with progress
      final request = await HttpClient().getUrl(Uri.parse(apkUrl));
      final response = await request.close();
      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          progressNotifier.value = receivedBytes / totalBytes;
        }
      }
      await sink.close();

      scaffoldMessenger.hideCurrentSnackBar();

      // Trigger Android package installer via intent
      await _installApk(filePath);
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${l.updateFailed}: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  /// Launch the Android package installer for the downloaded APK.
  static Future<void> _installApk(String filePath) async {
    const channel = MethodChannel('com.synohub.synohub/installer');
    try {
      await channel.invokeMethod('installApk', {'path': filePath});
    } catch (_) {
      // Fallback: try opening the file directly via shell
      // This works on some devices but not all
      await Process.run('sh', [
        '-c',
        'am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d file://$filePath',
      ]);
    }
  }
}
