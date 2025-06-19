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
  VideoPlayerController? _controller1;
  VideoPlayerController? _controller2;
  bool _isInitialized = false;
  bool _hasError = false;
  AudioSession? _audioSession;
  Duration? _previewEndPosition;
  bool _isPlayingPreview = false;
  Timer? _loopTimer;
  
  // Dual player control
  bool _useController1 = true; // Which controller is currently active
  bool _isPreparingNext = false; // Prevent multiple preparations

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() async {
    try {
      _isPlayingPreview = false;
      _isPreparingNext = false;
      _previewEndPosition = null;
      
      _loopTimer?.cancel();
      _loopTimer = null;
      
      // Dispose both controllers
      await _controller1?.pause();
      await _controller1?.dispose();
      _controller1 = null;
      
      await _controller2?.pause();
      await _controller2?.dispose();
      _controller2 = null;
      
      // Deactivate audio session
      if (_audioSession != null) {
        try {
          await _audioSession!.setActive(false);
        } catch (e) {
          debugPrint('Error deactivating audio session: $e');
        }
      }
    } catch (e) {
      debugPrint('Error disposing video controllers: $e');
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
      await _configureAudioSession();
      
      // Initialize BOTH controllers simultaneously
      await _initializeDualControllers();
      
      if (mounted) {
        _previewEndPosition = Duration(seconds: widget.previewDurationSeconds);
        
        setState(() {
          _isInitialized = true;
        });
        
        // Start with controller1
        await _startSeamlessLoop();
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

  Future<void> _initializeDualControllers() async {
    // Create two identical controllers
    _controller1 = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    
    _controller2 = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    // Initialize both controllers in parallel
    await Future.wait([
      _controller1!.initialize(),
      _controller2!.initialize(),
    ]);
    
    // Configure both controllers
    await Future.wait([
      _controller1!.setVolume(0.0),
      _controller2!.setVolume(0.0),
      _controller1!.seekTo(Duration.zero),
      _controller2!.seekTo(Duration.zero),
    ]);
    
    // Disable native looping on both
    _controller1!.setLooping(false);
    _controller2!.setLooping(false);
    
    debugPrint('🎥 Dual controllers initialized successfully');
  }

  Future<void> _configureAudioSession() async {
    try {
      _audioSession = await AudioSession.instance;
      
      await _audioSession!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
      
      debugPrint('✅ Video audio session configured for mixing');
    } catch (e) {
      debugPrint('⚠️ Error configuring video audio session: $e');
    }
  }

  Future<void> _startSeamlessLoop() async {
    if (_controller1 == null || _controller2 == null || !mounted) return;
    
    _isPlayingPreview = true;
    
    // Start playing with controller1
    await _controller1!.play();
    debugPrint('🎥 Starting SEAMLESS dual-controller loop: ${_previewEndPosition!.inSeconds}s');
    
    // Start monitoring for seamless switching
    _loopTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_isPlayingPreview || _previewEndPosition == null) {
        return;
      }
      
      final activeController = _useController1 ? _controller1! : _controller2!;
      final currentPosition = activeController.value.position;
      
      // When we're 200ms before the end, prepare the next controller
      final timeUntilEnd = _previewEndPosition! - currentPosition;
      if (timeUntilEnd <= const Duration(milliseconds: 200) && timeUntilEnd > Duration.zero && !_isPreparingNext) {
        _prepareNextController();
      }
      
      // When we reach the end, switch controllers instantly
      if (currentPosition >= _previewEndPosition!) {
        _switchControllers();
      }
    });
  }

  void _prepareNextController() async {
    if (_isPreparingNext) return;
    _isPreparingNext = true;
    
    try {
      final nextController = _useController1 ? _controller2! : _controller1!;
      
      // Prepare the next controller to start from beginning
      await nextController.seekTo(Duration.zero);
      await nextController.setVolume(0.0);
      
      debugPrint('🎥 Next controller prepared and ready');
    } catch (e) {
      debugPrint('Error preparing next controller: $e');
    }
  }

  void _switchControllers() async {
    if (!mounted || !_isPlayingPreview) return;
    
    try {
      final currentController = _useController1 ? _controller1! : _controller2!;
      final nextController = _useController1 ? _controller2! : _controller1!;
      
      // INSTANT switch - no delay
      await Future.wait([
        currentController.pause(), // Stop current
        nextController.play(),     // Start next
      ]);
      
      // Switch the active controller flag
      _useController1 = !_useController1;
      _isPreparingNext = false;
      
      debugPrint('🎥 INSTANT controller switch: Controller${_useController1 ? "1" : "2"} now active');
    } catch (e) {
      debugPrint('Error switching controllers: $e');
    }
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.videoUrl != oldWidget.videoUrl || 
        widget.previewDurationSeconds != oldWidget.previewDurationSeconds) {
      _disposeControllers();
      _initializeVideo();
    }
    
    if (widget.shouldPause != oldWidget.shouldPause) {
      _handlePauseState();
    }
  }
  
  void _handlePauseState() async {
    if (_controller1 == null || _controller2 == null) return;
    
    try {
      if (widget.shouldPause) {
        _isPlayingPreview = false;
        _loopTimer?.cancel();
        
        // Pause both controllers
        await Future.wait([
          _controller1!.pause(),
          _controller2!.pause(),
        ]);
        
        debugPrint('🎥 Both controllers paused');
      } else {
        // Resume with fresh start
        await Future.wait([
          _controller1!.seekTo(Duration.zero),
          _controller2!.seekTo(Duration.zero),
          _controller1!.setVolume(0.0),
          _controller2!.setVolume(0.0),
        ]);
        
        _useController1 = true; // Reset to controller1
        _isPreparingNext = false;
        await _startSeamlessLoop();
        
        debugPrint('🎥 Controllers resumed with dual-loop');
      }
    } catch (e) {
      debugPrint('Error handling pause state: $e');
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
            // Dual video players - show active one
            if (_isInitialized && _controller1 != null && _controller2 != null)
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: Duration.zero, // Instant switch
                  child: FittedBox(
                    key: ValueKey(_useController1 ? 'controller1' : 'controller2'),
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: (_useController1 ? _controller1! : _controller2!).value.size.width,
                      height: (_useController1 ? _controller1! : _controller2!).value.size.height,
                      child: VideoPlayer(_useController1 ? _controller1! : _controller2!),
                    ),
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
            
            // Gradient overlay
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
            
            // Play indicator
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