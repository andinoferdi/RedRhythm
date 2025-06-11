import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../utils/app_colors.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/playlist_repository.dart';
import 'playlist_form_dialog.dart';

class PlaylistTab extends StatefulWidget {
  const PlaylistTab({super.key});

  @override
  State<PlaylistTab> createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  bool _isLoading = true;
  List<RecordModel> _playlists = [];
  String? _errorMessage;
  RecordModel? _selectedPlaylist;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final repository = PlaylistRepository(pbService);
      final playlists = await repository.getUserPlaylists();

      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load playlists: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showAddPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => PlaylistFormDialog(
        onSuccess: _fetchPlaylists,
      ),
    );
  }

  void _showEditPlaylistDialog(RecordModel playlist) {
    showDialog(
      context: context,
      builder: (context) => PlaylistFormDialog(
        playlist: playlist,
        onSuccess: _fetchPlaylists,
      ),
    );
  }

  void _showDeleteConfirmDialog(RecordModel playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Hapus Playlist', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus playlist "${playlist.data['name']}"?\n\nTindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlaylist(playlist);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Playlist "${playlist.data['name']}" berhasil dihapus')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      
      _fetchPlaylists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal menghapus playlist: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPlaylists,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // If no playlists, show a centered add button
    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kamu belum memiliki playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPlaylistDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Otherwise, show the list of playlists with an add button at the bottom
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._playlists.map((playlist) => _buildPlaylistItem(
            title: playlist.data['name'] ?? 'Playlist Tanpa Judul',
            artist: playlist.data['description'] ?? '',
            image: playlist.data['cover_image'] ?? '',
            playlistId: playlist.id,
          )),
          const SizedBox(height: 16),
          _buildAddPlaylistButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem({
    required String title,
    required String artist,
    required String image,
    required String playlistId,
  }) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    final isSelected = _selectedPlaylist?.id == playlistId;
    
    // Get proper image URL using repository
    final pbService = PocketBaseService();
    final repository = PlaylistRepository(pbService);
    final String imageUrl = repository.getCoverImageUrl(playlist);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlaylist = isSelected ? null : playlist;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Colors.red, width: 1) : null,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist.isNotEmpty ? artist : 'Tidak ada deskripsi',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Show action buttons when selected
              if (isSelected) ...[
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditPlaylistDialog(playlist),
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(playlist),
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[800],
      child: const Icon(Icons.music_note, color: Colors.white),
    );
  }

  Widget _buildAddPlaylistButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ElevatedButton.icon(
          onPressed: _showAddPlaylistDialog,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Playlist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(200, 45),
          ),
        ),
      ),
    );
  }
} 