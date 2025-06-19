import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audio_session/audio_session.dart';
import '../utils/app_colors.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool shouldPause;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.width = 160,
    this.height = 240,
    this.borderRadius,
    this.onTap,
    this.shouldPause = false,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  AudioSession? _audioSession;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() async {
    try {
      // Stop the video first
      await _controller?.pause();
      
      // Properly dispose the controller
      await _controller?.dispose();
      _controller = null;
      
      // Deactivate audio session if we activated one
      if (_audioSession != null) {
        try {
          await _audioSession!.setActive(false);
        } catch (e) {
          debugPrint('Error deactivating audio session: $e');
        }
      }
    } catch (e) {
      debugPrint('Error disposing video controller: $e');
    }
  }

  void _initializeVideo() async {
    if (widget.videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    try {
      // Configure audio session to NOT interrupt main audio
      await _configureAudioSession();
      
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          // Allow video to play in background without claiming audio focus
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // CRITICAL: Set volume to 0 BEFORE playing to prevent audio conflicts
        await _controller!.setVolume(0.0);
        _controller!.setLooping(true);
        
        // Start playing silently
        await _controller!.play();
        
        // Start preview loop
        _startPreviewLoop();
      }
    } catch (error) {
      debugPrint('Error initializing video thumbnail: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      _audioSession = await AudioSession.instance;
      
      // Configure audio session to mix with others and not gain focus
      await _audioSession!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient, // Key: Use ambient category
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie, // Video content
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck, // Key: Use transient duck to avoid interruption
        androidWillPauseWhenDucked: false,
      ));
      
      debugPrint('✅ Video audio session configured for mixing');
    } catch (e) {
      debugPrint('⚠️ Error configuring video audio session: $e');
      // Continue without audio session configuration
    }
  }

  void _startPreviewLoop() {
    if (_controller == null || !mounted) return;
    
    // Create a 3-second preview loop
    Future.doWhile(() async {
      if (!mounted || _controller == null) return false;
      
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted && _controller != null && _controller!.value.isInitialized) {
        // Ensure volume stays at 0 throughout playback
        await _controller!.setVolume(0.0);
        await _controller!.seekTo(Duration.zero);
        await _controller!.play();
      }
      
      return mounted && _controller != null;
    });
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reinitialize if URL changes
    if (widget.videoUrl != oldWidget.videoUrl) {
      _disposeController();
      _initializeVideo();
    }
    
    // Handle pause/resume based on shouldPause parameter
    if (widget.shouldPause != oldWidget.shouldPause) {
      _handlePauseState();
    }
  }
  
  void _handlePauseState() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      if (widget.shouldPause) {
        // Pause the video to avoid audio conflicts
        await _controller!.pause();
        debugPrint('🎥 Video paused to avoid audio conflict');
      } else {
        // Resume the video with volume still at 0
        await _controller!.setVolume(0.0);
        await _controller!.play();
        debugPrint('🎥 Video resumed silently');
      }
    } catch (e) {
      debugPrint('Error handling video pause state: $e');
    }
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