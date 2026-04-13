import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';

class StorageManagerScreen extends StatefulWidget {
  const StorageManagerScreen({super.key});

  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  // Raw storage data from API
  Map<String, dynamic> _storageData = {};
  List<Map<String, dynamic>> _storagePools = [];
  List<Map<String, dynamic>> _volumes = [];
  List<Map<String, dynamic>> _disks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchStorageData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStorageData() async {
    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      final resp = await api.getStorageInfo();
      if (resp['success'] == true) {
        _storageData = resp['data'] as Map<String, dynamic>? ?? {};
        _storagePools = List<Map<String, dynamic>>.from(
          _storageData['storagePools'] as List? ?? [],
        );
        _volumes = List<Map<String, dynamic>>.from(
          _storageData['volumes'] as List? ?? [],
        );
        _disks = List<Map<String, dynamic>>.from(
          _storageData['disks'] as List? ?? [],
        );
      }
      _loading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.pie_chart,
                color: AppColors.primaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l.storageManager,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryContainer,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primaryContainer,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: l.overview),
            Tab(text: l.storage),
            Tab(text: l.hddSsd),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildStorageTab(),
                _buildHddTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: Overview
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    final l = AppLocalizations.of(context)!;
    final info = SessionManager.instance.nasInfo;
    final hasDegraded = _storagePools.any(
      (p) =>
          (p['status'] as String? ?? '').toLowerCase().contains('degrad') ||
          (p['status'] as String? ?? '').toLowerCase().contains('crash'),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health status alert
          _buildHealthAlert(hasDegraded),
          const SizedBox(height: 16),

          // Volume Usage section
          Text(
            l.volumeUsage,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          if (info != null)
            ...info.volumes.map((v) => _buildVolumeUsageCard(v)),

          const SizedBox(height: 16),

          // Drive Information
          if (info != null) _buildDriveInfoCard(info),
        ],
      ),
    );
  }

  Widget _buildHealthAlert(bool hasDegraded) {
    final l = AppLocalizations.of(context)!;
    final color = hasDegraded ? AppColors.error : AppColors.secondary;
    final icon = hasDegraded ? Icons.error_outline : Icons.check_circle_outline;
    final title = hasDegraded ? l.critical : l.healthyStatus;
    final msg = hasDegraded ? l.storagePoolDegraded : l.allStorageHealthy;

    return GlassCard(
      borderRadius: 18,
      hasGlow: hasDegraded,
      borderColor: hasDegraded ? AppColors.error : null,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeUsageCard(VolumeInfo v) {
    final l = AppLocalizations.of(context)!;
    final pct = v.totalSizeGb > 0 ? v.usedSizeGb / v.totalSizeGb : 0.0;
    final pctStr = '${(pct * 100).round()}%';

    // Determine pool info
    String poolName = '';
    String poolStatus = 'normal';
    for (final pool in _storagePools) {
      final poolVols = pool['volumes'] as List? ?? [];
      for (final pv in poolVols) {
        final pvId = pv is Map ? pv['id'] : pv;
        if (pvId == v.id) {
          poolName = pool['id'] as String? ?? '';
          poolStatus = pool['status'] as String? ?? 'normal';
          break;
        }
      }
    }

    final isDegraded = poolStatus.toLowerCase().contains('degrad');
    final statusColor = isDegraded ? AppColors.error : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDegraded
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.id,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (poolName.isNotEmpty)
                        Text(
                          poolName,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDegraded ? l.degraded : l.healthyStatus,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  pct > 0.85 ? AppColors.error : AppColors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_sizeStr(v.usedSizeGb)} / ${_sizeStr(v.totalSizeGb)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                  ),
                ),
                Text(
                  pctStr,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveInfoCard(NasInfo info) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                l.driveInformation,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            info.hostname.isNotEmpty ? info.hostname : info.model,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Visual NAS drive bays
          _buildDriveBays(info),
        ],
      ),
    );
  }

  Widget _buildDriveBays(NasInfo info) {
    final bayCount = info.disks.length.clamp(2, 8);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2E2E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(bayCount, (i) {
          final hasDisk = i < info.disks.length;
          final isNormal = hasDisk && info.disks[i].status == 'normal';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasDisk
                        ? (isNormal
                              ? AppColors.secondary.withValues(alpha: 0.15)
                              : AppColors.error.withValues(alpha: 0.15))
                        : AppColors.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasDisk
                          ? (isNormal
                                ? AppColors.secondary.withValues(alpha: 0.4)
                                : AppColors.error.withValues(alpha: 0.4))
                          : AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: hasDisk
                        ? Icon(
                            Icons.storage,
                            size: 16,
                            color: isNormal
                                ? AppColors.secondary
                                : AppColors.error,
                          )
                        : Icon(
                            Icons.remove,
                            size: 14,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${i + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: Storage (Pools + Volumes detail)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStorageTab() {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_storagePools.isEmpty && _volumes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  l.noStoragePoolData,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          // Storage pools
          ..._storagePools.asMap().entries.map((e) {
            final pool = e.value;
            return _buildStoragePoolCard(pool, e.key);
          }),

          // Volumes without pool mapping
          if (_storagePools.isEmpty)
            ..._volumes.asMap().entries.map((e) {
              return _buildRawVolumeCard(e.value, e.key);
            }),
        ],
      ),
    );
  }

  Widget _buildStoragePoolCard(Map<String, dynamic> pool, int index) {
    final l = AppLocalizations.of(context)!;
    final poolId = pool['id'] as String? ?? l.storagePoolN(index + 1);
    final status = pool['status'] as String? ?? 'normal';
    final isDegraded = status.toLowerCase().contains('degrad');
    final statusColor = isDegraded ? AppColors.error : AppColors.secondary;
    final sizeBytes = _parseSizeBytes(pool['size']?['total']);
    final sizeStr = _sizeStr(sizeBytes ~/ (1024 * 1024 * 1024));

    // RAID type
    final raidType = pool['raid_type'] as String? ?? '';

    // Disks in this pool
    final poolDisks = pool['disks'] as List? ?? [];

    // Volumes in this pool
    final poolVols = pool['volumes'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pool header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDegraded ? Icons.warning_amber : Icons.dns,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poolId,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (sizeStr.isNotEmpty)
                        Text(
                          sizeStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDegraded ? l.degraded : l.healthyStatus,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // RAID Type
            if (raidType.isNotEmpty) _infoRow(l.raidType, raidType),

            // Disk count
            if (poolDisks.isNotEmpty)
              _infoRow(l.drives, l.nDisks(poolDisks.length)),

            const SizedBox(height: 8),

            // Drive info table
            if (poolDisks.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    // Table header
                    Row(
                      children: [
                        _tblHdr(l.device, 2),
                        _tblHdr(l.drive, 2),
                        _tblHdr(l.size, 2),
                        _tblHdr(l.status, 1),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...poolDisks.map((pd) => _buildPoolDiskRow(pd)),
                  ],
                ),
              ),
            ],

            // Volumes in this pool
            if (poolVols.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...poolVols.map((pv) {
                final volId = pv is Map
                    ? (pv['id'] as String? ?? '')
                    : pv.toString();
                // Find matching volume data
                final volData = _volumes.firstWhere(
                  (v) => v['id'] == volId,
                  orElse: () => <String, dynamic>{},
                );
                if (volData.isEmpty) return const SizedBox.shrink();
                return _buildVolumeEntry(volData);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPoolDiskRow(dynamic pd) {
    final l = AppLocalizations.of(context)!;
    final diskId = pd is Map ? (pd['id'] as String? ?? '') : pd.toString();
    // Find matching disk
    final diskData = _disks.firstWhere(
      (d) => d['id'] == diskId,
      orElse: () => <String, dynamic>{},
    );
    final model = diskData['model'] as String? ?? diskId;
    final status = diskData['status'] as String? ?? 'normal';
    final sizeBytes = _parseSizeBytes(diskData['size_total']);
    final sizeGb = sizeBytes ~/ (1024 * 1024 * 1024);
    final isNormal = status.toLowerCase() == 'normal';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              diskId,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              model,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _sizeStr(sizeGb),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isNormal ? l.normal : status,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isNormal ? AppColors.secondary : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeEntry(Map<String, dynamic> vol) {
    final l = AppLocalizations.of(context)!;
    final volId = vol['id'] as String? ?? '';
    final status = vol['status'] as String? ?? 'normal';
    final isDegraded = status.toLowerCase().contains('degrad');
    final statusColor = isDegraded ? AppColors.error : AppColors.secondary;
    final totalBytes = _parseSizeBytes(vol['size']?['total']);
    final usedBytes = _parseSizeBytes(vol['size']?['used']);
    final totalGb = totalBytes ~/ (1024 * 1024 * 1024);
    final usedGb = usedBytes ~/ (1024 * 1024 * 1024);
    final pct = totalGb > 0 ? usedGb / totalGb : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isDegraded ? Icons.warning_amber_rounded : Icons.check_circle,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  volId,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDegraded ? l.degraded : l.healthyStatus,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryContainer),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_sizeStr(usedGb)} / ${_sizeStr(totalGb)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.primaryContainer,
                  ),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawVolumeCard(Map<String, dynamic> vol, int index) {
    final l = AppLocalizations.of(context)!;
    final volId = vol['id'] as String? ?? l.volumeN(index + 1);
    final totalBytes = _parseSizeBytes(vol['size']?['total']);
    final usedBytes = _parseSizeBytes(vol['size']?['used']);
    final totalGb = totalBytes ~/ (1024 * 1024 * 1024);
    final usedGb = usedBytes ~/ (1024 * 1024 * 1024);
    final pct = totalGb > 0 ? usedGb / totalGb : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  volId,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_sizeStr(usedGb)} / ${_sizeStr(totalGb)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.primaryContainer,
                  ),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3: HDD/SSD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHddTab() {
    final l = AppLocalizations.of(context)!;
    if (_disks.isEmpty) {
      return Center(
        child: Text(
          l.noDiskInfo,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _disks.length,
      itemBuilder: (ctx, i) {
        final disk = _disks[i];
        return _buildDiskCard(disk, i);
      },
    );
  }

  Widget _buildDiskCard(Map<String, dynamic> disk, int index) {
    final l = AppLocalizations.of(context)!;
    final model = disk['model'] as String? ?? l.unknown;
    final status = disk['status'] as String? ?? 'normal';
    final temp = disk['temp'] as int? ?? 0;
    final sizeBytes = _parseSizeBytes(disk['size_total']);
    final sizeGb = sizeBytes ~/ (1024 * 1024 * 1024);
    final isNormal = status.toLowerCase() == 'normal';
    final statusColor = isNormal ? AppColors.secondary : AppColors.error;
    final vendor = disk['vendor'] as String? ?? '';
    final diskType =
        disk['diskType'] as String? ??
        (disk['pciSlot'] != null ? 'SSD' : 'HDD');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drive icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storage, size: 18, color: statusColor),
                      Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.driveN(index + 1),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$vendor $model ($diskType)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _diskInfoChip(Icons.straighten, _sizeStr(sizeGb)),
                const SizedBox(width: 8),
                if (temp > 0) _diskInfoChip(Icons.thermostat, '$temp°C'),
                const SizedBox(width: 8),
                _diskInfoChip(
                  isNormal ? Icons.check_circle : Icons.warning_amber,
                  isNormal ? l.normal : status,
                  color: statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _diskInfoChip(IconData icon, String text, {Color? color}) {
    final c = color ?? AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label:  ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tblHdr(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  String _sizeStr(int gb) {
    if (gb >= 1024) return '${(gb / 1024).toStringAsFixed(1)} TB';
    return '$gb GB';
  }

  int _parseSizeBytes(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
