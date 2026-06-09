import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class Helpers {
  Helpers._();

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final id = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
    return '${DateTime.now().millisecondsSinceEpoch}_$id';
  }

  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-.]'), '_').replaceAll(RegExp(r'\s+'), '_');
  }

  static String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  static bool isImageFile(String path) {
    const extensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff'];
    return extensions.contains(getFileExtension(path));
  }

  static bool isVideoFile(String path) {
    const extensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
    return extensions.contains(getFileExtension(path));
  }

  static Future<Directory> getAppDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/ai_image_studio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/ai_image_studio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> getGalleryDirectory() async {
    final appDir = await getAppDirectory();
    final dir = Directory('${appDir.path}/gallery');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> getProjectsDirectory() async {
    final appDir = await getAppDirectory();
    final dir = Directory('${appDir.path}/projects');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> saveToGallery(File file) async {
    final galleryDir = await getGalleryDirectory();
    final fileName = '${generateId()}.${getFileExtension(file.path)}';
    final savedFile = await file.copy('${galleryDir.path}/$fileName');
    return savedFile.path;
  }

  static void vibrate() {
    HapticFeedback.mediumImpact();
  }

  static void showSnackBar(BuildContext context, String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFCF6679) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  static String getAspectRatioLabel(double ratio) {
    if ((ratio - 1.0).abs() < 0.01) return '1:1';
    if ((ratio - 16 / 9).abs() < 0.01) return '16:9';
    if ((ratio - 9 / 16).abs() < 0.01) return '9:16';
    if ((ratio - 4 / 3).abs() < 0.01) return '4:3';
    if ((ratio - 3 / 2).abs() < 0.01) return '3:2';
    if ((ratio - 21 / 9).abs() < 0.01) return '21:9';
    return ratio.toStringAsFixed(2);
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
