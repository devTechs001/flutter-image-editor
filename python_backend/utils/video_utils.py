import os
import cv2
import numpy as np
from PIL import Image


def get_video_info(video_path):
    """Get video metadata"""
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return None

    info = {
        'width': int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
        'height': int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)),
        'fps': cap.get(cv2.CAP_PROP_FPS),
        'frame_count': int(cap.get(cv2.CAP_PROP_FRAME_COUNT)),
        'duration': cap.get(cv2.CAP_PROP_FRAME_COUNT) / cap.get(cv2.CAP_PROP_FPS),
        'codec': int(cap.get(cv2.CAP_PROP_FOURCC)),
    }
    cap.release()
    return info


def extract_frames(video_path, output_dir, interval=1):
    """Extract frames from video at specified interval (seconds)"""
    os.makedirs(output_dir, exist_ok=True)
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_interval = int(fps * interval)

    frames = []
    count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if count % frame_interval == 0:
            frame_path = os.path.join(output_dir, f'frame_{count}.jpg')
            cv2.imwrite(frame_path, frame)
            frames.append(frame_path)
        count += 1

    cap.release()
    return frames


def create_thumbnail(video_path, output_path=None, time_sec=1):
    """Create thumbnail from video at specified time"""
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_pos = int(fps * time_sec)
    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_pos)
    ret, frame = cap.read()
    cap.release()

    if ret:
        if output_path is None:
            output_dir = os.path.dirname(video_path)
            output_path = os.path.join(
                output_dir,
                f"thumb_{os.path.basename(video_path)}.jpg"
            )
        cv2.imwrite(output_path, frame)
        return output_path
    return None


def concatenate_videos(video_paths, output_path):
    """Concatenate multiple videos"""
    if not video_paths:
        return None

    cap = cv2.VideoCapture(video_paths[0])
    fps = cap.get(cv2.CAP_PROP_FPS)
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    cap.release()

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

    for video_path in video_paths:
        cap = cv2.VideoCapture(video_path)
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            out.write(frame)
        cap.release()

    out.release()
    return output_path


def add_text_overlay(image, text, position=(50, 50),
                     font_scale=1, color=(255, 255, 255),
                     thickness=2):
    """Add text overlay to image"""
    font = cv2.FONT_HERSHEY_SIMPLEX
    return cv2.putText(image, text, position, font,
                       font_scale, color, thickness, cv2.LINE_AA)
