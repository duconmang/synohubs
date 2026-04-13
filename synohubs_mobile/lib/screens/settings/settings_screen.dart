import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'connection_settings.dart';
import 'appearance_settings.dart';
import 'about_screen.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.settings,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Connection ──
            _sectionLabel(l.nasConnection),
            const SizedBox(height: 10),
            GlassCard(
              borderRadius: 22,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _tile(
                    context,
                    icon: Icons.lan,
                    color: AppColors.primaryContainer,
                    title: l.connection,
                    subtitle: '192.168.1.50 : 5001 (HTTPS)',
                    onTap: () => _push(context, const ConnectionSettings()),
                  ),
                  _divider(),
                  _statusTile(context),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Appearance ──
            _sectionLabel(l.appearance),
            const SizedBox(height: 10),
            GlassCard(
              borderRadius: 22,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _tile(
                    context,
                    icon: Icons.palette_outlined,
                    color: AppColors.tertiary,
                    title: l.themeAndColors,
                    subtitle: l.darkCyanAccent,
                    onTap: () => _push(context, const AppearanceSettings()),
                  ),
                  _divider(),
                  _tile(
                    context,
                    icon: Icons.language,
                    color: AppColors.secondary,
                    title: l.language,
                    subtitle: l.languageEnglish,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Notifications ──
            _sectionLabel(l.notifications),
            const SizedBox(height: 10),
            GlassCard(
              borderRadius: 22,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.notifications_active_outlined,
                    color: AppColors.primaryContainer,
                    title: l.pushNotifications,
                    value: true,
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.warning_amber,
                    color: AppColors.tertiary,
                    title: l.systemAlerts,
                    value: true,
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.backup_outlined,
                    color: AppColors.secondary,
                    title: l.backupAlerts,
                    value: true,
                  ),
                  _divider(),
                  _switchTile(
                    icon: Icons.disc_full_outlined,
                    color: AppColors.error,
                    title: l.storageWarnings,
                    value: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── About ──
            _sectionLabel(l.about),
            const SizedBox(height: 10),
            GlassCard(
              borderRadius: 22,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _tile(
                    context,
                    icon: Icons.info_outline,
                    color: AppColors.primary,
                    title: l.aboutSynoHub,
                    subtitle: l.version,
                    onTap: () => _push(context, const AboutScreen()),
                  ),
                  _divider(),
                  _tile(
                    context,
                    icon: Icons.system_update_outlined,
                    color: AppColors.secondary,
                    title: l.checkForUpdates,
                    subtitle: l.upToDate,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (_) {},
            activeThumbColor: AppColors.primaryContainer,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.outline,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _statusTile(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wifi, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.connected,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(
        height: 1,
        color: AppColors.outlineVariant.withValues(alpha: 0.15),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
