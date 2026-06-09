import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import '../utils/constants.dart';

class VideoPreview extends StatefulWidget {
  final String videoUrl;
  final bool autoplay;
  final bool showControls;
  final double? aspectRatio;
  final VoidCallback? onError;

  const VideoPreview({
    super.key,
    required this.videoUrl,
    this.autoplay = false,
    this.showControls = true,
    this.aspectRatio,
    this.onError,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _thumbnailPath;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoUrl.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      }

      await _controller!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);

        if (widget.autoplay) {
          _controller!.play();
          setState(() => _isPlaying = true);
        }

        _controller!.addListener(() {
          if (mounted) {
            setState(() => _isPlaying = _controller!.value.isPlaying);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        widget.onError?.call();
        _generateThumbnail();
      }
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await _getTempDir()).path,
        imageFormat: ImageFormat.PNG,
        quality: 80,
      );
      if (mounted) setState(() => _thumbnailPath = thumb);
    } catch (_) {}
  }

  Future<Directory> _getTempDir() async {
    final dir = Directory.systemTemp;
    return dir;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    return _buildPlayer();
  }

  Widget _buildPlayer() {
    final aspectRatio = widget.aspectRatio ?? _controller!.value.aspectRatio;

    return GestureDetector(
      onTap: () {
        if (_isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (widget.showControls) _buildControls(),
          if (!_isPlaying && _isInitialized)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Icon(
                    Icons.play_circle,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (_isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          Text(
            _formatDuration(_controller!.value.position),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_controller!.value.duration),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: Container(
        color: AppColors.card,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: Container(
        color: AppColors.card,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_thumbnailPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_thumbnailPath!),
                  fit: BoxFit.cover,
                  height: 120,
                ),
              )
            else
              const Icon(Icons.video_library, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Video Preview',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class VideoThumbnailGrid extends StatelessWidget {
  final List<String> videoPaths;
  final ValueChanged<String>? onTap;

  const VideoThumbnailGrid({
    super.key,
    required this.videoPaths,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: videoPaths.length,
      itemBuilder: (_, index) {
        return GestureDetector(
          onTap: () => onTap?.call(videoPaths[index]),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.video_file, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
