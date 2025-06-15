import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/player_controller.dart';
import '../../states/player_state.dart';
import '../../models/song.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helpers.dart';

@RoutePage()
class MusicPlayerScreen extends ConsumerStatefulWidget {
  final Song? song;
  
  const MusicPlayerScreen({this.song, super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen> {

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentSong = playerState.currentSong ?? widget.song;
    
    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'No song is currently playing',
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    // Note: Removed automatic playback initiation to prevent interference with existing playback
    // The music player screen should only display current state, not start new playback

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text),
          onPressed: () => context.router.maybePop(),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.text),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Album Art
              Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.greyDark, // Background color for fallback
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Album art image with enhanced error handling
                      ImageHelpers.buildSafeNetworkImage(
                        imageUrl: currentSong.albumArtUrl,
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(20),
                        showLoadingIndicator: true,
                        fallbackWidget: _buildFallbackAlbumArt(),
                      ),
                      
                      // Show loading indicator when buffering
                      if (playerState.isBuffering)
                        Container(
                          height: 280,
                          width: 280,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Song info
              Column(
                children: [
                  Text(
                    currentSong.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSong.artist,
                    style: const TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Playback controls
              Column(
                children: [
                  // Slider
                  Slider(
                    value: playerState.currentPosition.inSeconds.toDouble(),
                    max: currentSong.duration.inSeconds.toDouble(),
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.greyDark,
                    onChanged: (value) {
                      ref.read(playerControllerProvider.notifier).seekTo(
                        Duration(seconds: value.toInt()),
                      );
                    },
                  ),
                  
                  // Time indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerState.currentPosition),
                          style: const TextStyle(color: AppColors.greyLight),
                        ),
                        Text(
                          _formatDuration(currentSong.duration),
                          style: const TextStyle(color: AppColors.greyLight),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Always show shuffle button - supports both playlist and general shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: playerState.shuffleMode ? AppColors.primary : AppColors.text,
                          size: 24,
                        ),
                        onPressed: () {
                          ref.read(playerControllerProvider.notifier).toggleShuffle();
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: AppColors.text,
                          size: 36,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(playerControllerProvider.notifier).skipPrevious();
                          } catch (e) {
                            debugPrint('Error skipping to previous song: $e');
                          }
                        },
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isBuffering
                                ? Icons.hourglass_empty
                                : playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.textOnPrimary,
                            size: 36,
                          ),
                          onPressed: () {
                            if (playerState.isBuffering) {
                              // Do nothing while buffering
                              return;
                            }
                            
                            if (playerState.isPlaying) {
                              ref.read(playerControllerProvider.notifier).pause();
                            } else {
                              ref.read(playerControllerProvider.notifier).resume();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: AppColors.text,
                          size: 36,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(playerControllerProvider.notifier).skipNext();
                          } catch (e) {
                            debugPrint('Error skipping to next song: $e');
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          playerState.repeatMode == RepeatMode.off
                              ? Icons.repeat
                              : playerState.repeatMode == RepeatMode.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                          color: playerState.repeatMode == RepeatMode.off
                              ? AppColors.text
                              : AppColors.primary,
                          size: 24,
                        ),
                        onPressed: () {
                          ref.read(playerControllerProvider.notifier).toggleRepeatMode();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Lyrics Section
              _buildLyricsSection(currentSong),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLyricsSection(Song currentSong) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(
              Icons.lyrics_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Lyrics',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Lyrics content
        currentSong.lyrics == null || currentSong.lyrics!.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(33, 33, 33, 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.greyDark,
                    width: 0.5,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      size: 48,
                      color: AppColors.greyLight,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No lyrics available',
                      style: TextStyle(
                        color: AppColors.greyLight,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Lyrics will appear here when available',
                      style: TextStyle(
                        color: AppColors.greyLight,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE53E3E), // Red primary
                      const Color(0xFFD53F8C), // Red-pink
                      const Color(0xFFC53030), // Darker red
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53E3E).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  currentSong.lyrics!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.8,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
        
        const SizedBox(height: 20),
        
        // Footer
        Center(
          child: Text(
            '♪ ${currentSong.title} - ${currentSong.artist} ♪',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 40), // Extra space at bottom
      ],
    );
  }
  
  /// Build fallback album art when image fails to load
  Widget _buildFallbackAlbumArt() {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.greyDark,
            AppColors.background,
          ],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'No Album Art',
            style: TextStyle(
              color: AppColors.greyLight,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
