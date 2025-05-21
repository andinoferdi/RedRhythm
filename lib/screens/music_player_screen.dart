import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/player/player_controller.dart';
import '../features/player/player_state.dart';
import '../models/song.dart';

@RoutePage()
class MusicPlayerScreen extends ConsumerWidget {
  final Song? song;
  
  const MusicPlayerScreen({this.song, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final currentSong = playerState.currentSong ?? song;
    
    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No song is currently playing',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => context.router.pop(),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Album Art
            Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(currentSong.albumArtUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Song info
            Column(
              children: [
                Text(
                  currentSong.title,
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: Colors.grey,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            
            // Playback controls
            Column(
              children: [
                // Slider
                Slider(
                  value: playerState.currentPosition.inSeconds.toDouble(),
                  max: currentSong.duration.inSeconds.toDouble(),
                  activeColor: const Color(0xFFE71E27),
                  inactiveColor: Colors.grey.shade800,
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
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        _formatDuration(currentSong.duration),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: playerState.shuffleMode ? const Color(0xFFE71E27) : Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).toggleShuffle();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).skipPrevious();
                      },
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE71E27),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
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
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: () {
                        ref.read(playerControllerProvider.notifier).skipNext();
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
                            ? Colors.white
                            : const Color(0xFFE71E27),
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
          ],
        ),
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