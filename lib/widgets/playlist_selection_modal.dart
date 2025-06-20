import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/pocketbase_service.dart';
import '../repositories/song_playlist_repository.dart';
import '../utils/app_colors.dart';
import '../utils/font_usage_guide.dart';
import 'playlist_image_widget.dart';
import '../providers/favorite_provider.dart';

// Import the provider from mini_player
import 'mini_player.dart' show playlistUpdateNotifierProvider;

class PlaylistSelectionModal extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback? onPlaylistsChanged;

  const PlaylistSelectionModal({
    super.key,
    required this.song,
    this.onPlaylistsChanged,
  });

  @override
  ConsumerState<PlaylistSelectionModal> createState() => _PlaylistSelectionModalState();
}

class _PlaylistSelectionModalState extends ConsumerState<PlaylistSelectionModal> {
  List<Playlist> _playlists = [];
  Map<String, bool> _playlistStates = {};
  bool _isLoading = true;
  bool _isApplyingChanges = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      
      final playlists = await repository.getAllPlaylists();
      
      // Check if song is in favorites - use async method
      final favoriteRepository = ref.read(favoriteRepositoryProvider);
      final isFavorite = await favoriteRepository.isFavorite(widget.song.id);
      
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _playlistStates = {};
          _isFavorite = isFavorite;
          
          // Initialize playlist states
          for (final playlist in playlists) {
            _playlistStates[playlist.id] = playlist.songs.contains(widget.song.id);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to get playlist artwork
  Widget _buildPlaylistArtwork(Playlist playlist) {
    // Convert Playlist to RecordModel-like structure for the unified widget
    // This is a temporary approach until we unify the playlist data models
    final fakeRecord = _createFakeRecordFromPlaylist(playlist);
    
    return PlaylistImageWidget(
      playlist: fakeRecord,
      size: 48,
      borderRadius: 4,
      showMosaicForEmptyPlaylists: true,
    );
  }
  
  // Temporary helper to convert Playlist to RecordModel-like structure
  dynamic _createFakeRecordFromPlaylist(Playlist playlist) {
    return _FakeRecord(
      id: playlist.id,
      data: {
        'name': playlist.name,
        'cover_image': playlist.imageUrl ?? '',
        'songs': playlist.songs,
      },
    );
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

      // Handle favorites change
      final favoriteRepository = ref.read(favoriteRepositoryProvider);
      final originalFavoriteState = await favoriteRepository.isFavorite(widget.song.id);
      if (_isFavorite != originalFavoriteState) {
        hasChanges = true;
        if (_isFavorite) {
          // Add to favorites
          await favoriteRepository.addToFavorites(widget.song.id);
          addedCount++;
        } else {
          // Remove from favorites
          await favoriteRepository.removeFromFavorites(widget.song.id);
          removedCount++;
        }
        
        // Refresh favorites provider after change
        ref.read(favoriteProvider.notifier).loadFavorites();
      }

      for (final playlist in _playlists) {
        final currentState = _playlistStates[playlist.id] ?? false;
        final originalState = playlist.songs.contains(widget.song.id);

        if (currentState != originalState) {
          hasChanges = true;
          if (currentState) {
            // Add song to playlist
            await repository.addSongToPlaylist(playlist.id, widget.song.id);
            addedCount++;
          } else {
            // Remove song from playlist
            await repository.removeSongFromPlaylist(playlist.id, widget.song.id);
            removedCount++;
          }
        }
      }

      if (hasChanges) {
        // Notify playlist update
        ref.read(playlistUpdateNotifierProvider.notifier).notifyPlaylistUpdated();
        widget.onPlaylistsChanged?.call();
        
        // Show success message with proper distinction
        List<String> messages = [];
        
        // Handle favorites message separately
        if (_isFavorite != originalFavoriteState) {
          if (_isFavorite) {
            messages.add('Ditambahkan ke favorit');
          } else {
            messages.add('Dihapus dari favorit');
          }
        }
        
        // Handle playlist changes
        int playlistAdded = 0;
        int playlistRemoved = 0;
        
        for (final playlist in _playlists) {
          final currentState = _playlistStates[playlist.id] ?? false;
          final originalState = playlist.songs.contains(widget.song.id);
          
          if (currentState != originalState) {
            if (currentState) {
              playlistAdded++;
            } else {
              playlistRemoved++;
            }
          }
        }
        
        if (playlistAdded > 0 && playlistRemoved > 0) {
          messages.add('Ditambahkan ke $playlistAdded, dihapus dari $playlistRemoved playlist');
        } else if (playlistAdded > 0) {
          messages.add('Ditambahkan ke $playlistAdded playlist${playlistAdded > 1 ? 's' : ''}');
        } else if (playlistRemoved > 0) {
          messages.add('Dihapus dari $playlistRemoved playlist${playlistRemoved > 1 ? 's' : ''}');
        }
        
        if (mounted && messages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                messages.join(' • '),
                style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error applying changes: $e');
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
              color: AppColors.textSecondary.withValues(alpha: 0.3),
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
                        style: FontUsageGuide.modalTitle.copyWith(
                          fontSize: 20,
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
                        style: FontUsageGuide.modalButton.copyWith(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                ),
              ],
            ),
          ),
          
          // Favorites section
          Container(
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      // Favorites icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red.shade300,
                              Colors.red.shade600,
                              Colors.red.shade800,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      
                      // Favorites info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lagu yang Disukai',
                              style: FontUsageGuide.listSongTitle.copyWith(
                                color: AppColors.text,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Favorit',
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
                            color: _isFavorite 
                              ? AppColors.primary 
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          color: _isFavorite ? AppColors.primary : Colors.transparent,
                        ),
                        child: _isFavorite
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
            ),
          ),
          
          // Divider
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          
          // Recently played section (if playlists exist)
          if (_playlists.isNotEmpty) ...[
            SizedBox(height: 16),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Recently created',
                    style: FontUsageGuide.homeSectionHeader.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No playlists yet',
                          style: FontUsageGuide.emptyStateTitle.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first playlist to save songs',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
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
                                        style: FontUsageGuide.listSongTitle.copyWith(
                                          color: AppColors.text,
                                          fontSize: 16,
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
                                        : AppColors.textSecondary.withValues(alpha: 0.5),
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

// Temporary fake record class to bridge the gap between Playlist and RecordModel
class _FakeRecord {
  final String id;
  final Map<String, dynamic> data;
  
  _FakeRecord({required this.id, required this.data});
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


