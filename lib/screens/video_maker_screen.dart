import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/video_maker_provider.dart';
import '../models/video_project.dart';
import '../widgets/video_preview.dart';
import '../widgets/ai_loading_indicator.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class VideoMakerScreen extends StatefulWidget {
  const VideoMakerScreen({super.key});

  @override
  State<VideoMakerScreen> createState() => _VideoMakerScreenState();
}

class _VideoMakerScreenState extends State<VideoMakerScreen> {
  final _promptController = TextEditingController();
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _promptController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoMakerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Video Maker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showProjectHistory(context, provider),
            tooltip: 'Projects',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.generatedVideoUrl != null)
              _buildVideoPreview(provider),
            if (provider.isLoading)
              AiLoadingIndicator(
                message: 'Generating video...',
                progress: provider.renderProgress,
              ),
            _buildPromptSection(provider),
            const SizedBox(height: 20),
            _buildSlideshowSection(provider),
            const SizedBox(height: 20),
            _buildSettingsSection(provider),
            const SizedBox(height: 20),
            _buildGenerateButton(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(VideoMakerProvider provider) {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: VideoPreview(
          videoUrl: provider.generatedVideoUrl!,
          autoplay: true,
        ),
      ),
    );
  }

  Widget _buildPromptSection(VideoMakerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('AI Video Generation', style: AppStyles.heading3),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              hintText: 'Describe the video you want to create...',
              prefixIcon: Icon(Icons.text_fields),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                label: 'Nature timelapse',
                onTap: () => _promptController.text = 'A beautiful nature timelapse with mountains and sunset',
              ),
              _SuggestionChip(
                label: 'City drone shot',
                onTap: () => _promptController.text = 'Cinematic drone shot flying over a futuristic city at night',
              ),
              _SuggestionChip(
                label: 'Abstract art',
                onTap: () => _promptController.text = 'Abstract colorful flowing art animation with particles',
              ),
              _SuggestionChip(
                label: 'Product showcase',
                onTap: () => _promptController.text = 'Elegant product showcase rotation on a clean background',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideshowSection(VideoMakerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.collections, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text('Slideshow Maker', style: AppStyles.heading3),
                ],
              ),
              if (provider.selectedImages.isNotEmpty)
                TextButton(
                  onPressed: () => provider.clearImages(),
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.selectedImages.isEmpty)
            GestureDetector(
              onTap: () => provider.pickImages(),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[500]),
                      const SizedBox(height: 8),
                      Text('Tap to add images', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            ),
          if (provider.selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.selectedImages.length + 1,
                itemBuilder: (_, i) {
                  if (i == provider.selectedImages.length) {
                    return GestureDetector(
                      onTap: () => provider.pickImages(),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.add, color: Colors.grey),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            provider.selectedImages[i],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => provider.removeImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _TransitionChip(
                    label: 'Fade',
                    selected: true,
                    onTap: () {},
                  ),
                  _TransitionChip(
                    label: 'Slide',
                    selected: false,
                    onTap: () {},
                  ),
                  _TransitionChip(
                    label: 'Zoom',
                    selected: false,
                    onTap: () {},
                  ),
                  _TransitionChip(
                    label: 'None',
                    selected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSection(VideoMakerProvider provider) {
    int duration = provider.currentProject?.duration ?? 5;
    String aspectRatio = provider.currentProject?.aspectRatio ?? '16:9';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Text('Settings', style: AppStyles.heading3),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duration (seconds)', style: AppStyles.caption),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: duration,
                          isExpanded: true,
                          items: [5, 10, 15, 30, 60].map((d) {
                            return DropdownMenuItem(value: d, child: Text('$d sec'));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) provider.setDuration(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aspect Ratio', style: AppStyles.caption),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: aspectRatio,
                          isExpanded: true,
                          items: AspectRatio.values.map((ar) {
                            return DropdownMenuItem(
                              value: ar.label,
                              child: Text(ar.label),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) provider.setAspectRatio(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(VideoMakerProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.isLoading
            ? null
            : () => _generateVideo(provider),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.isLoading ? Icons.hourglass_top : Icons.videocam,
            ),
            const SizedBox(width: 12),
            Text(
              provider.isLoading ? 'Generating...' : 'Generate Video',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _generateVideo(VideoMakerProvider provider) {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty && provider.selectedImages.isEmpty) {
      Helpers.showSnackBar(context, 'Enter a prompt or add images first', isError: true);
      return;
    }

    if (provider.selectedImages.isNotEmpty) {
      provider.createSlideshowVideo(
        images: provider.selectedImages,
        durationPerImage: 3,
      );
    } else {
      provider.generateVideoFromPrompt(
        prompt,
        duration: provider.currentProject?.duration ?? 5,
        aspectRatio: provider.currentProject?.aspectRatio ?? '16:9',
      );
    }
  }

  void _showProjectHistory(BuildContext context, VideoMakerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
            const SizedBox(height: 16),
            Text('Video Projects', style: AppStyles.heading2),
            const SizedBox(height: 16),
            if (provider.projects.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 48, color: Colors.grey[700]),
                      const SizedBox(height: 12),
                      Text('No projects yet', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: provider.projects.length,
                  itemBuilder: (_, i) {
                    final project = provider.projects[i];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getProjectStatusColor(project.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getProjectStatusIcon(project.status),
                          color: _getProjectStatusColor(project.status),
                        ),
                      ),
                      title: Text(project.name, style: AppStyles.label),
                      subtitle: Text(
                        Helpers.formatDate(project.createdAt),
                        style: AppStyles.caption,
                      ),
                      trailing: Text(
                        project.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getProjectStatusColor(project.status),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        provider.selectProject(project.id);
                        _promptController.text = project.prompt;
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getProjectStatusColor(VideoStatus status) {
    switch (status) {
      case VideoStatus.draft: return Colors.grey;
      case VideoStatus.rendering: return AppColors.warning;
      case VideoStatus.completed: return AppColors.success;
      case VideoStatus.failed: return AppColors.error;
    }
  }

  IconData _getProjectStatusIcon(VideoStatus status) {
    switch (status) {
      case VideoStatus.draft: return Icons.edit_note;
      case VideoStatus.rendering: return Icons.hourglass_top;
      case VideoStatus.completed: return Icons.check_circle;
      case VideoStatus.failed: return Icons.error;
    }
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _TransitionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TransitionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
