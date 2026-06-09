import 'dart:io';
import 'package:flutter/material.dart';
import '../models/image_data.dart';
import '../utils/helpers.dart';

class GalleryProvider extends ChangeNotifier {
  List<ImageData> _images = [];
  List<ImageData> _filteredImages = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _isGrid = true;

  List<ImageData> get images => _searchQuery.isEmpty ? _images : _filteredImages;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get isGrid => _isGrid;
  int get imageCount => _images.length;

  Future<void> loadGallery() async {
    _isLoading = true;
    notifyListeners();

    try {
      final galleryDir = await Helpers.getGalleryDirectory();
      final files = galleryDir.listSync();

      _images = files
          .whereType<File>()
          .where((f) => Helpers.isImageFile(f.path))
          .map((f) {
            final stat = f.statSync();
            return ImageData(
              id: Helpers.generateId(),
              path: f.path,
              name: f.path.split('/').last,
              createdAt: stat.modified,
              sizeInBytes: stat.size,
            );
          })
          .toList();

      _applySort();
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applySort();
    _applyFilter();
    notifyListeners();
  }

  void toggleViewMode() {
    _isGrid = !_isGrid;
    notifyListeners();
  }

  void _applySort() {
    switch (_sortBy) {
      case 'date':
        _images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'name':
        _images.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'size':
        _images.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
        break;
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredImages = _images;
    } else {
      _filteredImages = _images.where((img) =>
        img.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  Future<void> deleteImage(String imageId) async {
    final index = _images.indexWhere((img) => img.id == imageId);
    if (index != -1) {
      final file = File(_images[index].path);
      if (await file.exists()) {
        await file.delete();
      }
      _images.removeAt(index);
      _applyFilter();
      notifyListeners();
    }
  }

  Future<void> importImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await Helpers.saveToGallery(file);
      await loadGallery();
    }
  }

  void clear() {
    _images.clear();
    _filteredImages.clear();
    _searchQuery = '';
    notifyListeners();
  }
}
