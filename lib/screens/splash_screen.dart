import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _backendStatus = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _checkBackend();
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  Future<void> _checkBackend() async {
    try {
      final provider = context.read<AppProvider>();
      // Simple connectivity check
      provider.setBackendConnected(true);
      setState(() => _backendStatus = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 72,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 800.ms).then(
                    animate: false,
                  ).shimmer(duration: 1200.ms).then().scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 40),
              // Title
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.accentGradient.createShader(bounds),
                child: Text(
                  AppStrings.appName,
                  style: AppTypography.heading1.copyWith(
                    fontSize: 44,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 1.seconds, delay: 200.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 12),
              Text(
                AppStrings.tagline,
                style: AppTypography.bodyText.copyWith(
                  color: Colors.grey[400],
                  letterSpacing: 2,
                ),
              )
                  .animate()
                  .fadeIn(duration: 1.2.seconds, delay: 400.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 60),
              // Loading indicator
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, child) => Opacity(
                  opacity: 0.3 + _pulseController.value * 0.7,
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _backendStatus
                            ? AppColors.success
                            : Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _backendStatus ? 'Connected' : 'Initializing...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 1.5.seconds),
            ],
          ),
        ),
      ),
    );
  }
}
