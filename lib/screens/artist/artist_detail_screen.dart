import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/pocketbase_service.dart';

import '../../utils/image_helpers.dart';
import '../../controllers/player_controller.dart';
import '../../providers/artist_select_provider.dart';
import '../../widgets/song_item_widget.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/shimmer_widget.dart';
import '../../widgets/custom_bottom_nav.dart';

@RoutePage()
class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String? artistName;
  final int? sourceTabIndex; // 0: Home, 1: Explore, 2: Library

  const ArtistDetailScreen({
    required this.artistId,
    this.artistName,
    this.sourceTabIndex,
    super.key,
  });

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  late ScrollController _scrollController;
  late ArtistRepository _artistRepository;
  late SongRepository _songRepository;

  Artist? _artist;
  List<Song> _songs = [];
  bool _isLoadingArtist = true;
  bool _isLoadingSongs = true;
  String? _errorMessage;
  bool _isFollowing = false;


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _artistRepository = ArtistRepository(PocketBaseService());
    _songRepository = SongRepository(PocketBaseService());
    _loadData();
    
    // Reset shuffle mode when entering artist detail screen (context change)
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
    // If sourceTabIndex is provided, use it
    if (widget.sourceTabIndex != null) {
      return widget.sourceTabIndex!;
    }
    
    // Try to determine from route stack
    final router = context.router;
    final routeStack = router.stack;
    
    // Look for the previous route in the stack
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
          // For nested routes or unknown routes, try to find the root
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
    
    // Default to Home if unable to determine
    return 0;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingArtist = true;
      _isLoadingSongs = true;
      _errorMessage = null;
    });

    try {
      Artist? artist;
      if (widget.artistId.isNotEmpty) {
        artist = await _artistRepository.getArtistById(widget.artistId);
      } else if (widget.artistName != null && widget.artistName!.isNotEmpty) {
        artist = await _artistRepository.getArtistByName(widget.artistName!);
      }

      if (artist == null && widget.artistName != null) {
        artist = Artist(
          id: '',
          name: widget.artistName!,
          bio: 'No biography available for this artist.',
          created: DateTime.now(),
          updated: DateTime.now(),
        );
      }

      final selectedArtists = ref.read(artistSelectProvider);
      final isFollowing = selectedArtists.any((artistSelect) =>
          artistSelect.artistId == artist?.id ||
          artistSelect.artistName == artist?.name);

      setState(() {
        _artist = artist;
        _isLoadingArtist = false;
        _isFollowing = isFollowing;
      });

      if (artist != null) {
        List<Song> songs;
        if (artist.id.isNotEmpty) {
          songs = await _songRepository.getSongsByArtist(artist.id);
        } else {
          songs = await _songRepository.getSongsByArtistName(artist.name);
        }

        // Sort songs by play_count (highest to lowest) for popularity order
        songs.sort((a, b) => b.playCount.compareTo(a.playCount));

        setState(() {
          _songs = songs;
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load artist data: $e';
        _isLoadingArtist = false;
        _isLoadingSongs = false;
      });
    }
  }

  Future<void> _toggleFollowArtist() async {
    if (_artist == null) return;

    try {
      if (_isFollowing) {
        final success = await ref
            .read(artistSelectProvider.notifier)
            .removeArtistSelection(_artist!.id);

        if (mounted && success) {
          setState(() {
            _isFollowing = false;
          });
          
          // Show unfollow notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Telah berhenti mengikuti "${_artist!.name}"',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
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
        final success = await ref
            .read(artistSelectProvider.notifier)
            .addArtistSelection(_artist!.id);

        if (mounted && success) {
          setState(() {
            _isFollowing = true;
          });
          
          // Show follow notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kini mengikuti "${_artist!.name}"',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
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
      // Show error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing 
                  ? 'Gagal berhenti mengikuti artis: $e'
                  : 'Gagal mengikuti artis: $e'
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
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
      // Use original order (already sorted by popularity)
      playQueue = List<Song>.from(_songs);
      startIndex = _songs.indexOf(song);
    }

    ref.read(playerControllerProvider.notifier).playQueueFromArtist(
      playQueue,
      startIndex,
      _artist!.id,
    );
  }

  void _playAllSongs() {
    if (_songs.isEmpty) return;
    
    final playerState = ref.read(playerControllerProvider);
    final currentArtistId = playerState.currentArtistId;
    
    // If currently playing from this artist, pause/resume
    if (currentArtistId == _artist?.id) {
      if (playerState.isPlaying) {
        // Pause current playback
        ref.read(playerControllerProvider.notifier).pause();
      } else {
        // Resume current playback
        ref.read(playerControllerProvider.notifier).resume();
      }
    } else {
      // Prepare queue based on shuffle setting
      List<Song> playQueue;
      int startIndex;

      if (playerState.shuffleMode) {
        // Create shuffled queue
        playQueue = List<Song>.from(_songs);
        playQueue.shuffle();
        startIndex = 0;
      } else {
        // Use original order (sorted by popularity)
        playQueue = List<Song>.from(_songs);
        startIndex = 0;
      }

      // Start playing with prepared queue
      ref.read(playerControllerProvider.notifier).playQueueFromArtist(
        playQueue,
        startIndex,
        _artist!.id,
      );
    }
  }

  /// Toggle shuffle mode
  void _toggleShuffle() {
    final playerState = ref.read(playerControllerProvider);
    
    // Only allow shuffle toggle if playing from this artist or no artist context
    if (playerState.currentArtistId == null || playerState.currentArtistId == _artist?.id) {
      ref.read(playerControllerProvider.notifier).toggleShuffle();
      
      // If currently playing from this artist, update the queue accordingly
      if (playerState.currentArtistId == _artist?.id && playerState.currentSong != null) {
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
      // Restore original order (sorted by popularity)
      newQueue = List.from(_songs);
      newIndex = currentIndex;
    }

    // Update player queue
    ref.read(playerControllerProvider.notifier).updateQueue(newQueue, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    
    // Calculate bottom padding for mini player and bottom nav
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Spotify dark background
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

    if (_isLoadingArtist) {
      return _buildLoadingState();
    }

    if (_artist == null) {
      return _buildArtistNotFoundState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildArtistHeader(),
        SliverToBoxAdapter(child: _buildArtistActions()),
        SliverToBoxAdapter(child: _buildPopularSongsSection()),
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



  Widget _buildArtistHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: false,
      floating: false,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Artist image
            ImageHelpers.buildSafeNetworkImage(
              imageUrl: _artist!.imageUrl,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover, // Fill the entire area
              fallbackWidget: Container(
                color: const Color(0xFF282828),
                child: Center(
                  child: Text(
                    _artist!.name.isNotEmpty
                        ? _artist!.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                    ),
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

            // Artist name and stats
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _artist!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Gotham',
                      letterSpacing: 0.8,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '9,2 jt pendengar bulanan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Gotham',
                      letterSpacing: 0.3,
                      height: 1.2,
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

  Widget _buildArtistActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Follow button
          Consumer(
            builder: (context, ref, child) {
              final selectedArtists = ref.watch(artistSelectProvider);
              final isFollowing = selectedArtists.any((artistSelect) =>
                  artistSelect.artistId == _artist?.id ||
                  artistSelect.artistName == _artist?.name);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: _toggleFollowArtist,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: Text(
                    isFollowing ? 'Mengikuti' : 'Ikuti',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gotham',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              );
            },
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
              final isPlayingFromThisArtist = playerState.currentArtistId == _artist?.id;
              final isPlaying = isPlayingFromThisArtist && playerState.isPlaying;
              
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.red, // Red color like playlist
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





  Widget _buildPopularSongsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Populer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Gotham',
              letterSpacing: 0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
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
    final displaySongs = _songs.length > 5 ? _songs.sublist(0, 5) : _songs;

    return Column(
      children: displaySongs.asMap().entries.map((entry) {
        final index = entry.key;
        final song = entry.value;

        return Consumer(
          builder: (context, ref, child) {
            final playerState = ref.watch(playerControllerProvider);
            final currentArtistId = playerState.currentArtistId;
            
            // STRICT CHECKING: Only show as "playing" if:
            // 1. Song is currently playing
            // 2. CurrentArtistId matches THIS artist (not null)
            // 3. Song is in current queue at correct position
            
            final isCurrentSong = playerState.currentSong?.id == song.id;
            final isPlayingFromThisArtist = currentArtistId != null && 
                                           currentArtistId == _artist?.id;
            
            // CRITICAL: Only show as playing if song is playing FROM THIS ARTIST
            // If currentArtistId is null OR different from this artist, don't show as playing
            
            final shouldShowAsPlaying = isCurrentSong && 
                                      isPlayingFromThisArtist && 
                                      playerState.isPlaying;
            
            // Additional validation: Check queue position to prevent race conditions
            bool isActuallyPlayingFromQueue = false;
            if (shouldShowAsPlaying && playerState.queue.isNotEmpty) {
              final currentIndex = playerState.currentIndex;
              if (currentIndex >= 0 && currentIndex < playerState.queue.length) {
                final queueSong = playerState.queue[currentIndex];
                isActuallyPlayingFromQueue = queueSong.id == song.id;
              }
            }
            
            // FINAL CHECK: All conditions must be true
            final isPlaying = shouldShowAsPlaying && isActuallyPlayingFromQueue;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Song number with play indicator
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
                      isCurrentSong: isCurrentSong && isPlayingFromThisArtist,
                      isPlaying: isPlaying,
                      onTap: () => _playSong(song),
                      contentPadding: EdgeInsets.zero,
                      trailing: isPlaying 
                          ? null // AnimatedSoundBars will be shown by SongItemWidget
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
        5,
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
              'Tidak ada lagu dari ${_artist!.name}',
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
          CircularProgressIndicator(
            color: Color(0xFF1DB954),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat informasi artist...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
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
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Tidak dapat memuat data artist',
              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: 'Gotham',),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Artist tidak ditemukan',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gotham',
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informasi artist yang Anda cari tidak tersedia',
              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: 'Gotham',),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.router.maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


