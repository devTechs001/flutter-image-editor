import os
import json


class ImageCaptioner:
    def __init__(self):
        self.model = None
        self.feature_extractor = None
        self.tokenizer = None
        self._load_model()

    def _load_model(self):
        """Load image captioning model"""
        try:
            from transformers import (
                VisionEncoderDecoderModel,
                ViTImageProcessor,
                AutoTokenizer,
            )
            import torch

            model_name = "nlpconnect/vit-gpt2-image-captioning"
            self.model = VisionEncoderDecoderModel.from_pretrained(model_name)
            self.feature_extractor = ViTImageProcessor.from_pretrained(model_name)
            self.tokenizer = AutoTokenizer.from_pretrained(model_name)

            self.device = "cuda" if torch.cuda.is_available() else "cpu"
            self.model.to(self.device)
            self.model.eval()

            print(f"Image captioning model loaded on {self.device}")

        except ImportError:
            print("transformers not available, using keyword-based captioning")
            self.model = 'keyword'
        except Exception as e:
            print(f"Could not load captioning model: {e}")
            self.model = 'keyword'

    def caption(self, image_path, max_length=50, num_beams=4):
        """Generate caption for image"""
        if self.model is None:
            return "Image captioning not available"

        try:
            if hasattr(self.model, 'generate'):
                return self._transformers_caption(image_path, max_length, num_beams)
            else:
                return self._keyword_caption(image_path)
        except Exception as e:
            return f"Captioning error: {e}"

    def _transformers_caption(self, image_path, max_length, num_beams):
        """Generate caption using transformer model"""
        from PIL import Image
        import torch

        image = Image.open(image_path).convert('RGB')
        pixel_values = self.feature_extractor(
            images=image, return_tensors="pt"
        ).pixel_values.to(self.device)

        with torch.no_grad():
            output_ids = self.model.generate(
                pixel_values,
                max_length=max_length,
                num_beams=num_beams,
                no_repeat_ngram_size=2,
                early_stopping=True,
            )

        caption = self.tokenizer.decode(output_ids[0], skip_special_tokens=True)
        return caption

    def _keyword_caption(self, image_path):
        """Generate simple keyword-based caption"""
        import cv2
        import numpy as np

        img = cv2.imread(image_path)
        if img is None:
            return "Could not read image"

        h, w = img.shape[:2]
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        keywords = []

        # Analyze image properties
        avg_brightness = np.mean(gray)
        if avg_brightness > 200:
            keywords.append('bright')
        elif avg_brightness < 50:
            keywords.append('dark')

        # Detect if it's a portrait or landscape
        if w > h:
            keywords.append('landscape')
        elif h > w:
            keywords.append('portrait')
        else:
            keywords.append('square')

        # Analyze colorfulness
        color_std = np.std(img, axis=(0, 1))
        if np.mean(color_std) > 50:
            keywords.append('colorful')
        else:
            keywords.append('monochrome')

        # Edge detection for complexity
        edges = cv2.Canny(gray, 100, 200)
        edge_ratio = np.sum(edges > 0) / (h * w)
        if edge_ratio > 0.1:
            keywords.append('detailed')
        elif edge_ratio < 0.01:
            keywords.append('simple')

        # Detect faces
        face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )
        faces = face_cascade.detectMultiScale(gray, 1.1, 5)
        if len(faces) > 0:
            if len(faces) == 1:
                keywords.append('person')
            else:
                keywords.append(f'{len(faces)} people')

        # Text detection (simple)
        sobel = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        text_confidence = np.mean(np.abs(sobel))
        if text_confidence > 80:
            keywords.append('text')

        if not keywords:
            keywords.append('image')

        return f"A {' '.join(keywords)} photo"

    def caption_batch(self, image_paths):
        """Generate captions for multiple images"""
        return [self.caption(path) for path in image_paths]
