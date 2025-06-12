import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import 'animated_sound_bars.dart';

class SongItemWidget extends ConsumerWidget {
  final Song song;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final EdgeInsets? contentPadding;

  const SongItemWidget({
    super.key,
    required this.song,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return ListTile(
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.grey[800],
          child: song.albumArtUrl.isNotEmpty
              ? Image.network(
                  song.albumArtUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.music_note, color: Colors.white);
                  },
                )
              : const Icon(Icons.music_note, color: Colors.white),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isCurrentSong ? Colors.red : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? (isPlaying
          ? const AnimatedSoundBars(
              color: Colors.red,
              size: 20.0,
              isAnimating: true,
            )
          : null),
      onTap: onTap ?? () {
        ref.read(playerControllerProvider.notifier).playSong(song);
      },
    );
  }
} 