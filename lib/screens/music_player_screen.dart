import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/music_player/album_art.dart';
import '../widgets/music_player/playback_controls.dart';
import '../widgets/music_player/track_info.dart';
import '../widgets/music_player/progress_bar.dart';
import '../widgets/music_player/lyrics_view.dart';
import '../models/song.dart';
import '../providers/music_player_provider.dart';

class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({
    Key? key,
    required this.song,
    required this.playlist,
  }) : super(key: key);

  final Song song;
  final String playlist;

  @override
  Widget build(BuildContext context) {
    // Initialize the provider with the current song
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
      if (playerProvider.currentSong == null || playerProvider.currentSong!.id != song.id) {
        playerProvider.playSong(song);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<MusicPlayerProvider>(
          builder: (context, playerProvider, _) {
            final currentSong = playerProvider.currentSong ?? song;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, playlist),
                  const SizedBox(height: 20),
                  AlbumArt(imageUrl: currentSong.albumArtUrl),
                  const SizedBox(height: 20),
                  TrackInfo(
                    title: currentSong.title,
                    artist: currentSong.artist,
                  ),
                  const SizedBox(height: 20),
                  ProgressBar(
                    currentTime: playerProvider.currentPosition,
                    totalTime: currentSong.duration,
                  ),
                  const SizedBox(height: 20),
                  const PlaybackControls(),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),
                  _buildLyricsHeader(),
                  Expanded(
                    child: LyricsView(lyrics: currentSong.lyrics),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String playlist) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PLAYING FROM PLAYLIST:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                playlist,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.more_vert,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'LYRICS',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
} 