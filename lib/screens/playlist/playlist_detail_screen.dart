import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../../utils/app_colors.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/song_playlist_repository.dart';
import '../../models/song.dart';
import '../library/playlist_form_dialog.dart';
import 'add_songs_screen.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/animated_sound_bars.dart';
import '../../widgets/custom_bottom_nav.dart';

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

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _fetchPlaylistSongs();
    _fetchCreatorInfo();
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

      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
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

  void _showEditPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => PlaylistFormDialog(
        playlist: _currentPlaylist,
        onSuccess: () {
          _refreshPlaylist();
          widget.onPlaylistUpdated?.call();
        },
      ),
    );
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

    final username = _creatorUser?.data['username'] as String?;
    final currentUserId = PocketBaseService().currentUser?.id;
    final creatorId = _currentPlaylist.data['user_id'] as String?;
    
    final isCurrentUser = currentUserId == creatorId;
    final displayName = isCurrentUser 
        ? 'kamu' 
        : (username ?? 'Unknown User');

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
            padding: const EdgeInsets.all(40),
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
                  'Tambahkan lagu untuk memulai',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
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
          return _buildSongItem(song, index);
        },
        childCount: _songs.length,
      ),
    );
  }

  Widget _buildSongItem(Song song, int index) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.grey[800],
          child: song.albumArtUrl.isNotEmpty
              ? Image.network(
                  song.albumArtUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.music_note, color: Colors.white);
                  },
                )
              : const Icon(Icons.music_note, color: Colors.white),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isCurrentSong ? Colors.red : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
              trailing: isPlaying
            ? const AnimatedSoundBars(
                color: Colors.red,
                size: 20.0,
                isAnimating: true,
              )
            : null,
      onTap: () {
        _playSong(song, index);
      },
    );
  }
}
