import 'package:flutter/material.dart';
import '../routes.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTabIndex = 1; // Default to Playlists tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildTabBar(),
                    _buildQuickActions(),
                    _buildRecentlyPlayed(),
                  ],
                ),
              ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.search,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Folders', 'Playlists', 'Artists', 'Albums', 'Podcasts'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(30),
                  color: _selectedTabIndex == index
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Text(
                  tabs[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        children: [
          _buildActionItem(
            icon: Icons.add,
            title: 'Add New Playlist',
            onTap: () {
              // Handle add new playlist
            },
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            icon: Icons.favorite,
            title: 'Your Liked Songs',
            onTap: () {
              // Handle liked songs
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE71E27),
                    Color(0xFFB71C1C),
                  ],
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayed() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recently played',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentItem(
            image: 'assets/images/placeholder_artist.jpg',
            title: 'Conan Gray',
            subtitle: null,
            isArtist: true,
          ),
          _buildRecentItem(
            image: 'assets/images/placeholder_playlist.jpg',
            title: '3:00am vibes',
            subtitle: '18 songs',
          ),
          _buildRecentItem(
            image: 'assets/images/placeholder_album.jpg',
            title: 'Wiped Out!',
            subtitle: 'The Neighbourhood',
          ),
          _buildRecentItem(
            image: 'assets/images/placeholder_playlist2.jpg',
            title: 'Extra Dynamic',
            subtitle: 'Updated Aug 10 • ur mom ashley',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem({
    required String image,
    required String title,
    String? subtitle,
    bool isArtist = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: isArtist ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isArtist ? null : BorderRadius.circular(4),
                image: DecorationImage(
                  image: AssetImage(image),
                  fit: BoxFit.cover,
                ),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
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
      ),
    );
  }

  Widget _buildBottomNavBar() {
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
          _buildNavItem(Icons.home, 'Home', false, () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          }),
          _buildNavItem(Icons.search, 'Explore', false, () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.explore);
          }),
          _buildNavItem(Icons.library_music, 'Library', true, () {
            // Already on library screen
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
            color: isSelected ? AppColors.primary : Colors.white,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
