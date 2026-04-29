import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../admin/admin_dashboard.dart';
import '../student/student_dashboard.dart';

/// Premium splash screen for CampusHub.
///
/// Design tokens sourced from the Stitch "CampusHub Splash Screen" project:
///   • Primary: #6961FF  • Font: Inter  • Roundness: 12 px
///   • Style: Glassmorphism over deep-indigo gradient, light mode.
///
/// All existing auth / navigation logic is preserved unchanged.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Design-system colors (from Stitch) ──────────────────────────────────
  static const Color _primary = Color(0xFF6750A4);
  static const Color _primaryDark = Color(0xFF4F378A);
  static const Color _accent = Color(0xFF4ECDC4);
  static const Color _gradientStart = Color(0xFF1D1B2F);
  static const Color _gradientMid = Color(0xFF4F378A);
  static const Color _gradientEnd = Color(0xFF6750A4);

  // ── Animation controllers ───────────────────────────────────────────────
  late final AnimationController _mainCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _particleCtrl;

  // ── Animations ──────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _glowFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _loaderFade;
  late final Animation<double> _backgroundBlur;

  Timer? _authTimer;

  @override
  void initState() {
    super.initState();

    // ── Main sequenced animation (2 s) ──────────────────────────────────
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Logo: scale in with elastic overshoot (0 → 60 %)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    // Logo: fade in (0 → 35 %)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );

    // Glow ring around logo (20 → 55 %)
    _glowFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.20, 0.55, curve: Curves.easeOut),
      ),
    );

    // Title "CampusHub" (35 → 60 %)
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.35, 0.60, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.35, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline (50 → 75 %)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.50, 0.75, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.50, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Loader (65 → 85 %)
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
      ),
    );

    // Background blur sweep (0 → 40 %)
    _backgroundBlur = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // ── Infinite pulse on the glow ring ─────────────────────────────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // ── Shimmer sweep across the title ──────────────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // ── Floating particles ──────────────────────────────────────────────
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _mainCtrl.forward();

    // Trigger auth check after animations settle
    _authTimer = Timer(const Duration(milliseconds: 2800), _checkAuth);
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  // ── Auth check — EXACTLY the same logic as before ─────────────────────
  Future<void> _checkAuth() async {
    if (!mounted) return;

    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    final userModel = await authService.getUserData(user.id);
    if (userModel == null) {
      await authService.signOut();
      if (mounted) _navigateTo(const LoginScreen());
      return;
    }

    if (mounted) {
      if (userModel.isAdmin) {
        _navigateTo(AdminDashboard(user: userModel));
      } else {
        _navigateTo(StudentDashboard(user: userModel));
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainCtrl,
          _pulseCtrl,
          _shimmerCtrl,
          _particleCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ─ Layer 0: Deep gradient background ──────────────────────
              _buildGradientBackground(),

              // ─ Layer 1: Animated mesh / orbs ──────────────────────────
              _buildFloatingOrbs(size),

              // ─ Layer 2: Floating particles ────────────────────────────
              _buildParticles(size),

              // ─ Layer 3: Glassmorphic blur overlay ─────────────────────
              if (_backgroundBlur.value > 0)
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _backgroundBlur.value,
                    sigmaY: _backgroundBlur.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),

              // ─ Layer 4: Main content ──────────────────────────────────
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // ── Logo with glow ────────────────────────────────
                      _buildLogo(),

                      const SizedBox(height: 36),

                      // ── Title "CampusHub" ─────────────────────────────
                      _buildTitle(),

                      const SizedBox(height: 12),

                      // ── Tagline ───────────────────────────────────────
                      _buildTagline(),

                      const Spacer(flex: 2),

                      // ── Loading indicator ─────────────────────────────
                      _buildLoader(),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Gradient background ─────────────────────────────────────────────────
  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gradientStart,
            _gradientMid,
            _gradientEnd,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // ── Decorative floating orbs ────────────────────────────────────────────
  Widget _buildFloatingOrbs(Size size) {
    final pulse = _pulseCtrl.value;
    return Stack(
      children: [
        // Top-right orb
        Positioned(
          top: -size.width * 0.25,
          right: -size.width * 0.15,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accent.withValues(alpha: 0.15 + pulse * 0.05),
                  _accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom-left orb
        Positioned(
          bottom: -size.width * 0.3,
          left: -size.width * 0.2,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primary.withValues(alpha: 0.20 + pulse * 0.05),
                  _primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Center glow
        Positioned(
          top: size.height * 0.25,
          left: size.width * 0.15,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryDark.withValues(alpha: 0.12 + pulse * 0.04),
                  _primaryDark.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Floating particles ──────────────────────────────────────────────────
  Widget _buildParticles(Size size) {
    return CustomPaint(
      size: size,
      painter: _ParticlePainter(
        progress: _particleCtrl.value,
        color: Colors.white,
      ),
    );
  }

  // ── Logo widget ─────────────────────────────────────────────────────────
  Widget _buildLogo() {
    final pulseValue = _pulseCtrl.value;
    final glowOpacity = _glowFade.value * (0.3 + pulseValue * 0.15);

    return FadeTransition(
      opacity: _logoFade,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            // Outer glow ring
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: glowOpacity),
                blurRadius: 50 + pulseValue * 15,
                spreadRadius: 8 + pulseValue * 6,
              ),
              BoxShadow(
                color: _accent.withValues(alpha: glowOpacity * 0.5),
                blurRadius: 80 + pulseValue * 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Title with shimmer ──────────────────────────────────────────────────
  Widget _buildTitle() {
    return Opacity(
      opacity: _titleFade.value,
      child: Transform.translate(
        offset: Offset(0, _titleSlide.value),
        child: ShaderMask(
          shaderCallback: (bounds) {
            final shimmerOffset =
                _shimmerCtrl.value * (bounds.width + 200) - 100;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.white,
                Color(0xFFB8C4FF),
                Colors.white,
              ],
              stops: [
                (shimmerOffset - 60) / bounds.width,
                shimmerOffset / bounds.width,
                (shimmerOffset + 60) / bounds.width,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: Text(
            'CampusHub',
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tagline ─────────────────────────────────────────────────────────────
  Widget _buildTagline() {
    return Opacity(
      opacity: _taglineFade.value,
      child: Transform.translate(
        offset: Offset(0, _taglineSlide.value),
        child: Text(
          'Connect  •  Collaborate  •  Grow',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  // ── Premium loading indicator ───────────────────────────────────────────
  Widget _buildLoader() {
    return Opacity(
      opacity: _loaderFade.value,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom animated dots loader
          SizedBox(
            width: 60,
            height: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                // Stagger each dot by a phase offset
                final phase = (_shimmerCtrl.value + i * 0.25) % 1.0;
                final scale = 0.5 + 0.5 * math.sin(phase * math.pi);
                final opacity = 0.3 + 0.7 * math.sin(phase * math.pi);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: opacity),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: opacity * 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Particle painter for floating ambient dots ──────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  // Pre-computed particle positions (seeded for determinism)
  static final List<_Particle> _particles = _generateParticles(18);

  _ParticlePainter({required this.progress, required this.color});

  static List<_Particle> _generateParticles(int count) {
    final rng = math.Random(42);
    return List.generate(count, (_) {
      return _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.5 + rng.nextDouble() * 2.5,
        speed: 0.3 + rng.nextDouble() * 0.7,
        opacity: 0.15 + rng.nextDouble() * 0.25,
        phase: rng.nextDouble(),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;

      // Gentle vertical drift + horizontal sway
      final x = p.x * size.width + math.sin(t * math.pi * 2) * 20;
      final y = (p.y + t * 0.4) % 1.2 * size.height;

      // Fade in/out based on vertical position
      final fadeY = 1.0 -
          ((y / size.height) - 0.5).abs() * 2.0;
      final alpha = (p.opacity * fadeY.clamp(0.0, 1.0));

      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double x, y, size, speed, opacity, phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}
