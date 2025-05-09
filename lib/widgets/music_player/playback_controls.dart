import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_player_provider.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, playerProvider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildShuffleButton(playerProvider),
            _buildPreviousButton(playerProvider),
            _buildPlayPauseButton(playerProvider),
            _buildNextButton(playerProvider),
            _buildRepeatButton(playerProvider),
          ],
        );
      },
    );
  }

  Widget _buildShuffleButton(MusicPlayerProvider provider) {
    return IconButton(
      icon: Icon(
        Icons.shuffle,
        color: provider.isShuffleEnabled ? Colors.red : Colors.white70,
        size: 24,
      ),
      onPressed: () => provider.toggleShuffle(),
    );
  }

  Widget _buildPreviousButton(MusicPlayerProvider provider) {
    return IconButton(
      icon: const Icon(
        Icons.skip_previous,
        color: Colors.white,
        size: 40,
      ),
      onPressed: () => provider.previousSong(),
    );
  }

  Widget _buildPlayPauseButton(MusicPlayerProvider provider) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
      child: IconButton(
        icon: Icon(
          provider.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 36,
        ),
        onPressed: () => provider.togglePlayPause(),
      ),
    );
  }

  Widget _buildNextButton(MusicPlayerProvider provider) {
    return IconButton(
      icon: const Icon(
        Icons.skip_next,
        color: Colors.white,
        size: 40,
      ),
      onPressed: () => provider.nextSong(),
    );
  }

  Widget _buildRepeatButton(MusicPlayerProvider provider) {
    return IconButton(
      icon: Icon(
        Icons.repeat,
        color: provider.isRepeatEnabled ? Colors.red : Colors.white70,
        size: 24,
      ),
      onPressed: () => provider.toggleRepeat(),
    );
  }
} 