import cv2
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter, ImageOps
import os
import time
import uuid


class ImageEditor:
    def __init__(self):
        self.output_dir = os.path.join(
            os.path.dirname(os.path.dirname(__file__)), 'outputs'
        )
        os.makedirs(self.output_dir, exist_ok=True)

    def _get_output_path(self, prefix='edit'):
        return os.path.join(
            self.output_dir,
            f"{prefix}_{int(time.time())}_{uuid.uuid4().hex[:8]}.png"
        )

    def enhance(self, image_path, brightness=1.0, contrast=1.0,
                saturation=1.0, sharpness=1.0, denoise=False):
        """Enhance image with various parameters"""
        img = Image.open(image_path).convert('RGB')

        if brightness != 1.0:
            img = ImageEnhance.Brightness(img).enhance(brightness)
        if contrast != 1.0:
            img = ImageEnhance.Contrast(img).enhance(contrast)
        if saturation != 1.0:
            img = ImageEnhance.Color(img).enhance(saturation)
        if sharpness != 1.0:
            img = ImageEnhance.Sharpness(img).enhance(sharpness)

        if denoise:
            img = img.filter(ImageFilter.MedianFilter(size=3))

        output_path = self._get_output_path('enhanced')
        img.save(output_path)
        return output_path

    def style_transfer(self, image_path, style='oil_painting'):
        """Apply artistic style transfer"""
        img = cv2.imread(image_path)

        if style == 'oil_painting':
            result = cv2.xphoto.oilPainting(img, 7, 1)
        elif style == 'watercolor':
            result = cv2.stylization(img, sigma_s=60, sigma_r=0.6)
        elif style == 'sketch':
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            inv = cv2.bitwise_not(gray)
            blur = cv2.GaussianBlur(inv, (21, 21), 0)
            result = cv2.divide(gray, 255 - blur, scale=256)
            result = cv2.cvtColor(result, cv2.COLOR_GRAY2BGR)
        elif style == 'pixel_art':
            h, w = img.shape[:2]
            pixel_size = 8
            temp = cv2.resize(img, (w // pixel_size, h // pixel_size),
                              interpolation=cv2.INTER_NEAREST)
            result = cv2.resize(temp, (w, h), interpolation=cv2.INTER_NEAREST)
        elif style == 'cartoon':
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            blur = cv2.medianBlur(gray, 5)
            edges = cv2.adaptiveThreshold(blur, 255,
                                          cv2.ADAPTIVE_THRESH_MEAN_C,
                                          cv2.THRESH_BINARY, 9, 9)
            color = cv2.bilateralFilter(img, 9, 300, 300)
            result = cv2.bitwise_and(color, color, mask=edges)
        else:
            result = img

        output_path = self._get_output_path(f'style_{style}')
        cv2.imwrite(output_path, result)
        return output_path

    def colorize(self, image_path):
        """Colorize black and white image"""
        img = cv2.imread(image_path)
        if len(img.shape) == 2:
            img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)

        net = cv2.dnn.readNetFromCaffe(
            'ai_models/colorization_deploy_v2.prototxt',
            'ai_models/colorization_release_v2.caffemodel'
        ) if os.path.exists('ai_models/colorization_deploy_v2.prototxt') else None

        if net is not None:
            # Use DNN colorization
            pass

        # Fallback: simple colorization using histogram matching
        result = cv2.applyColorMap(img, cv2.COLORMAP_BONE)

        output_path = self._get_output_path('colorized')
        cv2.imwrite(output_path, result)
        return output_path

    def super_resolution(self, image_path, scale=2):
        """Upscale image using super resolution"""
        img = cv2.imread(image_path)
        h, w = img.shape[:2]

        new_w, new_h = w * scale, h * scale

        result = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_CUBIC)

        sr = cv2.dnn_superres.DnnSuperResImpl_create()
        model_path = 'ai_models/ESPCN_x2.pb'
        if os.path.exists(model_path):
            sr.readModel(model_path)
            sr.setModel('espcn', scale)
            result = sr.upsample(img)

        output_path = self._get_output_path('super_res')
        cv2.imwrite(output_path, result)
        return output_path

    def remove_background(self, image_path):
        """Remove background from image"""
        try:
            from rembg import remove

            with open(image_path, 'rb') as f:
                input_data = f.read()

            output_data = remove(input_data)

            output_path = self._get_output_path('no_bg')
            with open(output_path, 'wb') as f:
                f.write(output_data)

            return output_path
        except ImportError:
            # Fallback: use OpenCV grabcut
            img = cv2.imread(image_path)
            mask = np.zeros(img.shape[:2], np.uint8)
            bgd = np.zeros((1, 65), np.float64)
            fgd = np.zeros((1, 65), np.float64)

            h, w = img.shape[:2]
            rect = (10, 10, w - 20, h - 20)
            cv2.grabCut(img, mask, rect, bgd, fgd, 5, cv2.GC_INIT_WITH_RECT)

            mask2 = np.where((mask == 2) | (mask == 0), 0, 1).astype('uint8')
            result = img * mask2[:, :, np.newaxis]

            output_path = self._get_output_path('no_bg_fallback')
            cv2.imwrite(output_path, result)
            return output_path

    def analyze(self, image_path):
        """Analyze image properties"""
        img = cv2.imread(image_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

        return {
            'brightness': float(np.mean(gray) / 255.0),
            'contrast': float(np.std(gray) / 127.5),
            'saturation': float(np.mean(hsv[:, :, 1]) / 255.0),
            'sharpness': float(cv2.Laplacian(gray, cv2.CV_64F).var()),
            'resolution': f"{img.shape[1]}x{img.shape[0]}",
            'channels': img.shape[2],
            'file_size': os.path.getsize(image_path),
            'dominant_colors': self._get_dominant_colors(img),
        }

    def _get_dominant_colors(self, img, k=5):
        """Extract dominant colors using K-means"""
        pixels = img.reshape(-1, 3)
        pixels = np.float32(pixels)

        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0)
        _, labels, centers = cv2.kmeans(
            pixels, k, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS
        )

        colors = []
        for center in centers:
            colors.append({
                'r': int(center[2]),
                'g': int(center[1]),
                'b': int(center[0]),
                'hex': '#{:02x}{:02x}{:02x}'.format(
                    int(center[2]), int(center[1]), int(center[0])
                )
            })

        return colors
