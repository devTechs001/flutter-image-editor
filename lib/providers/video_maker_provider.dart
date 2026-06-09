import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/video_project.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class VideoMakerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  List<VideoProject> _projects = [];
  VideoProject? _currentProject;
  bool _isLoading = false;
  String? _error;
  double _renderProgress = 0.0;
  String? _generatedVideoUrl;
  List<File> _selectedImages = [];

  List<VideoProject> get projects => _projects;
  VideoProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get renderProgress => _renderProgress;
  String? get generatedVideoUrl => _generatedVideoUrl;
  List<File> get selectedImages => _selectedImages;

  VideoProject createProject(String name) {
    final project = VideoProject(
      id: Helpers.generateId(),
      name: name,
    );
    _currentProject = project;
    _projects.add(project);
    notifyListeners();
    return project;
  }

  Future<void> pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFiles.isNotEmpty) {
        _selectedImages = pickedFiles.map((f) => File(f.path)).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pick images: $e';
      notifyListeners();
    }
  }

  void addImage(File image) {
    _selectedImages.add(image);
    notifyListeners();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _selectedImages.removeAt(oldIndex);
    _selectedImages.insert(newIndex, item);
    notifyListeners();
  }

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  Future<void> generateVideoFromPrompt(String prompt, {
    int duration = 5,
    String aspectRatio = '16:9',
    String projectName = 'AI Generated Video',
  }) async {
    _isLoading = true;
    _renderProgress = 0.0;
    _error = null;
    _generatedVideoUrl = null;
    notifyListeners();

    try {
      final project = VideoProject(
        id: Helpers.generateId(),
        name: projectName,
        prompt: prompt,
        duration: duration,
        aspectRatio: aspectRatio,
        status: VideoStatus.rendering,
      );
      _currentProject = project;
      _projects.add(project);
      notifyListeners();

      _renderProgress = 0.3;
      notifyListeners();

      final videoUrl = await _apiService.generateVideo(
        prompt,
        duration: duration,
        aspectRatio: aspectRatio,
      );

      _renderProgress = 0.8;
      notifyListeners();

      _generatedVideoUrl = videoUrl;
      project.outputPath = videoUrl;
      project.status = VideoStatus.completed;

      _renderProgress = 1.0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Video generation failed: $e';
      if (_currentProject != null) {
        _currentProject!.status = VideoStatus.failed;
      }
      notifyListeners();
    }
  }

  Future<void> createSlideshowVideo({
    required List<File> images,
    int durationPerImage = 3,
    String transition = 'fade',
    String? musicPath,
  }) async {
    _isLoading = true;
    _renderProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      final project = VideoProject(
        id: Helpers.generateId(),
        name: 'Slideshow ${Helpers.formatDate(DateTime.now())}',
        status: VideoStatus.rendering,
      );

      for (int i = 0; i < images.length; i++) {
        final clip = VideoClip(
          id: Helpers.generateId(),
          imagePath: images[i].path,
          duration: durationPerImage.toDouble(),
          transition: transition,
        );
        project.clips = [...project.clips, clip];
        _renderProgress = (i + 1) / images.length * 0.7;
        notifyListeners();
      }

      project.musicPath = musicPath;
      _currentProject = project;
      _projects.add(project);
      notifyListeners();

      final imagePaths = images.map((f) => f.path).toList();
      final videoPath = await _apiService.createSlideshow(
        imagePaths,
        transitions: transition != 'none',
        musicPath: musicPath,
      );

      _renderProgress = 1.0;
      project.outputPath = videoPath;
      project.status = VideoStatus.completed;
      _generatedVideoUrl = videoPath;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Slideshow creation failed: $e';
      if (_currentProject != null) {
        _currentProject!.status = VideoStatus.failed;
      }
      notifyListeners();
    }
  }

  void setAspectRatio(String ratio) {
    if (_currentProject != null) {
      _currentProject!.aspectRatio = ratio;
      notifyListeners();
    }
  }

  void setDuration(int duration) {
    if (_currentProject != null) {
      _currentProject!.duration = duration;
      notifyListeners();
    }
  }

  void deleteProject(String projectId) {
    _projects.removeWhere((p) => p.id == projectId);
    if (_currentProject?.id == projectId) {
      _currentProject = null;
    }
    notifyListeners();
  }

  void selectProject(String projectId) {
    _currentProject = _projects.firstWhere((p) => p.id == projectId);
    notifyListeners();
  }

  void clear() {
    _currentProject = null;
    _generatedVideoUrl = null;
    _error = null;
    _isLoading = false;
    _renderProgress = 0.0;
    _selectedImages.clear();
    notifyListeners();
  }
}
