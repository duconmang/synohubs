import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';

class LogCenterScreen extends StatefulWidget {
  const LogCenterScreen({super.key});

  @override
  State<LogCenterScreen> createState() => _LogCenterScreenState();
}

class _LogCenterScreenState extends State<LogCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  List<Map<String, dynamic>> _generalLogs = [];
  List<Map<String, dynamic>> _connectionLogs = [];
  int _totalGeneral = 0;
  int _totalConnection = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      final results = await Future.wait([
        api.getLogs(offset: 0, limit: 100, logType: 'general'),
        api.getConnectionLogs(offset: 0, limit: 50),
      ]);

      // Parse general logs
      if (results[0]['success'] == true) {
        final data = results[0]['data'] as Map<String, dynamic>? ?? {};
        _generalLogs = List<Map<String, dynamic>>.from(
          data['items'] as List? ??
              data['logs'] as List? ??
              data['result'] as List? ??
              [],
        );
        _totalGeneral = (data['total'] as int?) ?? _generalLogs.length;
      }

      // Parse connection logs
      if (results[1]['success'] == true) {
        final data = results[1]['data'] as Map<String, dynamic>? ?? {};
        _connectionLogs = List<Map<String, dynamic>>.from(
          data['items'] as List? ??
              data['logs'] as List? ??
              data['result'] as List? ??
              [],
        );
        _totalConnection = (data['total'] as int?) ?? _connectionLogs.length;
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
                Icons.receipt_long,
                color: AppColors.primaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l.logCenter,
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
            Tab(text: l.logs),
            Tab(text: l.connections),
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
                _buildLogsTab(),
                _buildConnectionsTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: Overview
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    final l = AppLocalizations.of(context)!;
    // Count levels
    int infoCount = 0, warnCount = 0, errCount = 0;
    for (final log in _generalLogs) {
      final level = _logLevel(log);
      if (level == 'warning' || level == 'warn') {
        warnCount++;
      } else if (level == 'error' || level == 'err' || level == 'crit') {
        errCount++;
      } else {
        infoCount++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  l.totalLogs,
                  '$_totalGeneral',
                  Icons.receipt_long,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  l.connections,
                  '$_totalConnection',
                  Icons.people,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  l.info,
                  '$infoCount',
                  Icons.info_outline,
                  AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  l.warnings,
                  '$warnCount',
                  Icons.warning_amber,
                  AppColors.tertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  l.errors,
                  '$errCount',
                  Icons.error_outline,
                  AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Last 20 logs
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 16,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                l.lastNLogs(_generalLogs.length.clamp(0, 20)),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ..._generalLogs.take(20).map((log) => _buildLogEntry(log)),

          if (_generalLogs.isEmpty)
            _emptyState(l.noLogsAvailable, Icons.receipt_long),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
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
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: Logs (full list)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLogsTab() {
    final l = AppLocalizations.of(context)!;
    if (_generalLogs.isEmpty) {
      return Center(child: _emptyState(l.noLogsAvailable, Icons.receipt_long));
    }

    return Column(
      children: [
        // Header bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                l.systemLogs,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l.nItems(_totalGeneral),
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

        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _tblHdr(l.level, 1),
                _tblHdr(l.time, 2),
                _tblHdr(l.user, 2),
                _tblHdr(l.event, 4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Log list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _generalLogs.length,
            itemBuilder: (ctx, i) => _buildLogRow(_generalLogs[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildLogRow(Map<String, dynamic> log) {
    final level = _logLevel(log);
    final time = _logTime(log);
    final user =
        log['user'] as String? ??
        log['username'] as String? ??
        log['who'] as String? ??
        '';
    final event =
        log['msg'] as String? ??
        log['event'] as String? ??
        log['message'] as String? ??
        log['desc'] as String? ??
        '';

    final levelColor = _levelColor(level);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GlassCard(
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Level badge
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _capitalizeLevel(level),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            // Time
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // User
            Expanded(
              flex: 2,
              child: Text(
                user,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Event
            Expanded(
              flex: 4,
              child: Text(
                event,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3: Connection logs
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildConnectionsTab() {
    final l = AppLocalizations.of(context)!;
    if (_connectionLogs.isEmpty) {
      return Center(
        child: _emptyState(l.noConnectionLogs, Icons.people_outline),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                l.connectionLogs,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l.nItems(_totalConnection),
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _connectionLogs.length,
            itemBuilder: (ctx, i) =>
                _buildConnectionLogEntry(_connectionLogs[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionLogEntry(Map<String, dynamic> log) {
    final time = _logTime(log);
    final user =
        log['user'] as String? ??
        log['username'] as String? ??
        log['who'] as String? ??
        '';
    final event =
        log['msg'] as String? ??
        log['event'] as String? ??
        log['message'] as String? ??
        log['desc'] as String? ??
        '';
    final level = _logLevel(log);
    final levelColor = _levelColor(level);

    // Try to extract IP from event message
    final ipMatch = RegExp(r'\[(\d+\.\d+\.\d+\.\d+)\]').firstMatch(event);
    final ip = ipMatch?.group(1) ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _capitalizeLevel(level),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: levelColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time,
                  size: 11,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.isNotEmpty) ...[
                  Icon(
                    Icons.person,
                    size: 12,
                    color: AppColors.primaryContainer.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    user,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              event,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurface,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (ip.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.lan,
                    size: 11,
                    color: AppColors.secondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ip,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Log entry card (for overview)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLogEntry(Map<String, dynamic> log) {
    final level = _logLevel(log);
    final time = _logTime(log);
    final user =
        log['user'] as String? ??
        log['username'] as String? ??
        log['who'] as String? ??
        '';
    final event =
        log['msg'] as String? ??
        log['event'] as String? ??
        log['message'] as String? ??
        log['desc'] as String? ??
        '';
    final program =
        log['program'] as String? ?? log['category'] as String? ?? '';
    final levelColor = _levelColor(level);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: level, time, user
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _capitalizeLevel(level),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: levelColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (program.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      program,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Event message
            Text(
              event,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurface,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (user.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 11,
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════
  Widget _emptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
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
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  String _logLevel(Map<String, dynamic> log) {
    final level =
        (log['level'] as String? ??
                log['log_level'] as String? ??
                log['severity'] as String? ??
                'info')
            .toLowerCase();
    return level;
  }

  String _logTime(Map<String, dynamic> log) {
    // Try various time field names
    final time =
        log['time'] as String? ??
        log['timestamp'] as String? ??
        log['date'] as String? ??
        '';
    if (time.isNotEmpty) return time;

    // Try epoch
    final epoch = log['time_epoch'] as int? ?? log['ut'] as int? ?? 0;
    if (epoch > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }
    return '';
  }

  Color _levelColor(String level) {
    if (level.contains('warn')) return AppColors.tertiary;
    if (level.contains('err') || level.contains('crit')) return AppColors.error;
    return AppColors.primaryContainer; // info
  }

  String _capitalizeLevel(String level) {
    if (level.isEmpty) return 'Info';
    if (level.contains('warn')) return 'Warn';
    if (level.contains('err')) return 'Error';
    if (level.contains('crit')) return 'Crit';
    return 'Info';
  }
}
