import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _buildProfileSection(),
            const SizedBox(height: 24),

            // Appearance
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 12),
            _buildGlassTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: appProvider.isDarkMode ? 'Dark theme active' : 'Light theme active',
              trailing: Switch.adaptive(
                value: appProvider.isDarkMode,
                onChanged: (_) => appProvider.toggleTheme(),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Features
            _buildSectionTitle('Features'),
            const SizedBox(height: 12),
            _buildMenuTile(Icons.image_search, 'Image Quality', 'High resolution output', () {}),
            _buildMenuTile(Icons.video_settings, 'Video Settings', 'Default duration, aspect ratio', () {}),
            _buildMenuTile(Icons.save_alt, 'Auto Save', 'Save edits automatically', () {}),
            const SizedBox(height: 12),

            // Storage
            _buildSectionTitle('Storage'),
            const SizedBox(height: 12),
            _buildStorageTile(),
            const SizedBox(height: 12),

            // About
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            _buildMenuTile(Icons.info_outline, 'About', 'v${AppConstants.appVersion}', () => _showAbout(context)),
            _buildMenuTile(Icons.code, 'Open Source', 'MIT License', () {}),
            _buildMenuTile(Icons.share, 'Share App', 'Tell others about AI Image Studio', () {
              SharePlus.instance.share(
                ShareParams(
                  text: 'Check out AI Image Studio - the ultimate AI-powered image editor and video maker!',
                ),
              );
            }),
            _buildMenuTile(Icons.star_outline, 'Rate Us', 'Leave a review', () {}),
            const SizedBox(height: 32),

            // Danger zone
            _buildSectionTitle('Data'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text('Clear All Data', style: TextStyle(color: AppColors.error)),
                subtitle: Text(
                  'Remove all cached files and reset settings',
                  style: TextStyle(color: AppColors.error.withOpacity(0.7)),
                ),
                onTap: () => _confirmClearData(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: AppStyles.cardPadding,
      decoration: AppStyles.glassCard,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User', style: AppTypography.heading4),
                const SizedBox(height: 4),
                Text(
                  'Pro Plan',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: AppTypography.overline.copyWith(color: Colors.grey),
      ),
    );
  }

  Widget _buildGlassTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: AppStyles.glassCard,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: AppTypography.label),
        subtitle: Text(subtitle, style: AppTypography.caption),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppStyles.glassCard,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: AppTypography.label),
        subtitle: Text(subtitle, style: AppTypography.caption),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
      ),
    );
  }

  Widget _buildStorageTile() {
    return Container(
      padding: AppStyles.cardPadding,
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storage, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Storage Usage', style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.35,
              backgroundColor: AppColors.card,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '35% used - 350 MB of 1 GB',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: 'MIT License - Open Source',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all cached images, projects, and reset settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Helpers.showSnackBar(context, 'All data cleared');
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
