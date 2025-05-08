import 'package:flutter/material.dart';
import '../routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildContinueListening(),
              const SizedBox(height: 30),
              _buildYourTopMixes(),
              const SizedBox(height: 30),
              _buildRecentListening(),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AndinoFerdi',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.stats);
                },
                child: const Icon(Icons.stacked_line_chart,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 24),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              const Icon(Icons.settings_outlined,
                  color: Colors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueListening() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Continue Listening',
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
            childAspectRatio: 2.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPlaylistCard(
                'Coffee & Jazz',
                Icons.coffee,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                ),
              ),
              _buildPlaylistCard(
                'RELEASED',
                Icons.new_releases,
                iconColor: Colors.green,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                ),
              ),
              _buildPlaylistCard(
                'Anything Goes',
                Icons.all_inclusive,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                ),
              ),
              _buildPlaylistCard(
                'Anime OSTs',
                Icons.music_note,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                ),
              ),
              _buildPlaylistCard(
                'Harry\'s House',
                Icons.house,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                ),
              ),
              _buildPlaylistCard(
                'Lo-Fi Beats',
                Icons.headphones,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYourTopMixes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Your Top Mixes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            children: [
              _buildMixCard(
                'Pop Mix',
                Colors.red.shade400,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              const SizedBox(width: 16),
              _buildMixCard(
                'Chill Mix',
                Colors.amber.shade400,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              const SizedBox(width: 16),
              _buildMixCard(
                'K-Pop Mix',
                Colors.green.shade400,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentListening() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Based on your recent listening',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            children: [
              _buildRecommendationCard(
                'Harry\'s House',
                Icons.house,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              const SizedBox(width: 16),
              _buildRecommendationCard(
                'Night Tape',
                Icons.nightlight_round,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistCard(String title, IconData icon,
      {Color? iconColor, required Gradient gradient}) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey.shade800,
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixCard(String title, Color accentColor,
      {required Gradient gradient}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade800,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: gradient,
                ),
              ),
              // Add circular white elements for the design
              Positioned(
                right: 20,
                top: 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 170,
          height: 4,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 170,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, IconData icon,
      {required Gradient gradient}) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade800,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 50,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: gradient,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
          _buildNavItem(Icons.home_filled, 'Home', true, () {}),
          _buildNavItem(Icons.search, 'Explore', false, () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.explore);
          }),
          _buildNavItem(Icons.library_music, 'Library', false, () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.library);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isSelected, VoidCallback onTap) {
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
