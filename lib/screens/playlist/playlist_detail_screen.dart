import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../../utils/app_colors.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/song_playlist_repository.dart';
import '../../models/song.dart';

import 'add_songs_screen.dart';
import 'edit_playlist_screen.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/mini_player.dart';

import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/song_item_widget.dart';

@RoutePage()
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final RecordModel playlist;
  final VoidCallback? onPlaylistUpdated;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    this.onPlaylistUpdated,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  bool _isLoading = true;
  List<Song> _songs = [];
  String? _errorMessage;
  late RecordModel _currentPlaylist;
  RecordModel? _creatorUser;
  bool _isLoadingCreator = true;
  
  // Recommended songs
  List<Song> _recommendedSongs = [];
  bool _isLoadingRecommended = false;
  final Set<String> _addingSongIds = {};

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _fetchPlaylistSongs();
    _fetchCreatorInfo();
    _fetchRecommendedSongs();
  }

  Future<void> _fetchPlaylistSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final repository = SongPlaylistRepository(pbService);
      final songs = await repository.getPlaylistSongs(_currentPlaylist.id);

      debugPrint('Fetched ${songs.length} playlist songs');
      for (final song in songs.take(3)) {
        debugPrint('Playlist Song: ${song.title} by ${song.artist}, Album Art: ${song.albumArtUrl}');
      }

      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching playlist songs: $e');
      setState(() {
        _errorMessage = 'Failed to load songs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCreatorInfo() async {
    try {
      final pbService = PocketBaseService();
      await pbService.initialize();

      final creatorId = _currentPlaylist.data['user_id'] as String?;
      if (creatorId != null && creatorId.isNotEmpty) {
        final creator = await pbService.pb.collection('users').getOne(creatorId);
        setState(() {
          _creatorUser = creator;
          _isLoadingCreator = false;
        });
      } else {
        setState(() {
          _isLoadingCreator = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCreator = false;
      });
    }
  }

  Future<void> _fetchRecommendedSongs() async {
    setState(() {
      _isLoadingRecommended = true;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      // Get all songs from database with expanded artist and album data
      final allSongsResult = await pbService.pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        sort: '@random', // Random sort for variety
        expand: 'artist_id,album_id', // Expand artist and album relations
      );
      
      // Convert to Song objects and filter out songs already in playlist
      final currentSongIds = _songs.map((song) => song.id).toSet();
      final allSongs = allSongsResult.items.map((record) => Song.fromRecord(record)).toList();
      final filteredSongs = _songs.isEmpty 
          ? allSongs // If playlist is empty, show all songs
          : allSongs.where((song) => !currentSongIds.contains(song.id)).toList();
      
      // Take first 10 songs as recommendations
      final recommended = filteredSongs.take(10).toList();

      debugPrint('Fetched ${recommended.length} recommended songs');
      for (final song in recommended.take(3)) {
        debugPrint('Song: ${song.title} by ${song.artist}, Album Art: ${song.albumArtUrl}');
      }

      setState(() {
        _recommendedSongs = recommended;
        _isLoadingRecommended = false;
      });
    } catch (e) {
      debugPrint('Error fetching recommended songs: $e');
      setState(() {
        _recommendedSongs = [];
        _isLoadingRecommended = false;
      });
    }
  }

  void _showEditPlaylistDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlaylistScreen(playlist: _currentPlaylist),
      ),
    );
    
    // If changes were made, refresh the playlist
    if (result == true) {
      _refreshPlaylist();
      widget.onPlaylistUpdated?.call();
    }
  }

  Future<void> _refreshPlaylist() async {
    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final updatedPlaylist = await pbService.pb
          .collection('playlists')
          .getOne(_currentPlaylist.id);
      
      setState(() {
        _currentPlaylist = updatedPlaylist;
      });
      
      // Also refresh the songs list to reflect any changes
      await _fetchPlaylistSongs();
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  Future<void> _navigateToAddSongs() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddSongsScreen(playlist: _currentPlaylist),
      ),
    );

    // If songs were added successfully, refresh the playlist
    if (result == true) {
      _fetchPlaylistSongs();
      _fetchRecommendedSongs(); // Refresh recommendations too
    }
  }

  Future<void> _addSongToPlaylist(Song song) async {
    setState(() {
      _addingSongIds.add(song.id);
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final repository = SongPlaylistRepository(pbService);
      await repository.addSongToPlaylist(
        playlistId: _currentPlaylist.id,
        songId: song.id,
      );

      // Refresh playlist songs and recommendations
      await _fetchPlaylistSongs();
      await _fetchRecommendedSongs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${song.title} berhasil ditambahkan',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan lagu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _addingSongIds.remove(song.id);
      });
    }
  }

  /// Play song (show in mini player, don't navigate)
void _playSong(Song song, int index) {
  // Set up queue with all playlist songs
  ref.read(playerControllerProvider.notifier).playQueue(_songs, index);
}

  /// Play all songs in playlist starting from first
void _playAllSongs() {
  if (_songs.isEmpty) return;
  
  final playerState = ref.read(playerControllerProvider);
  final isPlaylistPlaying = _songs.any((song) => song.id == playerState.currentSong?.id);
  
  if (isPlaylistPlaying && playerState.isPlaying) {
    // Pause current playback
    ref.read(playerControllerProvider.notifier).pause();
  } else if (isPlaylistPlaying && !playerState.isPlaying) {
    // Resume current playback
    ref.read(playerControllerProvider.notifier).resume();
  } else {
    // Start playing from first song
    ref.read(playerControllerProvider.notifier).playQueue(_songs, 0);
  }
}

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildPlaylistInfo(),
                ),
                SliverToBoxAdapter(
                  child: _buildPlayButton(),
                ),
                _buildSongsList(),
                // Recommended songs section
                SliverToBoxAdapter(
                  child: _buildRecommendedSongsSection(),
                ),
                // Add bottom spacing for navigation bar and mini player
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 70 + bottomPadding + (playerState.currentSong != null ? 64 : 0),
                  ),
                ),
              ],
            ),
          ),
          // Show mini player if there's a current song
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Library tab index
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final pbService = PocketBaseService();
    final repository = PlaylistRepository(pbService);
    final String imageUrl = repository.getCoverImageUrl(_currentPlaylist);

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              margin: const EdgeInsets.only(top: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.queue_music,
        color: Colors.white,
        size: 80,
      ),
    );
  }

  Widget _buildCreatorAvatar() {
    if (_isLoadingCreator) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey[700],
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    final avatarUrl = _creatorUser?.data['avatar'] as String?;
    final pbService = PocketBaseService();
    
    if (avatarUrl != null && avatarUrl.isNotEmpty && _creatorUser != null) {
      final imageUrl = pbService.pb.files.getUrl(_creatorUser!, avatarUrl).toString();
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to default avatar
        },
        child: null,
      );
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey[700],
      child: const Icon(
        Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCreatorText() {
    if (_isLoadingCreator) {
      return Text(
        'Loading...',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Get the creator's name from the user record
    final name = _creatorUser?.data['name'] as String?;
    final username = _creatorUser?.data['username'] as String?;
    
    // Use 'name' field first, fallback to 'username', then 'Unknown User'
    final displayName = name?.isNotEmpty == true 
        ? name!
        : (username?.isNotEmpty == true ? username! : 'Unknown User');

    return Text(
      'Dibuat oleh $displayName',
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentPlaylist.data['name'] ?? 'Playlist Tanpa Judul',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showEditPlaylistDialog,
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentPlaylist.data['description']?.isNotEmpty == true) ...[
            Text(
              _currentPlaylist.data['description'],
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _buildCreatorAvatar(),
              const SizedBox(width: 8),
              _buildCreatorText(),
              const SizedBox(width: 16),
              Text(
                '${_songs.length} lagu',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    final playerState = ref.watch(playerControllerProvider);
    final isPlaylistPlaying = _songs.any((song) => song.id == playerState.currentSong?.id);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Flexible(
            child: ElevatedButton.icon(
              onPressed: _songs.isNotEmpty ? _playAllSongs : null,
              icon: Icon(
                isPlaylistPlaying && playerState.isPlaying 
                    ? Icons.pause 
                    : Icons.play_arrow, 
                color: Colors.white,
              ),
              label: Text(
                isPlaylistPlaying && playerState.isPlaying ? 'Jeda' : 'Putar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              // TODO: Implement shuffle functionality
            },
            icon: const Icon(Icons.shuffle, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.all(12),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _navigateToAddSongs,
            icon: const Icon(Icons.add, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Colors.red),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchPlaylistSongs,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Playlist masih kosong',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan lagu untuk memulai atau pilih dari rekomendasi di bawah',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToAddSongs,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Tambah Lagu',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _songs[index];
          return SongItemWidget(
            song: song,
            subtitle: song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            onTap: () {
              _playSong(song, index);
            },
          );
        },
        childCount: _songs.length,
      ),
    );
  }

  Widget _buildRecommendedSongsSection() {
    // Always show recommendations, especially when playlist is empty
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        // Header with title and reload button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Lagu yang Direkomendasikan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Reload button
              ElevatedButton.icon(
                onPressed: _isLoadingRecommended ? null : _fetchRecommendedSongs,
                icon: _isLoadingRecommended
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.black, size: 18),
                label: const Text(
                  'Muat ulang',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Recommended songs list
        _buildRecommendedSongsList(),
      ],
    );
  }

  Widget _buildRecommendedSongsList() {
    if (_isLoadingRecommended) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (_recommendedSongs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.music_note,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada rekomendasi tersedia',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recommendedSongs.map((song) => _buildRecommendedSongItem(song)).toList(),
    );
  }

  Widget _buildRecommendedSongItem(Song song) {
    final isAdding = _addingSongIds.contains(song.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: SongItemWidget(
        song: song,
        subtitle: song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
        contentPadding: const EdgeInsets.symmetric(vertical: 4),

        trailing: isAdding
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : IconButton(
                onPressed: () => _addSongToPlaylist(song),
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                ),
              ),
        onTap: () {
          // Play the recommended song
          ref.read(playerControllerProvider.notifier).playSong(song);
        },
      ),
    );
  }
}
