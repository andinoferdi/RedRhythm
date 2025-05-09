import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_player_provider.dart';
import 'custom_progress_bar.dart';

class ProgressBar extends StatelessWidget {
  final Duration currentTime;
  final Duration totalTime;

  const ProgressBar({
    Key? key,
    required this.currentTime,
    required this.totalTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicPlayerProvider>(context, listen: false);

    return CustomProgressBar(
      currentTime: currentTime,
      totalTime: totalTime,
      onSeek: (position) {
        provider.seekTo(position);
      },
    );
  }
} 