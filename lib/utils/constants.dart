import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'AI Image Studio';
  static const String apiBaseUrl = 'http://localhost:5000';
  static const String wsUrl = 'ws://localhost:5000/ws';

  static const Duration defaultTimeout = Duration(seconds: 60);
  static const Duration longTimeout = Duration(seconds: 120);

  static const double defaultPadding = 20.0;
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double smallRadius = 12.0;
  static const double iconSize = 24.0;
  static const double appBarHeight = 60.0;

  static const List<String> supportedImageFormats = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff',
  ];
  static const List<String> supportedVideoFormats = [
    'mp4', 'mov', 'avi', 'mkv', 'webm',
  ];

  static const int maxImageSize = 20 * 1024 * 1024;
  static const int maxVideoSize = 200 * 1024 * 1024;
}

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color tertiary = Color(0xFFFF6584);
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color card = Color(0xFF2D2D44);
  static const Color cardLight = Color(0xFF3D3D5C);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5B52E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44), Color(0xFF16213E)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF03DAC6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> filterColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF03DAC6),
    Color(0xFFFFC107),
    Color(0xFF4CAF50),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];
}

class AppStyles {
  AppStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static BoxDecoration glassCard = BoxDecoration(
    color: AppColors.card.withOpacity(0.8),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration gradientCard = BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    gradient: const LinearGradient(
      colors: [Color(0xFF6C63FF), Color(0xFF5B52E8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF6C63FF).withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 400);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
}
