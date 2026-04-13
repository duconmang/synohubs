import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Beautiful splash screen shown during silent Google Sign-In.
/// Features the SynoHub logo with a rotating neon glow effect.
class SplashScreen extends StatefulWidget {
  final Future<void> Function() onInit;

  const SplashScreen({super.key, required this.onInit});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _neonController;
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // Neon rotation
    _neonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Pulse scale
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Kick off initialization
    _initialize();
  }

  Future<void> _initialize() async {
    await widget.onInit();
  }

  @override
  void dispose() {
    _neonController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF070D1A),
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            // Background particles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _neonController,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(_neonController.value),
                ),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Neon-bordered logo ──
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _neonController,
                      _pulseController,
                    ]),
                    builder: (_, __) {
                      final pulse = 1.0 + _pulseController.value * 0.06;
                      return Transform.scale(
                        scale: pulse,
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: CustomPaint(
                            painter: _NeonBorderPainter(
                              progress: _neonController.value,
                            ),
                            child: Center(
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryContainer
                                          .withValues(alpha: 0.3),
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/icons/SynoHub.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // App name
                  Text(
                    'SynoHub',
                    style: GoogleFonts.manrope(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.synologyNasManagement,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading indicator
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryContainer.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    l.connecting,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom branding
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Center(
                child: Text(
                  l.version,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Neon border painter — rotating gradient stroke around the logo
// ═══════════════════════════════════════════════════════════════════
class _NeonBorderPainter extends CustomPainter {
  final double progress;
  _NeonBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
      const Radius.circular(34),
    );

    final angle = progress * 2 * pi;

    // ── Outer glow layer ──
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle,
        endAngle: angle + 2 * pi,
        colors: [
          AppColors.primaryContainer.withValues(alpha: 0.0),
          AppColors.primaryContainer.withValues(alpha: 0.6),
          AppColors.secondary.withValues(alpha: 0.5),
          AppColors.tertiary.withValues(alpha: 0.3),
          AppColors.primaryContainer.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRRect(rrect, glowPaint);

    // ── Inner crisp neon line ──
    final neonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle,
        endAngle: angle + 2 * pi,
        colors: [
          AppColors.primaryContainer.withValues(alpha: 0.0),
          AppColors.primaryContainer,
          AppColors.secondary,
          AppColors.tertiary.withValues(alpha: 0.6),
          AppColors.primaryContainer.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRRect(rrect, neonPaint);

    // ── Bright head dot (leading point of the neon trail) ──
    final headX = center.dx + radius * cos(angle);
    final headY = center.dy + radius * sin(angle);
    canvas.drawCircle(
      Offset(headX, headY),
      4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(Offset(headX, headY), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _NeonBorderPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════
// Floating particles background
// ═══════════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(77);

    for (int i = 0; i < 40; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble();

      final y = (baseY + t * speed * 200) % size.height;
      final x = baseX + sin((t + phase) * 2 * pi) * 15;
      final alpha = 0.05 + (sin((t + phase) * 2 * pi) + 1) / 2 * 0.15;
      final radius = 1.0 + rng.nextDouble() * 1.5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = AppColors.primaryContainer.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
