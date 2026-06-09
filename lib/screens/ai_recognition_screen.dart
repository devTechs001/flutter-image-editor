import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/image_editor_provider.dart';
import '../models/ai_response.dart';
import '../widgets/ai_loading_indicator.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AiRecognitionScreen extends StatefulWidget {
  const AiRecognitionScreen({super.key});

  @override
  State<AiRecognitionScreen> createState() => _AiRecognitionScreenState();
}

class _AiRecognitionScreenState extends State<AiRecognitionScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  String _recognizedText = '';
  List<DetectedObject> _detectedObjects = [];
  String? _imageCaption;
  List<Face> _detectedFaces = [];
  bool _showBoundingBoxes = true;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _recognizedText = '';
        _detectedObjects.clear();
        _detectedFaces.clear();
        _imageCaption = null;
      });
    }
  }

  Future<void> _recognizeTextML() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFile(_selectedImage!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);

      String text = '';
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          text += '${line.text}\n';
        }
      }
      await textRecognizer.close();

      setState(() {
        _recognizedText = text.isEmpty ? 'No text found' : text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      Helpers.showSnackBar(context, 'Recognition failed: $e', isError: true);
    }
  }

  Future<void> _detectFaces() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFile(_selectedImage!);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableContours: true,
        ),
      );
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      setState(() {
        _detectedFaces = faces;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      Helpers.showSnackBar(context, 'Face detection failed: $e', isError: true);
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      // Analyze using ML Kit
      await _recognizeTextML();
      await _detectFaces();

      // Simulate caption generation
      setState(() {
        _imageCaption = 'This image contains ${_detectedFaces.length > 0 ? '${_detectedFaces.length} face(s)' : 'various elements'}';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recognition'),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _analyzeImage,
              tooltip: 'Re-analyze',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImage != null) _buildImagePreview(),
            if (_isProcessing) const AiLoadingIndicator(
              message: 'Analyzing image...',
            ),
            if (_selectedImage == null && !_isProcessing)
              _buildEmptyState(),
            if (_selectedImage != null) ...[
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 20),
              if (_imageCaption != null) _buildCaptionCard(),
              if (_detectedFaces.isNotEmpty) _buildFaceResults(),
              if (_recognizedText.isNotEmpty) _buildTextResults(),
              if (_detectedObjects.isNotEmpty) _buildObjectResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
          if (_showBoundingBoxes && _detectedFaces.isNotEmpty)
            ..._detectedFaces.map((face) => _buildFaceOverlay(face)),
        ],
      ),
    );
  }

  Widget _buildFaceOverlay(Face face) {
    final rect = face.boundingBox;
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: face.smilingProbability != null
            ? Positioned(
                top: -24,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(face.smilingProbability! * 100).toStringAsFixed(0)}% smile',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.visibility, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text('AI Recognition', style: AppStyles.heading2),
          const SizedBox(height: 12),
          Text(
            'Analyze images with AI',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Select Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.text_fields,
            label: 'Extract Text',
            color: const Color(0xFF6C63FF),
            onTap: _recognizeTextML,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.face,
            label: 'Detect Faces',
            color: const Color(0xFFFF6584),
            onTap: _detectFaces,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.auto_awesome,
            label: 'Full Analysis',
            color: const Color(0xFF03DAC6),
            onTap: _analyzeImage,
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.glassCard,
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Caption', style: AppStyles.label),
                const SizedBox(height: 4),
                Text(_imageCaption ?? '', style: AppStyles.bodyText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.face, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Text('Faces Detected (${_detectedFaces.length})', style: AppStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          ..._detectedFaces.asMap().entries.map((entry) {
            final i = entry.key;
            final face = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Face ${i + 1}', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  if (face.smilingProbability != null)
                    _buildStat('Smile', '${(face.smilingProbability! * 100).toStringAsFixed(0)}%'),
                  const SizedBox(width: 12),
                  if (face.leftEyeOpenProbability != null)
                    _buildStat('Eyes', '${((face.leftEyeOpenProbability! + (face.rightEyeOpenProbability ?? 0)) / 2 * 100).toStringAsFixed(0)}%'),
                  const SizedBox(width: 12),
                  if (face.headEulerAngleZ != null)
                    _buildStat('Angle', '${face.headEulerAngleZ!.toStringAsFixed(0)}°'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTextResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Recognized Text', style: AppStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _recognizedText,
              style: AppStyles.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('Detected Objects', style: AppStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _detectedObjects.map((obj) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(obj.label, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${(obj.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[300],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
