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
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _artistRepository = ArtistRepository(PocketBaseService());
    _songRepository = SongRepository(PocketBaseService());

    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Calculate header opacity based on scroll position
    final scrollPosition = _scrollController.position.pixels;
    final maxScroll = 200.0; // Threshold for full opacity

    setState(() {
      _headerOpacity = (scrollPosition / maxScroll).clamp(0.0, 1.0);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingArtist = true;
      _isLoadingSongs = true;
      _errorMessage = null;
    });

    try {
      // Load artist data
      Artist? artist;
      if (widget.artistId.isNotEmpty) {
        artist = await _artistRepository.getArtistById(widget.artistId);
      } else if (widget.artistName != null && widget.artistName!.isNotEmpty) {
        artist = await _artistRepository.getArtistByName(widget.artistName!);
      }

      if (artist == null && widget.artistName != null) {
        // Create a placeholder artist if we only have the name
        artist = Artist(
          id: '',
          name: widget.artistName!,
          bio: 'No biography available for this artist.',
          created: DateTime.now(),
          updated: DateTime.now(),
        );
      }

      // Check if user is following this artist
      final selectedArtists = ref.read(artistSelectProvider);
      final isFollowing = selectedArtists.any((artistSelect) =>
          artistSelect.artistId == artist?.id ||
          artistSelect.artistName == artist?.name);

      setState(() {
        _artist = artist;
        _isLoadingArtist = false;
        _isFollowing = isFollowing;
      });

      // Load songs by artist
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
        // Unfollow artist
        final success = await ref
            .read(artistSelectProvider.notifier)
            .removeArtistSelection(_artist!.id);

        if (mounted && success) {
          setState(() {
            _isFollowing = false;
          });

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // Follow artist
        final success = await ref
            .read(artistSelectProvider.notifier)
            .addArtistSelection(_artist!.id);

        if (mounted && success) {
          setState(() {
            _isFollowing = true;
          });

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing
                ? 'Gagal berhenti mengikuti artis: $e'
                : 'Gagal mengikuti artis: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _playSong(Song song) {
    // Play the selected song
    ref.read(playerControllerProvider.notifier).playSong(song);
  }

  void _playAllSongs() {
    if (_songs.isEmpty) return;

    // Play first song and set up queue with shuffle enabled
    ref.read(playerControllerProvider.notifier).playSong(_songs[0]);
    // Enable shuffle to play all songs randomly
    ref.read(playerControllerProvider.notifier).toggleShuffle();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          _buildMainContent(),

          // Floating header that appears when scrolling
          _buildFloatingHeader(),

          // Mini player at bottom if a song is playing
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
        // Artist header with image
        _buildArtistHeader(),

        // Artist stats and actions
        SliverToBoxAdapter(
          child: _buildArtistActions(),
        ),

        // Popular songs section
        SliverToBoxAdapter(
          child: _buildPopularSongsSection(),
        ),

        // About section
        SliverToBoxAdapter(
          child: _buildAboutSection(),
        ),

        // Bottom padding for mini player
        SliverToBoxAdapter(
          child: SizedBox(
              height: ref.watch(playerControllerProvider).currentSong != null
                  ? 80
                  : 20),
        ),
      ],
    );
  }

  Widget _buildFloatingHeader() {
    if (_artist == null) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _headerOpacity,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: MediaQuery.of(context).padding.top + 56,
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              if (_headerOpacity > 0.1)
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.router.pop(),
                ),
                Expanded(
                  child: Text(
                    _artist!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DM Sans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // Show more options
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistHeader() {
    return SliverAppBar(
      expandedHeight: 300,
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
              height: 300,
              fit: BoxFit.cover,
              fallbackWidget: Container(
                color: AppColors.greyDark,
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

            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            // Back button and more options
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.router.pop(),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {
                          // Show more options
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Artist name at bottom
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
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DM Sans',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '9,3 jt pendengar bulanan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontFamily: 'DM Sans',
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Follow/Unfollow button
          GestureDetector(
            onTap: _toggleFollowArtist,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isFollowing ? Colors.white : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
                color: _isFollowing ? Colors.transparent : Colors.white,
              ),
              child: Text(
                _isFollowing ? 'Mengikuti' : 'Ikuti',
                style: TextStyle(
                  color: _isFollowing ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Shuffle play button
          Expanded(
            child: GestureDetector(
              onTap: _playAllSongs,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shuffle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Acak Putar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSongsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Populer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
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

  Widget _buildLoadingSongs() {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
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
                fontFamily: 'DM Sans',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList() {
    // Limit to top 5 songs for popular section
    final displaySongs = _songs.length > 5 ? _songs.sublist(0, 5) : _songs;

    return Column(
      children: displaySongs.asMap().entries.map((entry) {
        final index = entry.key;
        final song = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Song number
              SizedBox(
                width: 30,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'DM Sans',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              // Song item
              Expanded(
                child: SongItemWidget(
                  song: song,
                  subtitle: song.albumName,
                  onTap: () => _playSong(song),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
          const SizedBox(height: 16),

          // Artist bio
          Text(
            _artist!.bio.isNotEmpty
                ? _artist!.bio
                : 'Tidak ada informasi biografi untuk ${_artist!.name}.',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.5,
              fontFamily: 'DM Sans',
            ),
          ),

          const SizedBox(height: 20),

          // Artist stats
          Row(
            children: [
              _buildStatItem(
                '9,3 jt',
                'Pendengar Bulanan',
              ),
              const SizedBox(width: 40),
              _buildStatItem(
                '${_songs.length}',
                'Lagu',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontFamily: 'DM Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat informasi artist...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontFamily: 'DM Sans',
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
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Tidak dapat memuat data artist',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'DM Sans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                  fontFamily: 'DM Sans',
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
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informasi artist yang Anda cari tidak tersedia',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'DM Sans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.router.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                  fontFamily: 'DM Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
