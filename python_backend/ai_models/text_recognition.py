import os


class TextRecognizer:
    def __init__(self):
        self.reader = None
        self._load_reader()

    def _load_reader(self):
        """Initialize EasyOCR reader"""
        try:
            import easyocr
            self.reader = easyocr.Reader(['en', 'ch_sim'], gpu=False)
            print("EasyOCR reader initialized")
        except ImportError:
            print("easyocr not installed, trying pytesseract...")
            self._load_tesseract()

    def _load_tesseract(self):
        """Fallback to pytesseract"""
        try:
            import pytesseract
            self.reader = 'tesseract'
            print("Using pytesseract for OCR")
        except ImportError:
            print("No OCR library available")
            self.reader = None

    def extract(self, image_path):
        """Extract text from image"""
        if self.reader is None:
            return "OCR not available"

        try:
            if hasattr(self.reader, 'readtext'):
                return self._extract_easyocr(image_path)
            else:
                return self._extract_tesseract(image_path)
        except Exception as e:
            return f"OCR error: {str(e)}"

    def _extract_easyocr(self, image_path):
        """Extract text using EasyOCR"""
        results = self.reader.readtext(image_path)

        extracted_text = []
        for bbox, text, confidence in results:
            extracted_text.append(text)

        return ' '.join(extracted_text)

    def _extract_tesseract(self, image_path):
        """Extract text using Tesseract"""
        import pytesseract
        from PIL import Image

        img = Image.open(image_path)
        text = pytesseract.image_to_string(img)
        return text.strip()

    def extract_with_positions(self, image_path):
        """Extract text with position information"""
        if self.reader is None:
            return []

        try:
            if hasattr(self.reader, 'readtext'):
                results = self.reader.readtext(image_path)
                extracted = []
                for bbox, text, confidence in results:
                    extracted.append({
                        'text': text,
                        'confidence': float(confidence),
                        'bbox': [list(point) for point in bbox]
                    })
                return extracted
            else:
                return []
        except Exception:
            return []
