import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:ui';
import '../controllers/player_controller.dart';
import '../routes/app_router.dart';
import '../utils/app_colors.dart';
// Used for Song type in playerState.currentSong and MusicPlayerRoute
import '../models/song.dart';
import '../repositories/song_playlist_repository.dart';
import '../services/pocketbase_service.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _isLoadingPlaylists = false;
  bool _isInPlaylist = false;

  @override
  void initState() {
    super.initState();
    _checkIfSongInPlaylist();
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkIfSongInPlaylist();
  }

  Future<void> _checkIfSongInPlaylist() async {
    final currentSong = ref.read(playerControllerProvider).currentSong;
    if (currentSong == null) return;

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      
      // Get all playlists that contain this song
      final playlists = await repository.getPlaylistsContainingSong(currentSong.id);
      
      if (mounted) {
        setState(() {
          _isInPlaylist = playlists.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking playlists: $e');
    }
  }

  void _showAddToPlaylistModal(BuildContext context, Song song) async {
    setState(() {
      _isLoadingPlaylists = true;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      final playlists = await repository.getAllPlaylists();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF282828),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tambahkan ke playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: Implement create new playlist
                    Navigator.pop(context);
                  },
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.add, color: Colors.black),
                  ),
                  label: Text(
                    'Playlist baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final bool isInPlaylist = playlist.songs.contains(song.id);

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                          image: playlist.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(playlist.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: playlist.imageUrl == null
                            ? Icon(Icons.queue_music, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        playlist.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isInPlaylist
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () async {
                        try {
                          if (isInPlaylist) {
                            await repository.removeSongFromPlaylist(
                              playlist.id,
                              song.id,
                            );
                          } else {
                            await repository.addSongToPlaylist(
                              playlist.id,
                              song.id,
                            );
                          }
                          Navigator.pop(context);
                          _checkIfSongInPlaylist();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal ${isInPlaylist ? 'menghapus dari' : 'menambahkan ke'} playlist',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat playlist')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlaylists = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          border: Border(
            top: BorderSide(
              color: const Color.fromRGBO(255, 255, 255, 0.1),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.text),
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
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
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.artist,
                              style: const TextStyle(
                                color: AppColors.greyLight,
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
                          // Add to Playlist Button
                          IconButton(
                            icon: _isLoadingPlaylists
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    _isInPlaylist ? Icons.check : Icons.add,
                                    color: AppColors.text,
                                  ),
                            onPressed: () => _showAddToPlaylistModal(context, currentSong),
                          ),
                          // Play/Pause Button
                          IconButton(
                            icon: Icon(
                              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppColors.text,
                            ),
                            onPressed: () {
                              if (playerState.isPlaying) {
                                ref.read(playerControllerProvider.notifier).pause();
                              } else {
                                ref.read(playerControllerProvider.notifier).resume();
                              }
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
