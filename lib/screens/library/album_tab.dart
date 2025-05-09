import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class AlbumTab extends StatelessWidget {
  const AlbumTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Your Albums'),
          _buildSortOption('Recently added'),
          _buildAlbumsList(),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFe91429), Color(0xFFb71c1c)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.album,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String option) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          const Icon(
            Icons.swap_vert,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            option,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsList() {
    final albums = [
      {
        'title': 'Superache',
        'artist': 'Conan Gray',
        'year': '2022',
        'image': 'assets/images/playlists/superache.jpg',
      },
      {
        'title': 'DAWN FM',
        'artist': 'The Weekend',
        'year': '2022',
        'image': 'assets/images/playlists/dawn_fm.jpg',
      },
      {
        'title': 'Planet Her',
        'artist': 'Doja Cat',
        'year': '2021',
        'image': 'assets/images/playlists/planet_her.jpg',
      },
      {
        'title': 'Wiped Out!',
        'artist': 'The Neighbourhood',
        'year': '2015',
        'image': 'assets/images/playlists/wiped_out.jpg',
      },
      {
        'title': 'Bloom',
        'artist': 'Troye Sivan',
        'year': '2018',
        'image': 'assets/images/playlists/bloom.jpg',
      },
    ];
    
    return Column(
      children: albums.map((album) => _buildAlbumItem(
        title: album['title']!,
        artist: album['artist']!,
        year: album['year']!,
        image: album['image']!,
      )).toList(),
    );
  }

  Widget _buildAlbumItem({
    required String title,
    required String artist,
    required String year,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.asset(
              image,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.white),
                );
              },
            ),
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
                  '$artist • $year',
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
} 