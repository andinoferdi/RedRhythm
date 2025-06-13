import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/pocketbase_service.dart';
import '../repositories/song_playlist_repository.dart';
import '../utils/app_colors.dart';

// Import the provider from mini_player
import 'mini_player.dart' show playlistUpdateNotifierProvider;

class PlaylistSelectionModal extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback? onPlaylistsChanged;

  const PlaylistSelectionModal({
    Key? key,
    required this.song,
    this.onPlaylistsChanged,
  }) : super(key: key);

  @override
  ConsumerState<PlaylistSelectionModal> createState() => _PlaylistSelectionModalState();
}

class _PlaylistSelectionModalState extends ConsumerState<PlaylistSelectionModal> {
  List<Playlist> _playlists = [];
  Map<String, bool> _playlistStates = {};
  bool _isLoading = true;
  bool _isApplyingChanges = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      debugPrint('🎵 PLAYLIST_MODAL: Loading playlists for song: ${widget.song.title}');
      
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      
      final playlists = await repository.getAllPlaylists();
      debugPrint('🎵 PLAYLIST_MODAL: Loaded ${playlists.length} playlists');
      
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _playlistStates = {};
          
          // Initialize playlist states
          for (final playlist in playlists) {
            _playlistStates[playlist.id] = playlist.songs.contains(widget.song.id);
            debugPrint('🎵 PLAYLIST_MODAL: Playlist "${playlist.name}" contains song: ${_playlistStates[playlist.id]}');
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🎵 PLAYLIST_MODAL: Error loading playlists: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load playlists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to get playlist artwork
  Widget _buildPlaylistArtwork(Playlist playlist) {
    // If playlist has custom image, use it
    if (playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: NetworkImage(playlist.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    
    // If playlist has songs, create a mosaic from album covers
    if (playlist.songs.isNotEmpty) {
      return FutureBuilder<List<Song>>(
        future: _getPlaylistSongs(playlist.id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final songs = snapshot.data!;
            return _buildMosaicArtwork(songs);
          }
          
          // Loading state - show placeholder
          return _buildPlaceholderArtwork();
        },
      );
    }
    
    // Fallback to default playlist icon for empty playlists
    return _buildPlaceholderArtwork();
  }

  // Build mosaic artwork from multiple album covers
  Widget _buildMosaicArtwork(List<Song> songs) {
    if (songs.isEmpty) {
      return _buildPlaceholderArtwork();
    }

    // Get unique album covers (max 4)
    final Set<String> uniqueCovers = {};
    final List<String> albumCovers = [];
    
    for (final song in songs) {
      if (song.albumArtUrl.isNotEmpty && !uniqueCovers.contains(song.albumArtUrl)) {
        uniqueCovers.add(song.albumArtUrl);
        albumCovers.add(song.albumArtUrl);
        if (albumCovers.length >= 4) break;
      }
    }

    if (albumCovers.isEmpty) {
      return _buildPlaceholderArtwork();
    }

    // Logic for displaying artwork:
    // - If only 1 unique album OR playlist has 3 or fewer songs: show single cover
    // - If 2-4 unique albums AND more than 3 songs: show grid
    if (albumCovers.length == 1 || songs.length <= 3) {
      return _buildSingleCover(albumCovers[0]);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _buildGridCover(albumCovers),
      ),
    );
  }

  // Single album cover
  Widget _buildSingleCover(String imageUrl) {
    return Image.network(
      imageUrl,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderArtwork(),
    );
  }

  // Grid of multiple album covers (2x2 or 1x2 depending on count)
  Widget _buildGridCover(List<String> imageUrls) {
    if (imageUrls.length == 2) {
      // 1x2 grid
      return Row(
        children: [
          Expanded(
            child: Image.network(
              imageUrls[0],
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
            ),
          ),
          Expanded(
            child: Image.network(
              imageUrls[1],
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
            ),
          ),
        ],
      );
    } else {
      // 2x2 grid for 3 or 4 images
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Image.network(
                    imageUrls[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.textSecondary.withOpacity(0.2),
                    ),
                  ),
                ),
                Expanded(
                  child: Image.network(
                    imageUrls[1],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.textSecondary.withOpacity(0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: imageUrls.length > 2
                      ? Image.network(
                          imageUrls[2],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.textSecondary.withOpacity(0.2),
                          ),
                        )
                      : Container(
                          color: AppColors.textSecondary.withOpacity(0.2),
                        ),
                ),
                Expanded(
                  child: imageUrls.length > 3
                      ? Image.network(
                          imageUrls[3],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.textSecondary.withOpacity(0.2),
                          ),
                        )
                      : Container(
                          color: AppColors.textSecondary.withOpacity(0.2),
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Placeholder artwork
  Widget _buildPlaceholderArtwork() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.queue_music,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  // Cache for playlist songs to avoid repeated API calls
  final Map<String, List<Song>> _playlistSongsCache = {};

  Future<List<Song>> _getPlaylistSongs(String playlistId) async {
    // Check cache first
    if (_playlistSongsCache.containsKey(playlistId)) {
      return _playlistSongsCache[playlistId]!;
    }

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      
      final songs = await repository.getPlaylistSongs(playlistId);
      
      // Cache the result
      _playlistSongsCache[playlistId] = songs;
      
      return songs;
    } catch (e) {
      debugPrint('🎵 PLAYLIST_MODAL: Error getting songs for playlist $playlistId: $e');
      _playlistSongsCache[playlistId] = [];
      return [];
    }
  }

  Future<void> _createNewPlaylist() async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Create New Playlist',
          style: TextStyle(color: AppColors.text),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: Text(
              'Create',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final pbService = PocketBaseService();
        await pbService.initialize();
        final repository = SongPlaylistRepository(pbService);
        
        // Create playlist with current user
        final userId = pbService.currentUser?.id ?? '';
        final newPlaylist = await repository.createPlaylist(result, userId);
        
        // Add song to the new playlist
        await repository.addSongToPlaylist(newPlaylist.id, widget.song.id);
        
        // Reload playlists to show the new one
        await _loadPlaylists();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playlist "$result" created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('🎵 PLAYLIST_MODAL: Error creating playlist: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create playlist'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _applyChanges() async {
    if (_isApplyingChanges) return;
    
    setState(() {
      _isApplyingChanges = true;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);

      bool hasChanges = false;
      int addedCount = 0;
      int removedCount = 0;

      for (final playlist in _playlists) {
        final currentState = _playlistStates[playlist.id] ?? false;
        final originalState = playlist.songs.contains(widget.song.id);

        if (currentState != originalState) {
          hasChanges = true;
          if (currentState) {
            // Add song to playlist
            debugPrint('🎵 PLAYLIST_MODAL: Adding song to playlist "${playlist.name}"');
            await repository.addSongToPlaylist(playlist.id, widget.song.id);
            addedCount++;
          } else {
            // Remove song from playlist
            debugPrint('🎵 PLAYLIST_MODAL: Removing song from playlist "${playlist.name}"');
            await repository.removeSongFromPlaylist(playlist.id, widget.song.id);
            removedCount++;
          }
        }
      }

      if (hasChanges) {
        // Notify playlist update
        ref.read(playlistUpdateNotifierProvider.notifier).notifyPlaylistUpdated();
        widget.onPlaylistsChanged?.call();
        
        // Show success message
        String message = '';
        if (addedCount > 0 && removedCount > 0) {
          message = 'Added to $addedCount, removed from $removedCount playlists';
        } else if (addedCount > 0) {
          message = 'Added to $addedCount playlist${addedCount > 1 ? 's' : ''}';
        } else if (removedCount > 0) {
          message = 'Removed from $removedCount playlist${removedCount > 1 ? 's' : ''}';
        }

        if (mounted && message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('🎵 PLAYLIST_MODAL: Error applying changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingChanges = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.text,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 16),
                
                // Title and song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to playlist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.song.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Done button
                TextButton(
                  onPressed: _isApplyingChanges ? null : _applyChanges,
                  child: _isApplyingChanges
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ],
            ),
          ),
          
          // Create new playlist button
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _createNewPlaylist,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Create playlist',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Divider
          if (_playlists.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              height: 1,
              color: AppColors.textSecondary.withOpacity(0.2),
            ),
            
            // Recently played section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Recently created',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: Show all playlists or sort options
                    },
                    child: Text(
                      'Show all',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Playlist list
          Expanded(
            child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : _playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No playlists yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first playlist to save songs',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = _playlists[index];
                      final isSelected = _playlistStates[playlist.id] ?? false;
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _playlistStates[playlist.id] = !isSelected;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                // Playlist artwork
                                _buildPlaylistArtwork(playlist),
                                SizedBox(width: 16),
                                
                                // Playlist info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        playlist.name,
                                        style: TextStyle(
                                          color: AppColors.text,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '${playlist.songs.length} song${playlist.songs.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Checkbox
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                        ? AppColors.primary 
                                        : AppColors.textSecondary.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                  child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the modal
Future<void> showPlaylistSelectionModal(
  BuildContext context,
  Song song, {
  VoidCallback? onPlaylistsChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PlaylistSelectionModal(
      song: song,
      onPlaylistsChanged: onPlaylistsChanged,
    ),
  );
} 