// KANAWA - Splash Screen (App Motorista)
// v1.2 — Sessão persistente + validação de token

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/kanawa_theme.dart';
import '../../shared/widgets/kanawa_logo_pin.dart';
import '../../shared/widgets/kanawa_signature.dart';
import '../auth/login_screen.dart';
import '../driver/driver_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _wordController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _wordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _entryController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _wordController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    await _navigate();
  }

  Future<void> _navigate() async {
    // ═══════════════════════════════════════════════════
    // 1. Verifica se há tokens guardados
    // ═══════════════════════════════════════════════════
    final hasSession = await ApiClient.hasSession();
    if (!mounted) return;

    if (!hasSession) {
      debugPrint('🚪 Sem sessão — vai para Login');
      _goTo(const LoginScreen());
      return;
    }

    // ═══════════════════════════════════════════════════
    // 2. Tem tokens → valida com /auth/me/
    //    (ApiClient renova automaticamente se o access expirou)
    // ═══════════════════════════════════════════════════
    debugPrint('🔐 Sessão encontrada — a validar token...');
    final response = await ApiClient.get('/auth/me/');
    if (!mounted) return;

    if (response.success) {
      // Token válido → verifica se é DRIVER
      final data = response.data;
      if (data is Map && data['user_type'] == 10) {
        debugPrint('✅ Token válido (DRIVER) → Home');
        _goTo(const DriverHomeScreen());
        return;
      }

      // Se for outro tipo, limpa e vai para Login
      debugPrint('⚠️ Token válido mas não é DRIVER');
      await ApiClient.clearTokens();
      if (!mounted) return;
      _goTo(const LoginScreen());
      return;
    }

    // Token inválido → limpa e vai para Login
    debugPrint('❌ Token inválido → Login');
    await ApiClient.clearTokens();
    if (!mounted) return;
    _goTo(const LoginScreen());
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _wordController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 4),

              // Pin
              AnimatedBuilder(
                animation: _entryController,
                builder: (context, _) {
                  final entry =
                      Curves.easeOutCubic.transform(_entryController.value);
                  return Opacity(
                    opacity: entry,
                    child: Transform.translate(
                      offset: Offset(0, (1 - entry) * 20),
                      child: Transform.scale(
                        scale: 0.82 + (entry * 0.18),
                        child: const KanawaLogoPin(
                          size: 150,
                          showShadow: true,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Wordmark
              AnimatedBuilder(
                animation: _wordController,
                builder: (_, __) => _AnimatedWordmark(
                  progress: _wordController.value,
                ),
              ),

              const SizedBox(height: 12),

              // Badge MOTORISTA
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: KanawaColors.driver.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: KanawaColors.driver.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_car_rounded,
                        color: KanawaColors.driver,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MOTORISTA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: KanawaColors.driver,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Frase
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                ),
                child: Text(
                  'Conduz. Ganha. Cresce.\nO KANAWA conta contigo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KanawaColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Progresso
              AnimatedBuilder(
                animation: _progressController,
                builder: (_, __) => _ProgressBar(
                  progress: _progressController.value,
                ),
              ),

              const Spacer(flex: 3),

              // Assinatura
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryController,
                  curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                ),
                child: const Center(child: KanawaSignature()),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WORDMARK ANIMADO
// ═══════════════════════════════════════════════════════════
class _AnimatedWordmark extends StatelessWidget {
  final double progress;

  const _AnimatedWordmark({required this.progress});

  @override
  Widget build(BuildContext context) {
    const word = 'KANAWA';
    const total = 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final start = index / total * 0.55;
        final end = start + 0.45;
        final p = ((progress - start) / (end - start)).clamp(0.0, 1.0);
        final curved = Curves.easeOutCubic.transform(p);

        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, (1 - curved) * 12),
            child: Text(
              word[index],
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: KanawaColors.textStrong,
                height: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BARRA DE PROGRESSO
// ═══════════════════════════════════════════════════════════
class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    const maxWidth = 160.0;
    const barHeight = 4.0;

    return SizedBox(
      width: maxWidth,
      height: barHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: KanawaColors.blueSoft,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KanawaColors.blueDark, Color(0xFF4A90E2)],
                ),
                borderRadius: BorderRadius.circular(barHeight / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}