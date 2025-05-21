import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        bottom: false, // Don't apply bottom safe area to avoid double padding
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16), // Consistent top spacing
              _buildSearchHeader(),
              const SizedBox(height: 16), // Consistent spacing
              _buildSearchBar(),
              const SizedBox(height: 24), // Adjusted spacing
              _buildYourTopGenres(),
              const SizedBox(height: 30),
              _buildBrowseAll(),
              // Add a bottom spacing to account for the navigation bar
              SizedBox(height: 70 + bottomPadding), // Consistent with home screen
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with home screen
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade800, width: 1),
                    color: Colors.grey.shade800,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 145, // Constrain width
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 28, // Match size with Library screen
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: const [
                Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 28, // Match size with Library screen
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade800, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Songs, Artists, Podcasts & More',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourTopGenres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Your Top Genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildGenreCard(
                  'Kpop', const Color(0xFF8BC34A), Icons.music_note),
              _buildGenreCard(
                  'Indie', const Color(0xFFE91E63), Icons.music_video),
              _buildGenreCard('R&B', const Color(0xFF5C6BC0), Icons.piano),
              _buildGenreCard('Pop', const Color(0xFFE67E22), Icons.mic),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseAll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Browse All',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildGenreCard(
                  'Made\nfor You', const Color(0xFF039BE5), Icons.person),
              _buildGenreCard(
                  'RELEASED', const Color(0xFF9C27B0), Icons.new_releases,
                  isGradient: true),
              _buildGenreCard(
                  'Music\nCharts', const Color(0xFF3F51B5), Icons.equalizer),
              _buildGenreCard(
                  'Podcasts', const Color(0xFFD32F2F), Icons.podcasts),
              _buildGenreCard(
                  'Bollywood', const Color(0xFFFF9800), Icons.movie),
              _buildGenreCard(
                  'Pop\nFusion', const Color(0xFF009688), Icons.queue_music),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenreCard(String title, Color color, IconData icon,
      {bool isGradient = false}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (isGradient)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.green.shade300,
                      Colors.green.shade500,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    radius: 0.8,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
