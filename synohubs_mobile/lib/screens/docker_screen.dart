import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';

class DockerScreen extends StatefulWidget {
  const DockerScreen({super.key});

  @override
  State<DockerScreen> createState() => _DockerScreenState();
}

class _DockerScreenState extends State<DockerScreen> {
  List<_Container> _containers = [];
  bool _loading = true;
  bool _dockerAvailable = true;
  String? _error;
  String _search = '';
  String? _actionPending;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchContainers();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchContainers(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchContainers() async {
    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      final result = await api.dockerList();
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        final rawList = data['containers'] as List? ?? [];
        final parsed = rawList.map((c) {
          final m = c as Map<String, dynamic>;
          return _Container(
            name: m['name'] as String? ?? 'unknown',
            image: m['image'] as String? ?? '',
            status: (m['status'] as String? ?? 'stopped').toLowerCase(),
            upTime: m['up_time'] as int? ?? 0,
          );
        }).toList();

        _containers = parsed;
        _dockerAvailable = true;
        _error = null;

        // Try fetching resource usage
        try {
          final resResult = await api.dockerGetResources();
          if (resResult['success'] == true) {
            final resources = (resResult['data'] as Map?)?['resources'] as List? ?? [];
            for (final res in resources) {
              final rm = res as Map<String, dynamic>;
              final name = rm['name'] as String? ?? '';
              final idx = _containers.indexWhere((c) => c.name == name);
              if (idx >= 0) {
                _containers[idx] = _containers[idx].copyWith(
                  cpu: (rm['cpu'] as num?)?.toDouble(),
                  memory: (rm['memory'] as num?)?.toInt(),
                  memoryLimit: (rm['memoryLimit'] as num?)?.toInt(),
                );
              }
            }
          }
        } catch (_) {}
      } else {
        final code = (result['error'] as Map?)?['code'];
        if (code == 109 || code == 119) {
          _dockerAvailable = false;
        } else {
          _error = 'Docker API error: $code';
        }
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('119') || msg.contains('not found')) {
        _dockerAvailable = false;
      } else {
        _error = msg;
      }
    }

    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _handleAction(String name, String action) async {
    setState(() => _actionPending = name);
    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      Map<String, dynamic> result;
      switch (action) {
        case 'start':
          result = await api.dockerStart(name);
          break;
        case 'stop':
          result = await api.dockerStop(name);
          break;
        case 'restart':
          result = await api.dockerRestart(name);
          break;
        default:
          return;
      }
      if (result['success'] != true) {
        _error = 'Failed to $action "$name"';
      }
      await Future.delayed(const Duration(milliseconds: 1500));
      await _fetchContainers();
    } catch (e) {
      _error = 'Failed to $action "$name": $e';
    }
    _actionPending = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

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
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud, color: AppColors.primaryContainer, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Docker',
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
            icon: Icon(
              Icons.refresh,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: _fetchContainers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : !_dockerAvailable
              ? _buildNotAvailable()
              : _buildContent(),
    );
  }

  Widget _buildNotAvailable() {
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
                Icons.cloud_off,
                size: 36,
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Docker Not Available',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Container Manager (Docker) is not installed or not running on this NAS.\nInstall it from Package Center.',
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

  Widget _buildContent() {
    final filtered = _containers.where((c) {
      final q = _search.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.image.toLowerCase().contains(q);
    }).toList();

    final running = filtered.where((c) => c.isRunning).toList();
    final stopped = filtered.where((c) => !c.isRunning).toList();

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
          child: _buildStats(),
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
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _error = null),
                    child: const Icon(Icons.close, size: 14, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

        // Container list
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (running.isNotEmpty) ...[
                      _sectionLabel('Running (${running.length})'),
                      ...running.map(_buildContainerCard),
                    ],
                    if (stopped.isNotEmpty) ...[
                      _sectionLabel('Stopped (${stopped.length})'),
                      ...stopped.map(_buildContainerCard),
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
                hintText: 'Search containers...',
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

  Widget _buildStats() {
    final total = _containers.length;
    final runCount = _containers.where((c) => c.isRunning).length;
    final stopCount = total - runCount;

    return Row(
      children: [
        _statBadge('$total', 'Total', AppColors.primaryContainer),
        const SizedBox(width: 8),
        _statBadge('$runCount', 'Running', AppColors.secondary),
        const SizedBox(width: 8),
        _statBadge('$stopCount', 'Stopped', AppColors.onSurfaceVariant),
      ],
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

  Widget _buildContainerCard(_Container c) {
    final isPending = _actionPending == c.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderRadius: 16,
        borderColor: c.isRunning ? AppColors.secondary : null,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon + Name + Status
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (c.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.cloud,
                    size: 18,
                    color: c.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.image,
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
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (c.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.isRunning ? Icons.play_arrow : Icons.stop,
                        size: 10,
                        color: c.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        c.isRunning ? 'Running' : 'Stopped',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: c.isRunning ? AppColors.secondary : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Row 2: Uptime + Resources + Actions
            const SizedBox(height: 10),
            Row(
              children: [
                // Uptime / Resources
                if (c.isRunning && c.upTime > 0) ...[
                  Icon(Icons.timer_outlined, size: 12, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatUptime(c.upTime),
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                ],
                if (c.cpu != null) ...[
                  Icon(Icons.memory, size: 12, color: AppColors.primaryContainer),
                  const SizedBox(width: 3),
                  Text(
                    '${c.cpu!.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (c.memory != null) ...[
                  Icon(Icons.sd_storage, size: 12, color: AppColors.tertiary),
                  const SizedBox(width: 3),
                  Text(
                    _formatBytes(c.memory!),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
                const Spacer(),

                // Action buttons
                if (c.isRunning) ...[
                  _actionBtn(Icons.restart_alt, AppColors.primaryContainer, isPending, () {
                    _handleAction(c.name, 'restart');
                  }),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.stop, AppColors.error, isPending, () {
                    _handleAction(c.name, 'stop');
                  }),
                ] else
                  _actionBtn(Icons.play_arrow, AppColors.secondary, isPending, () {
                    _handleAction(c.name, 'start');
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, bool pending, VoidCallback onTap) {
    return GestureDetector(
      onTap: pending ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: pending
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_outlined, size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            _search.isNotEmpty ? 'No containers match your search' : 'No Docker containers found',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds <= 0) return '';
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes > 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (bytes > 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

class _Container {
  final String name;
  final String image;
  final String status;
  final int upTime;
  final double? cpu;
  final int? memory;
  final int? memoryLimit;

  _Container({
    required this.name,
    required this.image,
    required this.status,
    this.upTime = 0,
    this.cpu,
    this.memory,
    this.memoryLimit,
  });

  bool get isRunning => status == 'running';

  _Container copyWith({double? cpu, int? memory, int? memoryLimit}) {
    return _Container(
      name: name,
      image: image,
      status: status,
      upTime: upTime,
      cpu: cpu ?? this.cpu,
      memory: memory ?? this.memory,
      memoryLimit: memoryLimit ?? this.memoryLimit,
    );
  }
}
