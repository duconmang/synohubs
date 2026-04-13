import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/nas_models.dart';
import '../services/session_manager.dart';
import '../services/app_updater.dart';
import '../widgets/glass_card.dart';
import 'resource_monitor_screen.dart';
import 'storage_manager_screen.dart';
import 'log_center_screen.dart';
import '../l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    SessionManager.instance.addListener(_onDataChanged);
    // Check for app updates after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdater.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    SessionManager.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async {
    await SessionManager.instance.refreshData();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final info = SessionManager.instance.nasInfo;

    if (info == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final sw = MediaQuery.of(context).size.width;
    final hPad = sw < 360 ? 14.0 : 20.0;
    final l = AppLocalizations.of(context)!;
    final isAdmin = SessionManager.instance.isAdmin;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemInfo(info),
            if (isAdmin) ...[
              const SizedBox(height: 20),
              _buildCpuRam(info),
              const SizedBox(height: 20),
              _buildStatsGrid(info),
              const SizedBox(height: 20),
              _buildStorageAndVolumes(info),
              const SizedBox(height: 20),
              _buildRunningServices(info),
            ],
            if (!isAdmin) ...[
              const SizedBox(height: 20),
              _buildNonAdminNotice(),
            ],
            const SizedBox(height: 20),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildNonAdminNotice() {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.tertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.limitedAccess,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.limitedAccessDesc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ① SYSTEM INFORMATION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSystemInfo(NasInfo info) {
    final l = AppLocalizations.of(context)!;
    final imagePath = NasModels.imageFor(info.model);
    final sw = MediaQuery.of(context).size.width;
    final imgH = (sw * 0.28).clamp(80.0, 140.0);

    return GlassCard(
      borderRadius: 24,
      hasGlow: true,
      padding: EdgeInsets.all(sw < 360 ? 16 : 20),
      child: Column(
        children: [
          // NAS image
          Container(
            width: double.infinity,
            height: imgH,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: imagePath.isNotEmpty
                  ? Image.asset(
                      imagePath,
                      height: imgH - 20,
                      fit: BoxFit.contain,
                    )
                  : const Icon(
                      Icons.storage,
                      size: 56,
                      color: AppColors.primary,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Synology ${info.model}',
            style: GoogleFonts.manrope(
              fontSize: sw < 360 ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l.healthy,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info grid (2 columns)
          Row(
            children: [
              Expanded(child: _infoCell(l.dsmVersion, info.dsmVersion)),
              const SizedBox(width: 12),
              Expanded(child: _infoCell(l.uptime, info.uptimeFormatted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoCell(
                  l.lanIp,
                  info.lanIp,
                  valueColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _infoCell(l.serial, info.serial)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ② CPU & RAM
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCpuRam(NasInfo info) {
    final l = AppLocalizations.of(context)!;
    final cpuPercent = (info.cpuLoad * 100).round();
    final ramUsedGb = (info.ramUsedMb / 1024).toStringAsFixed(1);
    final ramTotalGb = (info.ramTotalMb / 1024).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.resourceMonitor),
        const SizedBox(height: 10),
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _resourceBar(
                label: l.cpu,
                value: info.cpuLoad,
                displayValue: '$cpuPercent%',
                color: AppColors.primaryContainer,
              ),
              const SizedBox(height: 16),
              _resourceBar(
                label: l.ram,
                value: info.ramUsage,
                displayValue: '$ramUsedGb / $ramTotalGb GB',
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resourceBar({
    required String label,
    required double value,
    required String displayValue,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              displayValue,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ③ STATS BENTO (2×2)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid(NasInfo info) {
    final l = AppLocalizations.of(context)!;
    final runningPkgs = info.packages.where((p) => p.isRunning).length;
    final totalPkgs = info.packages.length;
    final sw = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _statCard(
                Icons.dns,
                AppColors.primaryContainer,
                info.uptimeFormatted.split(',').first,
                l.uptime,
                sw,
              ),
              const SizedBox(height: 10),
              _statCard(
                Icons.apps,
                AppColors.secondary,
                '$runningPkgs/$totalPkgs',
                l.services,
                sw,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _statCard(
                Icons.thermostat,
                AppColors.tertiary,
                '${info.temperatureC}°C',
                l.cpuTemp,
                sw,
              ),
              const SizedBox(height: 10),
              _statCard(
                Icons.storage,
                AppColors.primary,
                '${info.disks.length}',
                l.disks,
                sw,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    Color color,
    String value,
    String label,
    double sw,
  ) {
    final valueFontSize = (sw * 0.04).clamp(13.0, 18.0);

    return GlassCard(
      borderRadius: 18,
      padding: EdgeInsets.symmetric(
        horizontal: sw < 360 ? 12 : 14,
        vertical: sw < 360 ? 12 : 14,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ④ STORAGE CAPACITY + VOLUME HEALTH
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStorageAndVolumes(NasInfo info) {
    final l = AppLocalizations.of(context)!;
    final usagePct = info.storageUsage;
    final pctStr = '${(usagePct * 100).round()}%';
    final sw = MediaQuery.of(context).size.width;

    String sizeStr(int gb) {
      if (gb >= 1024) return '${(gb / 1024).toStringAsFixed(1)} TB';
      return '$gb GB';
    }

    final arcSize = (sw * 0.42).clamp(120.0, 200.0);
    final arcFontSize = (arcSize * 0.18).clamp(20.0, 36.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.storageAndVolumes),
        const SizedBox(height: 10),

        // Storage Capacity
        GlassCard(
          borderRadius: 24,
          hasGlow: true,
          padding: EdgeInsets.all(sw < 360 ? 16 : 20),
          child: Column(
            children: [
              Text(
                l.storageCapacity,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: arcSize,
                height: arcSize,
                child: CustomPaint(
                  painter: _StorageProgressPainter(usagePct),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pctStr,
                          style: GoogleFonts.manrope(
                            fontSize: arcFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sizeStr(info.storageUsedGb)} / ${sizeStr(info.storageTotalGb)}',
                          style: GoogleFonts.inter(
                            fontSize: (arcFontSize * 0.35).clamp(9.0, 12.0),
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Volume breakdown
              if (info.volumes.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...info.volumes.map((v) {
                  final pct = v.totalSizeGb > 0
                      ? v.usedSizeGb / v.totalSizeGb
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            v.id,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${sizeStr(v.usedSizeGb)} / ${sizeStr(v.totalSizeGb)}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor:
                                  AppColors.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.primaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Disk Health
        if (info.disks.isNotEmpty)
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storage,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.diskHealth,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (info.volumes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          info.volumes.first.raidType.isNotEmpty
                              ? info.volumes.first.raidType.toUpperCase()
                              : 'BASIC',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...info.disks.asMap().entries.expand(
                  (e) => [
                    if (e.key > 0) const SizedBox(height: 8),
                    _driveSlot(
                      l.bayN(e.key + 1),
                      e.value.model,
                      e.value.status == 'normal' ? l.normal : e.value.status,
                      e.value.status == 'normal'
                          ? AppColors.secondary
                          : AppColors.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _driveSlot(
    String bay,
    String model,
    String status,
    Color statusColor,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            status == 'Normal'
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            size: 14,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bay,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                model,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ⑤ RUNNING SERVICES (real packages from API)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRunningServices(NasInfo info) {
    final l = AppLocalizations.of(context)!;
    // Show up to 8 installed packages
    final pkgs = info.packages.take(8).toList();
    if (pkgs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.installedPackages),
        const SizedBox(height: 10),
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: pkgs
                .asMap()
                .entries
                .expand(
                  (e) => [
                    if (e.key > 0) _serviceDivider(),
                    _serviceRow(
                      _packageIcon(e.value.id),
                      e.value.name.isNotEmpty ? e.value.name : e.value.id,
                      e.value.isRunning ? l.running : l.stopped,
                      e.value.isRunning
                          ? AppColors.secondary
                          : AppColors.onSurfaceVariant,
                      e.value.isRunning,
                    ),
                  ],
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  IconData _packageIcon(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('docker') || lower.contains('container')) {
      return Icons.cloud;
    }
    if (lower.contains('plex') || lower.contains('media')) {
      return Icons.play_circle_fill;
    }
    if (lower.contains('download')) return Icons.download;
    if (lower.contains('surveillance') || lower.contains('camera')) {
      return Icons.videocam;
    }
    if (lower.contains('photo')) return Icons.photo;
    if (lower.contains('audio') || lower.contains('music'))
      return Icons.music_note;
    if (lower.contains('drive')) return Icons.folder;
    if (lower.contains('note')) return Icons.note;
    if (lower.contains('hyper') || lower.contains('backup'))
      return Icons.backup;
    if (lower.contains('antivirus') || lower.contains('security')) {
      return Icons.security;
    }
    return Icons.extension;
  }

  Widget _serviceRow(
    IconData icon,
    String name,
    String status,
    Color color,
    bool running,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: running
                  ? AppColors.secondary
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: running ? AppColors.secondary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: AppColors.outlineVariant.withValues(alpha: 0.15),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ⑧ QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuickActions() {
    final l = AppLocalizations.of(context)!;
    final isAdmin = SessionManager.instance.isAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.quickActions),
        const SizedBox(height: 10),

        if (isAdmin) ...[
          // Row 1: DSM Tools (admin only)
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  Icons.monitor_heart,
                  l.resourceMonitorAction,
                  AppColors.primaryContainer,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResourceMonitorScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  Icons.pie_chart,
                  l.storageManagerAction,
                  AppColors.secondary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StorageManagerScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  Icons.receipt_long,
                  l.logCenterAction,
                  AppColors.tertiary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogCenterScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Power + Refresh (admin only for power)
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  Icons.restart_alt,
                  l.restart,
                  AppColors.primary,
                  () => _confirmAction(l.restart, () async {
                    await SessionManager.instance.api?.reboot();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  Icons.power_settings_new,
                  l.shutdown,
                  AppColors.error,
                  () => _confirmAction(l.shutdown, () async {
                    await SessionManager.instance.api?.shutdown();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  Icons.refresh,
                  l.refresh,
                  AppColors.tertiary,
                  _onRefresh,
                ),
              ),
            ],
          ),
        ] else ...[
          // Non-admin: only refresh
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  Icons.refresh,
                  l.refresh,
                  AppColors.tertiary,
                  _onRefresh,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _confirmAction(String action, VoidCallback onConfirm) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.confirmActionTitle(action),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          l.confirmActionMessage(action),
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              action,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Circular Progress Painter
// ═══════════════════════════════════════════════════════════════════
class _StorageProgressPainter extends CustomPainter {
  final double progress;
  _StorageProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 14) / 2;
    final strokeWidth = (size.shortestSide * 0.07).clamp(6.0, 12.0);

    // Background circle — green for free/available space
    final bgPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: const [AppColors.primary, AppColors.primaryContainer],
    );
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _StorageProgressPainter old) =>
      old.progress != progress;
}
