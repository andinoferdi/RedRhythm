import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/player_controller.dart';
import '../../states/player_state.dart';
import '../../models/song.dart';

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
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No song is currently playing',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // If a song was provided but not yet played, start playback
    if (widget.song != null && (playerState.currentSong == null || playerState.currentSong?.id != widget.song?.id)) {
      // Use a microtask to avoid state changes during build
      Future.microtask(() {
        ref.read(playerControllerProvider.notifier).playSong(widget.song!);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => context.router.maybePop(),
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
                  image: DecorationImage(
                    image: NetworkImage(currentSong.albumArtUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                // Show loading indicator when buffering
                child: playerState.isBuffering 
                  ? Container(
                      color: const Color.fromRGBO(0, 0, 0, 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE71E27),
                        ),
                      ),
                    )
                  : null,
              ),
              
              const SizedBox(height: 30),
              
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
              
              const SizedBox(height: 30),
              
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
                            playerState.isBuffering
                                ? Icons.hourglass_empty
                                : playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
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
    // Debug print
    debugPrint('Music Player - Song: ${currentSong.title}, Lyrics: ${currentSong.lyrics?.isNotEmpty == true ? "HAS LYRICS (${currentSong.lyrics!.length} chars)" : "NO LYRICS"}');
    if (currentSong.lyrics?.isNotEmpty == true) {
      debugPrint('Lyrics content preview: ${currentSong.lyrics!.substring(0, currentSong.lyrics!.length > 100 ? 100 : currentSong.lyrics!.length)}...');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(
              Icons.lyrics_outlined,
              color: Color(0xFFE71E27),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Lyrics',
              style: TextStyle(
                color: Color(0xFFE71E27),
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
                    color: Colors.grey.shade800,
                    width: 0.5,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No lyrics available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Lyrics will appear here when available',
                      style: TextStyle(
                        color: Colors.grey,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(33, 33, 33, 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  currentSong.lyrics!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.7,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
        
        const SizedBox(height: 20),
        
        // Footer
        Center(
          child: Text(
            '♪ ${currentSong.title} - ${currentSong.artist} ♪',
            style: TextStyle(
              color: Colors.grey.shade600,
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
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
} 