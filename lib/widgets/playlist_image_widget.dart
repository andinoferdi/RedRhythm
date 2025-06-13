import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/song.dart';
import '../services/pocketbase_service.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/song_playlist_repository.dart';
import '../utils/app_colors.dart';

/// A unified widget for displaying playlist images consistently across the app
class PlaylistImageWidget extends StatefulWidget {
  final dynamic playlist; // Support both RecordModel and fake records
  final double size;
  final double borderRadius;
  final bool showMosaicForEmptyPlaylists;
  
  const PlaylistImageWidget({
    super.key,
    required this.playlist,
    this.size = 48.0,
    this.borderRadius = 4.0,
    this.showMosaicForEmptyPlaylists = false,
  });

  // Cache for playlist songs to avoid repeated API calls
  static final Map<String, List<Song>> _playlistSongsCache = {};

  /// Clear the cache for a specific playlist (useful when playlist is updated)
  static void clearCache(String playlistId) {
    _playlistSongsCache.remove(playlistId);
  }

  /// Clear all cached playlist data
  static void clearAllCache() {
    _playlistSongsCache.clear();
  }

  @override
  State<PlaylistImageWidget> createState() => _PlaylistImageWidgetState();
}

class _PlaylistImageWidgetState extends State<PlaylistImageWidget> {
  List<Song>? _songs;
  bool _isLoading = false;
  String? _currentPlaylistId;
  
  @override
  void initState() {
    super.initState();
    _currentPlaylistId = widget.playlist.id;
    _loadPlaylistSongs();
  }

  @override
  void didUpdateWidget(PlaylistImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if playlist ID changed
    if (oldWidget.playlist.id != widget.playlist.id) {
      _currentPlaylistId = widget.playlist.id;
      _loadPlaylistSongs();
    }
  }

  void _loadPlaylistSongs() {
    final playlistId = widget.playlist.id;
    
    // Check cache first
    if (PlaylistImageWidget._playlistSongsCache.containsKey(playlistId)) {
      final cachedSongs = PlaylistImageWidget._playlistSongsCache[playlistId]!;
      debugPrint('🎵 PLAYLIST_IMAGE: Found ${cachedSongs.length} cached songs for playlist $playlistId');
      setState(() {
        _songs = cachedSongs;
        _isLoading = false;
      });
      return;
    }

    // Only set loading if we don't have cached data
    if (_songs == null) {
      setState(() {
        _isLoading = true;
      });
    }

    _getPlaylistSongs(playlistId).then((songs) {
      if (mounted && _currentPlaylistId == playlistId) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _buildPlaylistImage(),
      ),
    );
  }

  Widget _buildPlaylistImage() {
    // First, check if playlist has a custom cover image
    String customImageUrl = '';
    
    try {
      // Handle both RecordModel and fake records
      if (widget.playlist is RecordModel) {
        final pbService = PocketBaseService();
        final repository = PlaylistRepository(pbService);
        customImageUrl = repository.getCoverImageUrl(widget.playlist as RecordModel);
      } else {
        // Handle fake record from playlist selection modal
        final coverImage = widget.playlist.data['cover_image'] as String?;
        if (coverImage != null && coverImage.isNotEmpty) {
          customImageUrl = coverImage;
        }
      }
    } catch (e) {
      debugPrint('🎵 PLAYLIST_IMAGE: Error getting cover image URL: $e');
    }

    if (customImageUrl.isNotEmpty) {
      return Image.network(
        customImageUrl,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }

    // If no custom image and we should show mosaic, try to build mosaic from songs
    if (widget.showMosaicForEmptyPlaylists) {
      return _buildMosaicOrPlaceholder();
    }

    // Fallback to placeholder
    return _buildPlaceholderImage();
  }

  Widget _buildMosaicOrPlaceholder() {
    if (_isLoading && _songs == null) {
      // Only show loading indicator if we don't have any data yet
      return _buildPlaceholderImage();
    }
    
    if (_songs != null && _songs!.isNotEmpty) {
      return _buildMosaicArtwork(_songs!);
    }
    
    return _buildPlaceholderImage();
  }

  Widget _buildFallbackImage() {
    if (widget.showMosaicForEmptyPlaylists) {
      return _buildMosaicOrPlaceholder();
    }
    return _buildPlaceholderImage();
  }

  Widget _buildMosaicArtwork(List<Song> songs) {
    if (songs.isEmpty) {
      debugPrint('🎵 PLAYLIST_IMAGE: No songs found, showing placeholder');
      return _buildPlaceholderImage();
    }

    debugPrint('🎵 PLAYLIST_IMAGE: Building mosaic from ${songs.length} songs');

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

    debugPrint('🎵 PLAYLIST_IMAGE: Found ${albumCovers.length} unique album covers');

    if (albumCovers.isEmpty) {
      debugPrint('🎵 PLAYLIST_IMAGE: No album covers found, showing placeholder');
      return _buildPlaceholderImage();
    }

    // Logic for displaying artwork:
    // - If only 1 unique album OR playlist has 3 or fewer songs: show single cover
    // - If 2-4 unique albums AND more than 3 songs: show grid
    if (albumCovers.length == 1 || songs.length <= 3) {
      debugPrint('🎵 PLAYLIST_IMAGE: Showing single cover');
      return _buildSingleCover(albumCovers[0]);
    }

    debugPrint('🎵 PLAYLIST_IMAGE: Showing grid cover with ${albumCovers.length} images');
    return _buildGridCover(albumCovers);
  }

  Widget _buildSingleCover(String imageUrl) {
    return Image.network(
      imageUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildGridCover(List<String> imageUrls) {
    if (imageUrls.length == 2) {
      // 1x2 grid
      return Row(
        children: [
          Expanded(
            child: Image.network(
              imageUrls[0],
              height: widget.size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
          ),
          Expanded(
            child: Image.network(
              imageUrls[1],
              height: widget.size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
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
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Expanded(
                  child: Image.network(
                    imageUrls[1],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
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
                            color: AppColors.textSecondary.withValues(alpha: 0.2),
                          ),
                        )
                      : Container(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                ),
                Expanded(
                  child: imageUrls.length > 3
                      ? Image.network(
                          imageUrls[3],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.textSecondary.withValues(alpha: 0.2),
                          ),
                        )
                      : Container(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Icon(
        Icons.queue_music,
        color: AppColors.textSecondary,
        size: widget.size * 0.4,
      ),
    );
  }

  Future<List<Song>> _getPlaylistSongs(String playlistId) async {
    debugPrint('🎵 PLAYLIST_IMAGE: Getting songs for playlist $playlistId');
    
    // Check cache first
    if (PlaylistImageWidget._playlistSongsCache.containsKey(playlistId)) {
      final cachedSongs = PlaylistImageWidget._playlistSongsCache[playlistId]!;
      debugPrint('🎵 PLAYLIST_IMAGE: Found ${cachedSongs.length} cached songs for playlist $playlistId');
      return cachedSongs;
    }

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      
      final songs = await repository.getPlaylistSongs(playlistId);
      debugPrint('🎵 PLAYLIST_IMAGE: Loaded ${songs.length} songs for playlist $playlistId');
      
      // Cache the result
      PlaylistImageWidget._playlistSongsCache[playlistId] = songs;
      
      return songs;
    } catch (e) {
      debugPrint('🎵 PLAYLIST_IMAGE: Error getting songs for playlist $playlistId: $e');
      PlaylistImageWidget._playlistSongsCache[playlistId] = [];
      return [];
    }
  }
} 