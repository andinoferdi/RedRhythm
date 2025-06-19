import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:video_player/video_player.dart';
import '../../providers/shorts_provider.dart';
import '../../models/shorts.dart';
import '../../utils/app_colors.dart';
import '../../utils/font_usage_guide.dart';
import '../../widgets/video_thumbnail_widget.dart';

@RoutePage()
class ShortsScreen extends ConsumerStatefulWidget {
  final String? initialGenreId;
  final int? initialIndex;

  const ShortsScreen({
    super.key,
    this.initialGenreId,
    this.initialIndex,
  });

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Load shorts if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shortsState = ref.read(shortsProvider);
      if (shortsState.shorts.isEmpty) {
        ref.read(shortsProvider.notifier).loadShorts();
      }
      
      // Update current index in provider
      ref.read(shortsProvider.notifier).updateCurrentIndex(_currentIndex);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setState(() {
      _isVisible = state == AppLifecycleState.resumed;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Update current index in provider
    ref.read(shortsProvider.notifier).updateCurrentIndex(index);
    
    // Load more shorts if near end
    final shortsState = ref.read(shortsProvider);
    if (index >= shortsState.shorts.length - 3 && !shortsState.hasReachedMax) {
      ref.read(shortsProvider.notifier).loadMoreShorts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.router.pop(),
        ),
        title: Text(
          'Shorts',
          style: FontUsageGuide.appBarTitle.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showMoreOptions();
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final shortsState = ref.watch(shortsProvider);
          
          if (shortsState.isLoading && shortsState.shorts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          
          if (shortsState.error != null && shortsState.shorts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.grey.shade400,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load shorts',
                    style: FontUsageGuide.modalTitle.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shortsState.error!,
                    style: FontUsageGuide.modalBody.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(shortsProvider.notifier).refreshShorts();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (shortsState.shorts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    color: Colors.grey.shade400,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No shorts available',
                    style: FontUsageGuide.modalTitle.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new content',
                    style: FontUsageGuide.modalBody.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return Stack(
            children: [
              // Video PageView
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: shortsState.shorts.length,
                itemBuilder: (context, index) {
                  final short = shortsState.shorts[index];
                  final isActive = index == _currentIndex;
                  
                  return ShortsVideoPlayer(
                    short: short,
                    isActive: isActive && _isVisible,
                    onLike: () => _onLikeShort(short),
                    onShare: () => _onShareShort(short),
                    onComment: () => _onCommentShort(short),
                  );
                },
              ),
              
              // Loading indicator for more content
              if (shortsState.isLoadingMore)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading more...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onLikeShort(Shorts short) {
    ref.read(shortsProvider.notifier).toggleLike(short.id);
    
    // Show heart animation
    _showHeartAnimation();
  }

  void _onShareShort(Shorts short) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${short.displayTitle}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _onCommentShort(Shorts short) {
    // TODO: Implement comments
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comments coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showHeartAnimation() {
    // TODO: Implement heart animation overlay
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.white),
              title: const Text('Refresh', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(shortsProvider.notifier).refreshShorts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Individual video player widget for shorts
class ShortsVideoPlayer extends StatefulWidget {
  final Shorts short;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;

  const ShortsVideoPlayer({
    super.key,
    required this.short,
    required this.isActive,
    required this.onLike,
    required this.onShare,
    required this.onComment,
  });

  @override
  State<ShortsVideoPlayer> createState() => _ShortsVideoPlayerState();
}

class _ShortsVideoPlayerState extends State<ShortsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

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

  @override
  void didUpdateWidget(ShortsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playVideo();
      } else {
        _pauseVideo();
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.short.videoUrl.isEmpty) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.short.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false, // Take audio focus for full-screen
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(1.0); // Full volume for full-screen

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.isActive) {
          _playVideo();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  Future<void> _playVideo() async {
    if (_controller != null && _isInitialized && !_isPlaying) {
      await _controller!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _pauseVideo() async {
    if (_controller != null && _isInitialized && _isPlaying) {
      await _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        if (_isInitialized && _controller != null)
          GestureDetector(
            onTap: _togglePlayPause,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        else
          Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // Play/Pause overlay
        if (!_isPlaying && _isInitialized)
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),

        // Right side controls
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              // Like button
              _buildActionButton(
                icon: Icons.favorite_border,
                label: widget.short.formattedLikes,
                onTap: widget.onLike,
              ),
              const SizedBox(height: 20),
              
              // Comment button
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: 'Comments',
                onTap: widget.onComment,
              ),
              const SizedBox(height: 20),
              
              // Share button
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: widget.onShare,
              ),
            ],
          ),
        ),

        // Bottom info
        Positioned(
          left: 16,
          right: 80,
          bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist name
              Text(
                widget.short.displayArtist,
                style: FontUsageGuide.authButtonText.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // Title
              Text(
                widget.short.displayTitle,
                style: FontUsageGuide.modalBody.copyWith(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Hashtags
              if (widget.short.hashtagsList.isNotEmpty)
                Wrap(
                  children: widget.short.hashtagsList.take(3).map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '#$tag',
                        style: FontUsageGuide.listMetadata.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
