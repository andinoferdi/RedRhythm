import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/app_colors.dart';

@RoutePage()
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        bottom: false, // Don't apply bottom safe area to avoid double padding
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16), // Consistent top spacing
              _buildSearchHeader(context, ref),
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, WidgetRef ref) {
    // Get the current authenticated user
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    // Get the PocketBase URL for constructing the avatar URL
    final pocketBaseUrl = ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with home screen
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                UserAvatar(
                  user: user,
                  baseUrl: pocketBaseUrl,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 145, // Constrain width
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 25, // Match size with Library screen
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
                  color: AppColors.text,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.greyDark, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: AppColors.greyLight,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Songs, Artists, Podcasts & More',
              style: TextStyle(
                color: AppColors.greyLight,
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
              color: AppColors.text,
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
                  'Kpop', AppColors.genreKpop, Icons.music_note),
              _buildGenreCard(
                  'Indie', AppColors.genreIndie, Icons.music_video),
              _buildGenreCard('R&B', AppColors.genreRnB, Icons.piano),
              _buildGenreCard('Pop', AppColors.genrePop, Icons.mic),
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
              color: AppColors.text,
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
                  'Made\nfor You', AppColors.info, Icons.person),
              _buildGenreCard(
                  'RELEASED', AppColors.genreReleased, Icons.new_releases,
                  isGradient: true),
              _buildGenreCard(
                  'Music\nCharts', AppColors.genreCharts, Icons.equalizer),
              _buildGenreCard(
                  'Podcasts', AppColors.genrePodcasts, Icons.podcasts),
              _buildGenreCard(
                  'Bollywood', AppColors.genreBollywood, Icons.movie),
              _buildGenreCard(
                  'Pop\nFusion', AppColors.genrePopFusion, Icons.queue_music),
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
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  icon,
                  color: AppColors.textOnPrimary,
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
