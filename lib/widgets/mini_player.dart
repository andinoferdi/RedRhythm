import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:ui';
import '../controllers/player_controller.dart';
import '../routes/app_router.dart';
import '../utils/app_colors.dart';
// Used for Song type in playerState.currentSong and MusicPlayerRoute
import '../models/song.dart';
import '../models/playlist.dart';
import '../repositories/song_playlist_repository.dart';
import '../services/pocketbase_service.dart';
import 'playlist_selection_modal.dart';

// Provider for playlist update notifications
final playlistUpdateNotifierProvider = StateNotifierProvider<PlaylistUpdateNotifier, int>((ref) {
  return PlaylistUpdateNotifier();
});

class PlaylistUpdateNotifier extends StateNotifier<int> {
  PlaylistUpdateNotifier() : super(0);

  void notifyPlaylistUpdated() {
    state++;
  }
}

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _isLoadingPlaylists = false;
  bool _isInPlaylist = false;
  String? _lastCheckedSongId; // Cache to avoid unnecessary checks

  // Add cache for playlist data to reduce database calls
  static List<Playlist>? _cachedPlaylists;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  // Add optimistic state for immediate UI feedback
  bool _optimisticState = false;
  bool _hasOptimisticState = false;

  @override
  void initState() {
    super.initState();
    // Check playlist status after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfSongInPlaylist();
    });
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only check if song actually changed
    final currentSong = ref.read(playerControllerProvider).currentSong;
    if (currentSong?.id != _lastCheckedSongId) {
      // Immediately update to loading state for better UX
      setState(() {
        _isLoadingPlaylists = true;
      });
      _checkIfSongInPlaylist();
    }
  }

  Future<void> _checkIfSongInPlaylist() async {
    final currentSong = ref.read(playerControllerProvider).currentSong;
    if (currentSong == null) {
      debugPrint('🎵 MINI_PLAYER: No current song, skipping playlist check');
      if (mounted) {
        setState(() {
          _isInPlaylist = false;
          _lastCheckedSongId = null;
        });
      }
      return;
    }

    // Skip if we already checked this song recently
    if (_lastCheckedSongId == currentSong.id && !_isLoadingPlaylists) {
      debugPrint('🎵 MINI_PLAYER: Song ${currentSong.title} already checked, skipping');
      return;
    }

    try {
      debugPrint('🎵 MINI_PLAYER: Checking if song "${currentSong.title}" (ID: ${currentSong.id}) is in any playlist');
      
      // Set loading state immediately for better UX
      if (mounted) {
        setState(() {
          _isLoadingPlaylists = true;
        });
      }
      
      List<Playlist> allPlaylists;
      
      // Use cache if available and valid
      final now = DateTime.now();
      if (_cachedPlaylists != null && 
          _cacheTimestamp != null && 
          now.difference(_cacheTimestamp!).compareTo(_cacheValidDuration) < 0) {
        debugPrint('🎵 MINI_PLAYER: Using cached playlist data');
        allPlaylists = _cachedPlaylists!;
      } else {
        debugPrint('🎵 MINI_PLAYER: Fetching fresh playlist data');
        final pbService = PocketBaseService();
        await pbService.initialize();
        final repository = SongPlaylistRepository(pbService);
        allPlaylists = await repository.getAllPlaylists();
        
        // Update cache
        _cachedPlaylists = allPlaylists;
        _cacheTimestamp = now;
      }
      
      debugPrint('🎵 MINI_PLAYER: Total playlists available: ${allPlaylists.length}');
      
      bool foundInAnyPlaylist = false;
      
      for (final playlist in allPlaylists) {
        final containsSong = playlist.songs.contains(currentSong.id);
        if (containsSong) {
          foundInAnyPlaylist = true;
          debugPrint('🎵 MINI_PLAYER: ✅ Song found in playlist "${playlist.name}"');
          break; // Early exit for better performance
        }
      }
      
      debugPrint('🎵 MINI_PLAYER: Final result - song found in any playlist: $foundInAnyPlaylist');
      
      if (mounted) {
        setState(() {
          _isInPlaylist = foundInAnyPlaylist;
          _lastCheckedSongId = currentSong.id;
          _isLoadingPlaylists = false;
        });
        debugPrint('🎵 MINI_PLAYER: Updated button state - isInPlaylist: $_isInPlaylist');
        
        // Clear optimistic state now that we have real state
        _clearOptimisticState();
      }
    } catch (e) {
      debugPrint('🎵 MINI_PLAYER: Error checking playlists: $e');
      debugPrint('🎵 MINI_PLAYER: Error type: ${e.runtimeType}');
      // Don't show error to user for this background check
      if (mounted) {
        setState(() {
          _isInPlaylist = false; // Default to false on error
          _lastCheckedSongId = currentSong.id;
          _isLoadingPlaylists = false;
        });
        
        // Clear optimistic state on error too
        _clearOptimisticState();
      }
    }
  }

  // Clear cache when playlists are modified
  static void _clearPlaylistCache() {
    _cachedPlaylists = null;
    _cacheTimestamp = null;
    debugPrint('🎵 MINI_PLAYER: Playlist cache cleared');
  }

  Future<void> _showPlaylistModal(BuildContext context, Song song) async {
    debugPrint('🎵 MINI_PLAYER: Opening playlist modal for song: ${song.title}');
    
    await showPlaylistSelectionModal(
      context,
      song,
      onPlaylistsChanged: () {
        // Clear cache to force refresh
        _clearPlaylistCache();
        
        // Force immediate refresh of button state
        _lastCheckedSongId = null; // Reset cache
        _checkIfSongInPlaylist();
      },
    );
  }

  // Method to set optimistic state immediately after user action
  void _setOptimisticState(bool state) {
    setState(() {
      _optimisticState = state;
      _hasOptimisticState = true;
    });
    debugPrint('🎵 MINI_PLAYER: Set optimistic state to $state');
  }

  // Clear optimistic state when real state is confirmed
  void _clearOptimisticState() {
    if (_hasOptimisticState) {
      setState(() {
        _hasOptimisticState = false;
      });
      debugPrint('🎵 MINI_PLAYER: Cleared optimistic state');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentSong = playerState.currentSong;
    
    // Watch for playlist updates to refresh button state
    ref.listen(playlistUpdateNotifierProvider, (previous, next) {
      _checkIfSongInPlaylist();
    });
    
    // Watch for song changes to refresh button state
    ref.listen(playerControllerProvider.select((state) => state.currentSong), (previous, next) {
      if (next != null && (previous?.id != next.id)) {
        debugPrint('🎵 MINI_PLAYER: Song changed from ${previous?.title} to ${next.title}, checking playlist status');
        _checkIfSongInPlaylist();
      }
    });
    
    // Don't show mini player if no song is playing
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Navigate to full player screen when mini player is tapped
        context.router.push(MusicPlayerRoute(song: currentSong));
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          border: Border(
            top: BorderSide(
              color: const Color.fromRGBO(255, 255, 255, 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                // Progress Bar
                SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: playerState.currentPosition.inMilliseconds /
                        (currentSong.duration.inMilliseconds == 0 ? 1 : currentSong.duration.inMilliseconds),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.text),
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
                  ),
                ),
                // Content
                Expanded(
                  child: Row(
                    children: [
                      // Album Art
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(currentSong.albumArtUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Song Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.artist,
                              style: const TextStyle(
                                color: AppColors.greyLight,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Control Buttons
                      Row(
                        children: [
                          // Add to Playlist Button
                          Consumer(
                            builder: (context, ref, child) {
                              // Use optimistic state if available, otherwise use real state
                              final displayState = _hasOptimisticState ? _optimisticState : _isInPlaylist;
                              
                              return IconButton(
                                onPressed: _isLoadingPlaylists ? null : () async {
                                  final currentSong = ref.read(playerControllerProvider).currentSong;
                                  if (currentSong != null) {
                                    debugPrint('🎵 MINI_PLAYER: Opening playlist modal for song: ${currentSong.title}');
                                    
                                    // Set optimistic state based on current state
                                    // If currently in playlist, optimistically show it will be removed
                                    // If not in playlist, optimistically show it will be added
                                    final hasPlaylists = _cachedPlaylists?.isNotEmpty ?? true;
                                    if (hasPlaylists) {
                                      _setOptimisticState(!displayState);
                                    }
                                    
                                    await _showPlaylistModal(context, currentSong);
                                    
                                    // Clear optimistic state and refresh real state
                                    _clearOptimisticState();
                                    await _checkIfSongInPlaylist();
                                  }
                                },
                                icon: _isLoadingPlaylists 
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).iconTheme.color ?? Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      displayState ? Icons.check_circle : Icons.add_circle_outline,
                                      color: displayState 
                                        ? Colors.green 
                                        : Theme.of(context).iconTheme.color,
                                    ),
                                tooltip: _isLoadingPlaylists 
                                  ? 'Checking playlists...'
                                  : (displayState ? 'In playlist' : 'Add to playlist'),
                              );
                            },
                          ),
                          // Play/Pause Button
                          IconButton(
                            icon: Icon(
                              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppColors.text,
                            ),
                            onPressed: () {
                              if (playerState.isPlaying) {
                                ref.read(playerControllerProvider.notifier).pause();
                              } else {
                                ref.read(playerControllerProvider.notifier).resume();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
