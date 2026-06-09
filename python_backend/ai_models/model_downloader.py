#!/usr/bin/env python3
"""
AI Model Downloader & Manager
Downloads and manages ML models for the AI Image Editor backend.
"""

import os
import sys
import json
import hashlib
import requests
from pathlib import Path
from tqdm import tqdm
import concurrent.futures

MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'models')
os.makedirs(MODELS_DIR, exist_ok=True)

MODELS = {
    'yolov8n': {
        'url': 'https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.pt',
        'path': 'yolov8n.pt',
        'description': 'YOLOv8 nano object detection',
        'size_mb': 6.3,
    },
    'yolov8s': {
        'url': 'https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s.pt',
        'path': 'yolov8s.pt',
        'description': 'YOLOv8 small object detection',
        'size_mb': 22.5,
    },
    'esrgan': {
        'url': 'https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth',
        'path': 'RealESRGAN_x4plus.pth',
        'description': 'Real-ESRGAN super resolution',
        'size_mb': 67.0,
    },
    'colorization': {
        'url': 'http://eecs.berkeley.edu/~rich.zhang/projects/2016_colorization/files/demo_v2/colorization_release_v2.caffemodel',  # noqa
        'path': 'colorization_release_v2.caffemodel',
        'description': 'Image colorization model',
        'size_mb': 128.0,
    },
    'face_detection': {
        'url': 'https://github.com/opencv/opencv_3rdparty/raw/dnn_samples_face_detector_20170830/res10_300x300_ssd_iter_140000_fp16.caffemodel',  # noqa
        'path': 'face_detection.caffemodel',
        'description': 'OpenCV face detection model',
        'size_mb': 1.8,
    },
}


def get_model_status():
    """Check which models are downloaded"""
    status = {}
    for name, info in MODELS.items():
        model_path = os.path.join(MODELS_DIR, info['path'])
        exists = os.path.exists(model_path)
        size = os.path.getsize(model_path) if exists else 0
        status[name] = {
            'downloaded': exists,
            'size_mb': round(size / (1024 * 1024), 2),
            'expected_mb': info['size_mb'],
            'description': info['description'],
        }
    return status


def download_model(name, force=False):
    """Download a single model"""
    if name not in MODELS:
        print(f"❌ Unknown model: {name}")
        return False

    info = MODELS[name]
    model_path = os.path.join(MODELS_DIR, info['path'])

    if os.path.exists(model_path) and not force:
        size = os.path.getsize(model_path) / (1024 * 1024)
        print(f"✓ {name} already exists ({size:.1f} MB)")
        return True

    print(f"↓ Downloading {name} ({info['description']})...")
    print(f"  Size: {info['size_mb']} MB")
    print(f"  URL: {info['url']}")

    try:
        response = requests.get(info['url'], stream=True, timeout=30)
        response.raise_for_status()

        total_size = int(response.headers.get('content-length', 0))
        block_size = 8192

        with open(model_path, 'wb') as f:
            with tqdm(total=total_size, unit='B', unit_scale=True,
                      desc=name, ncols=80) as pbar:
                for chunk in response.iter_content(chunk_size=block_size):
                    f.write(chunk)
                    pbar.update(len(chunk))

        actual_size = os.path.getsize(model_path)
        print(f"✓ Downloaded {name} ({actual_size / (1024*1024):.1f} MB)")
        return True

    except requests.exceptions.RequestException as e:
        print(f"✗ Download failed: {e}")
        if os.path.exists(model_path):
            os.remove(model_path)
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def download_all(force=False, parallel=True):
    """Download all models"""
    print(f"{'='*60}")
    print(f"  AI Model Downloader")
    print(f"{'='*60}")
    print(f"  Models directory: {MODELS_DIR}")
    print(f"  Total models: {len(MODELS)}")
    print(f"{'='*60}\n")

    results = {}
    if parallel:
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            future_to_model = {
                executor.submit(download_model, name, force): name
                for name in MODELS
            }
            for future in concurrent.futures.as_completed(future_to_model):
                name = future_to_model[future]
                try:
                    results[name] = future.result()
                except Exception as e:
                    print(f"✗ {name} failed: {e}")
                    results[name] = False
    else:
        for name in MODELS:
            results[name] = download_model(name, force)

    print(f"\n{'='*60}")
    print(f"  Download Summary")
    print(f"{'='*60}")
    success = sum(1 for v in results.values() if v)
    total = len(results)
    print(f"  Successful: {success}/{total}")

    total_size = sum(
        os.path.getsize(os.path.join(MODELS_DIR, MODELS[n]['path']))
        for n in MODELS
        if os.path.exists(os.path.join(MODELS_DIR, MODELS[n]['path']))
    )
    print(f"  Total size: {total_size / (1024*1024*1024):.2f} GB")
    print(f"{'='*60}")

    return all(results.values())


def delete_model(name):
    """Delete a downloaded model"""
    if name not in MODELS:
        print(f"❌ Unknown model: {name}")
        return False

    model_path = os.path.join(MODELS_DIR, MODELS[name]['path'])
    if os.path.exists(model_path):
        os.remove(model_path)
        print(f"🗑️ Deleted {name}")
        return True
    else:
        print(f"⚠️ {name} not found")
        return False


def clear_all_models():
    """Delete all downloaded models"""
    confirm = input("Delete ALL downloaded models? (yes/no): ")
    if confirm.lower() == 'yes':
        count = 0
        for name in MODELS:
            if delete_model(name):
                count += 1
        print(f"Deleted {count} models")
    else:
        print("Cancelled")


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        description='AI Model Downloader & Manager'
    )
    parser.add_argument('action', nargs='?', default='status',
                        choices=['status', 'download', 'delete', 'clear'],
                        help='Action to perform')
    parser.add_argument('--model', '-m', help='Model name (for download/delete)')
    parser.add_argument('--force', '-f', action='store_true',
                        help='Force re-download')
    parser.add_argument('--sequential', action='store_true',
                        help='Download models sequentially')

    args = parser.parse_args()

    if args.action == 'status':
        status = get_model_status()
        print(f"\n{'='*60}")
        print(f"  Model Status")
        print(f"{'='*60}")
        for name, info in status.items():
            icon = '✓' if info['downloaded'] else '✗'
            print(f"  {icon} {name}: {'Downloaded' if info['downloaded'] else 'Missing'} "
                  f"({info['size_mb']:.1f}/{info['expected_mb']:.1f} MB) - {info['description']}")
        print(f"{'='*60}\n")

    elif args.action == 'download':
        if args.model:
            download_model(args.model, args.force)
        else:
            download_all(args.force, parallel=not args.sequential)

    elif args.action == 'delete':
        if args.model:
            delete_model(args.model)
        else:
            print("Please specify --model to delete")

    elif args.action == 'clear':
        clear_all_models()
