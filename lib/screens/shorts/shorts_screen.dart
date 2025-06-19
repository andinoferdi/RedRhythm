import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:video_player/video_player.dart';
import '../../providers/shorts_provider.dart';
import '../../models/shorts.dart';

import '../../utils/app_colors.dart';
import '../../utils/font_usage_guide.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/playlist_selection_modal.dart';
import '../../repositories/song_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/song_playlist_repository.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({super.key});

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen>
    with TickerProviderStateMixin {
  PageController? _pageController;
  Map<String, VideoPlayerController> _videoControllers = {};
  String? _currentVideoId;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Set system UI for full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Load initial shorts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shortsProvider.notifier).loadShorts();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    
    _pageController?.dispose();
    super.dispose();
  }

  /// Initialize video controller for a short
  VideoPlayerController? _initializeVideoController(Shorts short) {
    if (_isDisposed) return null;
    
    // Don't reinitialize if already exists
    if (_videoControllers.containsKey(short.id)) {
      return _videoControllers[short.id];
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(short.videoUrl),
      );

      controller.initialize().then((_) {
        if (!_isDisposed && mounted) {
          setState(() {});
          
          // Auto-play if this is the current video
          if (_currentVideoId == short.id) {
            controller.play();
            controller.setLooping(true);
          }
        }
      }).catchError((error) {
        debugPrint('Error initializing video controller: $error');
      });

      _videoControllers[short.id] = controller;
      return controller;
    } catch (e) {
      debugPrint('Error creating video controller: $e');
      return null;
    }
  }

  /// Handle page change
  void _onPageChanged(int index) {
    if (_isDisposed) return;

    final shortsState = ref.read(shortsProvider);
    if (index >= shortsState.shorts.length) return;

    final currentShort = shortsState.shorts[index];
    
    // Update shorts provider
    ref.read(shortsProvider.notifier).goToShort(index);
    
    // Update current video
    _currentVideoId = currentShort.id;
    
    // Pause all videos
    for (final controller in _videoControllers.values) {
      if (controller.value.isInitialized) {
        controller.pause();
      }
    }
    
    // Play current video
    final currentController = _videoControllers[currentShort.id];
    if (currentController?.value.isInitialized == true) {
      currentController!.play();
      currentController.setLooping(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer(
        builder: (context, ref, child) {
          final shortsState = ref.watch(shortsProvider);

          // Loading state
          if (shortsState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Error state
          if (shortsState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load shorts',
                    style: FontUsageGuide.errorTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shortsState.error!,
                    style: FontUsageGuide.errorMessage,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(shortsProvider.notifier).refreshShorts();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (shortsState.shorts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No shorts available',
                    style: FontUsageGuide.emptyStateTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new content',
                    style: FontUsageGuide.emptyStateMessage,
                  ),
                ],
              ),
            );
          }

          // Basic shorts feed placeholder
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Shorts Feature',
                      style: FontUsageGuide.modalTitle.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video shorts will appear here',
                      style: FontUsageGuide.modalBody.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Found ${shortsState.shorts.length} shorts',
                      style: FontUsageGuide.metadata.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: GestureDetector(
                  onTap: () => context.router.maybePop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
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

  Widget _buildShortItem(Shorts short, bool isActive) {
    final controller = _videoControllers[short.id];
    
    return GestureDetector(
      onTap: () {
        // Toggle play/pause
        if (controller?.value.isInitialized == true) {
          if (controller!.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            if (controller?.value.isInitialized == true)
              Center(
                child: AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              )
            else
              Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
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
                    Colors.black26,
                    Colors.black54,
                  ],
                  stops: [0.0, 0.6, 0.8, 1.0],
                ),
              ),
            ),
            
            // Content overlay
            Positioned(
              bottom: 100,
              left: 16,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Artist name
                  if (short.artistName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            short.artistName!,
                            style: FontUsageGuide.listArtistName.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Song title
                  if (short.songTitle != null)
                    Text(
                      short.songTitle!,
                      style: FontUsageGuide.listSongTitle.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Hashtags
                  if (short.hashtags?.isNotEmpty == true)
                    Text(
                      short.hashtags!,
                      style: FontUsageGuide.metadata.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            // Action buttons (right side)
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Like button
                  _buildActionButton(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    isActive: false, // TODO: Track user likes
                    label: short.formattedLikes,
                    onTap: () {
                      ref.read(shortsProvider.notifier).likeShort(short.id);
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Add to playlist button
                  _buildActionButton(
                    icon: Icons.add,
                    label: '',
                    onTap: () => _showAddToPlaylistModal(short),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Share button
                  _buildActionButton(
                    icon: Icons.share,
                    label: '',
                    onTap: () {
                      // TODO: Implement share functionality
                    },
                  ),
                ],
              ),
            ),
            
            // Play/Pause overlay
            if (controller?.value.isInitialized == true && !controller!.value.isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    IconData? activeIcon,
    bool isActive = false,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive && activeIcon != null ? activeIcon : icon,
              color: isActive ? AppColors.primary : Colors.white,
              size: 28,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: FontUsageGuide.metadata.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddToPlaylistModal(Shorts short) async {
    try {
      // Get song data from short
      final songRepository = SongRepository(GetIt.I<PocketBaseService>());
      final song = await songRepository.getSongById(short.songId);
      
      if (song == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song not found')),
        );
        return;
      }

      // Show playlist selection modal
      await showPlaylistSelectionModal(
        context,
        song,
        onPlaylistsChanged: () {
          // Optionally refresh UI or show success message
        },
      );
    } catch (e) {
      debugPrint('Error showing add to playlist modal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
} 