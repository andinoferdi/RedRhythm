import 'package:flutter/material.dart';
import '../models/song.dart';
import '../utils/app_colors.dart';

/// Widget to display play count for a song
class PlayCountWidget extends StatelessWidget {
  final Song song;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool showIcon;

  const PlayCountWidget({
    super.key,
    required this.song,
    this.textColor,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w400,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (song.playCount == 0) {
      return const SizedBox.shrink(); // Don't show if no plays
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.play_arrow_rounded,
            size: (fontSize ?? 12) + 2,
            color: textColor ?? Colors.grey[500],
          ),
          const SizedBox(width: 2),
        ],
        Text(
          song.formattedPlayCount,
          style: TextStyle(
            color: textColor ?? Colors.grey[500],
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: 'DM Sans',
          ),
        ),
      ],
    );
  }
}

/// Widget to display play count in a more prominent way (for details screens)
class PlayCountBadge extends StatelessWidget {
  final Song song;
  final Color? backgroundColor;
  final Color? textColor;

  const PlayCountBadge({
    super.key,
    required this.song,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (song.playCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.greyDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.headphones,
            size: 14,
            color: textColor ?? Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '${song.formattedPlayCount} plays',
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }
} 