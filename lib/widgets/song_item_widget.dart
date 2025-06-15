import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import 'animated_sound_bars.dart';

class SongItemWidget extends ConsumerWidget {
  final Song song;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final EdgeInsets? contentPadding;
  final bool? isCurrentSong;
  final bool? isPlaying;
  final bool isDisabled; // New parameter to explicitly disable tap
  final int? index;

  const SongItemWidget({
    super.key,
    required this.song,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.contentPadding,
    this.isCurrentSong,
    this.isPlaying,
    this.isDisabled = false, // Default to enabled
    this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(playerControllerProvider);
        
        // If disabled, never show as current song or playing
        final actualIsCurrentSong = isDisabled 
            ? false 
            : (isCurrentSong ?? (playerState.currentSong?.id == song.id));
        final actualIsPlaying = isDisabled 
            ? false 
            : (isPlaying ?? (actualIsCurrentSong && playerState.isPlaying));

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
              color: actualIsCurrentSong ? Colors.red : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle ?? (song.artist.isNotEmpty ? song.artist : 'Unknown Artist'),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailing ?? (actualIsPlaying
              ? const AnimatedSoundBars(
                  color: Colors.red,
                  size: 20.0,
                  isAnimating: true,
                )
              : null),
          onTap: isDisabled 
              ? null // Completely disable tap if isDisabled is true
              : (onTap ?? () {
                  // Reduced debug logging for better performance
                  ref.read(playerControllerProvider.notifier).playSongWithoutPlaylist(song);
                }),
        );
      },
    );
  }
} 