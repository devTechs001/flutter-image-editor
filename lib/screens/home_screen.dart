import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'image_editor_screen.dart';
import 'video_maker_screen.dart';
import 'ai_recognition_screen.dart';
import 'gallery_screen.dart';
import 'settings_screen.dart';
import 'batch_processing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = const [
    _HomeContent(),
    ImageEditorScreen(),
    VideoMakerScreen(),
    AiRecognitionScreen(),
    GalleryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final tabIndex = appProvider.currentTabIndex;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: AppAnimations.normal,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(tabIndex),
          child: _screens[tabIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(tabIndex, appProvider),
    );
  }

  Widget _buildBottomNav(int tabIndex, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BottomNavigationBar(
          currentIndex: tabIndex,
          onTap: (i) => provider.currentTabIndex = i,
          items: [
            _navItem(Icons.home_rounded, 'Home'),
            _navItem(Icons.edit_rounded, 'Edit'),
            _navItem(Icons.videocam_rounded, 'Video'),
            _navItem(Icons.visibility_rounded, 'AI'),
            _navItem(Icons.photo_library_rounded, 'Gallery'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            const SizedBox(height: 24),
            _buildQuickActions(context).animate().fadeIn(duration: 500.ms, delay: 100.ms),
            const SizedBox(height: 28),
            _buildAiFeaturesSection(context).animate().fadeIn(duration: 600.ms, delay: 200.ms),
            const SizedBox(height: 28),
            _buildExtraTools(context).animate().fadeIn(duration: 600.ms, delay: 300.ms),
            const SizedBox(height: 28),
            _buildRecentActivity(context).animate().fadeIn(duration: 600.ms, delay: 400.ms),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
              child: Text(
                AppStrings.appName,
                style: AppTypography.heading1.copyWith(fontSize: 34, color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.tagline,
              style: TextStyle(fontSize: 14, color: Colors.grey[400], letterSpacing: 0.5),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.auto_fix_high,
        label: 'Enhance',
        color: AppColors.primary,
        gradient: AppColors.primaryGradient,
        onTap: () => _goToTab(context, 1),
      ),
      _QuickAction(
        icon: Icons.auto_awesome,
        label: 'Generate',
        color: AppColors.secondary,
        gradient: AppColors.secondaryGradient,
        onTap: () => _showGenerateModal(context),
      ),
      _QuickAction(
        icon: Icons.visibility,
        label: 'Analyze',
        color: AppColors.tertiary,
        gradient: AppColors.tertiaryGradient,
        onTap: () => _goToTab(context, 3),
      ),
      _QuickAction(
        icon: Icons.video_library,
        label: 'Video',
        color: const Color(0xFFFFC107),
        gradient: AppColors.sunsetGradient,
        onTap: () => _goToTab(context, 2),
      ),
      _QuickAction(
        icon: Icons.dashboard_customize,
        label: 'Batch',
        color: const Color(0xFF9C27B0),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BatchProcessingScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Quick Actions', style: AppTypography.overline.copyWith(color: Colors.grey)),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _buildQuickActionCard(actions[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: 90,
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: action.color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(action.icon, color: action.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(action.label, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[300],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAiFeaturesSection(BuildContext context) {
    final features = [
      _AiFeature(
        icon: Icons.image_search,
        label: 'Super Resolution',
        description: 'Upscale images 4x with AI',
        color: AppColors.primary,
        onTap: () => _goToTab(context, 1),
      ),
      _AiFeature(
        icon: Icons.palette,
        label: 'Style Transfer',
        description: 'Artistic filters & effects',
        color: AppColors.tertiary,
        onTap: () => _goToTab(context, 1),
      ),
      _AiFeature(
        icon: Icons.content_cut,
        label: 'Remove BG',
        description: 'AI background removal',
        color: AppColors.secondary,
        onTap: () => _goToTab(context, 1),
      ),
      _AiFeature(
        icon: Icons.colorize,
        label: 'Colorize',
        description: 'B&W to vibrant color',
        color: const Color(0xFFFFC107),
        onTap: () => _goToTab(context, 1),
      ),
      _AiFeature(
        icon: Icons.text_fields,
        label: 'OCR Text',
        description: 'Extract text from images',
        color: const Color(0xFF00BCD4),
        onTap: () => _goToTab(context, 3),
      ),
      _AiFeature(
        icon: Icons.transform,
        label: 'Img2Img',
        description: 'Transform with AI prompts',
        color: const Color(0xFF9C27B0),
        onTap: () => _goToTab(context, 1),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AI Features', style: AppTypography.heading3.copyWith(fontSize: 22)),
            TextButton(
              onPressed: () => _goToTab(context, 1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          itemBuilder: (_, i) => _buildFeatureCard(features[i]),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(_AiFeature feature) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: feature.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, color: feature.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(feature.label, style: AppTypography.label),
                  const SizedBox(height: 2),
                  Text(feature.description, style: AppTypography.caption.copyWith(fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[700], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tools', style: AppTypography.heading3.copyWith(fontSize: 22)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToolCard(
                icon: Icons.dashboard_customize,
                label: 'Batch Processing',
                description: 'Process multiple files',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BatchProcessingScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolCard(
                icon: Icons.cloud_sync,
                label: 'Cloud Sync',
                description: 'Sync across devices',
                color: const Color(0xFF2196F3),
                onTap: () => Helpers.showSnackBar(context, 'Cloud sync coming soon'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToolCard(
                icon: Icons.settings,
                label: 'Settings',
                description: 'Customize your experience',
                color: const Color(0xFF607D8B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolCard(
                icon: Icons.download,
                label: 'Export All',
                description: 'Export all projects',
                color: const Color(0xFF4CAF50),
                onTap: () => Helpers.showSnackBar(context, 'Export feature coming soon'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppStyles.cardPadding,
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Recent Activity', style: AppTypography.heading4),
                ],
              ),
              TextButton(
                onPressed: () => _goToTab(context, 4),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Icon(Icons.hourglass_empty, size: 40, color: Colors.grey[700]),
                    const SizedBox(height: 12),
                    Text('No recent activity', style: TextStyle(color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    Text(
                      'Start editing to see your history',
                      style: AppTypography.caption.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToTab(BuildContext context, int index) {
    context.read<AppProvider>().currentTabIndex = index;
  }

  void _showGenerateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _GenerateOptionsSheet(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.onTap,
  });
}

class _AiFeature {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
  const _AiFeature({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTypography.label),
            const SizedBox(height: 2),
            Text(description, style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _GenerateOptionsSheet extends StatelessWidget {
  const _GenerateOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppStyles.bottomSheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
            child: Text('Generate With AI', style: AppTypography.heading2.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          _OptionTile(
            icon: Icons.image,
            title: 'Generate Image',
            subtitle: 'Create images from text prompts',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().currentTabIndex = 1;
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.videocam,
            title: 'Generate Video',
            subtitle: 'Create videos from descriptions',
            color: AppColors.tertiary,
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().currentTabIndex = 2;
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.text_fields,
            title: 'Extract Text',
            subtitle: 'OCR & text recognition',
            color: AppColors.secondary,
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().currentTabIndex = 3;
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.transform,
            title: 'Transform Image',
            subtitle: 'Img2Img AI transformation',
            color: const Color(0xFF9C27B0),
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().currentTabIndex = 1;
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.label),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption.copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 14),
          ],
        ),
      ),
    );
  }
}


