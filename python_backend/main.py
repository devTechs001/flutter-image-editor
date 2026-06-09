import os
import io
import base64
import json
import time
import uuid
from datetime import datetime
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.utils import secure_filename
from PIL import Image

from ai_models.image_editor import ImageEditor
from ai_models.object_detection import ObjectDetector
from ai_models.text_recognition import TextRecognizer
from ai_models.video_generator import VideoGenerator
from ai_models.stable_diffusion import StableDiffusionGenerator

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

image_editor = ImageEditor()
detector = ObjectDetector()
ocr = TextRecognizer()
video_gen = VideoGenerator()
image_gen = StableDiffusionGenerator()

UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
OUTPUT_FOLDER = os.path.join(os.path.dirname(__file__), 'outputs')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['OUTPUT_FOLDER'] = OUTPUT_FOLDER


def save_uploaded_file(file):
    filename = secure_filename(f"{uuid.uuid4().hex}_{file.filename}")
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)
    return filepath


def image_to_base64(image_path):
    with open(image_path, 'rb') as f:
        return base64.b64encode(f.read()).decode()


def get_output_path(prefix='output', ext='png'):
    filename = f"{prefix}_{int(time.time())}_{uuid.uuid4().hex[:8]}.{ext}"
    return os.path.join(OUTPUT_FOLDER, filename)


@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'models': {
            'image_editor': True,
            'object_detection': True,
            'ocr': True,
            'video_generator': True,
            'stable_diffusion': True,
        }
    })


@app.route('/api/process-image', methods=['POST'])
def process_image():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided', 'success': False}), 400

        image_file = request.files['image']
        action = request.form.get('action', 'enhance')
        params = request.form.get('parameters', '{}')

        if isinstance(params, str):
            params = json.loads(params)

        image_path = save_uploaded_file(image_file)

        if action == 'enhance':
            result = image_editor.enhance(image_path, **params)
        elif action == 'style_transfer':
            style = params.get('style', 'oil_painting')
            result = image_editor.style_transfer(image_path, style)
        elif action == 'colorize':
            result = image_editor.colorize(image_path)
        elif action == 'super_resolution':
            scale = params.get('scale', 2)
            result = image_editor.super_resolution(image_path, scale=scale)
        else:
            result = image_path

        img_base64 = image_to_base64(result)
        return jsonify({
            'image': img_base64,
            'image_url': result,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/detect-objects', methods=['POST'])
def detect_objects():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided', 'success': False}), 400

        image_file = request.files['image']
        image_path = save_uploaded_file(image_file)

        objects = detector.detect(image_path)

        return jsonify({
            'objects': objects,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/recognize-text', methods=['POST'])
def recognize_text():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided', 'success': False}), 400

        image_file = request.files['image']
        image_path = save_uploaded_file(image_file)

        extracted_text = ocr.extract(image_path)

        return jsonify({
            'text': extracted_text,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/generate-image', methods=['POST'])
def generate_image():
    try:
        data = request.get_json()
        if not data or 'prompt' not in data:
            return jsonify({'error': 'No prompt provided', 'success': False}), 400

        prompt = data['prompt']
        style = data.get('style', 'realistic')
        negative_prompt = data.get('negative_prompt', 'ugly, blurry, low quality')

        image_path = image_gen.generate(
            prompt,
            style=style,
            negative_prompt=negative_prompt
        )

        img_base64 = image_to_base64(image_path)

        return jsonify({
            'image_url': image_path,
            'image': img_base64,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/generate-video', methods=['POST'])
def generate_video():
    try:
        data = request.get_json()
        if not data or 'prompt' not in data:
            return jsonify({'error': 'No prompt provided', 'success': False}), 400

        prompt = data['prompt']
        duration = data.get('duration', 5)
        aspect_ratio = data.get('aspect_ratio', '16:9')

        video_path = video_gen.generate_from_prompt(
            prompt,
            duration=duration,
            aspect_ratio=aspect_ratio
        )

        return jsonify({
            'video_url': video_path,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/remove-bg', methods=['POST'])
def remove_background():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided', 'success': False}), 400

        image_file = request.files['image']
        image_path = save_uploaded_file(image_file)

        result_path = image_editor.remove_background(image_path)
        img_base64 = image_to_base64(result_path)

        return jsonify({
            'image_url': result_path,
            'image': img_base64,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/img2img', methods=['POST'])
def img2img():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided', 'success': False}), 400

        image_file = request.files['image']
        prompt = request.form.get('prompt', '')
        strength = float(request.form.get('strength', 0.75))

        if not prompt:
            return jsonify({'error': 'No prompt provided', 'success': False}), 400

        image_path = save_uploaded_file(image_file)

        result_path = image_gen.img2img(
            image_path,
            prompt,
            strength=strength
        )

        img_base64 = image_to_base64(result_path)

        return jsonify({
            'image_url': result_path,
            'image': img_base64,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/create-slideshow', methods=['POST'])
def create_slideshow():
    try:
        images = request.files.getlist('images')
        transitions = request.form.get('transitions', 'true').lower() == 'true'
        music = request.files.get('music')

        if not images:
            return jsonify({'error': 'No images provided', 'success': False}), 400

        image_paths = []
        for img in images:
            path = save_uploaded_file(img)
            image_paths.append(path)

        music_path = None
        if music:
            music_path = save_uploaded_file(music)

        video_path = video_gen.create_from_images(
            image_paths,
            transitions=transitions,
            music_path=music_path
        )

        return jsonify({
            'video_url': video_path,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/analyze', methods=['POST'])
def analyze_image():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided', 'success': False}), 400

        image_file = request.files['image']
        image_path = save_uploaded_file(image_file)

        objects = detector.detect(image_path)
        text = ocr.extract(image_path)
        analysis = image_editor.analyze(image_path)

        return jsonify({
            'objects': objects,
            'text': text,
            'analysis': analysis,
            'success': True
        })

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@app.route('/api/download/<filename>', methods=['GET'])
def download_file(filename):
    filepath = os.path.join(OUTPUT_FOLDER, secure_filename(filename))
    if os.path.exists(filepath):
        return send_file(filepath, as_attachment=True)
    return jsonify({'error': 'File not found', 'success': False}), 404


@app.errorhandler(413)
def too_large(e):
    return jsonify({'error': 'File too large', 'success': False}), 413


@app.errorhandler(500)
def server_error(e):
    return jsonify({'error': 'Internal server error', 'success': False}), 500


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV', 'production') == 'development'

    print(f"AI Image Editor Backend starting on port {port}")
    print(f"Upload folder: {UPLOAD_FOLDER}")
    print(f"Output folder: {OUTPUT_FOLDER}")
    print(f"Debug mode: {debug}")

    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug,
        threaded=True
    )
