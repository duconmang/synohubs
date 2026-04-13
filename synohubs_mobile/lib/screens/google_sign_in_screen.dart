import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../services/google_auth_service.dart';
import '../l10n/app_localizations.dart';

/// Shown when the user needs to sign in with Google interactively.
class GoogleSignInScreen extends StatefulWidget {
  final Future<void> Function() onSignedIn;

  const GoogleSignInScreen({super.key, required this.onSignedIn});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  late final AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await GoogleAuthService.instance.signIn();
      if (!mounted) return;
      if (ok) {
        await widget.onSignedIn();
      } else {
        setState(() {
          _loading = false;
          _error = 'Sign-in was cancelled';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.signInFailed(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: _GoogleBg(animation: _bgAnim)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

                    const SizedBox(height: 48),

                    // ── Sign-in card ──
                    GlassCard(
                      borderRadius: 28,
                      hasGlow: true,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            size: 36,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.signInToContinue,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.signInPrivacyNote,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── Google sign-in button ──
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                disabledBackgroundColor: Colors.white
                                    .withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Google "G" icon from material
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const _GoogleLogo(),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          l.signInWithGoogle,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Privacy note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.noDataStoredOnServers,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
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
}

// ═══════════════════════════════════════════════════════════════════
// Google "G" logo drawn with CustomPainter — no external asset needed
// ═══════════════════════════════════════════════════════════════════
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(22, 22), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final r = s / 2 * 0.9;

    // Blue arc (top-right)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -pi / 6,
      -2 * pi / 3,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18
        ..strokeCap = StrokeCap.butt,
    );

    // Green arc (bottom-right)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      pi / 6 + pi / 2,
      -pi / 3 - pi / 6,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18
        ..strokeCap = StrokeCap.butt,
    );

    // Yellow arc (bottom-left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      pi * 2 / 3 + pi / 6,
      -pi / 3,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18
        ..strokeCap = StrokeCap.butt,
    );

    // Red arc (top-left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      pi + pi / 6,
      -pi / 3,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.18
        ..strokeCap = StrokeCap.butt,
    );

    // Blue arm (horizontal bar to the right)
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + r, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = s * 0.18
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════
// Animated background (same cybertech style as NAS login)
// ═══════════════════════════════════════════════════════════════════
class _GoogleBg extends AnimatedWidget {
  const _GoogleBg({required Animation<double> animation})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoogleBgPainter((listenable as Animation<double>).value),
      size: Size.infinite,
    );
  }
}

class _GoogleBgPainter extends CustomPainter {
  final double t;
  _GoogleBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF070D1A),
    );

    final rng = Random(42);

    // Grid
    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Nodes
    for (int i = 0; i < 25; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final phase = rng.nextDouble();
      final pulse = (sin((t * 2 * pi) + (phase * 2 * pi)) + 1) / 2;
      final alpha = 0.1 + pulse * 0.2;
      canvas.drawCircle(
        Offset(cx, cy),
        1.5 + pulse * 1.5,
        Paint()..color = AppColors.primary.withValues(alpha: alpha),
      );
    }

    // Center glow
    final glow = RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 1.0,
      colors: [
        AppColors.primaryContainer.withValues(alpha: 0.06),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = glow.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleBgPainter old) => true;
}
