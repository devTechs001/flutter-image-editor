import 'dart:ui';

class ImageData {
  final String id;
  final String path;
  final String? thumbnailPath;
  final String name;
  final DateTime createdAt;
  final int width;
  final int height;
  final int sizeInBytes;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  ImageData({
    required this.id,
    required this.path,
    this.thumbnailPath,
    required this.name,
    DateTime? createdAt,
    this.width = 0,
    this.height = 0,
    this.sizeInBytes = 0,
    this.tags = const [],
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1.0;
  String get sizeFormatted => _formatSize(sizeInBytes);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'thumbnail_path': thumbnailPath,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'width': width,
    'height': height,
    'size_in_bytes': sizeInBytes,
    'tags': tags,
    'metadata': metadata,
  };

  factory ImageData.fromJson(Map<String, dynamic> json) => ImageData(
    id: json['id'],
    path: json['path'],
    thumbnailPath: json['thumbnail_path'],
    name: json['name'],
    createdAt: DateTime.parse(json['created_at']),
    width: json['width'] ?? 0,
    height: json['height'] ?? 0,
    sizeInBytes: json['size_in_bytes'] ?? 0,
    tags: List<String>.from(json['tags'] ?? []),
    metadata: json['metadata'],
  );
}

class FilterPreset {
  final String name;
  final Map<String, double> parameters;
  final String icon;

  const FilterPreset({
    required this.name,
    required this.parameters,
    required this.icon,
  });

  static const List<FilterPreset> presets = [
    FilterPreset(name: 'Original', parameters: {}, icon: '🎨'),
    FilterPreset(name: 'Vivid', parameters: {'saturation': 1.4, 'contrast': 1.2}, icon: '🌈'),
    FilterPreset(name: 'Vintage', parameters: {'saturation': 0.5, 'sepia': 0.6}, icon: '📸'),
    FilterPreset(name: 'Noir', parameters: {'saturation': 0.0, 'contrast': 1.5}, icon: '🖤'),
    FilterPreset(name: 'Warm', parameters: {'temperature': 0.3, 'saturation': 1.1}, icon: '☀️'),
    FilterPreset(name: 'Cool', parameters: {'temperature': -0.3, 'saturation': 1.1}, icon: '❄️'),
    FilterPreset(name: 'Dramatic', parameters: {'contrast': 1.8, 'shadows': -0.3}, icon: '🎭'),
    FilterPreset(name: 'Soft', parameters: {'blur': 0.3, 'brightness': 1.1}, icon: '✨'),
    FilterPreset(name: 'Neon', parameters: {'saturation': 2.0, 'contrast': 1.3}, icon: '💫'),
    FilterPreset(name: 'Retro', parameters: {'saturation': 0.7, 'vignette': 0.4}, icon: '📺'),
    FilterPreset(name: 'HDR', parameters: {'contrast': 1.6, 'shadows': -0.4, 'highlights': 0.3}, icon: '🌅'),
    FilterPreset(name: 'Pastel', parameters: {'saturation': 0.6, 'brightness': 1.15}, icon: '🌸'),
  ];
}

enum AdjustmentType {
  brightness,
  contrast,
  saturation,
  exposure,
  highlights,
  shadows,
  temperature,
  tint,
  vibrance,
  sharpness,
  blur,
  vignette,
  grain,
  hue,
  sepia,
}

class Adjustment {
  final AdjustmentType type;
  double value;

  Adjustment({required this.type, this.value = 0.0});

  String get label {
    switch (type) {
      case AdjustmentType.brightness: return 'Brightness';
      case AdjustmentType.contrast: return 'Contrast';
      case AdjustmentType.saturation: return 'Saturation';
      case AdjustmentType.exposure: return 'Exposure';
      case AdjustmentType.highlights: return 'Highlights';
      case AdjustmentType.shadows: return 'Shadows';
      case AdjustmentType.temperature: return 'Temperature';
      case AdjustmentType.tint: return 'Tint';
      case AdjustmentType.vibrance: return 'Vibrance';
      case AdjustmentType.sharpness: return 'Sharpness';
      case AdjustmentType.blur: return 'Blur';
      case AdjustmentType.vignette: return 'Vignette';
      case AdjustmentType.grain: return 'Grain';
      case AdjustmentType.hue: return 'Hue';
      case AdjustmentType.sepia: return 'Sepia';
    }
  }

  String get icon {
    switch (type) {
      case AdjustmentType.brightness: return '☀️';
      case AdjustmentType.contrast: return '🌓';
      case AdjustmentType.saturation: return '🎨';
      case AdjustmentType.exposure: return '📷';
      case AdjustmentType.highlights: return '✨';
      case AdjustmentType.shadows: return '🌑';
      case AdjustmentType.temperature: return '🌡️';
      case AdjustmentType.tint: return '🟣';
      case AdjustmentType.vibrance: return '💥';
      case AdjustmentType.sharpness: return '🔍';
      case AdjustmentType.blur: return '💧';
      case AdjustmentType.vignette: return '⭕';
      case AdjustmentType.grain: return '🌾';
      case AdjustmentType.hue: return '🔄';
      case AdjustmentType.sepia: return '🟤';
    }
  }
}
