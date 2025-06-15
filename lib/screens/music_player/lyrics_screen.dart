import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/player_controller.dart';
import '../../models/song.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helpers.dart';

@RoutePage()
class LyricsScreen extends ConsumerStatefulWidget {
  final Song song;
  
  const LyricsScreen({
    super.key,
    required this.song,
  });

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentSong = playerState.currentSong ?? widget.song;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
              onPressed: () => context.router.maybePop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: Implement share lyrics functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share lyrics feature coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // TODO: Implement more options
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.background.withValues(alpha: 0.9),
                      AppColors.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Small album art
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ImageHelpers.buildSafeNetworkImage(
                                  imageUrl: currentSong.albumArtUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  fallbackWidget: Container(
                                    color: AppColors.greyDark,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: AppColors.primary,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Song info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentSong.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentSong.artist,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Lyrics content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildLyricsContent(currentSong),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLyricsContent(Song song) {
    if (song.lyrics == null || song.lyrics!.trim().isEmpty) {
      return _buildNoLyricsState(song);
    }
    
    // Split lyrics into lines for better formatting
    final lyricsLines = song.lyrics!.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lyrics header
        Row(
          children: [
            const Icon(
              Icons.lyrics,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Lyrics',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            // Font size controls
            IconButton(
              icon: const Icon(Icons.text_decrease, color: AppColors.greyLight),
              onPressed: () {
                // TODO: Implement font size decrease
              },
            ),
            IconButton(
              icon: const Icon(Icons.text_increase, color: AppColors.greyLight),
              onPressed: () {
                // TODO: Implement font size increase
              },
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Lyrics text with solid gradient background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE53E3E), // Red primary
                const Color(0xFFD53F8C), // Red-pink
                const Color(0xFFC53030), // Darker red
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53E3E).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lyricsLines.map((line) {
              final trimmedLine = line.trim();
              
              // Empty line for spacing
              if (trimmedLine.isEmpty) {
                return const SizedBox(height: 12);
              }
              
              // Check if it's a chorus or special section (contains brackets)
              final isSpecialSection = trimmedLine.contains('[') && trimmedLine.contains(']');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  trimmedLine,
                  style: TextStyle(
                    color: isSpecialSection ? Colors.white : Colors.white,
                    fontSize: isSpecialSection ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                    fontFamily: 'Poppins',
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Song info footer
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greyDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '♪ ${song.title} - ${song.artist} ♪',
              style: const TextStyle(
                color: AppColors.greyLight,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }
  
  Widget _buildNoLyricsState(Song song) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          
          // Large music note icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.greyDark.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Icon(
              Icons.lyrics_outlined,
              size: 60,
              color: AppColors.greyLight,
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'No lyrics available',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Lyrics for "${song.title}" are not available yet.',
            style: const TextStyle(
              color: AppColors.greyLight,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Check back later or try another song.',
            style: TextStyle(
              color: AppColors.greyLight,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Suggest action button
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement suggest lyrics or report missing lyrics
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suggest lyrics feature coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Suggest Lyrics',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }
} 