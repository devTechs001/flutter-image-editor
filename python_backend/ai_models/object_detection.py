import os
import cv2
import numpy as np


class ObjectDetector:
    def __init__(self):
        self.model = None
        self.names = {}
        self._load_model()

    def _load_model(self):
        """Load YOLOv8 model"""
        try:
            from ultralytics import YOLO
            model_path = 'yolov8n.pt'
            if not os.path.exists(model_path):
                print(f"Downloading YOLOv8 model to {model_path}...")
            self.model = YOLO(model_path)
            self.names = self.model.names
            print(f"YOLOv8 model loaded with {len(self.names)} classes")
        except ImportError:
            print("ultralytics not installed, using OpenCV DNN fallback")
            self._load_opencv_model()

    def _load_opencv_model(self):
        """Fallback: load YOLO using OpenCV DNN"""
        weights = 'yolov4.weights'
        config = 'yolov4.cfg'
        names_file = 'coco.names'

        if all(os.path.exists(f) for f in [weights, config, names_file]):
            self.model = cv2.dnn.readNet(weights, config)
            with open(names_file, 'r') as f:
                self.names = {i: name.strip() for i, name in enumerate(f)}
        else:
            print("No YOLO model files found. Using simple contour detection.")
            self.model = 'contour'

    def detect(self, image_path, confidence=0.5):
        """Detect objects in image"""
        if self.model is None:
            return self._contour_detection(image_path)

        try:
            return self._yolo_detect(image_path, confidence)
        except Exception:
            return self._contour_detection(image_path)

    def _yolo_detect(self, image_path, confidence=0.5):
        """Detect objects using YOLO"""
        results = self.model(image_path, conf=confidence, verbose=False)

        detected_objects = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                class_id = int(box.cls[0])
                obj = {
                    'class': self.names.get(class_id, f'class_{class_id}'),
                    'confidence': float(box.conf[0]),
                    'bbox': box.xyxy[0].tolist(),
                    'center': [
                        float((box.xyxy[0][0] + box.xyxy[0][2]) / 2),
                        float((box.xyxy[0][1] + box.xyxy[0][3]) / 2)
                    ]
                }
                detected_objects.append(obj)

        return detected_objects

    def _contour_detection(self, image_path):
        """Simple contour-based object detection fallback"""
        img = cv2.imread(image_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        blur = cv2.GaussianBlur(gray, (5, 5), 0)
        _, thresh = cv2.threshold(blur, 60, 255, cv2.THRESH_BINARY)
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL,
                                       cv2.CHAIN_APPROX_SIMPLE)

        objects = []
        for contour in contours:
            area = cv2.contourArea(contour)
            if area > 1000:
                x, y, w, h = cv2.boundingRect(contour)
                objects.append({
                    'class': 'object',
                    'confidence': min(1.0, area / 100000),
                    'bbox': [float(x), float(y), float(x + w), float(y + h)],
                    'center': [float(x + w / 2), float(y + h / 2)]
                })

        return objects

    def detect_and_annotate(self, image_path, output_path=None):
        """Detect objects and draw bounding boxes"""
        if output_path is None:
            output_dir = os.path.join(
                os.path.dirname(os.path.dirname(__file__)), 'outputs'
            )
            os.makedirs(output_dir, exist_ok=True)
            output_path = os.path.join(
                output_dir,
                f"annotated_{os.path.basename(image_path)}"
            )

        if self.model and hasattr(self.model, '__call__'):
            results = self.model(image_path)
            annotated = results[0].plot()
            cv2.imwrite(output_path, annotated)
        else:
            img = cv2.imread(image_path)
            objects = self._contour_detection(image_path)
            for obj in objects:
                bbox = obj['bbox']
                cv2.rectangle(img,
                              (int(bbox[0]), int(bbox[1])),
                              (int(bbox[2]), int(bbox[3])),
                              (0, 255, 0), 2)
                cv2.putText(img,
                            f"{obj['class']}: {obj['confidence']:.2f}",
                            (int(bbox[0]), int(bbox[1]) - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
            cv2.imwrite(output_path, img)

        return output_path
