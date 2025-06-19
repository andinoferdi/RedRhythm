import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_colors.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.width = 160,
    this.height = 240,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initializeVideo() {
    if (widget.videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      _controller!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          
          // Start playing with muted sound and loop
          _controller!.setVolume(0.0); // Muted
          _controller!.setLooping(true);
          _controller!.play();
          
          // Stop after 3 seconds and restart (for preview effect)
          _startPreviewLoop();
        }
      }).catchError((error) {
        debugPrint('Error initializing video thumbnail: $error');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      debugPrint('Error creating video controller: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  void _startPreviewLoop() {
    if (_controller == null || !mounted) return;
    
    // Create a 3-second preview loop
    Future.doWhile(() async {
      if (!mounted || _controller == null) return false;
      
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted && _controller != null && _controller!.value.isInitialized) {
        await _controller!.seekTo(Duration.zero);
        _controller!.play();
      }
      
      return mounted && _controller != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
          color: Colors.grey.shade900,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player - FULL COVERAGE without gaps
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover, // This ensures video fills the entire container
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            
            // Loading or error state
            if (!_isInitialized || _hasError)
              Container(
                color: Colors.grey.shade900,
                child: Center(
                  child: _hasError
                      ? Icon(
                          Icons.video_library_outlined,
                          color: Colors.grey.shade600,
                          size: 32,
                        )
                      : const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                ),
              ),
            
            // Gradient overlay for better text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black38,
                  ],
                  stops: [0.0, 0.7, 1.0],
                ),
              ),
            ),
            
            // Play indicator overlay
            if (_isInitialized && !_hasError)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 