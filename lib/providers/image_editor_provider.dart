import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_data.dart';
import '../models/ai_response.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class ImageEditorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  File? _originalImage;
  File? _editedImage;
  bool _isLoading = false;
  String? _error;
  String? _processingMessage;

  List<Adjustment> _adjustments = [];
  String _selectedFilter = 'Original';
  List<DetectedObject> _detectedObjects = [];
  String _recognizedText = '';
  ProcessingAction? _currentAction;
  double _processingProgress = 0.0;

  List<File> _history = [];
  int _historyIndex = -1;

  File? get originalImage => _originalImage;
  File? get editedImage => _editedImage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get processingMessage => _processingMessage;
  List<Adjustment> get adjustments => _adjustments;
  String get selectedFilter => _selectedFilter;
  List<DetectedObject> get detectedObjects => _detectedObjects;
  String get recognizedText => _recognizedText;
  ProcessingAction? get currentAction => _currentAction;
  double get processingProgress => _processingProgress;
  bool get hasImage => _originalImage != null;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  double get imageAspectRatio {
    if (_originalImage == null) return 1.0;
    final decodedImage = decodeImageFromList(_originalImage!.readAsBytesSync());
    return decodedImage.width / decodedImage.height;
  }

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        _originalImage = File(pickedFile.path);
        _editedImage = File(pickedFile.path);
        _history = [File(pickedFile.path)];
        _historyIndex = 0;
        _adjustments = _createDefaultAdjustments();
        _selectedFilter = 'Original';
        _detectedObjects = [];
        _recognizedText = '';
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  Future<void> captureImage() async {
    await pickImage(source: ImageSource.camera);
  }

  List<Adjustment> _createDefaultAdjustments() {
    return AdjustmentType.values
        .map((type) => Adjustment(type: type, value: 0.0))
        .toList();
  }

  void updateAdjustment(AdjustmentType type, double value) {
    final index = _adjustments.indexWhere((a) => a.type == type);
    if (index != -1) {
      _adjustments[index].value = value;
      notifyListeners();
    }
  }

  void resetAdjustments() {
    for (final adj in _adjustments) {
      adj.value = 0.0;
    }
    _selectedFilter = 'Original';
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _editedImage = _history[_historyIndex];
      notifyListeners();
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _editedImage = _history[_historyIndex];
      notifyListeners();
    }
  }

  void _addToHistory(File image) {
    _history = _history.sublist(0, _historyIndex + 1);
    _history.add(image);
    _historyIndex++;
    _editedImage = image;
  }

  Future<void> applyAIProcessing(ProcessingAction action, {
    Map<String, dynamic>? parameters,
  }) async {
    if (_originalImage == null) return;

    _isLoading = true;
    _currentAction = action;
    _error = null;
    _processingMessage = 'Processing ${action.label.toLowerCase()}...';
    _processingProgress = 0.0;
    notifyListeners();

    try {
      _processingProgress = 0.3;
      notifyListeners();

      final response = await _apiService.processImage(
        imageFile: _originalImage!,
        action: action.name,
        parameters: parameters ?? _getAdjustmentParams(),
      );

      _processingProgress = 0.8;
      notifyListeners();

      if (response.success && response.imageBase64 != null) {
        final tempDir = await Helpers.getTempDirectory();
        final outputFile = File('${tempDir.path}/processed_${Helpers.generateId()}.png');
        await outputFile.writeAsBytes(
          base64Decode(response.imageBase64!),
        );
        _addToHistory(outputFile);
      }

      _processingProgress = 1.0;
      _processingMessage = null;
      _isLoading = false;
      _currentAction = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _currentAction = null;
      _error = 'Processing failed: $e';
      _processingMessage = null;
      notifyListeners();
    }
  }

  Map<String, dynamic> _getAdjustmentParams() {
    final params = <String, dynamic>{};
    for (final adj in _adjustments) {
      if (adj.value != 0.0) {
        params[adj.type.name] = adj.value;
      }
    }
    params['filter'] = _selectedFilter;
    return params;
  }

  Future<void> detectObjects() async {
    if (_originalImage == null) return;
    _isLoading = true;
    _currentAction = ProcessingAction.objectDetection;
    notifyListeners();

    try {
      final objects = await _apiService.detectObjects(_originalImage!);
      _detectedObjects = objects;
      _isLoading = false;
      _currentAction = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _currentAction = null;
      _error = 'Object detection failed: $e';
      notifyListeners();
    }
  }

  Future<void> recognizeText() async {
    if (_originalImage == null) return;
    _isLoading = true;
    _currentAction = ProcessingAction.textRecognition;
    notifyListeners();

    try {
      final text = await _apiService.recognizeText(_originalImage!);
      _recognizedText = text;
      _isLoading = false;
      _currentAction = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _currentAction = null;
      _error = 'Text recognition failed: $e';
      notifyListeners();
    }
  }

  Future<void> removeBackground() async {
    if (_originalImage == null) return;
    _isLoading = true;
    _currentAction = ProcessingAction.removeBackground;
    notifyListeners();

    try {
      final result = await _apiService.removeBackground(_originalImage!);
      _addToHistory(result);
      _isLoading = false;
      _currentAction = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _currentAction = null;
      _error = 'Background removal failed: $e';
      notifyListeners();
    }
  }

  Future<void> generateImage(String prompt, {String style = 'realistic'}) async {
    _isLoading = true;
    _currentAction = ProcessingAction.imageGeneration;
    notifyListeners();

    try {
      final result = await _apiService.generateImage(prompt, style: style);
      _originalImage = result;
      _editedImage = result;
      _history = [result];
      _historyIndex = 0;
      _isLoading = false;
      _currentAction = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _currentAction = null;
      _error = 'Image generation failed: $e';
      notifyListeners();
    }
  }

  Future<String> saveImage() async {
    if (_editedImage == null) throw Exception('No image to save');
    return await Helpers.saveToGallery(_editedImage!);
  }

  void clear() {
    _originalImage = null;
    _editedImage = null;
    _history = [];
    _historyIndex = -1;
    _adjustments = [];
    _selectedFilter = 'Original';
    _detectedObjects = [];
    _recognizedText = '';
    _error = null;
    _isLoading = false;
    _currentAction = null;
    notifyListeners();
  }
}
