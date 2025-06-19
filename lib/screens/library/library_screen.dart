import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../utils/app_colors.dart';
import '../../utils/font_usage_guide.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/user_avatar.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import '../../widgets/spotify_style_button.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/playlist_repository.dart';
import '../../widgets/mini_player.dart';
import '../../controllers/player_controller.dart';
import '../../routes/app_router.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/playlist_image_widget.dart';
import '../playlist/playlist_screen.dart';
import '../../providers/artist_select_provider.dart';
import '../../models/artist_select.dart';
import '../../utils/image_helpers.dart';
import '../../providers/album_select_provider.dart';
import '../../models/album_select.dart';

@RoutePage()
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {

  @override
  void initState() {
    super.initState();
    // Initialize playlist and artist loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistProvider.notifier).loadPlaylists();
      ref.read(artistSelectProvider.notifier).loadSelectedArtists();
      ref.read(albumSelectProvider.notifier).loadSelectedAlbums();
    });
  }

  Future<String> _getPlaylistCreatorName(RecordModel playlist) async {
    try {
      final creatorId = playlist.data['user_id'] as String?;
      if (creatorId == null || creatorId.isEmpty) {
        return 'Unknown User';
      }

      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final creatorUser = await pbService.pb.collection('users').getOne(creatorId);
      
      // Get the creator's name from the user record
      final name = creatorUser.data['name'] as String?;
      final username = creatorUser.data['username'] as String?;
      
      // Use 'name' field first, fallback to 'username', then 'Unknown User'
      return name?.isNotEmpty == true 
          ? name!
          : (username?.isNotEmpty == true ? username! : 'Unknown User');
          
    } catch (e) {
      // Return fallback name on error
      return 'Unknown User';
    }
  }

  void _showAdminOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
                            Text(
                            'Admin Options',
                style: FontUsageGuide.modalTitle,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.orange),
                title: Text(
                  'Update Song Durations',
                  style: FontUsageGuide.modalButton,
                ),
                subtitle: Text(
                  'Auto-detect durations from MP3 files',
                  style: FontUsageGuide.modalBody,
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.router.push(const DurationUpdateRoute());
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _navigateToPlaylistDetail(RecordModel playlist) {
    Navigator.push(
      context,
      AppRouter.createConsistentRoute(
        PlaylistScreen(
          playlist: playlist,
        ),
      ),
    );
  }

  void _showDeleteBottomSheet(RecordModel playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                PlaylistImageWidget(
                  playlist: playlist,
                  size: 60,
                  borderRadius: 8,
                  showMosaicForEmptyPlaylists: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                                          playlist.data['name'] ?? 'Playlist Tanpa Judul',
                        style: FontUsageGuide.modalTitle,
                      ),
                      Text(
                        'Playlist',
                        style: FontUsageGuide.metadata,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildBottomSheetOption(
              icon: Icons.delete_outline,
              title: 'Hapus playlist',
              subtitle: 'Playlist akan dihapus secara permanen',
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(playlist);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 8),
            _buildBottomSheetOption(
              icon: Icons.share_outlined,
              title: 'Bagikan playlist',
              subtitle: 'Bagikan ke teman-teman',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: isDestructive 
                      ? FontUsageGuide.modalButton.copyWith(color: Colors.red)
                      : FontUsageGuide.modalButton,
                  ),
                  Text(
                    subtitle,
                    style: FontUsageGuide.modalBody,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(RecordModel playlist) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF282828), // Spotify dark gray
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                'Hapus playlist',
                style: FontUsageGuide.modalTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle/Question
              Text(
                'Yakin ingin menghapus ${playlist.data['name']}?',
                style: FontUsageGuide.modalBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Button
                  Flexible(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        minimumSize: const Size(80, 40),
                      ),
                      child: Text(
                        'BATALKAN',
                        style: FontUsageGuide.authButtonText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Delete Button
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deletePlaylist(playlist);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        minimumSize: const Size(80, 40),
                      ),
                      child: Text(
                        'HAPUS',
                        style: FontUsageGuide.authButtonText.copyWith(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlaylist(RecordModel playlist) async {
    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final repository = PlaylistRepository(pbService);
      await repository.deletePlaylist(playlist.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Playlist "${playlist.data['name']}" berhasil dihapus',
                    style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Notify global playlist provider about deletion
        ref.read(playlistProvider.notifier).notifyPlaylistUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus playlist: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildPlaylistItem(RecordModel playlist) {
    return GestureDetector(
      onTap: () => _navigateToPlaylistDetail(playlist),
      onLongPress: () => _showDeleteBottomSheet(playlist),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            PlaylistImageWidget(
              playlist: playlist,
              size: 64,
              borderRadius: 8,
              showMosaicForEmptyPlaylists: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.data['name'] ?? 'Playlist Tanpa Judul',
                    style: FontUsageGuide.listSongTitle,
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<String>(
                    future: _getPlaylistCreatorName(playlist),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          'Playlist • ${snapshot.data}',
                          style: FontUsageGuide.metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      } else {
                        return Text(
                          'Playlist',
                          style: FontUsageGuide.metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistItem(ArtistSelect artistSelect) {
    return GestureDetector(
      onTap: () {
        // Navigate to artist detail screen
        context.router.push(ArtistDetailRoute(
          artistId: artistSelect.artistId,
          artistName: artistSelect.artistName,
        ));
      },
      onLongPress: () => _showArtistOptionsBottomSheet(artistSelect),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            // Artist Image - Using ImageHelpers like in artist_selection_screen
            ClipOval(
              child: Container(
                width: 64,
                height: 64,
                color: Colors.grey[800],
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: artistSelect.artistImageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  fallbackWidget: _buildArtistPlaceholder(artistSelect.artistName ?? 'Unknown'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artistSelect.artistName ?? 'Unknown Artist',
                    style: FontUsageGuide.listSongTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Artis',
                    style: FontUsageGuide.metadata,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumItem(AlbumSelect albumSelect) {
    return GestureDetector(
      onTap: () {
        // Navigate to album screen
        context.router.push(AlbumRoute(
          albumId: albumSelect.albumId,
          albumTitle: albumSelect.albumTitle,
        ));
      },
      onLongPress: () => _showAlbumOptionsBottomSheet(albumSelect),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            // Album Cover Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: albumSelect.albumCoverImageUrl ?? '',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.album,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    albumSelect.albumTitle ?? 'Unknown Album',
                    style: FontUsageGuide.listSongTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Album • ${albumSelect.albumArtistName ?? 'Unknown Artist'}',
                    style: FontUsageGuide.metadata,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistPlaceholder(String artistName) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          artistName.isNotEmpty ? artistName[0].toUpperCase() : 'A',
          style: FontUsageGuide.searchResultArtist,
        ),
      ),
    );
  }

  void _showArtistOptionsBottomSheet(ArtistSelect artistSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[800],
                    child: ImageHelpers.buildSafeNetworkImage(
                      imageUrl: artistSelect.artistImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      fallbackWidget: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                                    child: Text(
            (artistSelect.artistName?.isNotEmpty == true) 
                ? artistSelect.artistName![0].toUpperCase() 
                : 'A',
            style: FontUsageGuide.searchResultArtist,
          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artistSelect.artistName ?? 'Unknown Artist',
                        style: FontUsageGuide.modalTitle,
                        ),
                      Text(
                        'Artis',
                        style: FontUsageGuide.metadata,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildBottomSheetOption(
              icon: Icons.person_remove_outlined,
              title: 'Berhenti mengikuti',
              subtitle: 'Berhenti mengikuti artis ini',
              onTap: () {
                Navigator.pop(context);
                _removeArtistFromCollection(artistSelect);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 8),
            _buildBottomSheetOption(
              icon: Icons.share_outlined,
              title: 'Bagikan artis',
              subtitle: 'Bagikan ke teman-teman',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAlbumOptionsBottomSheet(AlbumSelect albumSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ImageHelpers.buildSafeNetworkImage(
                      imageUrl: albumSelect.albumCoverImageUrl ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      fallbackWidget: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.album,
                          color: Colors.white54,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        albumSelect.albumTitle ?? 'Unknown Album',
                        style: FontUsageGuide.modalTitle,
                      ),
                      Text(
                        'Album • ${albumSelect.albumArtistName ?? 'Unknown Artist'}',
                        style: FontUsageGuide.metadata,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildBottomSheetOption(
              icon: Icons.remove_circle_outline,
              title: 'Hapus dari library',
              subtitle: 'Hapus album dari library',
              onTap: () {
                Navigator.pop(context);
                _removeAlbumFromCollection(albumSelect);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 8),
            _buildBottomSheetOption(
              icon: Icons.share_outlined,
              title: 'Bagikan album',
              subtitle: 'Bagikan ke teman-teman',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _removeArtistFromCollection(ArtistSelect artistSelect) async {
    try {
      final success = await ref.read(artistSelectProvider.notifier).removeArtistSelection(artistSelect.artistId);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Telah berhenti mengikuti "${artistSelect.artistName}"',
                    style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal berhenti mengikuti artis: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _removeAlbumFromCollection(AlbumSelect albumSelect) async {
    try {
      final success = await ref.read(albumSelectProvider.notifier).removeAlbumSelection(albumSelect.albumId);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Album "${albumSelect.albumTitle}" dihapus dari library',
                    style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus album dari library: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildLibraryContent() {
    // Watch both playlist and artist providers
    final playlistState = ref.watch(autoRefreshPlaylistProvider);
    final selectedArtists = ref.watch(autoRefreshArtistSelectProvider);
    final selectedAlbums = ref.watch(autoRefreshAlbumSelectProvider);
    
    final isLoadingPlaylists = playlistState.isLoading;
    final playlists = playlistState.playlists;
    final playlistError = playlistState.error;
    
    // Combine playlists, artists, and albums into a single list for display
    final allItems = <dynamic>[];
    
    if (!isLoadingPlaylists && playlistError == null) {
      allItems.addAll(playlists);
    }
    
    allItems.addAll(selectedArtists);
    allItems.addAll(selectedAlbums);
    
    if (isLoadingPlaylists) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (playlistError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              playlistError,
              style: FontUsageGuide.errorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(playlistProvider.notifier).refreshPlaylists();
                ref.read(artistSelectProvider.notifier).refreshSelectedArtists();
                ref.read(albumSelectProvider.notifier).refreshSelectedAlbums();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (allItems.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.library_music,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Koleksi masih kosong',
                  style: FontUsageGuide.emptyStateTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan playlist, artis, atau album untuk\nmulai membangun koleksi musik kamu',
                  style: FontUsageGuide.emptyStateMessage,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        
        if (item is RecordModel) {
          // This is a playlist
          return _buildPlaylistItem(item);
        } else if (item is ArtistSelect) {
          // This is an artist
          return _buildArtistItem(item);
        } else if (item is AlbumSelect) {
          // This is an album
          return _buildAlbumItem(item);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    // Watch auto-refresh playlist provider for automatic updates
    ref.watch(autoRefreshPlaylistProvider);
    // Watch auto-refresh artist select provider for automatic updates
    ref.watch(autoRefreshArtistSelectProvider);
    // Watch auto-refresh album select provider for automatic updates
    ref.watch(autoRefreshAlbumSelectProvider);
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  // Pindahkan tombol ke atas, setelah header
                  _buildActionButtons(),
                  const SizedBox(
                      height:
                          16), // Spacing yang lebih kecil antara tombol dan content
                  Expanded(
                    child: _buildLibraryContent(),
                  ),
                  // Minimal spacing only
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Show mini player if there's a current song
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildHeader() {
    // Get the current authenticated user
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    // Get the PocketBase URL for constructing the avatar URL
    final pocketBaseUrl =
        ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with home and explore screens
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                UserAvatar(
                  user: user,
                  baseUrl: pocketBaseUrl,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 145, // Constrain width
                  child: GestureDetector(
                    onLongPress: () {
                      // Admin access through long press
                      _showAdminOptions(context);
                    },
                    child: Text(
                      'Library',
                      style: FontUsageGuide.appBarTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.text,
                  size: 28, // Match size with other screens
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tambah Artist Button - Spotify Style
          SpotifyStyleButton(
            title: 'Tambahkan artis',
            onTap: () {
              context.router.push(const ArtistSelectionRoute());
            },
          ),
          const SizedBox(height: 4), // Spacing yang ketat seperti sebelumnya
          // Tambah Playlist Button - Spotify Style
          SpotifyStyleButton(
            title: 'Tambahkan playlist',
            onTap: () {
              _showCreatePlaylistFlow();
            },
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistFlow() {
    _showCreatePlaylistDialog();
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor:
          Colors.black.withValues(alpha: 0.85), // Fixed deprecated withOpacity
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Check if mini player is active
            final playerState = ref.read(playerControllerProvider);
            final miniPlayerHeight = playerState.currentSong != null ? 64.0 : 0.0;
            
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: (MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 40) + miniPlayerHeight,
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.9, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.7, // Reduced height to accommodate mini player
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF212121),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4), // Fixed deprecated withOpacity
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          // Header with title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Text(
                              'Beri nama playlist-mu',
                              style: FontUsageGuide.modalTitle,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Text Input with Spotify styling
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFF333333), // Slightly lighter than background
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.grey[800]!,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: nameController,
                                style: FontUsageGuide.authFieldInput,
                                cursorColor:
                                    Colors.red, // Spotify green
                                decoration: InputDecoration(
                                  hintText: 'Playlist-ku',
                                  hintStyle: FontUsageGuide.authFieldInput.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                autofocus: true,
                              ),
                            ),
                          ),

                          // Buttons section - FIXED LAYOUT
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Cancel Button - Spotify style
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                        },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    minimumSize: const Size(100, 40),
                                  ),
                                  child: Text(
                                    'BATAL',
                                    style: FontUsageGuide.authButtonText.copyWith(
                                      color: isLoading
                                          ? Colors.grey[600]
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ),

                                // Create Button - Spotify green style
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          final name = nameController.text.trim();
                                          final currentContext = context; // Store context before async
                                          
                                          if (name.isEmpty) {
                                            ScaffoldMessenger.of(currentContext)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Nama playlist tidak boleh kosong'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() {
                                            isLoading = true;
                                          });

                                          try {
                                            final pbService = PocketBaseService();
                                            final repository =
                                                PlaylistRepository(pbService);
                                            await repository.createPlaylist(
                                              name: name,
                                              description: '',
                                              isPublic: false,
                                              coverImageFile: null,
                                            );

                                            if (currentContext.mounted) {
                                              Navigator.of(currentContext).pop();
                                              
                                              // Auto-refresh using global provider
                                              ref.read(playlistProvider.notifier).notifyPlaylistUpdated();
                                              
                                              ScaffoldMessenger.of(currentContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.check_circle,
                                                          color: Colors.black),
                                                      const SizedBox(width: 8),
                                                                                            Text(
                                        'Playlist "$name" berhasil dibuat!',
                                        style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.white,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            setState(() {
                                              isLoading = false;
                                            });
                                            if (currentContext.mounted) {
                                              ScaffoldMessenger.of(currentContext)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.error_outline,
                                                          color: Colors.white),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                          child: Text(
                                                              'Gagal membuat playlist: ${e.toString()}')),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.red, // Spotify green
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                    minimumSize: const Size(100, 40),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'BUAT',
                                          style: FontUsageGuide.authButtonText,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ));
          },
        );
      },
    );
  }
}


