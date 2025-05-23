import 'package:flutter/material.dart';

class ArtistTab extends StatelessWidget {
  const ArtistTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArtistsList(),
        ],
      ),
    );
  }

  Widget _buildArtistsList() {
    final artists = [
      {
        'name': 'The Weekend',
        'followers': '108.5M followers',
        'image': 'assets/images/profile/the_weekend.jpg',
      },
      {
        'name': 'Doja Cat',
        'followers': '87.3M followers',
        'image': 'assets/images/profile/doja_cat.jpg',
      },
      {
        'name': 'Conan Gray',
        'followers': '45.2M followers',
        'image': 'assets/images/profile/conan_gray.jpg',
      },
      {
        'name': 'The Neighbourhood',
        'followers': '39.8M followers',
        'image': 'assets/images/profile/the_neighbourhood.jpg',
      },
      {
        'name': 'Troye Sivan',
        'followers': '35.1M followers',
        'image': 'assets/images/profile/troye_sivan.jpg',
      },
    ];
    
    return Column(
      children: artists.map((artist) => _buildArtistItem(
        name: artist['name']!,
        followers: artist['followers']!,
        image: artist['image']!,
      )).toList(),
    );
  }

  Widget _buildArtistItem({
    required String name,
    required String followers,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[800],
            backgroundImage: AssetImage(image),
            onBackgroundImageError: (exception, stackTrace) {
              // Handle error
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  followers,
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