import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ArtistTab extends StatelessWidget {
  const ArtistTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Your Favorite Artists'),
          _buildSortOption('A - Z'),
          _buildArtistsList(),
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
              Icons.people,
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
            Icons.sort_by_alpha,
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