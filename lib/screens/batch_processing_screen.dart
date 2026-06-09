import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/image_editor_provider.dart';
import '../models/ai_response.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({super.key});

  @override
  State<BatchProcessingScreen> createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen> {
  List<File> _selectedFiles = [];
  bool _isProcessing = false;
  double _progress = 0.0;
  int _completedCount = 0;
  List<_BatchResult> _results = [];
  String _selectedAction = 'enhance';
  String _outputFormat = 'png';

  final Map<String, String> _actions = {
    'enhance': 'AI Enhance',
    'remove_bg': 'Remove BG',
    'compress': 'Compress',
    'resize': 'Resize',
    'convert': 'Convert Format',
  };

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.files.map((f) => File(f.path!)).toList();
        _results = [];
        _completedCount = 0;
        _progress = 0.0;
      });
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _completedCount = 0;
      _results = [];
    });

    for (int i = 0; i < _selectedFiles.length; i++) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final outputPath = '${_selectedFiles[i].path}_processed.$_outputFormat';
        await _selectedFiles[i].copy(outputPath);

        setState(() {
          _completedCount = i + 1;
          _progress = (i + 1) / _selectedFiles.length;
          _results.add(_BatchResult(
            fileName: _selectedFiles[i].path.split('/').last,
            success: true,
            outputPath: outputPath,
          ));
        });
      } catch (e) {
        setState(() {
          _results.add(_BatchResult(
            fileName: _selectedFiles[i].path.split('/').last,
            success: false,
            error: e.toString(),
          ));
        });
      }
    }

    setState(() => _isProcessing = false);
    if (mounted) {
      Helpers.showSnackBar(
        context,
        'Processed $_completedCount of ${_selectedFiles.length} files',
      );
    }
  }

  void _clearAll() {
    setState(() {
      _selectedFiles.clear();
      _results.clear();
      _completedCount = 0;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Processing'),
        actions: [
          if (_selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionSelector(),
            const SizedBox(height: 16),
            _buildFileSection(),
            const SizedBox(height: 16),
            if (_isProcessing || _results.isNotEmpty) _buildProgressSection(),
            if (_results.isNotEmpty) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSelector() {
    return Container(
      padding: AppStyles.cardPadding,
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('Batch Action', style: AppTypography.heading4),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _actions.entries.map((entry) {
              final isSelected = _selectedAction == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedAction = entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Output Format:', style: AppTypography.label),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _outputFormat,
                underline: const SizedBox(),
                items: ['png', 'jpg', 'webp', 'bmp'].map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.toUpperCase()));
                }).toList(),
                onChanged: (v) => setState(() => _outputFormat = v!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection() {
    return Container(
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
                  const Icon(Icons.folder_open, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Text('Selected Files', style: AppTypography.heading4),
                ],
              ),
              Text(
                '${_selectedFiles.length} files',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedFiles.isEmpty)
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[500]),
                      const SizedBox(height: 8),
                      Text('Tap to select images', style: TextStyle(color: Colors.grey[500])),
                      Text('Up to ${AppConstants.maxBatchSize} files', style: AppTypography.caption),
                    ],
                  ),
                ),
              ),
            ),
          if (_selectedFiles.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedFiles.length + 1,
                itemBuilder: (_, i) {
                  if (i == _selectedFiles.length) {
                    return GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        width: 80,
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
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedFiles[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.card,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFiles.removeAt(i)),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _startProcessing,
                icon: Icon(_isProcessing ? Icons.hourglass_top : Icons.play_arrow),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Start Processing',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      padding: AppStyles.cardPadding,
      decoration: AppStyles.glassCard,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.sync, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('Processing', style: AppTypography.heading4),
            ],
          ),
          const SizedBox(height: 20),
          if (_isProcessing)
            CircularPercentIndicator(
              radius: 50,
              percent: _progress,
              center: Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.heading3,
              ),
              progressColor: AppColors.primary,
              backgroundColor: AppColors.card,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 8,
            )
          else
            const Icon(Icons.check_circle, color: AppColors.success, size: 60),
          const SizedBox(height: 16),
          Text(
            _isProcessing
                ? 'Processing $_completedCount of ${_selectedFiles.length}...'
                : 'Completed $_completedCount of ${_selectedFiles.length} files',
            style: AppTypography.bodyText,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildResultsSection() {
    return Container(
      width: double.infinity,
      padding: AppStyles.cardPadding,
      decoration: AppStyles.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize, color: AppColors.success),
              const SizedBox(width: 12),
              Text('Results', style: AppTypography.heading4),
            ],
          ),
          const SizedBox(height: 12),
          ..._results.map((result) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: result.success ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        result.fileName,
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (result.success)
                      Text('Done', style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                      )),
                  ],
                ),
              )),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _BatchResult {
  final String fileName;
  final bool success;
  final String? outputPath;
  final String? error;

  _BatchResult({
    required this.fileName,
    required this.success,
    this.outputPath,
    this.error,
  });
}
