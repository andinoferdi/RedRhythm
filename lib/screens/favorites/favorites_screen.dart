import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../../utils/app_colors.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/song_item_widget.dart';
import '../../providers/favorite_provider.dart';
import '../../models/song.dart';
import '../../utils/font_usage_guide.dart';

@RoutePage()
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    // Load favorites on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoriteProvider.notifier).loadFavorites();
      // Reset shuffle mode when entering favorites screen (context change)
      ref.read(playerControllerProvider.notifier).resetShuffleOnContextChange();
    });
  }

  /// Force refresh of favorites
  Future<void> _forceRefresh() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    
    try {
      await ref.read(favoriteProvider.notifier).refreshFavorites();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Play song from favorites
  void _playSong(Song song) {
    final playerState = ref.read(playerControllerProvider);
    final favoriteSongs = ref.read(favoriteProvider).favoriteSongs;
    
    List<Song> playQueue;
    int startIndex;

    if (playerState.shuffleMode) {
      // Create shuffled queue with selected song at index 0
      playQueue = List.from(favoriteSongs);
      playQueue.shuffle();
      
      // Move selected song to first position
      playQueue.removeWhere((s) => s.id == song.id);
      playQueue.insert(0, song);
      startIndex = 0;
    } else {
      // Use original order
      playQueue = List.from(favoriteSongs);
      startIndex = favoriteSongs.indexOf(song);
    }

    ref.read(playerControllerProvider.notifier).playQueueFromPlaylist(playQueue, startIndex, 'favorites');
  }

  /// Toggle shuffle mode
  void _toggleShuffle() {
    final playerState = ref.read(playerControllerProvider);
    
    // Only allow shuffle toggle if no music is playing OR playing from this favorites context
    if (!playerState.isPlaying || playerState.currentPlaylistId == 'favorites') {
      ref.read(playerControllerProvider.notifier).toggleShuffle();
      
      // If currently playing from favorites, update the queue accordingly
      if (playerState.currentPlaylistId == 'favorites' && playerState.currentSong != null) {
        _updateShuffleForCurrentPlayback();
      }
    }
  }

  /// Update shuffle for current playback
  void _updateShuffleForCurrentPlayback() {
    final playerState = ref.read(playerControllerProvider);
    final currentSong = playerState.currentSong;
    final favoriteSongs = ref.read(favoriteProvider).favoriteSongs;
    
    if (currentSong == null) return;

    // Find current song index in original list
    final currentIndex = favoriteSongs.indexWhere((song) => song.id == currentSong.id);
    if (currentIndex == -1) return;

    List<Song> newQueue;
    int newIndex;

    if (playerState.shuffleMode) {
      // Create shuffled queue with current song at index 0
      newQueue = List.from(favoriteSongs);
      newQueue.shuffle();
      
      // Move current song to first position
      newQueue.removeWhere((song) => song.id == currentSong.id);
      newQueue.insert(0, currentSong);
      newIndex = 0;
    } else {
      // Restore original order
      newQueue = List.from(favoriteSongs);
      newIndex = currentIndex;
    }

    // Update player queue
    ref.read(playerControllerProvider.notifier).updateQueue(newQueue, newIndex);
  }

  /// Play all favorite songs starting from first
  void _playAllFavorites() {
    final favoriteSongs = ref.read(favoriteProvider).favoriteSongs;
    if (favoriteSongs.isEmpty) return;
    
    final playerState = ref.read(playerControllerProvider);
    
    // If currently playing from favorites, pause/resume
    if (playerState.currentPlaylistId == 'favorites') {
      if (playerState.isPlaying) {
        // Pause current playback
        ref.read(playerControllerProvider.notifier).pause();
      } else {
        // Resume current playback
        ref.read(playerControllerProvider.notifier).resume();
      }
    } else {
      // Prepare queue based on shuffle setting
      List<Song> playQueue;
      int startIndex;

      if (playerState.shuffleMode) {
        // Create shuffled queue
        playQueue = List.from(favoriteSongs);
        playQueue.shuffle();
        startIndex = 0;
      } else {
        // Use original order
        playQueue = List.from(favoriteSongs);
        startIndex = 0;
      }

      // Start playing with prepared queue
      ref.read(playerControllerProvider.notifier).playQueueFromPlaylist(playQueue, startIndex, 'favorites');
    }
  }

  /// Remove song from favorites
  Future<void> _removeFromFavorites(Song song) async {
    final success = await ref.read(favoriteProvider.notifier).removeFromFavorites(song.id);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.black),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${song.title} dihapus dari favorit',
                  style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
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

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final favoriteState = ref.watch(autoRefreshFavoriteProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: _buildFavoritesInfo(favoriteState),
                    ),
                    SliverToBoxAdapter(
                      child: _buildPlayButton(favoriteState),
                    ),
                    _buildSongsList(favoriteState),
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
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Library tab index
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.background,
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              margin: const EdgeInsets.only(top: 60),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
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
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesInfo(FavoriteState favoriteState) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lagu yang Disukai',
                  style: FontUsageGuide.homeGreeting.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              IconButton(
                onPressed: _forceRefresh,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
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
          Text(
            'Kumpulan lagu yang kamu sukai',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${favoriteState.favoriteSongs.length} lagu',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(FavoriteState favoriteState) {
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(playerControllerProvider);
        
        // Only consider as "favorites playing" if currently playing from favorites
        final isPlayingFromFavorites = playerState.currentPlaylistId == 'favorites' && 
                                      favoriteState.favoriteSongs.any((song) => song.id == playerState.currentSong?.id);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: favoriteState.favoriteSongs.isNotEmpty ? _playAllFavorites : null,
                  icon: Icon(
                    isPlayingFromFavorites && playerState.isPlaying 
                        ? Icons.pause 
                        : Icons.play_arrow, 
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    isPlayingFromFavorites && playerState.isPlaying ? 'Jeda' : 'Putar',
                    style: FontUsageGuide.authButtonText.copyWith(color: Colors.white),
                    overflow: TextOverflow.visible,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: const Size(120, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  final playerState = ref.read(playerControllerProvider);
                  // Only enable if no music is playing OR playing from favorites
                  if (!playerState.isPlaying || playerState.currentPlaylistId == 'favorites') {
                    _toggleShuffle();
                  }
                },
                icon: Icon(
                  Icons.shuffle, 
                  color: () {
                    // Check if shuffle is allowed
                    final canShuffle = !playerState.isPlaying || playerState.currentPlaylistId == 'favorites';
                    if (!canShuffle) return Colors.grey[600]; // Disabled color
                    return playerState.shuffleMode ? Colors.red : Colors.white;
                  }(),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: () {
                    final canShuffle = !playerState.isPlaying || playerState.currentPlaylistId == 'favorites';
                    if (!canShuffle) return Colors.grey[900]; // Disabled background
                    return playerState.shuffleMode ? Colors.red.withValues(alpha: 0.2) : Colors.grey[800];
                  }(),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongsList(FavoriteState favoriteState) {
    if (favoriteState.isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Colors.red),
          ),
        ),
      );
    }

    if (favoriteState.error != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  favoriteState.error!,
                  style: FontUsageGuide.modalBody.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _forceRefresh,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (favoriteState.favoriteSongs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada lagu favorit',
                  style: FontUsageGuide.emptyStateMessage.copyWith(color: Colors.grey[400]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai suka lagu dengan menekan ikon hati di pemutar musik',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
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
          final song = favoriteState.favoriteSongs[index];
          
          return Consumer(
            builder: (context, ref, child) {
              final playerState = ref.watch(playerControllerProvider);
              
              // Only show as "playing" if playing from favorites context
              final isCurrentSong = playerState.currentSong?.id == song.id;
              final isPlayingFromFavorites = playerState.currentPlaylistId == 'favorites';
              
              final shouldShowAsPlaying = isCurrentSong && 
                                        isPlayingFromFavorites && 
                                        playerState.isPlaying;
              
              final isPlaying = shouldShowAsPlaying;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                              style: FontUsageGuide.metadata.copyWith(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(width: 16),

                    // Use SongItemWidget for consistency
                    Expanded(
                      child: SongItemWidget(
                        song: song,
                        isCurrentSong: isCurrentSong && isPlayingFromFavorites,
                        isPlaying: isPlaying,
                        onTap: () => _playSong(song),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        trailing: IconButton(
                          onPressed: () => _removeFromFavorites(song),
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        childCount: favoriteState.favoriteSongs.length,
      ),
    );
  }
} 