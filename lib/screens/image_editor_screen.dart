import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/image_editor_provider.dart';
import '../models/image_data.dart';
import '../models/ai_response.dart';
import '../widgets/ai_loading_indicator.dart';
import '../widgets/filter_panel.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> with TickerProviderStateMixin {
  late TabController _toolTabController;
  bool _showTools = false;
  bool _isCropping = false;
  final CropController _cropController = CropController();

  @override
  void initState() {
    super.initState();
    _toolTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _toolTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ImageEditorProvider>();

    return Scaffold(
      appBar: provider.hasImage ? _buildEditorAppBar(provider) : null,
      body: provider.hasImage
          ? _buildEditorBody(provider)
          : _buildEmptyState(context, provider),
    );
  }

  PreferredSizeWidget _buildEditorAppBar(ImageEditorProvider provider) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => provider.clear(),
      ),
      title: Text(
        provider.currentAction?.label ?? 'Image Editor',
        style: AppStyles.heading3,
      ),
      actions: [
        if (provider.canUndo)
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: provider.undo,
            tooltip: 'Undo',
          ),
        if (provider.canRedo)
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: provider.redo,
            tooltip: 'Redo',
          ),
        IconButton(
          icon: Icon(_showTools ? Icons.close : Icons.tune),
          onPressed: () => setState(() => _showTools = !_showTools),
        ),
      ],
    );
  }

  Widget _buildEditorBody(ImageEditorProvider provider) {
    return Column(
      children: [
        Expanded(
          child: _isCropping ? _buildCropView(provider) : _buildImageView(provider),
        ),
        if (provider.isLoading)
          AiLoadingIndicator(
            message: provider.processingMessage ?? 'Processing...',
            progress: provider.processingProgress,
            action: provider.currentAction,
          ),
        if (_showTools) _buildToolPanel(provider),
      ],
    );
  }

  Widget _buildImageView(ImageEditorProvider provider) {
    return Stack(
      children: [
        PhotoView(
          imageProvider: FileImage(provider.editedImage ?? provider.originalImage!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          loadingBuilder: (_, event) => Center(
            child: CircularProgressIndicator(
              value: event == null ? null : event.cumulativeBytesLoaded / event.expectedTotalBytes,
            ),
          ),
        ),
        // Filter overlay indicator
        if (provider.selectedFilter != 'Original')
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                provider.selectedFilter,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        // Detected objects overlay
        if (provider.detectedObjects.isNotEmpty)
          ...provider.detectedObjects.map((obj) => _buildObjectOverlay(obj, provider)),
      ],
    );
  }

  Widget _buildObjectOverlay(DetectedObject obj, ImageEditorProvider provider) {
    if (obj.boundingBox == null) return const SizedBox.shrink();
    return Positioned(
      left: obj.boundingBox!.left,
      top: obj.boundingBox!.top,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${obj.label} (${(obj.confidence * 100).toStringAsFixed(0)}%)',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCropView(ImageEditorProvider provider) {
    return Crop(
      controller: _cropController,
      image: FileImage(provider.originalImage!),
      onCropped: (image) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/cropped_${Helpers.generateId()}.png');
        file.writeAsBytesSync(image);
        provider.clear();
        setState(() => _isCropping = false);
      },
    );
  }

  Widget _buildToolPanel(ImageEditorProvider provider) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _toolTabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.tune), text: 'Adjust'),
              Tab(icon: Icon(Icons.filter), text: 'Filters'),
              Tab(icon: Icon(Icons.auto_fix_high), text: 'AI Tools'),
              Tab(icon: Icon(Icons.crop), text: 'Crop'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _toolTabController,
              children: [
                _buildAdjustmentsTab(provider),
                FilterPanel(
                  selectedFilter: provider.selectedFilter,
                  onFilterSelected: provider.setFilter,
                ),
                _buildAiToolsTab(provider),
                _buildCropTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsTab(ImageEditorProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.adjustments.length,
      itemBuilder: (_, index) {
        final adj = provider.adjustments[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(adj.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  adj.label,
                  style: AppStyles.caption,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.card,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    min: -1.0,
                    max: 1.0,
                    value: adj.value,
                    onChanged: (v) => provider.updateAdjustment(adj.type, v),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  adj.value.toStringAsFixed(1),
                  style: AppStyles.caption,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiToolsTab(ImageEditorProvider provider) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _AiToolButton(
          icon: Icons.auto_fix_high,
          label: 'Enhance',
          color: const Color(0xFF6C63FF),
          onTap: () => provider.applyAIProcessing(ProcessingAction.enhance),
        ),
        _AiToolButton(
          icon: Icons.palette,
          label: 'Style',
          color: const Color(0xFFFF6584),
          onTap: () => _showStyleTransferDialog(provider),
        ),
        _AiToolButton(
          icon: Icons.content_cut,
          label: 'Remove BG',
          color: const Color(0xFF03DAC6),
          onTap: () => provider.removeBackground(),
        ),
        _AiToolButton(
          icon: Icons.colorize,
          label: 'Colorize',
          color: const Color(0xFFFFC107),
          onTap: () => provider.applyAIProcessing(ProcessingAction.colorize),
        ),
        _AiToolButton(
          icon: Icons.image_search,
          label: 'Upscale',
          color: const Color(0xFF4CAF50),
          onTap: () => provider.applyAIProcessing(ProcessingAction.superResolution),
        ),
        _AiToolButton(
          icon: Icons.transform,
          label: 'Transform',
          color: const Color(0xFF9C27B0),
          onTap: () => _showTransformDialog(provider),
        ),
        _AiToolButton(
          icon: Icons.visibility,
          label: 'Detect',
          color: const Color(0xFFFF9800),
          onTap: () => provider.detectObjects(),
        ),
        _AiToolButton(
          icon: Icons.text_fields,
          label: 'OCR',
          color: const Color(0xFF00BCD4),
          onTap: () => provider.recognizeText(),
        ),
        _AiToolButton(
          icon: Icons.auto_awesome,
          label: 'Generate',
          color: const Color(0xFFE91E63),
          onTap: () => _showGenerateImageDialog(provider),
        ),
      ],
    );
  }

  Widget _buildCropTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.crop, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Crop your image', style: AppStyles.bodyText),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isCropping = true),
            icon: const Icon(Icons.crop),
            label: const Text('Start Cropping'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ImageEditorProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.image, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text('No Image Selected', style: AppStyles.heading2),
          const SizedBox(height: 12),
          Text(
            'Choose an image to start editing',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => provider.pickImage(),
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => provider.captureImage(),
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.auto_awesome,
                label: 'Generate',
                onTap: () => _showGenerateImageDialog(provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStyleTransferDialog(ImageEditorProvider provider) {
    final styles = [
      {'name': 'Oil Painting', 'style': 'oil_painting'},
      {'name': 'Watercolor', 'style': 'watercolor'},
      {'name': 'Sketch', 'style': 'sketch'},
      {'name': 'Pop Art', 'style': 'pop_art'},
      {'name': 'Anime', 'style': 'anime'},
      {'name': 'Van Gogh', 'style': 'van_gogh'},
      {'name': 'Picasso', 'style': 'picasso'},
      {'name': 'Pixel Art', 'style': 'pixel_art'},
      {'name': '3D Render', 'style': '3d_render'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
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
            Text('Choose Style', style: AppStyles.heading2),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: styles.length,
              itemBuilder: (_, i) {
                final style = styles[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    provider.applyAIProcessing(
                      ProcessingAction.styleTransfer,
                      parameters: {'style': style['style']},
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.palette, color: AppColors.filterColors[i % AppColors.filterColors.length]),
                        const SizedBox(height: 8),
                        Text(
                          style['name']!,
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTransformDialog(ImageEditorProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Transform Image'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., "Make it look like a fantasy landscape"',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                provider.applyAIProcessing(
                  ProcessingAction.img2img,
                  parameters: {'prompt': controller.text},
                );
              }
            },
            child: const Text('Transform'),
          ),
        ],
      ),
    );
  }

  void _showGenerateImageDialog(ImageEditorProvider provider) {
    final promptController = TextEditingController();
    String selectedStyle = 'realistic';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Generate Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: promptController,
                decoration: const InputDecoration(
                  hintText: 'Describe the image you want...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStyle,
                decoration: const InputDecoration(
                  labelText: 'Style',
                ),
                items: const [
                  DropdownMenuItem(value: 'realistic', child: Text('Realistic')),
                  DropdownMenuItem(value: 'anime', child: Text('Anime')),
                  DropdownMenuItem(value: 'cinematic', child: Text('Cinematic')),
                  DropdownMenuItem(value: 'painting', child: Text('Painting')),
                ],
                onChanged: (v) => setDialogState(() => selectedStyle = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (promptController.text.isNotEmpty) {
                  provider.generateImage(promptController.text, style: selectedStyle);
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: AppStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _AiToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AiToolButton({
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
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[300])),
          ],
        ),
      ),
    );
  }
}
