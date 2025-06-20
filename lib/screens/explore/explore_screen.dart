import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/app_colors.dart';
import '../../utils/font_usage_guide.dart';
import '../../routes/app_router.dart';
import '../../widgets/mini_player.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/genre_card.dart';
import '../../widgets/dynamic_genre_card.dart';
import '../../widgets/spotify_search_bar.dart';
import '../../widgets/song_item_widget.dart';
import '../../models/genre.dart';
import '../../repositories/genre_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../providers/play_history_provider.dart';

@RoutePage()
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late GenreRepository _genreRepository;
  List<Genre> _topGenres = [];
  bool _isLoadingGenres = true;

  @override
  void initState() {
    super.initState();
    _genreRepository = GenreRepository(PocketBaseService());
    _loadTopGenres();
  }

  Future<void> _loadTopGenres() async {
    try {
      final genres = await _genreRepository.getAllGenres();
      print('DEBUG: Loaded ${genres.length} genres from database');
      for (final genre in genres) {
        print('DEBUG: Genre: ${genre.name}, ID: ${genre.id}, Image: ${genre.image}');
      }
      
      if (mounted) {
        setState(() {
          // Take first 4 genres for "Your Top Genres" section
          _topGenres = genres.take(4).toList();
          _isLoadingGenres = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading genres: $e');
      if (mounted) {
        setState(() {
          _isLoadingGenres = false;
          // Use empty list on error
          _topGenres = [];
        });
      }
    }
  }

  void _navigateToGenre(Genre genre) {
    context.router.push(GenreRoute(
      genreId: genre.id,
      genreName: genre.name,
      sourceTabIndex: 1, // Explore tab
    ));
  }

  /// Show recently played modal
  void _showRecentlyPlayedModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Recently Played',
                          style: FontUsageGuide.homeSectionHeader,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final playHistoryState = ref.watch(playHistoryProvider);
                        
                        if (playHistoryState.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (playHistoryState.recentlyPlayed.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: Colors.grey[600]),
                                const SizedBox(height: 16),
                                Text(
                                  'No recently played songs',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: playHistoryState.recentlyPlayed.length,
                          itemBuilder: (context, index) {
                            final song = playHistoryState.recentlyPlayed[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SongItemWidget(
                                song: song,
                                subtitle: 'Song • ${song.artist}',
                                onTap: () {
                                  Navigator.pop(context);
                                  ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false, // Don't apply bottom safe area to avoid double padding
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16), // Consistent top spacing
                    _buildSearchHeader(context, ref),
                    const SizedBox(height: 16), // Consistent spacing
                    _buildSearchBar(context),
                    const SizedBox(height: 24), // Adjusted spacing
                    _buildYourTopGenres(),
                    const SizedBox(height: 30),
                    _buildBrowseAll(),
                    // Add a bottom spacing to account for the navigation bar and mini player
                    SizedBox(height: 70 + bottomPadding + (playerState.currentSong != null ? 64 : 0)),
                  ],
                ),
              ),
            ),
          ),
          // Show mini player if there's a current song
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
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
                  child: Text(
                    'Search',
                    style: FontUsageGuide.appBarTitle.copyWith(fontSize: 25),
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

  Widget _buildSearchBar(BuildContext context) {
    return SpotifySearchBar(
      hintText: 'Apa yang ingin kamu dengarkan?',
      readOnly: true,
      onTap: () {
        // Navigate to search screen
        context.router.push(const SearchRoute());
      },
    );
  }

  Widget _buildYourTopGenres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Your Top Genres',
                style: FontUsageGuide.homeSectionHeader,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'TRENDING',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isLoadingGenres
              ? _buildLoadingGenres()
              : _topGenres.isEmpty
                  ? _buildEmptyGenres()
                  : _buildDynamicGenreGrid(),
        ),
      ],
    );
  }
  
  Widget _buildDynamicGenreGrid() {
    if (_topGenres.length == 1) {
      // Single large card
      return SizedBox(
        height: 160,
        child: DynamicGenreCard(
          genre: _topGenres[0],
          onTap: () => _navigateToGenre(_topGenres[0]),
        ),
      );
    } else if (_topGenres.length == 2) {
      // Two cards side by side
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 140,
              child: DynamicGenreCard(
                genre: _topGenres[0],
                onTap: () => _navigateToGenre(_topGenres[0]),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 140,
              child: DynamicGenreCard(
                genre: _topGenres[1],
                onTap: () => _navigateToGenre(_topGenres[1]),
              ),
            ),
          ),
        ],
      );
    } else if (_topGenres.length == 3) {
      // Asymmetric layout: one big on left, two small on right
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            // Large card on left
            Expanded(
              flex: 3,
              child: DynamicGenreCard(
                genre: _topGenres[0],
                onTap: () => _navigateToGenre(_topGenres[0]),
              ),
            ),
            const SizedBox(width: 16),
            // Two smaller cards on right
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: DynamicGenreCard(
                      genre: _topGenres[1],
                      onTap: () => _navigateToGenre(_topGenres[1]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DynamicGenreCard(
                      genre: _topGenres[2],
                      onTap: () => _navigateToGenre(_topGenres[2]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Default 2x2 grid for 4+ items
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _topGenres.take(4).map((genre) {
          return DynamicGenreCard(
            genre: genre,
            onTap: () => _navigateToGenre(genre),
          );
        }).toList(),
      );
    }
  }

  Widget _buildLoadingGenres() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyGenres() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No genres available',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseAll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Browse All',
                style: FontUsageGuide.homeSectionHeader,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildEnhancedGenreGrid(),
        ),
      ],
    );
  }
  
  Widget _buildEnhancedGenreGrid() {
    final categories = [
      {
        'title': 'My\nFavorites',
        'color': const Color(0xFFE91E63), // Pink
        'icon': Icons.favorite,
        'isGradient': true,
        'action': () => context.router.push(const FavoritesRoute()),
      },
      {
        'title': 'Trending\nShorts',
        'color': const Color(0xFF9C27B0), // Purple
        'icon': Icons.trending_up,
        'isGradient': true,
        'action': () => context.router.push(ShortsRoute()),
      },
      {
        'title': 'Recently\nPlayed',
        'color': const Color(0xFF607D8B), // Blue grey
        'icon': Icons.history,
        'isGradient': false,
        'action': () => _showRecentlyPlayedModal(),
      },
      {
        'title': 'Search\nMusic',
        'color': const Color(0xFF4CAF50), // Green
        'icon': Icons.search,
        'isGradient': false,
        'action': () => context.router.push(const SearchRoute()),
      },
      {
        'title': 'My\nLibrary',
        'color': const Color(0xFFFF9800), // Orange
        'icon': Icons.library_music,
        'isGradient': true,
        'action': () => context.router.push(const LibraryRoute()),
      },
      {
        'title': 'Artist\nSelection',
        'color': const Color(0xFF00BCD4), // Cyan
        'icon': Icons.person,
        'isGradient': false,
        'action': () => context.router.push(const ArtistSelectionRoute()),
      },
    ];

    // Add admin tools for authenticated users
    final authState = ref.watch(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      categories.add({
        'title': 'Admin\nTools',
        'color': const Color(0xFF795548), // Brown
        'icon': Icons.admin_panel_settings,
        'isGradient': true,
        'action': () => context.router.push(const DurationUpdateRoute()),
      });
    }

    // Adjust layout based on number of categories
    final hasAdminTools = categories.length > 6;
    
    return Column(
      children: [
        // First row with 2 regular cards
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 100,
                child: GenreCard(
                  title: categories[0]['title'] as String,
                  color: categories[0]['color'] as Color,
                  icon: categories[0]['icon'] as IconData,
                  isGradient: categories[0]['isGradient'] as bool,
                  onTap: categories[0]['action'] as VoidCallback?,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 100,
                child: GenreCard(
                  title: categories[1]['title'] as String,
                  color: categories[1]['color'] as Color,
                  icon: categories[1]['icon'] as IconData,
                  isGradient: categories[1]['isGradient'] as bool,
                  onTap: categories[1]['action'] as VoidCallback?,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Second row with 3 smaller cards
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 80,
                child: GenreCard(
                  title: categories[2]['title'] as String,
                  color: categories[2]['color'] as Color,
                  icon: categories[2]['icon'] as IconData,
                  isGradient: categories[2]['isGradient'] as bool,
                  onTap: categories[2]['action'] as VoidCallback?,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 80,
                child: GenreCard(
                  title: categories[3]['title'] as String,
                  color: categories[3]['color'] as Color,
                  icon: categories[3]['icon'] as IconData,
                  isGradient: categories[3]['isGradient'] as bool,
                  onTap: categories[3]['action'] as VoidCallback?,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 80,
                child: GenreCard(
                  title: categories[4]['title'] as String,
                  color: categories[4]['color'] as Color,
                  icon: categories[4]['icon'] as IconData,
                  isGradient: categories[4]['isGradient'] as bool,
                  onTap: categories[4]['action'] as VoidCallback?,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Third row with 1 wide card or 2 cards if admin tools available
        if (hasAdminTools && categories.length >= 7) 
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: GenreCard(
                    title: categories[5]['title'] as String,
                    color: categories[5]['color'] as Color,
                    icon: categories[5]['icon'] as IconData,
                    isGradient: categories[5]['isGradient'] as bool,
                    onTap: categories[5]['action'] as VoidCallback?,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: GenreCard(
                    title: categories[6]['title'] as String,
                    color: categories[6]['color'] as Color,
                    icon: categories[6]['icon'] as IconData,
                    isGradient: categories[6]['isGradient'] as bool,
                    onTap: categories[6]['action'] as VoidCallback?,
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            height: 120,
            child: GenreCard(
              title: categories[5]['title'] as String,
              color: categories[5]['color'] as Color,
              icon: categories[5]['icon'] as IconData,
              isGradient: categories[5]['isGradient'] as bool,
              onTap: categories[5]['action'] as VoidCallback?,
            ),
          ),
      ],
    );
  }


}



