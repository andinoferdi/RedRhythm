import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:video_player/video_player.dart';
import '../../providers/shorts_provider.dart';
import '../../providers/artist_select_provider.dart';
import '../../repositories/song_repository.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/song_playlist_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../models/shorts.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../models/playlist.dart';
import '../../utils/app_colors.dart';
import '../../utils/font_usage_guide.dart';
import '../../utils/image_helpers.dart';
import '../../widgets/playlist_selection_modal.dart';
import '../../controllers/player_controller.dart';
import '../../routes/app_router.dart';

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
  
  // Repositories
  late SongRepository _songRepository;
  late ArtistRepository _artistRepository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize repositories
    final pbService = PocketBaseService();
    _songRepository = SongRepository(pbService);
    _artistRepository = ArtistRepository(pbService);
    
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
                    songRepository: _songRepository,
                    artistRepository: _artistRepository,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Individual video player widget for shorts
class ShortsVideoPlayer extends ConsumerStatefulWidget {
  final Shorts short;
  final bool isActive;
  final SongRepository songRepository;
  final ArtistRepository artistRepository;

  const ShortsVideoPlayer({
    super.key,
    required this.short,
    required this.isActive,
    required this.songRepository,
    required this.artistRepository,
  });

  @override
  ConsumerState<ShortsVideoPlayer> createState() => _ShortsVideoPlayerState();
}

class _ShortsVideoPlayerState extends ConsumerState<ShortsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  
  // Song and Artist data
  Song? _song;
  Artist? _artist;
  bool _isLoadingData = true;
  
  // Add to playlist button state (matching mini player pattern)
  bool _isLoadingPlaylists = false;
  bool _isInPlaylist = false;
  String? _lastCheckedSongId;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadSongAndArtistData();
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
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(_isMuted ? 0.0 : 1.0);

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

  Future<void> _loadSongAndArtistData() async {
    try {
      // Load song data
      if (widget.short.songId.isNotEmpty) {
        final song = await widget.songRepository.getSongById(widget.short.songId);
        if (mounted) {
          setState(() {
            _song = song;
          });
          // Check playlist status after song is loaded
          _checkIfSongInPlaylist();
        }
      }

      // Load artist data
      if (widget.short.artistId.isNotEmpty) {
        final artist = await widget.artistRepository.getArtistById(widget.short.artistId);
        if (mounted) {
          setState(() {
            _artist = artist;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading song/artist data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Check if song is in playlist (matching mini player pattern)
  Future<void> _checkIfSongInPlaylist() async {
    if (_song == null) return;
    
    // Avoid duplicate checks for the same song
    if (_lastCheckedSongId == _song!.id) return;

    try {
      setState(() {
        _isLoadingPlaylists = true;
      });

      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      final allPlaylists = await repository.getAllPlaylists();

      bool foundInAnyPlaylist = false;

      for (final playlist in allPlaylists) {
        final containsSong = playlist.songs.contains(_song!.id);
        if (containsSong) {
          foundInAnyPlaylist = true;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _isInPlaylist = foundInAnyPlaylist;
          _lastCheckedSongId = _song!.id;
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInPlaylist = false;
          _lastCheckedSongId = _song!.id;
          _isLoadingPlaylists = false;
        });
      }
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

  void _toggleMute() {
    if (_controller != null && _isInitialized) {
      setState(() {
        _isMuted = !_isMuted;
        _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  Future<void> _toggleFollowArtist() async {
    if (_artist == null) return;

    try {
      final selectedArtists = ref.read(artistSelectProvider);
      final isCurrentlyFollowing = selectedArtists.any((artistSelect) => 
          artistSelect.artistId == _artist!.id);

      if (isCurrentlyFollowing) {
        // Unfollow artist
        final success = await ref.read(artistSelectProvider.notifier).removeArtistSelection(_artist!.id);
        
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Telah berhenti mengikuti "${_artist!.name}"',
                      style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // Follow artist
        final success = await ref.read(artistSelectProvider.notifier).addArtistSelection(_artist!.id);
        
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kini mengikuti "${_artist!.name}"',
                      style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status mengikuti: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _showPlaylistModal() async {
    if (_song == null) return;

    await showPlaylistSelectionModal(
      context,
      _song!,
      onPlaylistsChanged: () {
        // Refresh playlist status after changes
        _lastCheckedSongId = null;
        _checkIfSongInPlaylist();
      },
    );
  }

  // Navigate to music player (following home screen pattern)
  void _navigateToMusicPlayer() {
    if (_song == null) return;
    
    // Use the same logic as home screen for queue handling
    ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(_song!.id);
    
    // Navigate to music player screen
    context.router.push(MusicPlayerRoute(song: _song!));
  }

  // Navigate to artist detail
  void _navigateToArtistDetail() {
    if (_artist == null) return;
    
    context.router.push(ArtistDetailRoute(
      artistId: _artist!.id,
      artistName: _artist!.name,
    ));
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

        // Right side controls (only volume)
        Positioned(
          right: 16,
          bottom: 200,
          child: Column(
            children: [
              // Volume control
              _buildActionButton(
                icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                onTap: _toggleMute,
              ),
            ],
          ),
        ),

        // Bottom info section
        Positioned(
          left: 16,
          right: 80,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist section
              if (_artist != null) ...[
                Row(
                  children: [
                    // Artist avatar - clickable to navigate to artist detail
                    GestureDetector(
                      onTap: _navigateToArtistDetail,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: _artist!.imageUrl != null && _artist!.imageUrl!.isNotEmpty
                              ? Image.network(
                                  _artist!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                      const Icon(Icons.person, color: Colors.white),
                                )
                              : const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Artist name - also clickable
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToArtistDetail,
                        child: Text(
                          _artist!.name,
                          style: FontUsageGuide.authButtonText.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    // Follow button
                    Consumer(
                      builder: (context, ref, child) {
                        final selectedArtists = ref.watch(artistSelectProvider);
                        final isFollowing = selectedArtists.any((artistSelect) => 
                            artistSelect.artistId == _artist!.id);
                        
                        return GestureDetector(
                          onTap: _toggleFollowArtist,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFollowing 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isFollowing ? 'Mengikuti' : 'Ikuti',
                              style: FontUsageGuide.navigationLabel.copyWith(
                                color: isFollowing ? Colors.white : Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Song section with border and clickable area
              if (_song != null) ...[
                GestureDetector(
                  onTap: _navigateToMusicPlayer,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Row(
                      children: [
                        // Song thumbnail
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _song!.albumArtUrl.isNotEmpty
                                ? Image.network(
                                    _song!.albumArtUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                        const Icon(Icons.music_note, color: Colors.white),
                                  )
                                : const Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Song info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _song!.title,
                                style: FontUsageGuide.modalBody.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _song!.artist,
                                style: FontUsageGuide.listMetadata.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Add to playlist button (matching mini player style)
                        IconButton(
                          onPressed: _isLoadingPlaylists ? null : _showPlaylistModal,
                          icon: _isLoadingPlaylists
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _isInPlaylist
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: _isInPlaylist
                                      ? Colors.red
                                      : Colors.white,
                                  size: 24,
                                ),
                          tooltip: _isLoadingPlaylists
                              ? 'Checking playlists...'
                              : (_isInPlaylist
                                  ? 'In playlist'
                                  : 'Add to playlist'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Video title/description
              Text(
                widget.short.displayTitle,
                style: FontUsageGuide.modalBody.copyWith(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Hashtags
              if (widget.short.hashtagsList.isNotEmpty) ...[
                const SizedBox(height: 8),
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
            ],
          ),
        ),
        
        // Loading overlay
        if (_isLoadingData)
          Positioned(
            bottom: 80,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
