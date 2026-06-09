import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'image_editor_screen.dart';
import 'video_maker_screen.dart';
import 'ai_recognition_screen.dart';
import 'gallery_screen.dart';

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
        child: _screens[tabIndex],
      ),
      bottomNavigationBar: _buildBottomNav(tabIndex, appProvider),
    );
  }

  Widget _buildBottomNav(int tabIndex, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: tabIndex,
          onTap: (i) => provider.currentTabIndex = i,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_rounded), label: 'Edit'),
            BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: 'Video'),
            BottomNavigationBarItem(icon: Icon(Icons.visibility_rounded), label: 'AI'),
            BottomNavigationBarItem(icon: Icon(Icons.photo_library_rounded), label: 'Gallery'),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 28),
            _buildAiFeaturesGrid(context),
            const SizedBox(height: 28),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
              child: const Text(
                'AI Image Studio',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create amazing content with AI',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundImage: const AssetImage('assets/icons/avatar.png'),
          backgroundColor: AppColors.card,
          child: Icon(Icons.person, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _QuickActionCard(
            icon: Icons.auto_fix_high,
            label: 'AI Enhance',
            color: const Color(0xFF6C63FF),
            onTap: () => context.read<AppProvider>().currentTabIndex = 1,
          ),
          _QuickActionCard(
            icon: Icons.auto_awesome,
            label: 'Generate',
            color: const Color(0xFF03DAC6),
            onTap: () => _showGenerateDialog(context),
          ),
          _QuickActionCard(
            icon: Icons.visibility,
            label: 'Scan & Read',
            color: const Color(0xFFFF6584),
            onTap: () => context.read<AppProvider>().currentTabIndex = 3,
          ),
          _QuickActionCard(
            icon: Icons.video_library,
            label: 'Make Video',
            color: const Color(0xFFFFC107),
            onTap: () => context.read<AppProvider>().currentTabIndex = 2,
          ),
          _QuickActionCard(
            icon: Icons.photo_library,
            label: 'Gallery',
            color: const Color(0xFF4CAF50),
            onTap: () => context.read<AppProvider>().currentTabIndex = 4,
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeaturesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Features', style: AppStyles.heading2),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _FeatureCard(
              icon: Icons.image_search,
              label: 'Super Resolution',
              description: 'Upscale images 4x',
              color: const Color(0xFF6C63FF),
              onTap: () => _startProcessing(context, 'super_resolution'),
            ),
            _FeatureCard(
              icon: Icons.palette,
              label: 'Style Transfer',
              description: 'Artistic filters',
              color: const Color(0xFFFF6584),
              onTap: () => _startProcessing(context, 'style_transfer'),
            ),
            _FeatureCard(
              icon: Icons.content_cut,
              label: 'Remove BG',
              description: 'AI background removal',
              color: const Color(0xFF03DAC6),
              onTap: () => _startProcessing(context, 'remove_bg'),
            ),
            _FeatureCard(
              icon: Icons.colorize,
              label: 'Colorize',
              description: 'B&W to color',
              color: const Color(0xFFFFC107),
              onTap: () => _startProcessing(context, 'colorize'),
            ),
            _FeatureCard(
              icon: Icons.auto_fix_high,
              label: 'AI Enhance',
              description: 'Auto improve quality',
              color: const Color(0xFF4CAF50),
              onTap: () => _startProcessing(context, 'enhance'),
            ),
            _FeatureCard(
              icon: Icons.transform,
              label: 'Img2Img',
              description: 'Transform with AI',
              color: const Color(0xFF9C27B0),
              onTap: () => _startProcessing(context, 'img2img'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppStyles.heading2),
            TextButton(
              onPressed: () => context.read<AppProvider>().currentTabIndex = 4,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 140,
          decoration: AppStyles.glassCard,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 40, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                Text(
                  'Start editing your first image',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _startProcessing(BuildContext context, String action) {
    context.read<AppProvider>().currentTabIndex = 1;
  }

  void _showGenerateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenerateOptionsSheet(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AppStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Generate With AI', style: AppStyles.heading2),
          const SizedBox(height: 20),
          _GenerateOptionTile(
            icon: Icons.image,
            title: 'Generate Image',
            subtitle: 'Create images from text prompts',
            color: const Color(0xFF6C63FF),
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().currentTabIndex = 1;
            },
          ),
          const SizedBox(height: 12),
          _GenerateOptionTile(
            icon: Icons.videocam,
            title: 'Generate Video',
            subtitle: 'Create videos from descriptions',
            color: const Color(0xFFFF6584),
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().currentTabIndex = 2;
            },
          ),
          const SizedBox(height: 12),
          _GenerateOptionTile(
            icon: Icons.text_fields,
            title: 'Extract Text',
            subtitle: 'OCR & text recognition',
            color: const Color(0xFF03DAC6),
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().currentTabIndex = 3;
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GenerateOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GenerateOptionTile({
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
              padding: const EdgeInsets.all(10),
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
                  Text(title, style: AppStyles.label),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}
