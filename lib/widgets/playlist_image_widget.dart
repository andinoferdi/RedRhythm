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
  // Cache for built mosaic widgets to prevent unnecessary rebuilds
  static final Map<String, Widget> _mosaicWidgetCache = {};

  /// Clear the cache for a specific playlist (useful when playlist is updated)
  static void clearCache(String playlistId) {
    _playlistSongsCache.remove(playlistId);
    _mosaicWidgetCache.remove(playlistId);
  }

  /// Clear all cached playlist data
  static void clearAllCache() {
    _playlistSongsCache.clear();
    _mosaicWidgetCache.clear();
  }

  @override
  State<PlaylistImageWidget> createState() => _PlaylistImageWidgetState();
}

class _PlaylistImageWidgetState extends State<PlaylistImageWidget> {
  List<Song>? _songs;
  bool _isLoading = false;
  String? _currentPlaylistId;
  String? _lastBuiltCacheKey;
  
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
      _lastBuiltCacheKey = null; // Reset cache key
      _loadPlaylistSongs();
    }
  }

  String _getCacheKey() {
    return '${widget.playlist.id}_${widget.size}_${widget.showMosaicForEmptyPlaylists}';
  }

  void _loadPlaylistSongs() {
    final playlistId = widget.playlist.id;
    
    // Check cache first
    if (PlaylistImageWidget._playlistSongsCache.containsKey(playlistId)) {
      final cachedSongs = PlaylistImageWidget._playlistSongsCache[playlistId]!;
      if (mounted) {
        setState(() {
          _songs = cachedSongs;
          _isLoading = false;
        });
      }
      return;
    }

    // Only set loading if we don't have cached data
    if (_songs == null && mounted) {
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
      // Reduced debug logging for better performance
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
      return _buildPlaceholderImage();
    }

    // Use cache for built widgets to prevent unnecessary rebuilds
    final cacheKey = _getCacheKey();
    if (_lastBuiltCacheKey == cacheKey && 
        PlaylistImageWidget._mosaicWidgetCache.containsKey(cacheKey)) {
      return PlaylistImageWidget._mosaicWidgetCache[cacheKey]!;
    }

    // Reduced debug logging for better performance
    
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
      return _buildPlaceholderImage();
    }

    Widget builtWidget;
    // Logic for displaying artwork:
    // - If only 1 unique album OR playlist has 3 or fewer songs: show single cover
    // - If 2-4 unique albums AND more than 3 songs: show grid
    if (albumCovers.length == 1 || songs.length <= 3) {
      builtWidget = _buildSingleCover(albumCovers[0]);
    } else {
      builtWidget = _buildGridCover(albumCovers);
    }

    // Cache the built widget
    PlaylistImageWidget._mosaicWidgetCache[cacheKey] = builtWidget;
    _lastBuiltCacheKey = cacheKey;
    
    return builtWidget;
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
    // Check cache first
    if (PlaylistImageWidget._playlistSongsCache.containsKey(playlistId)) {
      final cachedSongs = PlaylistImageWidget._playlistSongsCache[playlistId]!;
      return cachedSongs;
    }

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      
      final songs = await repository.getPlaylistSongs(playlistId);
      
      // Cache the result
      PlaylistImageWidget._playlistSongsCache[playlistId] = songs;
      
      return songs;
    } catch (e) {
      return [];
    }
  }
} 