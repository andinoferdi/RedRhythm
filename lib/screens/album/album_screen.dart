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
import '../../utils/app_colors.dart';
import '../../models/playlist.dart';
import '../../repositories/song_playlist_repository.dart';
import '../../widgets/playlist_selection_modal.dart';

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
  late SongPlaylistRepository _playlistRepository;

  Album? _album;
  List<Song> _songs = [];
  bool _isLoadingAlbum = true;
  bool _isLoadingSongs = true;
  String? _errorMessage;

  // Playlist status tracking
  Map<String, bool> _songPlaylistStatus = {};
  bool _isLoadingPlaylistStatus = false;

  // Cache for playlist data to reduce database calls
  static List<Playlist>? _cachedPlaylists;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _albumRepository = AlbumRepository(PocketBaseService());
    _playlistRepository = SongPlaylistRepository(PocketBaseService());
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
        List<Song> songs = [];
        
        try {
          if (album.id.isNotEmpty) {
            songs = await _albumRepository.getAlbumSongs(album.id);
          }
          
          // If no songs found but we have album title, try searching by name
          if (songs.isEmpty && album.title.isNotEmpty) {
            songs = await _albumRepository.getSongsByAlbumName(album.title);
          }
        } catch (songsError) {
          // Don't fail the whole screen if songs can't be loaded
          print('Warning: Could not load songs for album: $songsError');
          
          // Try fallback search by album name
          try {
            if (album.title.isNotEmpty) {
              songs = await _albumRepository.getSongsByAlbumName(album.title);
            }
          } catch (fallbackError) {
            print('Warning: Fallback search also failed: $fallbackError');
            songs = [];
          }
        }

        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });

        // Load playlist status for all songs
        if (songs.isNotEmpty) {
          _checkSongsPlaylistStatus(songs);
        }
      } else {
        setState(() {
          _songs = [];
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

  Future<void> _checkSongsPlaylistStatus(List<Song> songs) async {
    if (songs.isEmpty) return;

    setState(() {
      _isLoadingPlaylistStatus = true;
    });

    try {
      List<Playlist> allPlaylists;

      // Use cache if available and valid
      final now = DateTime.now();
      if (_cachedPlaylists != null &&
          _cacheTimestamp != null &&
          now.difference(_cacheTimestamp!).compareTo(_cacheValidDuration) < 0) {
        allPlaylists = _cachedPlaylists!;
      } else {
        allPlaylists = await _playlistRepository.getAllPlaylists();
        // Update cache
        _cachedPlaylists = allPlaylists;
        _cacheTimestamp = now;
      }

      Map<String, bool> statusMap = {};

      for (final song in songs) {
        bool foundInAnyPlaylist = false;
        for (final playlist in allPlaylists) {
          if (playlist.songs.contains(song.id)) {
            foundInAnyPlaylist = true;
            break;
          }
        }
        statusMap[song.id] = foundInAnyPlaylist;
      }

      if (mounted) {
        setState(() {
          _songPlaylistStatus = statusMap;
          _isLoadingPlaylistStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlaylistStatus = false;
          // Default all to false on error
          for (final song in songs) {
            _songPlaylistStatus[song.id] = false;
          }
        });
      }
    }
  }

  // Clear cache when playlists are modified
  static void _clearPlaylistCache() {
    _cachedPlaylists = null;
    _cacheTimestamp = null;
  }

  Future<void> _showPlaylistModal(BuildContext context, Song song) async {
    await showPlaylistSelectionModal(
      context,
      song,
      onPlaylistsChanged: () {
        // Clear cache to force refresh
        _clearPlaylistCache();
        // Refresh playlist status for all songs
        _checkSongsPlaylistStatus(_songs);
      },
    );
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
      backgroundColor: AppColors.background,
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
        _buildSliverAppBar(),
        SliverToBoxAdapter(child: _buildAlbumInfo()),
        SliverToBoxAdapter(child: _buildAlbumActions()),
        _buildSongsList(),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.router.maybePop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.background,
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              margin: const EdgeInsets.only(top: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: _album!.coverImageUrl ?? '',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    color: const Color(0xFF282828),
                    child: const Center(
                      child: Icon(
                        Icons.album,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _album!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
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
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Album • ${_album!.releaseYear > 0 ? _album!.releaseYear : 'Unknown Year'}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Add to library button
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.white),
              iconSize: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Download button
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download, color: Colors.white),
            iconSize: 24,
          ),
          
          const SizedBox(width: 12),
          
          // More options
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
            iconSize: 24,
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
                iconSize: 24,
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
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_isLoadingSongs) {
      return SliverToBoxAdapter(child: _buildLoadingSongs());
    }

    if (_songs.isEmpty) {
      return SliverToBoxAdapter(child: _buildNoSongsMessage());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _songs[index];

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
              final isInPlaylist = _songPlaylistStatus[song.id] ?? false;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  children: [
                    // Track number or play indicator
                    SizedBox(
                      width: 24,
                      child: isPlaying
                          ? const Icon(
                              Icons.volume_up,
                              color: Colors.red,
                              size: 16,
                            )
                          : Text(
                              song.order > 0 ? '${song.order}' : '${index + 1}',
                              style: TextStyle(
                                color: Colors.grey[400],
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Playlist status indicator
                            if (_isLoadingPlaylistStatus)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => _showPlaylistModal(context, song),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isInPlaylist ? Colors.red : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: isInPlaylist 
                                        ? null 
                                        : Border.all(color: Colors.grey[600]!, width: 1),
                                  ),
                                  child: Icon(
                                    isInPlaylist ? Icons.check : Icons.add,
                                    color: isInPlaylist ? Colors.white : Colors.grey[400],
                                    size: 12,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(width: 8),

                            // More options
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        childCount: _songs.length,
      ),
    );
  }

  Widget _buildLoadingSongs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const SizedBox(width: 16),
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
