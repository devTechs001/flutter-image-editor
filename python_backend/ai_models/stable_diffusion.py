import os
import time
import uuid


class StableDiffusionGenerator:
    def __init__(self):
        self.device = "cpu"
        self.pipe = None
        self.img2img_pipe = None
        self.output_dir = os.path.join(
            os.path.dirname(os.path.dirname(__file__)), 'outputs'
        )
        os.makedirs(self.output_dir, exist_ok=True)
        self._load_models()

    def _load_models(self):
        """Load Stable Diffusion models"""
        try:
            import torch
            from diffusers import (StableDiffusionPipeline,
                                   StableDiffusionImg2ImgPipeline)

            self.device = "cuda" if torch.cuda.is_available() else "cpu"
            print(f"Using device: {self.device}")

            model_id = "runwayml/stable-diffusion-v1-5"
            dtype = torch.float16 if self.device == "cuda" else torch.float32

            self.pipe = StableDiffusionPipeline.from_pretrained(
                model_id, torch_dtype=dtype
            ).to(self.device)

            self.img2img_pipe = StableDiffusionImg2ImgPipeline.from_pretrained(
                model_id, torch_dtype=dtype
            ).to(self.device)

            print("Stable Diffusion models loaded successfully")
        except ImportError:
            print("diffusers not installed. Using simulated generation.")
        except Exception as e:
            print(f"Could not load Stable Diffusion: {e}")
            print("Using simulated image generation")

    def _get_output_path(self, prefix='gen'):
        return os.path.join(
            self.output_dir,
            f"{prefix}_{int(time.time())}_{uuid.uuid4().hex[:8]}.png"
        )

    def generate(self, prompt, style='realistic',
                 negative_prompt='ugly, blurry, low quality',
                 target_size=(512, 512)):
        """Generate image from text prompt"""
        if self.pipe is not None:
            try:
                style_modifiers = {
                    'realistic': 'photorealistic, 8k, highly detailed, sharp focus',
                    'anime': 'anime style, studio ghibli, anime artwork',
                    'cinematic': 'cinematic lighting, movie poster, dramatic',
                    'painting': 'oil painting, artistic, canvas texture',
                    'fantasy': 'fantasy art, magical, ethereal, detailed',
                    'cyberpunk': 'cyberpunk, neon, futuristic, sci-fi',
                    'watercolor': 'watercolor painting, soft, artistic',
                }

                full_prompt = prompt
                if style in style_modifiers:
                    full_prompt = f"{prompt}, {style_modifiers[style]}"

                import torch
                with torch.autocast(self.device):
                    image = self.pipe(
                        full_prompt,
                        negative_prompt=negative_prompt,
                        num_inference_steps=30,
                        guidance_scale=7.5,
                        height=target_size[1],
                        width=target_size[0],
                    ).images[0]

                output_path = self._get_output_path(f'gen_{style}')
                image.save(output_path)
                return output_path

            except Exception as e:
                print(f"SD generation error: {e}")
                return self._simulate_generation(prompt, target_size)

        return self._simulate_generation(prompt, target_size)

    def img2img(self, init_image_path, prompt, strength=0.75):
        """Transform existing image based on prompt"""
        if self.img2img_pipe is not None:
            try:
                from PIL import Image
                import torch

                init_image = Image.open(init_image_path).convert('RGB')

                with torch.autocast(self.device):
                    image = self.img2img_pipe(
                        prompt=prompt,
                        image=init_image,
                        strength=strength,
                        guidance_scale=7.5,
                        num_inference_steps=30,
                    ).images[0]

                output_path = self._get_output_path('transformed')
                image.save(output_path)
                return output_path

            except Exception as e:
                print(f"Img2Img error: {e}")

        # Fallback: copy original
        output_path = self._get_output_path('transformed')
        import shutil
        shutil.copy(init_image_path, output_path)
        return output_path

    def _simulate_generation(self, prompt, target_size=(512, 512)):
        """Generate a simulated image when SD is not available"""
        from PIL import Image, ImageDraw, ImageFont
        import random

        img = Image.new('RGB', target_size,
                        color=(random.randint(20, 60),
                               random.randint(20, 60),
                               random.randint(40, 80)))

        draw = ImageDraw.Draw(img)

        # Draw some random shapes
        for _ in range(random.randint(3, 8)):
            x = random.randint(0, target_size[0])
            y = random.randint(0, target_size[1])
            r = random.randint(20, 100)
            color = (random.randint(100, 255),
                     random.randint(100, 255),
                     random.randint(100, 255))
            draw.ellipse([x - r, y - r, x + r, y + r],
                         fill=color, outline=None)

        # Add prompt text
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)  # noqa
        except Exception:
            font = ImageFont.load_default()

        # Word wrap the prompt
        words = prompt.split()
        lines = []
        current_line = ""
        for word in words:
            test_line = f"{current_line} {word}".strip()
            bbox = draw.textbbox((0, 0), test_line, font=font)
            if bbox[2] - bbox[0] > target_size[0] - 40:
                lines.append(current_line)
                current_line = word
            else:
                current_line = test_line
        if current_line:
            lines.append(current_line)

        y_offset = target_size[1] - 40 - len(lines) * 25
        for line in lines:
            bbox = draw.textbbox((0, 0), line, font=font)
            text_width = bbox[2] - bbox[0]
            draw.text(
                ((target_size[0] - text_width) / 2, y_offset),
                line,
                fill='white',
                font=font
            )
            y_offset += 25

        output_path = self._get_output_path('simulated')
        img.save(output_path)
        return output_path
