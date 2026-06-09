import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/helpers.dart';

class FileManager {
  Future<File?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.image,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      debugPrint('File pick error: $e');
    }
    return null;
  }

  Future<List<File>> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.image,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
    } catch (e) {
      debugPrint('Multi-file pick error: $e');
    }
    return [];
  }

  Future<String> saveFile(File source, {String? fileName, String? subDirectory}) async {
    try {
      final appDir = await Helpers.getAppDirectory();
      var saveDir = appDir;

      if (subDirectory != null) {
        saveDir = Directory('${appDir.path}/$subDirectory');
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
      }

      final name = fileName ?? source.path.split('/').last;
      final destPath = '${saveDir.path}/$name';
      await source.copy(destPath);
      return destPath;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  Future<String> copyToTemp(File source) async {
    final tempDir = await Helpers.getTempDirectory();
    final destPath = '${tempDir.path}/${source.path.split('/').last}';
    await source.copy(destPath);
    return destPath;
  }

  Future<int> getDirectorySize(Directory dir) async {
    int totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  Future<void> cleanTempDirectory() async {
    final tempDir = await Helpers.getTempDirectory();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create();
    }
  }

  Future<Map<String, int>> getStorageUsage() async {
    final appDir = await Helpers.getAppDirectory();
    final galleryDir = await Helpers.getGalleryDirectory();
    final projectsDir = await Helpers.getProjectsDirectory();

    return {
      'total': await getDirectorySize(appDir),
      'gallery': await getDirectorySize(galleryDir),
      'projects': await getDirectorySize(projectsDir),
      'temp': await getDirectorySize(await Helpers.getTempDirectory()),
    };
  }

  Future<String> exportFile(File file, {String? format}) async {
    final outputDir = await Helpers.getAppDirectory();
    final exportDir = Directory('${outputDir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final baseName = file.path.split('/').last.split('.').first;
    final ext = format ?? file.path.split('.').last;
    final exportPath = '${exportDir.path}/${baseName}_export.$ext';
    await file.copy(exportPath);
    return exportPath;
  }
}
