import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_colors.dart';
import '../services/session_manager.dart';
import '../services/quickconnect_resolver.dart';
import '../widgets/glass_card.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final String? initialHost;
  final String? initialPort;
  final String? initialUser;
  final bool? initialHttps;
  final bool skipAutoLoad;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.initialHost,
    this.initialPort,
    this.initialUser,
    this.initialHttps,
    this.skipAutoLoad = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _addressCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _useHttps = true;
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = true;
  String? _error;

  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // Skip auto-load when adding a new NAS
    if (widget.skipAutoLoad) return;

    // Pre-fill from initial params (NAS Manager) if provided
    if (widget.initialHost != null) {
      _addressCtrl.text = widget.initialHost!;
      _portCtrl.text = widget.initialPort ?? '5001';
      _usernameCtrl.text = widget.initialUser ?? '';
      _useHttps = widget.initialHttps ?? true;
      if (mounted) setState(() {});
      return; // Don't auto-login — user needs to enter password
    }

    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final host = await storage.read(key: 'nas_host');
    if (host == null || host.isEmpty) return;
    _addressCtrl.text = host;
    _portCtrl.text = await storage.read(key: 'nas_port') ?? '5001';
    _usernameCtrl.text = await storage.read(key: 'nas_user') ?? '';
    _passwordCtrl.text = await storage.read(key: 'nas_pass') ?? '';
    final httpsStr = await storage.read(key: 'nas_https');
    _useHttps = httpsStr != 'false';
    _rememberMe = true;
    if (mounted) setState(() {});
    // Auto-login if all fields are filled
    if (_addressCtrl.text.isNotEmpty &&
        _usernameCtrl.text.isNotEmpty &&
        _passwordCtrl.text.isNotEmpty) {
      _doLogin();
    }
  }

  Future<void> _saveCredentials() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    if (_rememberMe) {
      await storage.write(key: 'nas_host', value: _addressCtrl.text.trim());
      await storage.write(key: 'nas_port', value: _portCtrl.text.trim());
      await storage.write(key: 'nas_user', value: _usernameCtrl.text.trim());
      await storage.write(key: 'nas_pass', value: _passwordCtrl.text);
      await storage.write(key: 'nas_https', value: _useHttps.toString());
    } else {
      await storage.delete(key: 'nas_host');
      await storage.delete(key: 'nas_port');
      await storage.delete(key: 'nas_user');
      await storage.delete(key: 'nas_pass');
      await storage.delete(key: 'nas_https');
    }
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _addressCtrl.dispose();
    _portCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Parse a full URL or plain host into (host, port, https) components.
  /// Supports: IP, hostname, hostname:port, https://host, https://host:port/path
  void _parseAddress() {
    var raw = _addressCtrl.text.trim();
    if (raw.isEmpty) return;

    // Don't parse QuickConnect inputs — they are handled separately
    if (QuickConnectResolver.isQuickConnect(raw)) return;

    // Detect and strip protocol prefix
    if (raw.startsWith('https://')) {
      raw = raw.substring(8);
      _useHttps = true;
    } else if (raw.startsWith('http://')) {
      raw = raw.substring(7);
      _useHttps = false;
    }

    // Strip trailing slashes and paths
    raw = raw.split('/').first;

    // Extract port from host:port format
    final bracketEnd = raw.lastIndexOf(']'); // IPv6 [::1]:port
    final colonIdx = raw.lastIndexOf(':');
    if (colonIdx > 0 && colonIdx > bracketEnd) {
      final portPart = raw.substring(colonIdx + 1);
      final parsed = int.tryParse(portPart);
      if (parsed != null && parsed > 0 && parsed <= 65535) {
        _portCtrl.text = parsed.toString();
        raw = raw.substring(0, colonIdx);
      }
    }

    _addressCtrl.text = raw;
    if (mounted) setState(() {});
  }

  Future<void> _doLogin({String? otpCode}) async {
    final rawAddr = _addressCtrl.text.trim();
    final user = _usernameCtrl.text.trim();
    final pass = _passwordCtrl.text;

    // ── QuickConnect detection ──
    if (QuickConnectResolver.isQuickConnect(rawAddr)) {
      if (user.isEmpty || pass.isEmpty) {
        setState(
          () => _error = AppLocalizations.of(context)!.allFieldsRequired,
        );
        return;
      }
      setState(() {
        _loading = true;
        _error = null;
      });

      try {
        final qcId = QuickConnectResolver.extractId(rawAddr);
        final result = await QuickConnectResolver.resolve(qcId);
        if (!mounted) return;

        // Fill resolved values into the form
        _addressCtrl.text = result.host;
        _portCtrl.text = result.port.toString();
        _useHttps = result.useHttps;
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '${AppLocalizations.of(context)!.quickConnectFailed}\n$e';
        });
        return;
      }
    } else {
      // Normal address — smart-parse
      _parseAddress();
    }

    final host = _addressCtrl.text.trim();
    final portStr = _portCtrl.text.trim();

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.allFieldsRequired;
      });
      return;
    }
    if (portStr.isEmpty) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.invalidPortNumber;
      });
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null || port < 1 || port > 65535) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.invalidPortNumber;
      });
      return;
    }

    // Start loading only if not already set by QC flow above
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final err = await SessionManager.instance.login(
      host: host,
      port: port,
      useHttps: _useHttps,
      account: user,
      password: pass,
      otpCode: otpCode,
    );

    if (!mounted) return;

    // 2FA required → show OTP dialog
    if (err == '2FA_REQUIRED') {
      setState(() => _loading = false);
      final otp = await _showOtpDialog();
      if (otp != null && otp.isNotEmpty) {
        _doLogin(otpCode: otp);
      }
      return;
    }

    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
    } else {
      await _saveCredentials();
      setState(() => _loading = false);
      widget.onLoginSuccess();
    }
  }

  /// Show a dialog to enter 2FA / OTP code.
  Future<String?> _showOtpDialog() {
    final otpCtrl = TextEditingController();
    final l = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
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
                Icons.security,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.otpDialogTitle,
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
            Text(
              l.otpDialogMessage,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 24,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest.withValues(
                  alpha: 0.3,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              l.cancel,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(otpCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              l.verify,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated cybertech background ──
          Positioned.fill(child: _CybertechBackground(animation: _bgAnim)),

          // ── Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),

                    // ── Logo ──
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/icons/SynoHub.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'SynoHub',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.synologyNasManagement,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Login form ──
                    GlassCard(
                      borderRadius: 28,
                      hasGlow: true,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Server address
                          _label(l.nasAddress),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _addressCtrl,
                            hint: l.ipHostnameOrQuickConnect,
                            icon: Icons.dns_outlined,
                          ),

                          const SizedBox(height: 20),

                          // Port & Protocol
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label(l.port.toUpperCase()),
                                    const SizedBox(height: 8),
                                    _textField(
                                      controller: _portCtrl,
                                      hint: l.port,
                                      icon: Icons.tag,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label(l.protocol),
                                    const SizedBox(height: 8),
                                    _protocolToggle(),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Username
                          _label(l.usernameLabel),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _usernameCtrl,
                            hint: l.usernameHint,
                            icon: Icons.person_outline,
                          ),

                          const SizedBox(height: 20),

                          // Password
                          _label(l.passwordLabel),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _passwordCtrl,
                            hint: l.passwordHint,
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),

                          // Error
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Remember me toggle
                          GestureDetector(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                    activeColor: AppColors.primary,
                                    side: BorderSide(
                                      color: AppColors.outlineVariant
                                          .withValues(alpha: 0.4),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l.rememberMe,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Connect button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryContainer,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _doLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: AppColors.onPrimary,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.onPrimary,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.link, size: 20),
                                          const SizedBox(width: 10),
                                          Text(
                                            l.connect,
                                            style: GoogleFonts.manrope(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form helpers ───────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _protocolToggle() {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _protocolChip('HTTP', !_useHttps),
          _protocolChip('HTTPS', _useHttps),
        ],
      ),
    );
  }

  Widget _protocolChip(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _useHttps = label == 'HTTPS'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Animated Cybertech Background
// ═══════════════════════════════════════════════════════════════════

class _CybertechBackground extends AnimatedWidget {
  const _CybertechBackground({required Animation<double> animation})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CybertechPainter((listenable as Animation<double>).value),
      size: Size.infinite,
    );
  }
}

class _CybertechPainter extends CustomPainter {
  final double t;
  _CybertechPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF070D1A),
    );

    final rng = Random(42);

    // ── Grid lines ──
    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    const gridSpacing = 40.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Glowing nodes ──
    for (int i = 0; i < 30; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final phase = rng.nextDouble();
      final pulse = (sin((t * 2 * pi) + (phase * 2 * pi)) + 1) / 2;
      final radius = 1.5 + pulse * 2;
      final alpha = 0.15 + pulse * 0.25;

      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()..color = AppColors.primary.withValues(alpha: alpha),
      );
      // Glow ring
      canvas.drawCircle(
        Offset(cx, cy),
        radius + 6,
        Paint()
          ..color = AppColors.primary.withValues(alpha: alpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // ── Connection lines between nearby nodes ──
    final nodes = <Offset>[];
    final rng2 = Random(42);
    for (int i = 0; i < 30; i++) {
      nodes.add(
        Offset(rng2.nextDouble() * size.width, rng2.nextDouble() * size.height),
      );
    }
    final linePaint = Paint()
      ..strokeWidth = 0.4
      ..color = AppColors.primary.withValues(alpha: 0.06);
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if ((nodes[i] - nodes[j]).distance < 160) {
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // ── Scanning sweep line ──
    final sweepY = (t % 1.0) * size.height;
    final sweepGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.0),
        AppColors.primary.withValues(alpha: 0.06),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - 60, size.width, 120),
      Paint()
        ..shader = sweepGradient.createShader(
          Rect.fromLTWH(0, sweepY - 60, size.width, 120),
        ),
    );

    // ── Radial vignette glow at center-top ──
    final centerGlow = RadialGradient(
      center: const Alignment(0, -0.6),
      radius: 1.0,
      colors: [
        AppColors.primaryContainer.withValues(alpha: 0.08),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = centerGlow.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _CybertechPainter old) => true;
}
