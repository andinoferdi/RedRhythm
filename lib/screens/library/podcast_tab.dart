import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class PodcastTab extends StatelessWidget {
  const PodcastTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Your Liked Podcasts'),
          _buildSortOption('A - Z'),
          _buildPodcastsList(),
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
              Icons.mic,
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

  Widget _buildPodcastsList() {
    final podcasts = [
      {
        'title': 'Anything Goes',
        'host': 'Emma Chamberlain',
        'updated': 'Updated Aug 31',
        'image': 'assets/images/playlists/anything_goes.jpg',
      },
      {
        'title': 'Ask Me Another',
        'host': 'NPR Studios',
        'updated': 'Updated Aug 18',
        'image': 'assets/images/playlists/ask_me_another.jpg',
      },
      {
        'title': 'Baking a Mystery',
        'host': 'Stephanie Soo',
        'updated': 'Updated Aug 21',
        'image': 'assets/images/playlists/baking_mystery.jpg',
      },
      {
        'title': 'Extra Dynamic',
        'host': 'ur mom ashley',
        'updated': 'Updated Aug 10',
        'image': 'assets/images/playlists/extra_dynamic.jpg',
      },
      {
        'title': 'Teenager Therapy',
        'host': 'iHeart Studios',
        'updated': 'Updated Aug 21',
        'image': 'assets/images/playlists/teenager_therapy.jpg',
      },
    ];
    
    return Column(
      children: podcasts.map((podcast) => _buildPodcastItem(
        title: podcast['title']!,
        host: podcast['host']!,
        updated: podcast['updated']!,
        image: podcast['image']!,
      )).toList(),
    );
  }

  Widget _buildPodcastItem({
    required String title,
    required String host,
    required String updated,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
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
                  child: const Icon(Icons.mic, color: Colors.white),
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
                  '$updated • $host',
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