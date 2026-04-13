import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';

class ResourceMonitorScreen extends StatefulWidget {
  const ResourceMonitorScreen({super.key});

  @override
  State<ResourceMonitorScreen> createState() => _ResourceMonitorScreenState();
}

class _ResourceMonitorScreenState extends State<ResourceMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  // Performance data
  double _cpuLoad = 0;
  int _cpuUser = 0;
  int _cpuSystem = 0;
  double _ramUsage = 0;
  int _ramUsedMb = 0;
  int _ramTotalMb = 0;
  int _ramCachedMb = 0;
  int _ramBufferMb = 0;
  double _networkRx = 0; // KB/s
  double _networkTx = 0; // KB/s
  double _diskRead = 0; // KB/s
  double _diskWrite = 0; // KB/s

  // History for mini-charts (last 30 samples)
  final List<double> _cpuHistory = [];
  final List<double> _ramHistory = [];
  final List<double> _netRxHistory = [];
  final List<double> _netTxHistory = [];

  // Connected users
  List<Map<String, dynamic>> _connections = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchAll(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      final results = await Future.wait([
        api.getSystemUtilization(),
        api.getCurrentConnections(),
      ]);

      final utilData = results[0]['data'] as Map<String, dynamic>? ?? {};
      final connResp = results[1];

      // CPU
      final cpu = utilData['cpu'] as Map<String, dynamic>? ?? {};
      final userLoad = (cpu['user_load'] as num?)?.toDouble() ?? 0;
      final sysLoad = (cpu['system_load'] as num?)?.toDouble() ?? 0;
      _cpuUser = userLoad.round();
      _cpuSystem = sysLoad.round();
      _cpuLoad = (userLoad + sysLoad) / 100.0;

      // Memory
      final mem = utilData['memory'] as Map<String, dynamic>? ?? {};
      final total = (mem['total_real'] as num?)?.toInt() ?? 0;
      final avail = (mem['avail_real'] as num?)?.toInt() ?? 0;
      final buffer = (mem['buffer'] as num?)?.toInt() ?? 0;
      final cached = (mem['cached'] as num?)?.toInt() ?? 0;
      _ramTotalMb = total ~/ 1024;
      _ramUsedMb = (total - avail - buffer - cached) ~/ 1024;
      _ramCachedMb = cached ~/ 1024;
      _ramBufferMb = buffer ~/ 1024;
      _ramUsage = _ramTotalMb > 0 ? _ramUsedMb / _ramTotalMb : 0;

      // Network
      final netList = utilData['network'] as List? ?? [];
      double rxTotal = 0, txTotal = 0;
      for (final n in netList) {
        final nMap = n as Map<String, dynamic>;
        rxTotal += (nMap['rx'] as num?)?.toDouble() ?? 0;
        txTotal += (nMap['tx'] as num?)?.toDouble() ?? 0;
      }
      _networkRx = rxTotal / 1024; // bytes → KB
      _networkTx = txTotal / 1024;

      // Disk
      final diskList = utilData['disk'] as List? ?? [];
      double rTotal = 0, wTotal = 0;
      for (final d in diskList) {
        final dMap = d as Map<String, dynamic>;
        final access = dMap['utilization'] as Map<String, dynamic>? ?? dMap;
        rTotal += (access['read_byte'] as num?)?.toDouble() ?? 0;
        wTotal += (access['write_byte'] as num?)?.toDouble() ?? 0;
      }
      _diskRead = rTotal / 1024;
      _diskWrite = wTotal / 1024;

      // History
      _cpuHistory.add(_cpuLoad);
      if (_cpuHistory.length > 30) _cpuHistory.removeAt(0);
      _ramHistory.add(_ramUsage);
      if (_ramHistory.length > 30) _ramHistory.removeAt(0);
      _netRxHistory.add(_networkRx);
      if (_netRxHistory.length > 30) _netRxHistory.removeAt(0);
      _netTxHistory.add(_networkTx);
      if (_netTxHistory.length > 30) _netTxHistory.removeAt(0);

      // Connections
      if (connResp['success'] == true) {
        final connData = connResp['data'] as Map<String, dynamic>? ?? {};
        _connections = List<Map<String, dynamic>>.from(
          connData['items'] as List? ?? connData['connection'] as List? ?? [],
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
                Icons.monitor_heart,
                color: AppColors.primaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l.resourceMonitor,
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
            Tab(text: l.performance),
            Tab(text: l.connections),
            Tab(text: l.details),
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
                _buildPerformanceTab(),
                _buildConnectionsTab(),
                _buildDetailsTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: Performance
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPerformanceTab() {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // CPU
          _buildMetricCard(
            title: l.cpu,
            icon: Icons.memory,
            color: AppColors.primaryContainer,
            value: '${(_cpuLoad * 100).round()}%',
            subtitle: l.cpuUsageBreakdown('$_cpuUser', '$_cpuSystem'),
            progress: _cpuLoad,
            history: _cpuHistory,
          ),
          const SizedBox(height: 12),

          // Memory
          _buildMetricCard(
            title: l.memory,
            icon: Icons.sd_storage,
            color: AppColors.tertiary,
            value: '${(_ramUsage * 100).round()}%',
            subtitle: l.memoryUsageDetail(
              '$_ramUsedMb',
              '$_ramTotalMb',
              '$_ramCachedMb',
            ),
            progress: _ramUsage,
            history: _ramHistory,
          ),
          const SizedBox(height: 12),

          // Network
          _buildNetworkCard(),
          const SizedBox(height: 12),

          // Disk I/O
          _buildDiskCard(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String subtitle,
    required double progress,
    required List<double> history,
  }) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                l.utilization,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini sparkline chart
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparklinePainter(
                data: history,
                color: color,
                maxVal: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard() {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                l.network,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini dual sparkline
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: Size.infinite,
              painter: _DualSparklinePainter(
                data1: _netRxHistory,
                data2: _netTxHistory,
                color1: AppColors.primaryContainer,
                color2: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _networkStat(
                '▼',
                _formatSpeed(_networkRx),
                AppColors.primaryContainer,
              ),
              const SizedBox(width: 24),
              _networkStat('▲', _formatSpeed(_networkTx), AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _networkStat(String arrow, String speed, Color color) {
    return Row(
      children: [
        Text(
          arrow,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          speed,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDiskCard() {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, size: 16, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Text(
                l.diskIO,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ioRow(
                  l.read,
                  _formatSpeed(_diskRead),
                  AppColors.primaryContainer,
                ),
              ),
              Expanded(
                child: _ioRow(
                  l.write,
                  _formatSpeed(_diskWrite),
                  AppColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ioRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: Connections
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildConnectionsTab() {
    final l = AppLocalizations.of(context)!;
    if (_connections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              l.noActiveConnections,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                l.connectedUsers,
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
                  l.nItems(_connections.length),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _tableHeader(l.time, flex: 2),
                _tableHeader(l.user, flex: 2),
                _tableHeader(l.ip, flex: 3),
                _tableHeader(l.type, flex: 2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Connection rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _connections.length,
            itemBuilder: (ctx, i) {
              final c = _connections[i];
              return _connectionRow(c);
            },
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
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

  Widget _connectionRow(Map<String, dynamic> c) {
    final time = c['time'] as String? ?? c['login_time'] as String? ?? '';
    final user = c['who'] as String? ?? c['user'] as String? ?? '';
    final ip = c['from'] as String? ?? c['ip'] as String? ?? '';
    final type = c['type'] as String? ?? 'HTTP/HTTPS';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassCard(
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                time,
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
                user,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                ip,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.primaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3: Details (Memory breakdown + Disk details)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDetailsTab() {
    final l = AppLocalizations.of(context)!;
    final info = SessionManager.instance.nasInfo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory breakdown
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pie_chart_outline,
                      size: 16,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.memoryBreakdown,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _detailRow(l.total, '$_ramTotalMb MB', AppColors.onSurface),
                _detailRow(l.used, '$_ramUsedMb MB', AppColors.tertiary),
                _detailRow(
                  l.cached,
                  '$_ramCachedMb MB',
                  AppColors.primaryContainer,
                ),
                _detailRow(
                  l.bufferLabel,
                  '$_ramBufferMb MB',
                  AppColors.secondary,
                ),
                _detailRow(
                  l.available,
                  '${_ramTotalMb - _ramUsedMb} MB',
                  const Color(0xFF66BB6A),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Per-disk info
          if (info != null && info.disks.isNotEmpty)
            GlassCard(
              borderRadius: 18,
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
                        l.diskInformation,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...info.disks.asMap().entries.map((e) {
                    final d = e.value;
                    final sizeStr = d.sizeGb >= 1024
                        ? '${(d.sizeGb / 1024).toStringAsFixed(1)} TB'
                        : '${d.sizeGb} GB';
                    return Padding(
                      padding: EdgeInsets.only(top: e.key > 0 ? 10 : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${e.key + 1}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.model,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  l.driveHddDetail(e.key + 1, sizeStr),
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
                              color:
                                  (d.status == 'normal'
                                          ? AppColors.secondary
                                          : AppColors.error)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              d.status == 'normal' ? l.normal : d.status,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: d.status == 'normal'
                                    ? AppColors.secondary
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double kbPerSec) {
    if (kbPerSec >= 1024) {
      return '${(kbPerSec / 1024).toStringAsFixed(1)} MB/s';
    }
    return '${kbPerSec.toStringAsFixed(1)} KB/s';
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sparkline chart painter (single line)
// ═══════════════════════════════════════════════════════════════════
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double maxVal;

  _SparklinePainter({
    required this.data,
    required this.color,
    this.maxVal = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Data line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final step = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] / maxVal).clamp(0, 1) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════
// Dual sparkline chart (for network rx/tx)
// ═══════════════════════════════════════════════════════════════════
class _DualSparklinePainter extends CustomPainter {
  final List<double> data1;
  final List<double> data2;
  final Color color1;
  final Color color2;

  _DualSparklinePainter({
    required this.data1,
    required this.data2,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double maxVal = 1;
    for (final v in data1) {
      if (v > maxVal) maxVal = v;
    }
    for (final v in data2) {
      if (v > maxVal) maxVal = v;
    }

    _drawLine(canvas, size, data1, color1, maxVal);
    _drawLine(canvas, size, data2, color2, maxVal);
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color,
    double maxVal,
  ) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final step = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] / maxVal).clamp(0, 1) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DualSparklinePainter old) => true;
}
