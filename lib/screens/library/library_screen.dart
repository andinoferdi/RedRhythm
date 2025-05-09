import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'library_controller.dart';
import 'library_tab_selector.dart';
import 'library_tab_enum.dart';
import 'playlist_tab.dart';
import 'artist_tab.dart';
import 'album_tab.dart';
import 'podcast_tab.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryController(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const LibraryTabSelector(),
                    const Expanded(
                      child: _TabContentView(),
                    ),
                  ],
                ),
              ),
              _buildBottomNavBar(),
            ],
          ),
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

  Widget _buildBottomNavBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.home,
            'Home',
            AppRoutes.home,
            false,
          ),
          _buildNavItem(
            Icons.search,
            'Explore',
            AppRoutes.explore,
            false,
          ),
          _buildNavItem(
            Icons.library_music,
            'Library',
            AppRoutes.library,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    String route,
    bool isActive,
  ) {
    return InkWell(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabContentView extends StatelessWidget {
  const _TabContentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryController>(
      builder: (context, controller, _) {
        switch (controller.selectedTab) {
          case LibraryTab.playlists:
            return const PlaylistTab();
          case LibraryTab.artists:
            return const ArtistTab();
          case LibraryTab.albums:
            return const AlbumTab();
          case LibraryTab.podcasts:
            return const PodcastTab();
        }
      },
    );
  }
} 