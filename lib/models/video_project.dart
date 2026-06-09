import 'dart:ui';

class VideoProject {
  final String id;
  String name;
  String prompt;
  final DateTime createdAt;
  DateTime updatedAt;
  VideoStatus status;
  String? outputPath;
  String? thumbnailPath;
  int duration;
  String aspectRatio;
  List<VideoClip> clips;
  List<VideoEffect> effects;
  String? audioPath;
  String? musicPath;
  final Map<String, dynamic> settings;

  VideoProject({
    required this.id,
    required this.name,
    this.prompt = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = VideoStatus.draft,
    this.outputPath,
    this.thumbnailPath,
    this.duration = 5,
    this.aspectRatio = '16:9',
    this.clips = const [],
    this.effects = const [],
    this.audioPath,
    this.musicPath,
    this.settings = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'prompt': prompt,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'status': status.name,
    'output_path': outputPath,
    'thumbnail_path': thumbnailPath,
    'duration': duration,
    'aspect_ratio': aspectRatio,
    'audio_path': audioPath,
    'music_path': musicPath,
    'settings': settings,
  };

  factory VideoProject.fromJson(Map<String, dynamic> json) => VideoProject(
    id: json['id'],
    name: json['name'],
    prompt: json['prompt'] ?? '',
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    status: VideoStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => VideoStatus.draft,
    ),
    outputPath: json['output_path'],
    thumbnailPath: json['thumbnail_path'],
    duration: json['duration'] ?? 5,
    aspectRatio: json['aspect_ratio'] ?? '16:9',
    audioPath: json['audio_path'],
    musicPath: json['music_path'],
    settings: Map<String, dynamic>.from(json['settings'] ?? {}),
  );
}

enum VideoStatus {
  draft,
  rendering,
  completed,
  failed,
}

class VideoClip {
  final String id;
  final String imagePath;
  final double startTime;
  final double duration;
  final String transition;
  final double transitionDuration;
  final Offset? panStart;
  final Offset? panEnd;
  final double scale;

  VideoClip({
    required this.id,
    required this.imagePath,
    this.startTime = 0,
    this.duration = 3,
    this.transition = 'fade',
    this.transitionDuration = 0.5,
    this.panStart,
    this.panEnd,
    this.scale = 1.0,
  });
}

class VideoEffect {
  final String type;
  final Map<String, dynamic> parameters;

  VideoEffect({required this.type, this.parameters = const {}});
}

enum AspectRatio {
  square('1:1', 1.0),
  portrait('9:16', 9 / 16),
  landscape('16:9', 16 / 9),
  story('9:16', 9 / 16),
  wide('21:9', 21 / 9),
  fourThree('4:3', 4 / 3),
  threeTwo('3:2', 3 / 2);

  final String label;
  final double ratio;

  const AspectRatio(this.label, this.ratio);
}
