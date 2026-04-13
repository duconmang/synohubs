import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show NasCertOverrides;
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../models/nas_profile.dart';
import '../services/nas_profile_store.dart';
import '../services/google_auth_service.dart';
import '../services/google_drive_backup.dart';
import '../services/session_manager.dart';
import '../services/locale_provider.dart';
import '../services/user_tier_provider.dart';
import '../utils/nas_models.dart';
import 'login_screen.dart';

class NasManagerScreen extends StatefulWidget {
  /// Called after the user successfully connects to a NAS.
  final VoidCallback onNasConnected;

  /// Called when the user signs out of Google.
  final VoidCallback onSignOut;

  const NasManagerScreen({
    super.key,
    required this.onNasConnected,
    required this.onSignOut,
  });

  @override
  State<NasManagerScreen> createState() => _NasManagerScreenState();
}

class _NasManagerScreenState extends State<NasManagerScreen> {
  final _store = NasProfileStore.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    await _store.load();
    if (mounted) setState(() => _loading = false);
    // Check each NAS status in parallel
    _checkAllNasStatus();
  }

  /// Ping each NAS concurrently using SYNO.API.Info (lightweight, no auth needed).
  Future<void> _checkAllNasStatus() async {
    final profiles = _store.profiles;
    if (profiles.isEmpty) return;

    // Register all NAS hosts for scoped SSL bypass
    for (final p in profiles) {
      NasCertOverrides.trustHost(p.host);
    }

    final futures = profiles.map((p) => _pingNas(p));
    await Future.wait(futures);

    if (mounted) setState(() {});
    // Persist updated online states
    for (final p in profiles) {
      await _store.update(p);
    }
  }

  /// Try to reach a NAS with a quick API.Info query (timeout 4s).
  Future<void> _pingNas(NasProfile profile) async {
    final scheme = profile.useHttps ? 'https' : 'http';
    final url = Uri.parse(
      '$scheme://${profile.host}:${profile.port}/webapi/query.cgi?api=SYNO.API.Info&version=1&method=query',
    );
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4)
        ..badCertificateCallback = (_, __, ___) => true;
      final request = await client.getUrl(url);
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      profile.isOnline = response.statusCode == 200;
      client.close(force: true);
    } catch (_) {
      profile.isOnline = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = GoogleAuthService.instance;
    final profiles = _store.profiles;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            // Google avatar
            if (auth.photoUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(auth.photoUrl!),
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryContainer.withValues(
                  alpha: 0.15,
                ),
                child: Text(
                  auth.displayName.isNotEmpty
                      ? auth.displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.displayName.isNotEmpty ? auth.displayName : 'SynoHub',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (auth.email.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            auth.email,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (UserTierProvider.instance.isVip) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'VIP',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language switcher
          IconButton(
            icon: const Icon(Icons.language, color: AppColors.onSurfaceVariant),
            onPressed: _showLanguagePicker,
          ),
          // Backup/Restore
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.onSurfaceVariant,
            ),
            color: AppColors.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: _onMenuAction,
            itemBuilder: (_) => [
              _menuItem(
                'backup',
                Icons.cloud_upload_outlined,
                l.backupToGoogleDrive,
              ),
              _menuItem(
                'restore',
                Icons.cloud_download_outlined,
                l.restoreFromGoogleDrive,
              ),
              const PopupMenuDivider(),
              _menuItem('signout', Icons.logout, l.signOut),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : profiles.isEmpty
          ? _buildEmptyState()
          : _buildGrid(profiles),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryContainer,
        icon: const Icon(Icons.add, color: AppColors.onPrimary),
        label: Text(
          l.addNas,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimary,
          ),
        ),
        onPressed: _addNas,
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenuAction(String action) async {
    switch (action) {
      case 'backup':
        await _backupToDrive();
        break;
      case 'restore':
        await _restoreFromDrive();
        break;
      case 'signout':
        await GoogleAuthService.instance.signOut();
        await NasProfileStore.instance.setUser('');
        UserTierProvider.instance.reset();
        widget.onSignOut();
        break;
    }
  }

  Future<void> _backupToDrive() async {
    final l = AppLocalizations.of(context)!;
    _showSnack(l.backingUp);
    try {
      final json = await _store.exportJson();
      await GoogleDriveBackup.instance.backup(json);
      if (mounted) _showSnack(l.backupSuccessful);
    } catch (e) {
      if (mounted) _showSnack(l.backupFailed(e.toString()));
    }
  }

  Future<void> _restoreFromDrive() async {
    final l = AppLocalizations.of(context)!;
    _showSnack(l.restoringFromDrive);
    try {
      final json = await GoogleDriveBackup.instance.restore();
      if (json == null) {
        if (mounted) _showSnack(l.noBackupFound);
        return;
      }
      await _store.importJson(json);
      if (mounted) {
        _showSnack(l.restoreSuccessful);
        setState(() {});
      }
    } catch (e) {
      if (mounted) _showSnack(l.restoreFailed(e.toString()));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Empty state
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dns_outlined,
                size: 36,
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.noNasTitle,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noNasSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NAS Grid
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGrid(List<NasProfile> profiles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.myNas,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.deviceCount(profiles.length),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: profiles.length,
              itemBuilder: (ctx, i) => _buildNasCard(profiles[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNasCard(NasProfile profile) {
    final modelImg = profile.model != null
        ? NasModels.imageFor(profile.model!)
        : '';
    final hasImage = modelImg.isNotEmpty;

    return GestureDetector(
      onTap: () => _connectToNas(profile),
      onLongPress: () => _showNasOptions(profile),
      child: GlassCard(
        borderRadius: 20,
        hasGlow: profile.isOnline,
        borderColor: profile.isOnline
            ? AppColors.secondary
            : AppColors.outlineVariant,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // NAS image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: hasImage
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          modelImg,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _fallbackIcon(),
                        ),
                      )
                    : _fallbackIcon(),
              ),
            ),

            const SizedBox(height: 10),

            // Nickname
            Text(
              profile.nickname.isNotEmpty ? profile.nickname : profile.host,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Model + address
            Text(
              profile.model ?? profile.displayAddress,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Online status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: profile.isOnline
                        ? AppColors.secondary
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  profile.isOnline
                      ? AppLocalizations.of(context)!.online
                      : AppLocalizations.of(context)!.offline,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: profile.isOnline
                        ? AppColors.secondary
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return const Center(
      child: Icon(Icons.dns, size: 40, color: AppColors.primaryContainer),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Connect to NAS
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _connectToNas(NasProfile profile) async {
    setState(() => _loading = true);

    // Try auto re-login with saved credentials
    final err = await SessionManager.instance.login(
      host: profile.host,
      port: profile.port,
      useHttps: profile.useHttps,
      account: profile.username,
      password: profile.password,
    );

    if (!mounted) return;

    if (err != null) {
      // Session expired or pw changed → open NAS login
      setState(() => _loading = false);
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onLoginSuccess: () => Navigator.pop(context, true),
            initialHost: profile.host,
            initialPort: profile.port.toString(),
            initialUser: profile.username,
            initialHttps: profile.useHttps,
          ),
        ),
      );

      if (success == true && mounted) {
        // Update model info after successful login
        await _updateProfileAfterLogin(profile);
        widget.onNasConnected();
      }
    } else {
      // Auto-login success
      await _updateProfileAfterLogin(profile);
      setState(() => _loading = false);
      widget.onNasConnected();
    }
  }

  Future<void> _updateProfileAfterLogin(NasProfile profile) async {
    final info = SessionManager.instance.nasInfo;
    if (info != null) {
      profile.model = info.model;
      profile.dsmVersion = info.dsmVersion;
      profile.lastConnected = DateTime.now();
      profile.isOnline = true;
      await _store.update(profile);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Add new NAS
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _addNas() async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          skipAutoLoad: true,
          onLoginSuccess: () => Navigator.pop(context, true),
        ),
      ),
    );

    if (success == true && mounted) {
      final sm = SessionManager.instance;
      final info = sm.nasInfo;

      // Prompt for nickname
      final nickname = await _askNickname(info?.model ?? sm.host);

      final profile = NasProfile(
        id: const Uuid().v4(),
        nickname: nickname ?? info?.model ?? sm.host,
        host: sm.host,
        port: sm.port,
        protocol: sm.useHttps ? 'https' : 'http',
        username: sm.account,
        password: sm.password,
        model: info?.model,
        dsmVersion: info?.dsmVersion,
        lastConnected: DateTime.now(),
        isOnline: true,
      );

      await _store.add(profile);
      if (mounted) {
        setState(() {});
        widget.onNasConnected();
      }
    }
  }

  Future<String?> _askNickname(String defaultName) async {
    final ctrl = TextEditingController(text: defaultName);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.nameThisNas,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.nasNicknameHint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            prefixIcon: const Icon(
              Icons.edit,
              size: 18,
              color: AppColors.primaryContainer,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryContainer),
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(
              AppLocalizations.of(context)!.save,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Long press NAS options
  // ═══════════════════════════════════════════════════════════════════
  void _showNasOptions(NasProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              profile.nickname.isNotEmpty ? profile.nickname : profile.host,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            if (profile.model != null)
              Text(
                profile.model!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),

            const SizedBox(height: 16),

            _optionTile(Icons.edit, AppLocalizations.of(context)!.rename, () {
              Navigator.pop(ctx);
              _renameNas(profile);
            }),
            _optionTile(
              Icons.info_outline,
              AppLocalizations.of(context)!.details,
              () {
                Navigator.pop(ctx);
                _showNasDetails(profile);
              },
            ),
            _optionTile(
              Icons.delete_outline,
              AppLocalizations.of(context)!.remove,
              () {
                Navigator.pop(ctx);
                _removeNas(profile);
              },
              color: AppColors.error,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? AppColors.onSurface;
    return ListTile(
      leading: Icon(icon, size: 20, color: c),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: c)),
      onTap: onTap,
    );
  }

  Future<void> _renameNas(NasProfile profile) async {
    final name = await _askNickname(profile.nickname);
    if (name != null && name.isNotEmpty && mounted) {
      profile.nickname = name;
      await _store.update(profile);
      setState(() {});
    }
  }

  void _showNasDetails(NasProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          profile.nickname,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info(AppLocalizations.of(context)!.host, profile.displayAddress),
            _info(
              AppLocalizations.of(context)!.protocol,
              profile.protocol.toUpperCase(),
            ),
            _info(AppLocalizations.of(context)!.username, profile.username),
            if (profile.model != null)
              _info(AppLocalizations.of(context)!.model, profile.model!),
            if (profile.dsmVersion != null)
              _info(AppLocalizations.of(context)!.dsm, profile.dsmVersion!),
            if (profile.lastConnected != null)
              _info(
                AppLocalizations.of(context)!.lastConnected,
                _formatDate(profile.lastConnected!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _removeNas(NasProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.removeNasTitle,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.removeNasMessage(profile.nickname),
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)!.remove,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _store.remove(profile.id);
      setState(() {});
      _showSnack(AppLocalizations.of(context)!.nasRemoved);
    }
  }

  void _showLanguagePicker() {
    final provider = LocaleProvider.instance;
    final current = provider.locale;

    const langs = [
      (Locale('en'), '🇬🇧', 'English'),
      (Locale('vi'), '🇻🇳', 'Tiếng Việt'),
      (Locale('zh'), '🇨🇳', '中文'),
      (Locale('ja'), '🇯🇵', '日本語'),
      (Locale('fr'), '🇫🇷', 'Français'),
      (Locale('pt'), '🇧🇷', 'Português'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.language,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...langs.map((l) {
              final isSelected = l.$1.languageCode == current.languageCode;
              return ListTile(
                leading: Text(l.$2, style: const TextStyle(fontSize: 24)),
                title: Text(
                  l.$3,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryContainer,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  provider.setLocale(l.$1);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
