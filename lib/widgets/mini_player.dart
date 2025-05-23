import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:ui';
import '../features/player/player_controller.dart';
import '../routes/app_router.dart';
// Used for Song type in playerState.currentSong and MusicPlayerRoute
import '../models/song.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final currentSong = playerState.currentSong;
    
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
          color: Colors.black.withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white.withOpacity(0.1),
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
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.artist,
                              style: TextStyle(
                                color: Colors.grey[400],
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
                          IconButton(
                            icon: Icon(
                              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (playerState.isPlaying) {
                                ref.read(playerControllerProvider.notifier).pause();
                              } else {
                                ref.read(playerControllerProvider.notifier).resume();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: Colors.white),
                            onPressed: () {
                              ref.read(playerControllerProvider.notifier).skipNext();
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