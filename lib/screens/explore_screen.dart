import 'package:flutter/material.dart';
import '../routes.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16), // Added top spacing
              _buildSearchHeader(),
              _buildSearchBar(),
              const SizedBox(height: 30),
              _buildYourTopGenres(),
              const SizedBox(height: 40),
              _buildBrowseAll(),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
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
          const Text(
            'Search',
            style: TextStyle(
              color: Color(0xFFE53935),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Songs, Artists, Podcasts & More',
              style: TextStyle(
                color: Colors.grey.shade600,
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
              _buildGenreCard('Kpop', const Color(0xFF8BC34A), Icons.music_note),
              _buildGenreCard('Indie', const Color(0xFFE91E63), Icons.music_video),
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
              _buildGenreCard('Made\nfor You', const Color(0xFF039BE5), Icons.person),
              _buildGenreCard('RELEASED', const Color(0xFF9C27B0), Icons.new_releases, isGradient: true),
              _buildGenreCard('Music\nCharts', const Color(0xFF3F51B5), Icons.equalizer),
              _buildGenreCard('Podcasts', const Color(0xFFD32F2F), Icons.podcasts),
              _buildGenreCard('Bollywood', const Color(0xFFFF9800), Icons.movie),
              _buildGenreCard('Pop\nFusion', const Color(0xFF009688), Icons.queue_music),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenreCard(String title, Color color, IconData icon, {bool isGradient = false}) {
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

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade900,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_filled, 'Home', false, () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          }),
          _buildNavItem(context, Icons.search, 'Explore', true, () {}),
          _buildNavItem(context, Icons.folder, 'Library', false, () {}),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFE71E27) : Colors.white,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE71E27) : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    final double width = size.width;

    // Draw 3 lines for simplified waveform
    canvas.drawLine(
        Offset(0, centerY), Offset(width * 0.2, centerY - size.height * 0.3), paint);
    canvas.drawLine(Offset(width * 0.2, centerY - size.height * 0.3),
        Offset(width * 0.5, centerY + size.height * 0.3), paint);
    canvas.drawLine(Offset(width * 0.5, centerY + size.height * 0.3),
        Offset(width * 0.8, centerY - size.height * 0.1), paint);
    canvas.drawLine(Offset(width * 0.8, centerY - size.height * 0.1),
        Offset(width, centerY + size.height * 0.2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
