import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import '../../repositories/album_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/image_helpers.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/song_item_widget.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/custom_bottom_nav.dart';

@RoutePage()
class AlbumScreen extends ConsumerStatefulWidget {
  final String albumId;
  final String? albumTitle;
  final int? sourceTabIndex; // 0: Home, 1: Explore, 2: Library

  const AlbumScreen({
    required this.albumId,
    this.albumTitle,
    this.sourceTabIndex,
    super.key,
  });

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  late ScrollController _scrollController;
  late AlbumRepository _albumRepository;

  Album? _album;
  List<Song> _songs = [];
  bool _isLoadingAlbum = true;
  bool _isLoadingSongs = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _albumRepository = AlbumRepository(PocketBaseService());
    _loadData();
    
    // Reset shuffle mode when entering album screen (context change)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerControllerProvider.notifier).resetShuffleOnContextChange();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Determine current tab index based on source or navigation stack
  int _determineCurrentTabIndex() {
    if (widget.sourceTabIndex != null) {
      return widget.sourceTabIndex!;
    }
    
    final router = context.router;
    final routeStack = router.stack;
    
    if (routeStack.length > 1) {
      final previousRoute = routeStack[routeStack.length - 2];
      final routeName = previousRoute.name;
      
      switch (routeName) {
        case 'HomeRoute':
          return 0;
        case 'ExploreRoute':
          return 1;
        case 'LibraryRoute':
          return 2;
        default:
          for (int i = routeStack.length - 2; i >= 0; i--) {
            final route = routeStack[i];
            switch (route.name) {
              case 'HomeRoute':
                return 0;
              case 'ExploreRoute':
                return 1;
              case 'LibraryRoute':
                return 2;
            }
          }
      }
    }
    
    return 0; // Default to Home
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingAlbum = true;
      _isLoadingSongs = true;
      _errorMessage = null;
    });

    try {
      Album? album;
      if (widget.albumId.isNotEmpty) {
        album = await _albumRepository.getAlbumById(widget.albumId);
      }

      // Create fallback album if not found but title provided
      if (album == null && widget.albumTitle != null) {
        album = Album(
          id: '',
          title: widget.albumTitle!,
          artistName: 'Unknown Artist',
          artistId: '',
          created: DateTime.now(),
          updated: DateTime.now(),
        );
      }

      setState(() {
        _album = album;
        _isLoadingAlbum = false;
      });

      if (album != null) {
        List<Song> songs;
        if (album.id.isNotEmpty) {
          songs = await _albumRepository.getAlbumSongs(album.id);
        } else {
          // Fallback: search by album name
          songs = [];
        }

        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load album data: $e';
        _isLoadingAlbum = false;
        _isLoadingSongs = false;
      });
    }
  }

  void _playSong(Song song) {
    if (_songs.isEmpty) return;
    
    final playerState = ref.read(playerControllerProvider);
    List<Song> playQueue;
    int startIndex;

    if (playerState.shuffleMode) {
      // Create shuffled queue with selected song at index 0
      playQueue = List<Song>.from(_songs);
      playQueue.shuffle();
      
      // Move selected song to first position
      playQueue.removeWhere((s) => s.id == song.id);
      playQueue.insert(0, song);
      startIndex = 0;
    } else {
      // Use original order (by track number)
      playQueue = List<Song>.from(_songs);
      startIndex = _songs.indexOf(song);
    }

    // Use artist context for album playback
    ref.read(playerControllerProvider.notifier).playQueueFromArtist(
      playQueue,
      startIndex,
      _album!.artistId.isNotEmpty ? _album!.artistId : 'album_${_album!.id}',
    );
  }

  void _playAllSongs() {
    if (_songs.isEmpty) return;
    
    final playerState = ref.read(playerControllerProvider);
    final currentArtistId = playerState.currentArtistId;
    final albumContextId = _album!.artistId.isNotEmpty ? _album!.artistId : 'album_${_album!.id}';
    
    // If currently playing from this album, pause/resume
    if (currentArtistId == albumContextId) {
      if (playerState.isPlaying) {
        ref.read(playerControllerProvider.notifier).pause();
      } else {
        ref.read(playerControllerProvider.notifier).resume();
      }
    } else {
      // Prepare queue based on shuffle setting
      List<Song> playQueue;
      int startIndex;

      if (playerState.shuffleMode) {
        playQueue = List<Song>.from(_songs);
        playQueue.shuffle();
        startIndex = 0;
      } else {
        playQueue = List<Song>.from(_songs);
        startIndex = 0;
      }

      // Start playing with prepared queue
      ref.read(playerControllerProvider.notifier).playQueueFromArtist(
        playQueue,
        startIndex,
        albumContextId,
      );
    }
  }

  /// Toggle shuffle mode
  void _toggleShuffle() {
    final playerState = ref.read(playerControllerProvider);
    final albumContextId = _album!.artistId.isNotEmpty ? _album!.artistId : 'album_${_album!.id}';
    
    // Only allow shuffle toggle if playing from this album or no context
    if (playerState.currentArtistId == null || playerState.currentArtistId == albumContextId) {
      ref.read(playerControllerProvider.notifier).toggleShuffle();
      
      // If currently playing from this album, update the queue accordingly
      if (playerState.currentArtistId == albumContextId && playerState.currentSong != null) {
        _updateShuffleForCurrentPlayback();
      }
    }
  }

  /// Update shuffle for current playback
  void _updateShuffleForCurrentPlayback() {
    final playerState = ref.read(playerControllerProvider);
    final currentSong = playerState.currentSong;
    if (currentSong == null) return;

    // Find current song index in original list
    final currentIndex = _songs.indexWhere((song) => song.id == currentSong.id);
    if (currentIndex == -1) return;

    List<Song> newQueue;
    int newIndex;

    if (playerState.shuffleMode) {
      // Create shuffled queue with current song at index 0
      newQueue = List.from(_songs);
      newQueue.shuffle();
      
      // Move current song to first position
      newQueue.removeWhere((song) => song.id == currentSong.id);
      newQueue.insert(0, currentSong);
      newIndex = 0;
    } else {
      // Restore original order (by track number)
      newQueue = List.from(_songs);
      newIndex = currentIndex;
    }

    // Update player queue
    ref.read(playerControllerProvider.notifier).updateQueue(newQueue, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          _buildMainContent(),
          if (playerState.currentSong != null)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _determineCurrentTabIndex(),
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isLoadingAlbum) {
      return _buildLoadingState();
    }

    if (_album == null) {
      return _buildAlbumNotFoundState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAlbumHeader(),
        SliverToBoxAdapter(child: _buildAlbumActions()),
        SliverToBoxAdapter(child: _buildTracksSection()),
        SliverToBoxAdapter(
          child: SizedBox(
            height: ref.watch(playerControllerProvider).currentSong != null
                ? 160 // 80 (mini player) + 80 (bottom nav)
                : 100, // 20 (base) + 80 (bottom nav)
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: false,
      floating: false,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Album cover
            ImageHelpers.buildSafeNetworkImage(
              imageUrl: _album!.coverImageUrl ?? '',
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
              fallbackWidget: Container(
                color: const Color(0xFF282828),
                child: const Center(
                  child: Icon(
                    Icons.album,
                    size: 120,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                    const Color(0xFF121212),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),

            // Header controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.router.maybePop(),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // Album info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _album!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Gotham',
                      letterSpacing: 0.8,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF282828),
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _album!.artistName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Gotham',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Album • ${_album!.releaseYear > 0 ? _album!.releaseYear : 'Unknown Year'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Gotham',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Download button (placeholder)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.download, color: Colors.white),
            ),
          ),

          const SizedBox(width: 16),

          // More options
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),

          const Spacer(),

          // Shuffle button
          Consumer(
            builder: (context, ref, child) {
              final playerState = ref.watch(playerControllerProvider);
              
              return IconButton(
                onPressed: _toggleShuffle,
                icon: Icon(
                  Icons.shuffle, 
                  color: playerState.shuffleMode ? Colors.red : Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: playerState.shuffleMode ? Colors.red.withValues(alpha: 0.2) : Colors.grey[800],
                  padding: const EdgeInsets.all(12),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Play button
          Consumer(
            builder: (context, ref, child) {
              final playerState = ref.watch(playerControllerProvider);
              final albumContextId = _album!.artistId.isNotEmpty ? _album!.artistId : 'album_${_album!.id}';
              final isPlayingFromThisAlbum = playerState.currentArtistId == albumContextId;
              final isPlaying = isPlayingFromThisAlbum && playerState.isPlaying;
              
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _playAllSongs,
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTracksSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isLoadingSongs
              ? _buildLoadingSongs()
              : _songs.isEmpty
                  ? _buildNoSongsMessage()
                  : _buildSongsList(),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return Column(
      children: _songs.asMap().entries.map((entry) {
        final index = entry.key;
        final song = entry.value;

        return Consumer(
          builder: (context, ref, child) {
            final playerState = ref.watch(playerControllerProvider);
            final albumContextId = _album!.artistId.isNotEmpty ? _album!.artistId : 'album_${_album!.id}';
            
            final isCurrentSong = playerState.currentSong?.id == song.id;
            final isPlayingFromThisAlbum = playerState.currentArtistId == albumContextId;
            
            final shouldShowAsPlaying = isCurrentSong && 
                                      isPlayingFromThisAlbum && 
                                      playerState.isPlaying;
            
            bool isActuallyPlayingFromQueue = false;
            if (shouldShowAsPlaying && playerState.queue.isNotEmpty) {
              final currentIndex = playerState.currentIndex;
              if (currentIndex >= 0 && currentIndex < playerState.queue.length) {
                final queueSong = playerState.queue[currentIndex];
                isActuallyPlayingFromQueue = queueSong.id == song.id;
              }
            }
            
            final isPlaying = shouldShowAsPlaying && isActuallyPlayingFromQueue;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Track number with play indicator
                  SizedBox(
                    width: 24,
                    child: isPlaying
                        ? const Icon(
                            Icons.volume_up,
                            color: Colors.red,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Use SongItemWidget for consistency
                  Expanded(
                    child: SongItemWidget(
                      song: song,
                      subtitle: song.formattedPlayCount,
                      isCurrentSong: isCurrentSong && isPlayingFromThisAlbum,
                      isPlaying: isPlaying,
                      onTap: () => _playSong(song),
                      contentPadding: EdgeInsets.zero,
                      trailing: isPlaying 
                          ? null
                          : IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildLoadingSongs() {
    return Column(
      children: List.generate(
        6,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const SizedBox(width: 24),
              const SizedBox(width: 16),
              ShimmerImagePlaceholder(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerImagePlaceholder(
                      width: 120,
                      height: 16,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 8),
                    ShimmerImagePlaceholder(
                      width: 80,
                      height: 12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSongsMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.music_off,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada lagu dalam album ini',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Memuat informasi album...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gotham',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Tidak dapat memuat data album',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Album tidak ditemukan',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gotham',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informasi album yang Anda cari tidak tersedia',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.router.maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Kembali', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
