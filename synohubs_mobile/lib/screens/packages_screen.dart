import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List<_PackageItem> _packages = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _actionLoading;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final api = SessionManager.instance.api;
    if (api == null) return;

    setState(() => _loading = true);
    try {
      final result = await api.getPackages();
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final rawList = data['packages'] as List? ?? [];
        _packages = rawList.map((p) {
          final m = p as Map<String, dynamic>;
          final additional = m['additional'] as Map<String, dynamic>? ?? {};
          final isRunning = additional['status'] == 'running' ||
              additional['running_status'] == 'running' ||
              additional['is_running'] == true ||
              m['status'] == 'running' ||
              m['is_running'] == true;
          final startable = additional['startable'] != false;
          return _PackageItem(
            id: m['id'] as String? ?? m['name'] as String? ?? '',
            name: m['dname'] as String? ?? m['name'] as String? ?? m['id'] as String? ?? '',
            version: m['version'] as String? ?? '',
            desc: additional['description'] as String? ?? m['desc'] as String? ?? '',
            isRunning: isRunning,
            startable: startable,
          );
        }).toList();
        _error = null;
      } else {
        _error = 'Failed to load packages';
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _handleStartStop(String id, bool currentlyRunning) async {
    setState(() => _actionLoading = id);
    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      if (currentlyRunning) {
        await api.packageStop(id);
      } else {
        await api.packageStart(id);
      }
      await Future.delayed(const Duration(milliseconds: 1000));
      await _fetch();
    } catch (e) {
      _error = 'Failed: $e';
    }
    _actionLoading = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apps, color: AppColors.secondary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.installedPackages,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant, size: 20),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final q = _search.toLowerCase();
    final filtered = _packages.where((p) {
      return p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q);
    }).toList();

    final running = filtered.where((p) => p.isRunning).toList();
    final stopped = filtered.where((p) => !p.isRunning).toList();
    final runCount = _packages.where((p) => p.isRunning).length;
    final stopCount = _packages.length - runCount;

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _buildSearchBar(),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _statBadge('${_packages.length}', 'Total', AppColors.primaryContainer),
              const SizedBox(width: 8),
              _statBadge('$runCount', 'Running', AppColors.secondary),
              const SizedBox(width: 8),
              _statBadge('$stopCount', 'Stopped', AppColors.onSurfaceVariant),
            ],
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GlassCard(
              borderRadius: 10,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.error)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _error = null),
                    child: const Icon(Icons.close, size: 14, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

        // Package list
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (running.isNotEmpty) ...[
                      _sectionLabel('Running (${running.length})'),
                      ...running.map(_buildPackageCard),
                    ],
                    if (stopped.isNotEmpty) ...[
                      _sectionLabel('Stopped (${stopped.length})'),
                      ...stopped.map(_buildPackageCard),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search packages...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Expanded(
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPackageCard(_PackageItem pkg) {
    final isPending = _actionLoading == pkg.id;
    final IconData pkgIcon = _packageIcon(pkg.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 16,
        borderColor: pkg.isRunning ? AppColors.secondary : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (pkg.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                pkgIcon,
                size: 20,
                color: pkg.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.name,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v${pkg.version}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (pkg.desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      pkg.desc,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Status + Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (pkg.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pkg.isRunning ? Icons.play_arrow : Icons.stop,
                        size: 10,
                        color: pkg.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        pkg.isRunning ? 'Running' : 'Stopped',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: pkg.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pkg.startable) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: isPending ? null : () => _handleStartStop(pkg.id, pkg.isRunning),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (pkg.isRunning ? AppColors.error : AppColors.secondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isPending
                          ? Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: pkg.isRunning ? AppColors.error : AppColors.secondary,
                                ),
                              ),
                            )
                          : Icon(
                              pkg.isRunning ? Icons.stop_circle : Icons.play_circle,
                              size: 16,
                              color: pkg.isRunning ? AppColors.error : AppColors.secondary,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _packageIcon(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('docker') || lower.contains('container')) return Icons.cloud;
    if (lower.contains('plex') || lower.contains('media')) return Icons.play_circle_fill;
    if (lower.contains('download')) return Icons.download;
    if (lower.contains('surveillance') || lower.contains('camera')) return Icons.videocam;
    if (lower.contains('photo')) return Icons.photo;
    if (lower.contains('audio') || lower.contains('music')) return Icons.music_note;
    if (lower.contains('drive')) return Icons.folder;
    if (lower.contains('note')) return Icons.note;
    if (lower.contains('hyper') || lower.contains('backup')) return Icons.backup;
    if (lower.contains('antivirus') || lower.contains('security')) return Icons.security;
    if (lower.contains('text') || lower.contains('editor')) return Icons.edit;
    if (lower.contains('mail')) return Icons.mail;
    if (lower.contains('web') || lower.contains('station')) return Icons.web;
    if (lower.contains('dns')) return Icons.dns;
    if (lower.contains('vpn')) return Icons.vpn_key;
    if (lower.contains('log')) return Icons.receipt_long;
    return Icons.extension;
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.apps, size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            _search.isNotEmpty ? 'No packages match your search' : 'No packages installed',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PackageItem {
  final String id;
  final String name;
  final String version;
  final String desc;
  final bool isRunning;
  final bool startable;

  _PackageItem({
    required this.id,
    required this.name,
    required this.version,
    this.desc = '',
    this.isRunning = false,
    this.startable = true,
  });
}
