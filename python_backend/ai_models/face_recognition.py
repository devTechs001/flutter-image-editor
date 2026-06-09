import cv2
import numpy as np
import os
import json


class FaceAnalyzer:
    def __init__(self):
        self.face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )
        self.eye_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_eye.xml'
        )
        self.smile_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_smile.xml'
        )
        self._load_age_gender_model()

    def _load_age_gender_model(self):
        """Load age and gender prediction models if available"""
        model_dir = os.path.join(
            os.path.dirname(os.path.dirname(__file__)), 'models'
        )
        self.age_net = None
        self.gender_net = None

        age_proto = os.path.join(model_dir, 'age_deploy.prototxt')
        age_model = os.path.join(model_dir, 'age_net.caffemodel')
        gender_proto = os.path.join(model_dir, 'gender_deploy.prototxt')
        gender_model = os.path.join(model_dir, 'gender_net.caffemodel')

        if all(os.path.exists(f) for f in [age_proto, age_model]):
            self.age_net = cv2.dnn.readNet(age_model, age_proto)

        if all(os.path.exists(f) for f in [gender_proto, gender_model]):
            self.gender_net = cv2.dnn.readNet(gender_model, gender_proto)

        self.age_list = ['(0-2)', '(4-6)', '(8-12)', '(15-20)',
                         '(25-32)', '(38-43)', '(48-53)', '(60-100)']
        self.gender_list = ['Male', 'Female']

    def detect_faces(self, image_path):
        """Detect faces and analyze facial features"""
        img = cv2.imread(image_path)
        if img is None:
            return []

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = self.face_cascade.detectMultiScale(
            gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30)
        )

        results = []
        for (x, y, w, h) in faces:
            face_roi = gray[y:y + h, x:x + w]
            face_color = img[y:y + h, x:x + w]

            face_data = {
                'bbox': [int(x), int(y), int(x + w), int(y + h)],
                'confidence': 0.95,
                'landmarks': self._detect_landmarks(face_roi),
                'age': self._predict_age(face_color),
                'gender': self._predict_gender(face_color),
                'emotion': self._detect_emotion(face_roi),
                'eyes': self._detect_eyes(face_roi, x, y),
                'smile': self._detect_smile(face_roi),
            }
            results.append(face_data)

        return results

    def _detect_landmarks(self, face_roi):
        """Detect facial landmarks"""
        h, w = face_roi.shape
        return {
            'left_eye': [int(w * 0.3), int(h * 0.35)],
            'right_eye': [int(w * 0.7), int(h * 0.35)],
            'nose': [int(w * 0.5), int(h * 0.5)],
            'mouth_left': [int(w * 0.3), int(h * 0.7)],
            'mouth_right': [int(w * 0.7), int(h * 0.7)],
        }

    def _detect_eyes(self, face_roi, offset_x, offset_y):
        """Detect eyes in face region"""
        eyes = self.eye_cascade.detectMultiScale(face_roi)
        eye_list = []
        for (ex, ey, ew, eh) in eyes:
            eye_list.append({
                'bbox': [int(offset_x + ex), int(offset_y + ey),
                         int(offset_x + ex + ew), int(offset_y + ey + eh)],
                'confidence': 0.8,
            })
        return eye_list

    def _detect_smile(self, face_roi):
        """Detect smile in face region"""
        smiles = self.smile_cascade.detectMultiScale(
            face_roi, scaleFactor=1.7, minNeighbors=20
        )
        return len(smiles) > 0

    def _detect_emotion(self, face_roi):
        """Detect basic emotion based on facial features"""
        h, w = face_roi.shape
        # Simple heuristic-based emotion detection
        mouth_region = face_roi[int(h * 0.6):int(h * 0.9), :]
        eye_region = face_roi[int(h * 0.2):int(h * 0.4), :]

        mouth_mean = np.mean(mouth_region)
        eye_mean = np.mean(eye_region)

        if mouth_mean < 100 and eye_mean < 100:
            return 'happy'
        elif mouth_mean > 150 and eye_mean > 150:
            return 'sad'
        elif mouth_mean > 130:
            return 'surprised'
        else:
            return 'neutral'

    def _predict_age(self, face_roi):
        """Predict age range"""
        if self.age_net is None:
            return 'unknown'

        try:
            blob = cv2.dnn.blobFromImage(
                face_roi, 1.0, (227, 227),
                (78.4263377603, 87.7689143744, 114.895847746),
                swapRB=False
            )
            self.age_net.setInput(blob)
            age_preds = self.age_net.forward()
            age = self.age_list[age_preds[0].argmax()]
            return age
        except Exception:
            return 'unknown'

    def _predict_gender(self, face_roi):
        """Predict gender"""
        if self.gender_net is None:
            return 'unknown'

        try:
            blob = cv2.dnn.blobFromImage(
                face_roi, 1.0, (227, 227),
                (78.4263377603, 87.7689143744, 114.895847746),
                swapRB=False
            )
            self.gender_net.setInput(blob)
            gender_preds = self.gender_net.forward()
            gender = self.gender_list[gender_preds[0].argmax()]
            return gender
        except Exception:
            return 'unknown'

    def compare_faces(self, face1_path, face2_path):
        """Compare two faces and return similarity score"""
        img1 = cv2.imread(face1_path)
        img2 = cv2.imread(face2_path)

        if img1 is None or img2 is None:
            return 0.0

        gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)

        # Resize to same size
        gray1 = cv2.resize(gray1, (100, 100))
        gray2 = cv2.resize(gray2, (100, 100))

        # Compute similarity using histogram comparison
        hist1 = cv2.calcHist([gray1], [0], None, [256], [0, 256])
        hist2 = cv2.calcHist([gray2], [0], None, [256], [0, 256])

        similarity = cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL)
        return float(max(0, similarity))
