import os
import time
import uuid
import numpy as np
from PIL import Image


class VideoGenerator:
    def __init__(self):
        self.temp_dir = os.path.join(
            os.path.dirname(os.path.dirname(__file__)), 'temp_video'
        )
        self.output_dir = os.path.join(
            os.path.dirname(os.path.dirname(__file__)), 'outputs'
        )
        os.makedirs(self.temp_dir, exist_ok=True)
        os.makedirs(self.output_dir, exist_ok=True)
        self._init_ffmpeg()

    def _init_ffmpeg(self):
        """Initialize moviepy with FFmpeg"""
        try:
            import imageio
            imageio.plugins.ffmpeg.download()
        except Exception:
            pass

    def _get_output_path(self, prefix='video'):
        return os.path.join(
            self.output_dir,
            f"{prefix}_{int(time.time())}_{uuid.uuid4().hex[:8]}.mp4"
        )

    def generate_from_prompt(self, prompt, duration=5, aspect_ratio='16:9'):
        """Generate video from text prompt using AI-generated frames"""
        from .stable_diffusion import StableDiffusionGenerator
        sd_gen = StableDiffusionGenerator()

        frames = []
        fps = 24
        num_frames = duration * fps

        # Calculate aspect ratio dimensions
        if aspect_ratio == '16:9':
            target_size = (1024, 576)
        elif aspect_ratio == '9:16':
            target_size = (576, 1024)
        elif aspect_ratio == '1:1':
            target_size = (768, 768)
        elif aspect_ratio == '4:3':
            target_size = (1024, 768)
        elif aspect_ratio == '21:9':
            target_size = (1024, 438)
        else:
            target_size = (768, 768)

        # Generate keyframes (1 per second for speed, interpolate rest)
        keyframes = []
        for i in range(duration):
            time_prompt = f"{prompt}, frame {i+1} of {duration}"
            try:
                img_path = sd_gen.generate(
                    time_prompt,
                    style='cinematic',
                    target_size=target_size
                )
                keyframes.append(Image.open(img_path).convert('RGB'))
            except Exception:
                # Create placeholder frame
                frame = Image.new('RGB', target_size,
                                  color=(50 + i * 20, 50, 100))
                keyframes.append(frame)

        # Interpolate between keyframes
        if len(keyframes) > 1:
            frames_per_segment = num_frames // (len(keyframes) - 1)
            for i in range(len(keyframes) - 1):
                for j in range(frames_per_segment):
                    alpha = j / frames_per_segment
                    interpolated = Image.blend(keyframes[i], keyframes[i + 1],
                                               alpha)
                    frames.append(np.array(interpolated))
        elif keyframes:
            for _ in range(num_frames):
                frames.append(np.array(keyframes[0]))

        # Ensure we have exactly num_frames
        while len(frames) < num_frames:
            frames.append(frames[-1] if frames else np.zeros((*target_size, 3),
                                                             dtype=np.uint8))
        frames = frames[:num_frames]

        # Create video
        output_path = self._get_output_path('ai_video')
        self._create_video(frames, output_path, fps)
        return output_path

    def create_from_images(self, image_paths, transitions=True, music_path=None):
        """Create video from multiple images with transitions"""
        try:
            from moviepy.editor import (ImageClip, concatenate_videoclips,
                                        AudioFileClip, CompositeVideoClip)

            clips = []
            for img_path in image_paths:
                clip = ImageClip(img_path, duration=3)
                if transitions:
                    clip = clip.crossfadeout(0.5)
                clips.append(clip)

            if clips:
                final = concatenate_videoclips(clips, method="compose")

                if music_path and os.path.exists(music_path):
                    try:
                        audio = AudioFileClip(music_path)
                        final = final.set_audio(audio)
                    except Exception:
                        pass

                output_path = self._get_output_path('slideshow')
                final.write_videofile(
                    output_path,
                    codec='libx264',
                    audio_codec='aac',
                    fps=24,
                    preset='medium',
                    threads=2,
                    logger=None
                )
                return output_path
        except ImportError:
            return self._create_video_fallback(image_paths)

        return self._get_output_path('slideshow')

    def _create_video(self, frames, output_path, fps=24):
        """Create video from numpy array frames"""
        try:
            from moviepy.editor import ImageSequenceClip
            clip = ImageSequenceClip(frames, fps=fps)
            clip.write_videofile(
                output_path,
                codec='libx264',
                fps=fps,
                preset='medium',
                threads=2,
                logger=None
            )
        except ImportError:
            self._create_video_cv2(frames, output_path, fps)

    def _create_video_cv2(self, frames, output_path, fps=24):
        """Create video using OpenCV"""
        import cv2

        if not frames:
            return

        h, w = frames[0].shape[:2]
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

        for frame in frames:
            frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
            out.write(frame_bgr)

        out.release()

    def _create_video_fallback(self, image_paths):
        """Fallback video creation using OpenCV"""
        import cv2

        if not image_paths:
            return None

        first_img = cv2.imread(image_paths[0])
        h, w = first_img.shape[:2]
        fps = 24

        output_path = self._get_output_path('slideshow_fallback')
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(output_path, fourcc, fps, (w, h))

        for img_path in image_paths:
            img = cv2.imread(img_path)
            if img is not None:
                img = cv2.resize(img, (w, h))
                for _ in range(fps * 3):  # 3 seconds per image
                    out.write(img)

        out.release()
        return output_path
