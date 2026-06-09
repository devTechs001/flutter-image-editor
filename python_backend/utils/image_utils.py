import cv2
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
import io
import base64


def load_image(image_path):
    """Load image from path"""
    return cv2.imread(image_path)


def load_image_pil(image_path):
    """Load image using PIL"""
    return Image.open(image_path).convert('RGB')


def save_image(image, output_path):
    """Save image to path"""
    cv2.imwrite(output_path, image)


def resize_image(image, max_size=1024):
    """Resize image maintaining aspect ratio"""
    h, w = image.shape[:2]
    if max(h, w) > max_size:
        scale = max_size / max(h, w)
        new_w = int(w * scale)
        new_h = int(h * scale)
        return cv2.resize(image, (new_w, new_h))
    return image


def image_to_base64(image_path, format='png'):
    """Convert image file to base64 string"""
    with open(image_path, 'rb') as f:
        return base64.b64encode(f.read()).decode()


def base64_to_image(base64_string):
    """Convert base64 string to PIL Image"""
    img_data = base64.b64decode(base64_string)
    return Image.open(io.BytesIO(img_data))


def apply_filter(image, filter_type, params=None):
    """Apply various filters to image"""
    if params is None:
        params = {}

    if filter_type == 'blur':
        k = params.get('kernel_size', 5)
        return cv2.GaussianBlur(image, (k, k), 0)

    elif filter_type == 'sharpen':
        kernel = np.array([[-1, -1, -1],
                           [-1, 9, -1],
                           [-1, -1, -1]])
        return cv2.filter2D(image, -1, kernel)

    elif filter_type == 'edge_detect':
        return cv2.Canny(image, 100, 200)

    elif filter_type == 'sepia':
        kernel = np.array([[0.272, 0.534, 0.131],
                           [0.349, 0.686, 0.168],
                           [0.393, 0.769, 0.189]])
        return cv2.transform(image, kernel)

    elif filter_type == 'vignette':
        rows, cols = image.shape[:2]
        kernel_x = cv2.getGaussianKernel(cols, cols / 3)
        kernel_y = cv2.getGaussianKernel(rows, rows / 3)
        kernel = kernel_y * kernel_x.T
        mask = kernel / kernel.max()
        for i in range(3):
            image[:, :, i] = image[:, :, i] * mask
        return image

    return image


def adjust_brightness_contrast(image, brightness=0, contrast=0):
    """Adjust brightness and contrast"""
    img = np.int16(image)
    img = img * (contrast / 127 + 1) - contrast + brightness
    img = np.clip(img, 0, 255)
    return np.uint8(img)


def get_image_info(image_path):
    """Get image metadata"""
    img = cv2.imread(image_path)
    if img is None:
        return None

    h, w = img.shape[:2]
    return {
        'width': w,
        'height': h,
        'channels': img.shape[2] if len(img.shape) > 2 else 1,
        'aspect_ratio': round(w / h, 2),
        'file_size': os.path.getsize(image_path),
    }
