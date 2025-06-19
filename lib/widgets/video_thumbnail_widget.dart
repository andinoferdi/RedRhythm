import 'dart:async';
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
  final int previewDurationSeconds; // Customizable preview duration

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.width = 160,
    this.height = 240,
    this.borderRadius,
    this.onTap,
    this.shouldPause = false,
    this.previewDurationSeconds = 7, // Default 7 seconds for Shorts
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  AudioSession? _audioSession;
  Duration? _previewEndPosition; // Track where preview should end
  bool _isPlayingPreview = false; // Track if we're in preview mode
  Timer? _loopTimer; // Timer for seamless looping

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
      // Stop preview monitoring
      _isPlayingPreview = false;
      _previewEndPosition = null;
      
      // Cancel loop timer
      _loopTimer?.cancel();
      _loopTimer = null;
      
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
        // Set preview end position (only load/play first X seconds)
        final videoDuration = _controller!.value.duration;
        final previewDuration = Duration(seconds: widget.previewDurationSeconds);
        _previewEndPosition = videoDuration.compareTo(previewDuration) < 0 
            ? videoDuration 
            : previewDuration;
        
        setState(() {
          _isInitialized = true;
        });
        
        // CRITICAL: Set volume to 0 BEFORE playing to prevent audio conflicts
        await _controller!.setVolume(0.0);
        _controller!.setLooping(false); // Don't loop the entire video
        
        // Start playing silently from beginning
        await _controller!.seekTo(Duration.zero);
        await _controller!.play();
        
        // Start monitoring video position for preview control
        _startPositionMonitoring();
        
        // Start optimized preview loop
        _startOptimizedPreviewLoop();
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

  void _startPositionMonitoring() {
    if (_controller == null || !mounted || _previewEndPosition == null) return;
    
    // Use precise timer for seamless looping without jeda
    _loopTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _controller == null || _previewEndPosition == null || !_isPlayingPreview) {
        timer.cancel();
        return;
      }
      
      final currentPosition = _controller!.value.position;
      
      // Check if we're approaching the end (with 100ms buffer for smooth transition)
      final remainingTime = _previewEndPosition! - currentPosition;
      
      if (remainingTime <= const Duration(milliseconds: 150) && remainingTime >= Duration.zero) {
        _seamlessRestart();
      }
    });
  }
  
  void _seamlessRestart() async {
    if (_controller == null || !mounted || !_isPlayingPreview) return;
    
    try {
      // Immediately seek to beginning without pausing for seamless loop
      await _controller!.seekTo(Duration.zero);
      
      // Ensure volume stays at 0 and keep playing
      await _controller!.setVolume(0.0);
      
      debugPrint('🎥 Seamless video loop: ${_previewEndPosition!.inSeconds}s');
    } catch (e) {
      debugPrint('Error in seamless restart: $e');
    }
  }

  void _startOptimizedPreviewLoop() {
    if (_controller == null || !mounted || _previewEndPosition == null) return;
    
    // Start the preview playback
    _isPlayingPreview = true;
    debugPrint('🎥 Starting optimized video preview: ${_previewEndPosition!.inSeconds}s duration');
  }

  void _startPreviewLoop() {
    // Legacy method - kept for compatibility
    _startOptimizedPreviewLoop();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reinitialize if URL or duration changes
    if (widget.videoUrl != oldWidget.videoUrl || 
        widget.previewDurationSeconds != oldWidget.previewDurationSeconds) {
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
        _isPlayingPreview = false;
        _loopTimer?.cancel();
        await _controller!.pause();
        debugPrint('🎥 Video paused to avoid audio conflict');
      } else {
        // Resume the video with volume still at 0, start from beginning of preview
        await _controller!.setVolume(0.0);
        await _controller!.seekTo(Duration.zero);
        await _controller!.play();
        _isPlayingPreview = true;
        // Restart seamless loop monitoring
        _startPositionMonitoring();
        debugPrint('🎥 Video resumed silently with seamless loop');
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