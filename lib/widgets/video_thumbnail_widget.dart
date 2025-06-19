import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Simple video thumbnail widget with stable looping (following shorts_screen.dart pattern)
/// Uses the same reliable logic as shorts screen for consistent behavior
class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool shouldPause;
  final bool autoPlay;
  final bool enableLooping;
  final bool showPlayIcon;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.onTap,
    this.shouldPause = false,
    this.autoPlay = true,
    this.enableLooping = true,
    this.showPlayIcon = true,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle shouldPause changes
    if (oldWidget.shouldPause != widget.shouldPause) {
      if (widget.shouldPause) {
        _pauseVideo();
      } else if (widget.autoPlay) {
        _playVideo();
      }
    }
    
    // Handle video URL changes
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _initializeController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pauseVideo();
        break;
      case AppLifecycleState.resumed:
        if (widget.autoPlay && !widget.shouldPause) {
          _playVideo();
        }
        break;
      default:
        break;
    }
  }

  // Following shorts_screen.dart initialization pattern
  Future<void> _initializeController() async {
    if (widget.videoUrl.isEmpty) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true, // Allow mixing with other audio (like shorts screen)
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();
      await _controller!.setLooping(widget.enableLooping); // Simple setLooping like shorts screen
      await _controller!.setVolume(0.0); // Muted by default for preview

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Auto-play if enabled (following shorts screen pattern)
        if (widget.autoPlay && !widget.shouldPause) {
          _playVideo();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  // Simple play/pause methods like shorts screen
  Future<void> _playVideo() async {
    if (_controller != null && _isInitialized && !_isPlaying) {
      await _controller!.play();
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  Future<void> _pauseVideo() async {
    if (_controller != null && _isInitialized && _isPlaying) {
      await _controller!.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _onTap() {
    _togglePlayPause();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: widget.borderRadius,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player (same pattern as shorts screen)
            if (_isInitialized && _controller != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),

            // Play/Pause overlay (similar to shorts screen)
            if (widget.showPlayIcon)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _onTap,
                  child: Container(
                    color: Colors.transparent,
                    child: AnimatedOpacity(
                      opacity: !_isPlaying ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: widget.borderRadius,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Tap to play/pause (invisible overlay)
            if (!widget.showPlayIcon)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _onTap,
                  child: Container(color: Colors.transparent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
