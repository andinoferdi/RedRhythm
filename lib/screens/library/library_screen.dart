import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../controllers/library_controller.dart';
import 'library_tab_selector.dart';
import 'library_tab_enum.dart';
import 'playlist_tab.dart';
import 'artist_tab.dart';
import 'album_tab.dart';
import 'podcast_tab.dart';

@RoutePage()
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return ChangeNotifierProvider(
      create: (_) => LibraryController(),
      child: Scaffold(
        backgroundColor: AppColors.surfaceDark,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              const LibraryTabSelector(),
              const Expanded(
                child: _TabContentView(),
              ),
              // No need for padding at the bottom of the column since we're using a bottom nav
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: 2,
          bottomPadding: bottomPadding,
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.graphic_eq,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 145, // Constrain width
                  child: const Text(
                    'Your Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

class _TabContentView extends StatelessWidget {
  const _TabContentView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // Add bottom padding
      child: Consumer<LibraryController>(
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
      ),
    );
  }
} 