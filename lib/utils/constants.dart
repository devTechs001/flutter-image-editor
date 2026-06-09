import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'AI Image Studio';
  static const String appVersion = '2.0.0';

  static const String apiBaseUrl = 'http://localhost:5000';
  static const String wsUrl = 'ws://localhost:5000/ws';
  static const String apiHealthUrl = '/api/health';

  static const Duration defaultTimeout = Duration(seconds: 60);
  static const Duration longTimeout = Duration(seconds: 120);
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const Duration debounceDuration = Duration(milliseconds: 300);

  static const double defaultPadding = 20.0;
  static const double cardRadius = 24.0;
  static const double buttonRadius = 16.0;
  static const double smallRadius = 12.0;
  static const double iconSize = 24.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 72.0;

  static const List<String> supportedImageFormats = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'heic', 'svg',
  ];

  static const List<String> supportedVideoFormats = [
    'mp4', 'mov', 'avi', 'mkv', 'webm', 'gif', 'apng',
  ];

  static const int maxImageSize = 50 * 1024 * 1024;
  static const int maxVideoSize = 500 * 1024 * 1024;
  static const int maxBatchSize = 50;
}

class AppColors {
  AppColors._();

  // Dark theme
  static const Color primary = Color(0xFF7C6FFF);
  static const Color primaryLight = Color(0xFF9E96FF);
  static const Color primaryDark = Color(0xFF5B4FE0);
  static const Color secondary = Color(0xFF00E5C8);
  static const Color secondaryLight = Color(0xFF4DFFE8);
  static const Color tertiary = Color(0xFFFF6B8A);
  static const Color tertiaryLight = Color(0xFFFF8FA8);
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF151528);
  static const Color surfaceLight = Color(0xFF1E1E3A);
  static const Color card = Color(0xFF1A1A35);
  static const Color cardLight = Color(0xFF252550);
  static const Color cardHover = Color(0xFF2A2A55);
  static const Color error = Color(0xFFCF6679);
  static const Color errorLight = Color(0xFFFF8A9E);
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color info = Color(0xFF64B5F6);

  // Light theme
  static const Color lightBackground = Color(0xFFF5F5FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFEEEEF5);
  static const Color lightCardLight = Color(0xFFE0E0EB);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B80);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C6FFF), Color(0xFF5B4FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00E5C8), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tertiaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFFF3D5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0D1A), Color(0xFF151528), Color(0xFF1A1A35)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7C6FFF), Color(0xFF00E5C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF7C6FFF), Color(0xFF00E5C8), Color(0xFFFF6B8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> accentColors = [
    Color(0xFF7C6FFF),
    Color(0xFF00E5C8),
    Color(0xFFFF6B8A),
    Color(0xFFFFC107),
    Color(0xFF4CAF50),
    Color(0xFFFF5722),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];

  static Color getFilterColor(int index) =>
      accentColors[index % accentColors.length];
}

class AppTypography {
  AppTypography._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    height: 1.5,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white60,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white38,
    height: 1.3,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Colors.white38,
    letterSpacing: 1.5,
  );
}

class AppStyles {
  AppStyles._();

  static BoxDecoration glassCard = BoxDecoration(
    color: AppColors.card.withOpacity(0.6),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(color: Colors.white.withOpacity(0.06)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration glassCardStrong = BoxDecoration(
    color: AppColors.card.withOpacity(0.85),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 40,
        offset: const Offset(0, 15),
      ),
    ],
  );

  static BoxDecoration gradientCard = BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    gradient: const LinearGradient(
      colors: [Color(0xFF7C6FFF), Color(0xFF5B4FE0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF7C6FFF).withOpacity(0.3),
        blurRadius: 25,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration neonBorder = BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: const Color(0xFF7C6FFF).withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF7C6FFF).withOpacity(0.1),
        blurRadius: 15,
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration bottomSheet = BoxDecoration(
    color: AppColors.surface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 50,
        offset: const Offset(0, -10),
      ),
    ],
  );

  static EdgeInsets screenPadding = const EdgeInsets.all(20);
  static EdgeInsets cardPadding = const EdgeInsets.all(20);
  static EdgeInsets sectionPadding = const EdgeInsets.symmetric(vertical: 24);

  static double cardHeight = 160;
  static double avatarSize = 48;
}

class AppAnimations {
  AppAnimations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 1000);
  static const Duration pageTransition = Duration(milliseconds: 400);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve linearCurve = Curves.linear;

  static const Map<String, dynamic> pageTransitionConfig = {
    'duration': Duration(milliseconds: 400),
    'curve': Curves.easeInOut,
  };
}

class AppIcons {
  AppIcons._();

  static const String edit = 'assets/icons/edit.svg';
  static const String ai = 'assets/icons/ai.svg';
  static const String video = 'assets/icons/video.svg';
  static const String gallery = 'assets/icons/gallery.svg';
  static const String settings = 'assets/icons/settings.svg';
  static const String profile = 'assets/icons/profile.svg';
}

class AppStrings {
  AppStrings._();

  static const String appName = 'AI Image Studio';
  static const String tagline = 'Create amazing content with AI';
  static const String noImage = 'No Image Selected';
  static const String noImageHint = 'Choose an image to start editing';
  static const String processing = 'Processing...';
  static const String success = 'Success!';
  static const String error = 'Something went wrong';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String share = 'Share';
  static const String download = 'Download';
  static const String export = 'Export';
  static const String generate = 'Generate';
  static const String enhance = 'Enhance';
  static const String transform = 'Transform';
  static const String detect = 'Detect';
  static const String analyze = 'Analyze';
}
