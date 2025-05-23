import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../utils/app_colors.dart';
import '../../services/pocketbase_service.dart';

class PlaylistTab extends StatefulWidget {
  const PlaylistTab({super.key});

  @override
  State<PlaylistTab> createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  bool _isLoading = true;
  List<RecordModel> _playlists = [];
  String? _errorMessage;

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
      
      final result = await pbService.pb.collection('playlists').getList(
        filter: 'user_id = "${pbService.currentUser?.id}"',
      );

      setState(() {
        _playlists = result.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load playlists: ${e.toString()}';
        _isLoading = false;
      });
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
              onPressed: () {
               
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
    final PocketBaseService pbService = PocketBaseService();
    final String imageUrl = image.isNotEmpty
        ? '${pbService.pb.baseUrl}/api/files/playlists/$playlistId/$image'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
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
                  artist,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          onPressed: () {
          },
          icon: const Icon(Icons.add),
          label: const Text('Tambah Playlist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(200, 45),
          ),
        ),
      ),
    );
  }
} 