import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helpers.dart';
import '../../controllers/player_controller.dart';
import '../../providers/artist_select_provider.dart';
import '../../widgets/song_item_widget.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/shimmer_widget.dart';

@RoutePage()
class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String? artistName;

  const ArtistDetailScreen({
    required this.artistId,
    this.artistName,
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
  String _selectedTab = 'Musik';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _artistRepository = ArtistRepository(PocketBaseService());
    _songRepository = SongRepository(PocketBaseService());
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                        fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w500,
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
    
    final songIndex = _songs.indexWhere((s) => s.id == song.id);
    if (songIndex == -1) return;
    
    // Play queue from artist context - exactly like playlist
    ref.read(playerControllerProvider.notifier).playQueueFromArtist(
      _songs,
      songIndex,
      _artist!.id, // Use artist ID as context
    );
  }

  void _playAllSongs() {
    if (_songs.isEmpty) return;
    
    // Play first song from artist context
    ref.read(playerControllerProvider.notifier).playQueueFromArtist(
      _songs,
      0,
      _artist!.id,
    );
  }

  void _shuffleAllSongs() {
    if (_songs.isEmpty) return;
    
    // Shuffle and play from artist context
    final shuffledSongs = List<Song>.from(_songs)..shuffle();
    ref.read(playerControllerProvider.notifier).playQueueFromArtist(
      shuffledSongs,
      0,
      _artist!.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);

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
        SliverToBoxAdapter(child: _buildNewReleaseSection()),
        SliverToBoxAdapter(child: _buildTabNavigation()),
        SliverToBoxAdapter(child: _buildPopularSongsSection()),
        SliverToBoxAdapter(
          child: SizedBox(
            height: ref.watch(playerControllerProvider).currentSong != null
                ? 80
                : 20,
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
                      fontWeight: FontWeight.bold,
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
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
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
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.router.pop(),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
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
                      fontSize: 48,
                      fontWeight: FontWeight.w900, // Extra bold
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '9,2 jt pendengar bulanan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
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
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
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
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DM Sans',
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
              final isPlayingFromThisArtist = playerState.currentArtistId == _artist?.id;
              final hasShuffleMode = isPlayingFromThisArtist && playerState.shuffleMode;
              
              return IconButton(
                onPressed: _songs.isNotEmpty ? _shuffleAllSongs : null,
                icon: Icon(
                  Icons.shuffle, 
                  color: hasShuffleMode ? Colors.red : Colors.white, 
                  size: 28
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Play button
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1DB954), // Spotify green
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _playAllSongs,
              icon: const Icon(
                Icons.play_arrow,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewReleaseSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  '🎵',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Dengarkan rilis baru',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: ['Musik', 'Clips', 'Event'].map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 32),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Column(
                children: [
                  Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 20,
                    color: isSelected
                        ? const Color(0xFF1DB954)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
              fontWeight: FontWeight.bold,
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
                              fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Tidak dapat memuat data artist',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informasi artist yang Anda cari tidak tersedia',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.router.pop(),
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
