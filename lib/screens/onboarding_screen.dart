import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.auto_awesome,
      title: 'AI-Powered Editing',
      description: 'Edit images with advanced AI tools.\nEnhance, transform, and create stunning visuals.',
      gradient: AppColors.primaryGradient,
    ),
    _OnboardingItem(
      icon: Icons.videocam,
      title: 'Video Generation',
      description: 'Generate videos from text prompts.\nCreate slideshows with AI-powered transitions.',
      gradient: AppColors.secondaryGradient,
    ),
    _OnboardingItem(
      icon: Icons.visibility,
      title: 'Smart Recognition',
      description: 'Detect objects, recognize text,\nand analyze faces with AI precision.',
      gradient: AppColors.tertiaryGradient,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    context.read<AppProvider>().completeOnboarding();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _navigateToHome,
                  child: Text(
                    _currentPage < _items.length - 1 ? 'Skip' : '',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ).animate().fadeIn(duration: 600.ms),
              ),
              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _buildPage(_items[i]),
                ),
              ),
              // Bottom section
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _items.length,
                        (i) => AnimatedContainer(
                          duration: AppAnimations.normal,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: _currentPage == i ? 32 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primary
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _currentPage < _items.length - 1
                            ? () => _pageController.nextPage(
                                  duration: AppAnimations.normal,
                                  curve: Curves.easeInOut,
                                )
                            : _navigateToHome,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentPage < _items.length - 1
                              ? 'Next'
                              : 'Get Started',
                          style: AppTypography.button,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: item.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: item.gradient.colors.first.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(item.icon, size: 72, color: Colors.white),
          ).animate().fadeIn(duration: 800.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 48),
          Text(
            item.title,
            style: AppTypography.heading2,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: AppTypography.bodyText,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
