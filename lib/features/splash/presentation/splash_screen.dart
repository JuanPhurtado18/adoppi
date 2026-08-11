import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controlador para el fade in y scale del logo
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Controlador para el pulso del corazón
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  // Controlador para el fade in del texto
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo — aparece en 600ms
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Pulso — late dos veces, cada latido dura 350ms
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_pulseController);

    // Texto — aparece subiendo suavemente en 500ms
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
  }

  Future<void> _startSequence() async {
    // Espera un frame para que el widget esté montado
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 1. Aparece el logo
    await _logoController.forward();
    if (!mounted) return;

    // 2. Primer latido
    await _pulseController.forward();
    _pulseController.reset();
    if (!mounted) return;

    // Pausa entre latidos
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    // 3. Segundo latido
    await _pulseController.forward();
    _pulseController.reset();
    if (!mounted) return;

    // 4. Aparece el texto
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _textController.forward();

    // 5. Espera y navega
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Centro — logo y texto
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo con animaciones de aparición y pulso
                    AnimatedBuilder(
                      animation: Listenable.merge(
                          [_logoController, _pulseController]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale: _logoScale.value * _pulseScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Texto con fade y slide
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          const Text(
                            'Adoppi',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Encuentra tu compañero perfecto',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Parte inferior — iconos de mascotas y ciudad
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFade.value,
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PetIcon(icon: Icons.pets, delay: 0),
                        const SizedBox(width: 16),
                        _PetIcon(icon: Icons.cruelty_free, delay: 150),
                        const SizedBox(width: 16),
                        _PetIcon(icon: Icons.favorite_border, delay: 300),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cali, Colombia',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetIcon extends StatefulWidget {
  final IconData icon;
  final int delay;

  const _PetIcon({required this.icon, required this.delay});

  @override
  State<_PetIcon> createState() => _PetIconState();
}

class _PetIconState extends State<_PetIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _float = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          widget.icon,
          color: Colors.white.withOpacity(0.9),
          size: 22,
        ),
      ),
    );
  }
}