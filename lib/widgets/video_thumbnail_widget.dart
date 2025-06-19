import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

/// Advanced video thumbnail widget with seamless looping for shorts
/// Implements best practices from TikTok/Instagram Reels/Spotify
class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool shouldPause;
  final int previewDurationSeconds;
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
    this.previewDurationSeconds = 7,
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
  Timer? _loopTimer;
  Duration? _previewEndPosition;
  bool _hasStartedPreview = false;

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
    _disposeController();
    _loopTimer?.cancel();
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
      _disposeController();
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

  Future<void> _initializeController() async {
    if (widget.videoUrl.isEmpty) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Set up video properties
        await _controller!.setVolume(0.0); // Muted by default for preview
        await _controller!.setLooping(widget.enableLooping);

        // Calculate preview duration
        final videoDuration = _controller!.value.duration;
        final previewDuration = Duration(seconds: widget.previewDurationSeconds);
        _previewEndPosition = previewDuration > videoDuration ? videoDuration : previewDuration;

        // Add listener for seamless looping
        _controller!.addListener(_onVideoProgress);

        // Auto-play if enabled
        if (widget.autoPlay && !widget.shouldPause) {
          _startPreview();
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

  void _disposeController() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isPlaying = false;
    _hasStartedPreview = false;
  }

  void _onVideoProgress() {
    if (!mounted || _controller == null || !widget.enableLooping) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    // Seamless looping logic - restart when reaching preview end or video end
    if (_previewEndPosition != null && position >= _previewEndPosition!) {
      _restartPreview();
    } else if (position >= duration && duration > Duration.zero) {
      _restartPreview();
    }
  }

  Future<void> _startPreview() async {
    if (_controller == null || !_isInitialized || _hasStartedPreview) return;

    try {
      await _controller!.seekTo(Duration.zero);
      await _controller!.play();
      
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _hasStartedPreview = true;
        });
      }
      
      debugPrint('🎥 Started seamless video preview: ${widget.previewDurationSeconds}s loop');
    } catch (e) {
      debugPrint('Error starting video preview: $e');
    }
  }

  Future<void> _restartPreview() async {
    if (_controller == null || !mounted) return;

    try {
      await _controller!.seekTo(Duration.zero);
      if (_isPlaying && !widget.shouldPause) {
        await _controller!.play();
      }
    } catch (e) {
      debugPrint('Error restarting video preview: $e');
    }
  }

  Future<void> _playVideo() async {
    if (_controller == null || !_isInitialized || _isPlaying) return;

    try {
      await _controller!.play();
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error playing video: $e');
    }
  }

  Future<void> _pauseVideo() async {
    if (_controller == null || !_isInitialized || !_isPlaying) return;

    try {
      await _controller!.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      debugPrint('Error pausing video: $e');
    }
  }

  void _onTap() {
    if (_controller != null && _isInitialized) {
      if (_isPlaying) {
        _pauseVideo();
      } else {
        _playVideo();
      }
    }
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
            // Video player
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

            // Play/Pause overlay
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

            // Looping indicator (small dot)
            if (widget.enableLooping && _isPlaying)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.loop,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
