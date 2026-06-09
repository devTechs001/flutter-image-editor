# AI Image Studio

A comprehensive Flutter application combining **AI-powered image editing**, **text/image recognition**, and **video generation from prompts**. Uses a Python backend for heavy AI processing while Flutter handles the UI.

## Features

### 🎨 Image Editing
- AI enhancement (brightness, contrast, saturation, sharpness)
- Background removal (AI-powered)
- Style transfer (oil painting, watercolor, sketch, anime, etc.)
- Super resolution (upscale images)
- Image colorization (B&W to color)
- Object detection & labeling
- Text recognition (OCR)
- 12+ filter presets
- Manual adjustments (15 adjustment types)
- Drawing/annotation canvas
- Crop tool

### 🎬 Video Generation
- Text prompt to AI-generated video
- Image sequence to video (slideshow maker)
- Animated transitions
- Music/soundtrack support
- Multiple aspect ratios (16:9, 9:16, 1:1, 4:3, 21:9, 3:2)

### 🤖 AI Recognition
- Object detection & labeling (YOLOv8)
- Face detection & analysis (Google ML Kit)
- Text recognition (OCR via EasyOCR/Tesseract)
- Image captioning
- Scene understanding

### ✨ Modern UI
- Dark theme with Material 3
- Glassmorphism design
- Smooth animations (flutter_animate)
- Gradient accents
- Adaptive layouts
- Lottie animations

## Tech Stack

**Frontend:**
- Flutter (Dart) with Riverpod & Provider
- Google ML Kit for on-device AI
- PhotoView, video_player, lottie

**Backend:**
- Python Flask API
- YOLOv8 (Ultralytics) for object detection
- EasyOCR / Tesseract for text recognition
- Stable Diffusion (Diffusers) for image generation
- MoviePy / OpenCV for video processing
- rembg for background removal

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Python 3.10+
- CUDA-capable GPU (recommended for Stable Diffusion)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ai-image-studio.git
cd ai-image-studio
```

2. **Set up Python backend**
```bash
cd python_backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

3. **Set up Flutter app**
```bash
flutter pub get
flutter run -d linux  # Or android/ios
```

### Docker Deployment
```bash
docker-compose up --build
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── screens/                     # UI screens
│   ├── splash_screen.dart       # Animated splash
│   ├── home_screen.dart         # Main dashboard
│   ├── image_editor_screen.dart # Full image editor
│   ├── video_maker_screen.dart  # Video generator
│   ├── ai_recognition_screen.dart # AI analysis
│   └── gallery_screen.dart      # Image gallery
├── widgets/                     # Reusable widgets
├── providers/                   # State management
├── services/                    # API & file handling
├── models/                      # Data models
└── utils/                       # Constants & helpers

python_backend/
├── main.py                      # Flask API server
├── ai_models/                   # ML models
│   ├── image_editor.py          # Image processing
│   ├── object_detection.py      # YOLOv8 detection
│   ├── text_recognition.py      # OCR
│   ├── video_generator.py       # Video creation
│   └── stable_diffusion.py      # AI image gen
└── utils/                       # Backend utilities
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/process-image` | Apply image editing operations |
| POST | `/api/detect-objects` | Detect objects in image |
| POST | `/api/recognize-text` | Extract text from image |
| POST | `/api/generate-image` | Generate image from prompt |
| POST | `/api/generate-video` | Generate video from prompt |
| POST | `/api/remove-bg` | Remove image background |
| POST | `/api/img2img` | Transform image with prompt |
| POST | `/api/create-slideshow` | Create video from images |
| POST | `/api/analyze` | Full image analysis |

## License

MIT
# flutter-image-editor
