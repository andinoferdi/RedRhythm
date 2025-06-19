import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/song.dart';
import '../services/pocketbase_service.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/song_playlist_repository.dart';
import '../utils/app_colors.dart';
import '../utils/image_helpers.dart';
import 'shimmer_widget.dart';

/// A unified widget for displaying playlist images consistently across the app
/// 
/// PRIORITY LOGIC:
/// 1. FIRST PRIORITY: Display playlist's custom cover_image if available
/// 2. SECOND PRIORITY: If no custom cover_image, fallback to mosaic from songs
/// 3. THIRD PRIORITY: If no songs or showMosaicForEmptyPlaylists=false, show placeholder
/// 
/// This ensures playlist owners can set custom covers while maintaining
/// automatic mosaic generation for playlists without custom covers.
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
    
    // Clear all mosaic cache that contains this playlist ID
    final keysToRemove = _mosaicWidgetCache.keys.where((key) => key.contains(playlistId)).toList();
    for (final key in keysToRemove) {
      _mosaicWidgetCache.remove(key);
    }
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
    
    // Only reload if playlist ID actually changed
    final playlistChanged = oldWidget.playlist.id != widget.playlist.id;
    
    if (playlistChanged) {
      _currentPlaylistId = widget.playlist.id;
      _lastBuiltCacheKey = null; // Reset cache key
      
      _loadPlaylistSongs();
    } else {
      // If only key changed (forced update), just rebuild without clearing cache
      final keyChanged = oldWidget.key != widget.key;
      if (keyChanged) {
        _lastBuiltCacheKey = null; // Reset cache key to force mosaic rebuild
        if (mounted) {
          setState(() {
            // Force rebuild
          });
        }
      }
    }
  }

  String _getCacheKey() {
    return '${widget.playlist.id}_${widget.size}_${widget.showMosaicForEmptyPlaylists}';
  }

  void _loadPlaylistSongs() {
    final playlistId = widget.playlist.id;
    
    // Use cache by default, only skip cache if explicitly cleared
    bool useCache = true;
    
    if (useCache && PlaylistImageWidget._playlistSongsCache.containsKey(playlistId)) {
      final cachedSongs = PlaylistImageWidget._playlistSongsCache[playlistId]!;

      if (mounted) {
        setState(() {
          _songs = cachedSongs;
          _isLoading = false;
        });
      }
      return;
    }

    // Only show loading if we don't have any data yet
    if (_songs == null) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    }

    _getPlaylistSongs(playlistId).then((songs) {
      if (mounted && _currentPlaylistId == playlistId) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted && _currentPlaylistId == playlistId) {
        setState(() {
          _songs = [];
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
    // FIRST PRIORITY: Check if playlist has a custom cover image
    String customImageUrl = '';
    final playlistId = widget.playlist.id;
    
    try {
      // Handle both RecordModel and fake records
      if (widget.playlist is RecordModel) {
        final pbService = PocketBaseService();
        final repository = PlaylistRepository(pbService);
        customImageUrl = repository.generatePlaylistCoverUrl(widget.playlist.data, playlistId) ?? '';

      } else {
        // Handle fake record from playlist selection modal
        final coverImage = widget.playlist.data['cover_image'] as String?;
        if (coverImage != null && coverImage.isNotEmpty) {
          customImageUrl = coverImage;
        }
      }
    } catch (e) {
      // Continue to fallback options
    }

    // If custom cover image exists and is valid, use it
    if (customImageUrl.isNotEmpty && ImageHelpers.isValidImageUrl(customImageUrl)) {
      return ImageHelpers.buildSafeNetworkImage(
        imageUrl: customImageUrl,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        showLoadingIndicator: true,
        fallbackWidget: _buildMosaicOrFallbackImage(),
      );
    }

    // SECOND PRIORITY: If no custom image, use mosaic from songs or fallback
    return _buildMosaicOrFallbackImage();
  }

  Widget _buildMosaicOrFallbackImage() {
    // If we should show mosaic, try to build it from songs
    if (widget.showMosaicForEmptyPlaylists) {
      return _buildMosaicOrPlaceholder();
    }

    // Otherwise, show placeholder
    return _buildPlaceholderImage();
  }

  Widget _buildMosaicOrPlaceholder() {
    if (_isLoading && _songs == null) {
      // Show loading indicator while fetching songs
      return _buildLoadingPlaceholder();
    }
    
    if (_songs != null && _songs!.isNotEmpty) {
      return _buildMosaicArtwork(_songs!);
    }
    
    return _buildPlaceholderImage();
  }



  Widget _buildMosaicArtwork(List<Song> songs) {
    if (songs.isEmpty) {
      return _buildPlaceholderImage();
    }

    // Use caching to prevent unnecessary rebuilds
    final cacheKey = _getCacheKey();
    
    // Don't use cache if this is a fresh load (key change)
    bool useCache = _lastBuiltCacheKey == cacheKey && 
                   PlaylistImageWidget._mosaicWidgetCache.containsKey(cacheKey);
    
    if (useCache) {
      return PlaylistImageWidget._mosaicWidgetCache[cacheKey]!;
    }
    
    // Get unique album covers (max 4)
    final Set<String> uniqueCovers = {};
    final List<String> albumCovers = [];
    
    for (final song in songs) {
      if (song.albumArtUrl.isNotEmpty && 
          ImageHelpers.isValidImageUrl(song.albumArtUrl) &&
          !uniqueCovers.contains(song.albumArtUrl)) {
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
    if (!ImageHelpers.isValidImageUrl(imageUrl)) {
      return _buildPlaceholderImage();
    }
    
    return ImageHelpers.buildSafeNetworkImage(
      imageUrl: imageUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      fallbackWidget: _buildPlaceholderImage(),
    );
  }

  Widget _buildGridCover(List<String> imageUrls) {
    if (imageUrls.length == 2) {
      // 1x2 grid
      return Row(
        children: [
          Expanded(
            child: _buildGridImageWidget(imageUrls[0], height: widget.size),
          ),
          Expanded(
            child: _buildGridImageWidget(imageUrls[1], height: widget.size),
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
                  child: _buildGridImageWidget(imageUrls[0]),
                ),
                Expanded(
                  child: _buildGridImageWidget(imageUrls[1]),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: imageUrls.length > 2
                      ? _buildGridImageWidget(imageUrls[2])
                      : Container(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                ),
                Expanded(
                  child: imageUrls.length > 3
                      ? _buildGridImageWidget(imageUrls[3])
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

  Widget _buildGridImageWidget(String imageUrl, {double? height}) {
    if (!ImageHelpers.isValidImageUrl(imageUrl)) {
      return Container(
        color: AppColors.textSecondary.withValues(alpha: 0.2),
      );
    }
    
    return ImageHelpers.buildSafeNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: height ?? (widget.size / 2),
      fit: BoxFit.cover,
      showLoadingIndicator: true,
      fallbackWidget: Container(
        color: AppColors.textSecondary.withValues(alpha: 0.2),
      ),
    );
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

  Widget _buildLoadingPlaceholder() {
    return ShimmerImagePlaceholder(
      width: widget.size,
      height: widget.size,
      borderRadius: BorderRadius.circular(widget.borderRadius),
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


