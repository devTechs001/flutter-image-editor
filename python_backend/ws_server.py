"""
WebSocket server for real-time AI processing communication.
Enables progress streaming and live updates between Flutter and Python.
"""

import asyncio
import json
import time
import uuid
import websockets
from ai_models.image_editor import ImageEditor
from ai_models.object_detection import ObjectDetector
from ai_models.text_recognition import TextRecognizer
from ai_models.stable_diffusion import StableDiffusionGenerator


class WebSocketHandler:
    def __init__(self):
        self.clients = set()
        self.tasks = {}
        self.image_editor = ImageEditor()
        self.detector = ObjectDetector()
        self.ocr = TextRecognizer()
        self.image_gen = StableDiffusionGenerator()

    async def register(self, websocket):
        self.clients.add(websocket)

    async def unregister(self, websocket):
        self.clients.discard(websocket)

    async def broadcast(self, message):
        if self.clients:
            await asyncio.gather(
                *[client.send(json.dumps(message)) for client in self.clients],
                return_exceptions=True,
            )

    async def send_progress(self, websocket, task_id, progress, status, data=None):
        message = {
            'type': 'progress',
            'task_id': task_id,
            'progress': progress,
            'status': status,
        }
        if data:
            message['data'] = data
        await websocket.send(json.dumps(message))

    async def handle_message(self, websocket, message):
        msg_type = message.get('type', '')

        if msg_type == 'ping':
            await websocket.send(json.dumps({
                'type': 'pong',
                'timestamp': time.time(),
            }))

        elif msg_type == 'process':
            task_id = message.get('task_id', str(uuid.uuid4()))
            action = message.get('action', '')
            image_path = message.get('image_path', '')
            parameters = message.get('parameters', {})

            self.tasks[task_id] = {'status': 'processing', 'progress': 0}
            await self._process_task(websocket, task_id, action, image_path, parameters)

        elif msg_type == 'subscribe':
            task_id = message.get('task_id', '')
            if task_id in self.tasks:
                await websocket.send(json.dumps({
                    'type': 'task_status',
                    'task_id': task_id,
                    'status': self.tasks[task_id],
                }))

    async def _process_task(self, websocket, task_id, action, image_path, parameters):
        try:
            await self.send_progress(websocket, task_id, 0.1, 'Starting...')

            if action == 'enhance':
                await self.send_progress(websocket, task_id, 0.3, 'Enhancing image...')
                result = self.image_editor.enhance(image_path, **parameters)

            elif action == 'style_transfer':
                await self.send_progress(websocket, task_id, 0.3, 'Applying style...')
                style = parameters.get('style', 'oil_painting')
                result = self.image_editor.style_transfer(image_path, style)

            elif action == 'remove_bg':
                await self.send_progress(websocket, task_id, 0.3, 'Removing background...')
                result = self.image_editor.remove_background(image_path)

            elif action == 'detect_objects':
                await self.send_progress(websocket, task_id, 0.3, 'Detecting objects...')
                objects = self.detector.detect(image_path)
                await self.send_progress(websocket, task_id, 1.0, 'Complete', {
                    'objects': objects,
                })
                self.tasks[task_id] = {'status': 'complete', 'progress': 1.0}
                return

            elif action == 'recognize_text':
                await self.send_progress(websocket, task_id, 0.3, 'Reading text...')
                text = self.ocr.extract(image_path)
                await self.send_progress(websocket, task_id, 1.0, 'Complete', {
                    'text': text,
                })
                self.tasks[task_id] = {'status': 'complete', 'progress': 1.0}
                return

            else:
                result = image_path

            await self.send_progress(websocket, task_id, 0.8, 'Finalizing...')

            import base64
            with open(result, 'rb') as f:
                img_base64 = base64.b64encode(f.read()).decode()

            await self.send_progress(websocket, task_id, 1.0, 'Complete', {
                'image': img_base64,
                'image_url': result,
            })
            self.tasks[task_id] = {'status': 'complete', 'progress': 1.0}

        except Exception as e:
            await self.send_progress(websocket, task_id, 0, f'Error: {str(e)}')
            self.tasks[task_id] = {'status': 'error', 'error': str(e)}


handler = WebSocketHandler()


async def ws_handler(websocket):
    await handler.register(websocket)
    try:
        async for raw_message in websocket:
            try:
                message = json.loads(raw_message)
                await handler.handle_message(websocket, message)
            except json.JSONDecodeError:
                await websocket.send(json.dumps({
                    'type': 'error',
                    'message': 'Invalid JSON',
                }))
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        await handler.unregister(websocket)


async def main():
    host = '0.0.0.0'
    port = 5001
    print(f"WebSocket server starting on ws://{host}:{port}")
    async with websockets.serve(ws_handler, host, port):
        await asyncio.Future()


if __name__ == '__main__':
    asyncio.run(main())
