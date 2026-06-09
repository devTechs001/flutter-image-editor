class AiResponse {
  final bool success;
  final String? error;
  final String? imageBase64;
  final String? imageUrl;
  final String? videoUrl;
  final String? text;
  final List<DetectedObject>? objects;
  final Map<String, dynamic>? metadata;

  AiResponse({
    required this.success,
    this.error,
    this.imageBase64,
    this.imageUrl,
    this.videoUrl,
    this.text,
    this.objects,
    this.metadata,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      success: json['success'] ?? true,
      error: json['error'],
      imageBase64: json['image'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      text: json['text'],
      objects: json['objects'] != null
          ? (json['objects'] as List)
              .map((o) => DetectedObject.fromJson(o))
              .toList()
          : null,
      metadata: json['metadata'],
    );
  }
}

class DetectedObject {
  final String label;
  final double confidence;
  final Rect? boundingBox;
  final Offset? center;

  DetectedObject({
    required this.label,
    required this.confidence,
    this.boundingBox,
    this.center,
  });

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    Rect? rect;
    if (json['bbox'] != null) {
      final bbox = json['bbox'];
      rect = Rect.fromLTRB(
        bbox[0].toDouble(),
        bbox[1].toDouble(),
        bbox[2].toDouble(),
        bbox[3].toDouble(),
      );
    }

    Offset? center;
    if (json['center'] != null) {
      center = Offset(
        json['center'][0].toDouble(),
        json['center'][1].toDouble(),
      );
    }

    return DetectedObject(
      label: json['class'] ?? json['label'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      boundingBox: rect,
      center: center,
    );
  }
}

class RecognitionResult {
  final String text;
  final double confidence;
  final Rect? boundingBox;

  RecognitionResult({
    required this.text,
    required this.confidence,
    this.boundingBox,
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) {
    Rect? rect;
    if (json['bbox'] != null) {
      final bbox = json['bbox'];
      rect = Rect.fromLTRB(
        bbox[0][0].toDouble(),
        bbox[0][1].toDouble(),
        bbox[2][0].toDouble(),
        bbox[2][1].toDouble(),
      );
    }

    return RecognitionResult(
      text: json['text'],
      confidence: json['confidence'].toDouble(),
      boundingBox: rect,
    );
  }
}

enum ProcessingAction {
  enhance,
  styleTransfer,
  colorize,
  superResolution,
  removeBackground,
  objectDetection,
  textRecognition,
  imageGeneration,
  videoGeneration,
  img2img,
}

extension ProcessingActionExtension on ProcessingAction {
  String get endpoint {
    switch (this) {
      case ProcessingAction.enhance:
      case ProcessingAction.styleTransfer:
      case ProcessingAction.colorize:
      case ProcessingAction.superResolution:
        return '/api/process-image';
      case ProcessingAction.removeBackground:
        return '/api/remove-bg';
      case ProcessingAction.objectDetection:
        return '/api/detect-objects';
      case ProcessingAction.textRecognition:
        return '/api/recognize-text';
      case ProcessingAction.imageGeneration:
        return '/api/generate-image';
      case ProcessingAction.videoGeneration:
        return '/api/generate-video';
      case ProcessingAction.img2img:
        return '/api/img2img';
    }
  }

  String get label {
    switch (this) {
      case ProcessingAction.enhance: return 'AI Enhance';
      case ProcessingAction.styleTransfer: return 'Style Transfer';
      case ProcessingAction.colorize: return 'Colorize';
      case ProcessingAction.superResolution: return 'Super Resolution';
      case ProcessingAction.removeBackground: return 'Remove BG';
      case ProcessingAction.objectDetection: return 'Detect Objects';
      case ProcessingAction.textRecognition: return 'Read Text';
      case ProcessingAction.imageGeneration: return 'Generate Image';
      case ProcessingAction.videoGeneration: return 'Generate Video';
      case ProcessingAction.img2img: return 'Transform';
    }
  }

  String get icon {
    switch (this) {
      case ProcessingAction.enhance: return '✨';
      case ProcessingAction.styleTransfer: return '🎭';
      case ProcessingAction.colorize: return '🌈';
      case ProcessingAction.superResolution: return '🔍';
      case ProcessingAction.removeBackground: return '✂️';
      case ProcessingAction.objectDetection: return '🎯';
      case ProcessingAction.textRecognition: return '📝';
      case ProcessingAction.imageGeneration: return '🖼️';
      case ProcessingAction.videoGeneration: return '🎬';
      case ProcessingAction.img2img: return '🔄';
    }
  }
}
