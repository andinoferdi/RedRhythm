import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/player_controller.dart';
import '../models/song.dart';
import '../utils/image_helpers.dart';
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

        return GestureDetector(
          onTap: isDisabled 
              ? null // Completely disable tap if isDisabled is true
              : (onTap ?? () {
                  // Reduced debug logging for better performance
                  ref.read(playerControllerProvider.notifier).playSongWithoutPlaylist(song);
                }),
          child: Container(
            padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.transparent,
            child: Row(
              children: [
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ImageHelpers.buildSafeNetworkImage(
                    imageUrl: song.albumArtUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    fallbackWidget: Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note, 
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Song info section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          color: actualIsCurrentSong ? Colors.red : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Gotham',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? (song.artist.isNotEmpty ? song.artist : 'Unknown Artist'),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Gotham',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Trailing section
                if (trailing != null || actualIsPlaying)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: trailing ?? (actualIsPlaying
                        ? const AnimatedSoundBars(
                            color: Colors.red,
                            size: 20.0,
                            isAnimating: true,
                          )
                        : null),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 


