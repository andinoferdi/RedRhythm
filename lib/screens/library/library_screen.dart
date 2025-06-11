import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/user_avatar.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import 'playlist_tab.dart';
import 'playlist_creation_flow.dart';

@RoutePage()
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 16),
            // Pindahkan tombol ke atas, setelah header
            _buildActionButtons(),
            const SizedBox(
                height:
                    16), // Spacing yang lebih kecil antara tombol dan content
            const Expanded(
              child: PlaylistTab(),
            ),
            SizedBox(height: 20 + bottomPadding),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildHeader() {
    // Get the current authenticated user
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    // Get the PocketBase URL for constructing the avatar URL
    final pocketBaseUrl =
        ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with home and explore screens
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
                    'Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25, // Match size with other screens
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.text,
                  size: 28, // Match size with other screens
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Tambah Artist Button - Spotify Style
          _buildSpotifyStyleButton(
            title: 'Tambahkan artis',
            onTap: () {
              // TODO: Implement add artist functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur Tambah Artist akan segera hadir!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          const SizedBox(height: 4), // Spacing yang ketat seperti sebelumnya
          // Tambah Playlist Button - Spotify Style
          _buildSpotifyStyleButton(
            title: 'Tambahkan playlist',
            onTap: () {
              _showCreatePlaylistFlow();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyStyleButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16), // Slightly larger radius
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 8), // Compact padding seperti sebelumnya
        child: Row(
          children: [
            // Plus icon in circle - Spotify style (bigger)
            Container(
              width: 52, // Slightly smaller for Spotify-like compact look
              height: 52, // Slightly smaller for Spotify-like compact look
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28, // Increased from 24
              ),
            ),
            const SizedBox(width: 16), // Compact spacing like Spotify
            // Text
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18, // Increased from 16
                  fontWeight: FontWeight.w600, // Increased from w500
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistCreationFlow(
          onSuccess: () {
            // Refresh playlists if needed
          },
        ),
      ),
    );
  }
}
