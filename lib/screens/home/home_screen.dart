import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:http/http.dart' as http;
import 'package:auto_route/auto_route.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/player_controller.dart';
import '../../utils/image_helpers.dart';
import '../../providers/play_history_provider.dart';
import '../../providers/genre_provider.dart';
import '../../providers/shorts_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/song_item_widget.dart';
import '../../widgets/video_thumbnail_widget.dart';
import '../../utils/font_usage_guide.dart';
import '../../utils/video_audio_manager.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_config.dart';

// Helper function to check if host is reachable
Future<bool> isHostReachable(String url) async {
  try {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Timeout', 408);
      },
    );
    return response.statusCode < 400;
  } catch (e) {
    return false;
  }
}

// Test and determine the best PocketBase URL using AppConfig
Future<String> determinePocketBaseUrl() async {
  // Use the proper URL list from AppConfig (Android emulator prioritized)
  final List<String> possibleUrls = AppConfig.possibleUrls;
  
  
  for (final url in possibleUrls) {
    try {
      final response = await http.get(
        Uri.parse('$url/api/health'),
        headers: AppConfig.getHeadersForUrl(url),
      ).timeout(
        AppConfig.shortTimeout,
        onTimeout: () {
          return http.Response('Timeout', 408);
        },
      );
      
      if (response.statusCode < 400) {
        return url;
      }
    } catch (e) {
      // Continue to next URL
    }
  }
  
  // Use default URL from AppConfig if all fail
  return AppConfig.defaultUrl;
}

// PocketBase instance with lazy initialization
late PocketBase pb;
bool isPbInitialized = false;

// Provider to ensure PocketBase is initialized before use
final pocketBaseInitProvider = FutureProvider<PocketBase>((ref) async {
  if (!isPbInitialized) {
    final url = await determinePocketBaseUrl();
    pb = PocketBase(url);
    isPbInitialized = true;
  }
  return pb;
});

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Provider for recently played songs
final recentlyPlayedProvider = FutureProvider<List<RecordModel>>((ref) async {
  // First ensure PocketBase is initialized with correct URL
  await ref.watch(pocketBaseInitProvider.future);
  
  final authState = ref.watch(authControllerProvider);
  final userId = authState.user?.id;
  
  if (userId == null) {
    return [];
  }
  
  try {
    // Verify we can reach the server
    final isReachable = await isHostReachable('${pb.baseUrl}/api/collections/recent_plays/records');
    if (!isReachable) {
      return [];
    }
    
    // First try direct filter on user_id
    var recentlyPlayed = await pb.collection('recent_plays').getList(
      page: 1,
      perPage: 3,
      filter: 'user_id = "$userId"',
      sort: '-played_at',
      expand: 'song_id',
    );
    
    return recentlyPlayed.items;
  } catch (e) {
    return [];
  }
});

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs
  
  bool _hasLoadedInitialData = false;
  bool _shouldPauseVideos = false; // Track if we should pause videos when music is playing
  bool _hasClearedFilterOnReturn = false; // Track if we've cleared filter on return
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load genres for proper genre name display
      ref.read(genreProvider.notifier).loadGenres();
      
      // Always load ALL shorts for home screen (clear any existing filter)
      ref.read(shortsProvider.notifier).clearFilter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if this route is becoming active and clear filter if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final route = ModalRoute.of(context);
        if (route?.isCurrent == true && !_hasClearedFilterOnReturn) {
          final shortsState = ref.read(shortsProvider);
          // Only clear filter if we have a genre filter active
          if (shortsState.currentGenreFilter != null) {
            debugPrint('🏠 Home screen: Route became active, clearing genre filter');
            _hasClearedFilterOnReturn = true;
            await ref.read(shortsProvider.notifier).clearFilter();
            // Reset the flag after a delay to allow future clears
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _hasClearedFilterOnReturn = false;
              }
            });
          }
        }
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh data when app comes back to foreground (user returns from other apps)
    if (state == AppLifecycleState.resumed && _hasLoadedInitialData && mounted) {
      Future.microtask(() {
        ref.read(playHistoryProvider.notifier).loadRecentlyPlayed();
        
        // Also clear shorts filter if we have one active
        final shortsState = ref.read(shortsProvider);
        if (shortsState.currentGenreFilter != null && !_hasClearedFilterOnReturn) {
          debugPrint('🏠 Home screen: App resumed, clearing genre filter');
          _hasClearedFilterOnReturn = true;
          ref.read(shortsProvider.notifier).clearFilter().then((_) {
            // Reset the flag after clearing
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _hasClearedFilterOnReturn = false;
              }
            });
          });
        }
      });
    }
    
    // Update global video audio manager based on app lifecycle
    if (state == AppLifecycleState.paused) {
      ref.read(videoAudioManagerProvider.notifier).appPaused();
      setState(() {
        _shouldPauseVideos = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      ref.read(videoAudioManagerProvider.notifier).appResumed();
      setState(() {
        _shouldPauseVideos = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    // Manual refresh via pull-to-refresh using new providers
    await Future.wait<void>([
      ref.read(playHistoryProvider.notifier).loadRecentlyPlayed(),
      ref.read(genreProvider.notifier).loadGenres(),
      ref.read(shortsProvider.notifier).refreshShorts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // Check if we need to clear filter when home screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasClearedFilterOnReturn) {
        final shortsState = ref.read(shortsProvider);
        if (shortsState.currentGenreFilter != null) {
          debugPrint('🏠 Home screen: Build detected filter, clearing');
          _hasClearedFilterOnReturn = true;
          ref.read(shortsProvider.notifier).clearFilter().then((_) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _hasClearedFilterOnReturn = false;
              }
            });
          });
        }
      }
    });
    
    // Removed auto-refresh listener to prevent Recently Played list from reordering
    // while user is interacting with the home screen. Data will only refresh when:
    // 1. User first opens the app
    // 2. User navigates back to home screen from other screens
    // 3. User manually pulls to refresh (if implemented)
    
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      // Use resizeToAvoidBottomInset: false to prevent keyboard from pushing up content
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // Ensure proper SafeArea handling for status bar
        top: true,
        bottom: false,
        child: Container(
          // Ensure consistent background color
          color: AppColors.surfaceDark,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        _buildContinueListening(context),
                        const SizedBox(height: 30),
                        _buildYourTopMixes(context),
                        const SizedBox(height: 30),
                        _buildRecentListening(context),
                        // Add a bottom spacing to account for the navigation bar and mini player
                        SizedBox(height: 70 + bottomPadding + 64), // Added 64 for mini player
                      ],
                    ),
                  ),
                ),
              ),
              // Mini Player
              const MiniPlayer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    // Get the PocketBase URL
    final pocketBaseUrl = ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 50, // Match exact height with explore and library screens
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
                  width: 145, // Match width constraint with other screens
                  child: Text(
                    'Home',
                    style: FontUsageGuide.appBarTitle.copyWith(fontSize: 25),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: Handle notifications
                  },
                  child: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 28),
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
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    _showProfileMenu(context);
                  },
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 28),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueListening(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Continue Listening',
            style: FontUsageGuide.homeSectionHeader,
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            // Watch new genre provider
            final genreState = ref.watch(genreProvider);
            
            // Show loading state
            if (genreState.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Show error state
            if (genreState.error != null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Error: ${genreState.error}',
                    style: FontUsageGuide.authErrorText,
                  ),
                ),
              );
            }
            
            // Show empty state
            if (genreState.genres.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No genres available',
                    style: FontUsageGuide.authFieldLabel.copyWith(color: Colors.grey),
                  ),
                ),
              );
            }
            
            // Get the PocketBase URL for image URLs
            
            // Show genres grid
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: genreState.genres.take(6).map((genre) {
                  // Map genre icon names to Material icons
                  IconData icon = Icons.music_note;
                  final genreName = genre.name.toLowerCase();
                  
                  if (genreName.contains('jazz')) {
                    icon = Icons.coffee;
                  } else if (genreName.contains('release')) {
                    icon = Icons.new_releases;
                  } else if (genreName.contains('anything')) {
                    icon = Icons.all_inclusive;
                  } else if (genreName.contains('anime')) {
                    icon = Icons.music_note;
                  } else if (genreName.contains('house')) {
                    icon = Icons.house;
                  } else if (genreName.contains('lo-fi')) {
                    icon = Icons.headphones;
                  }
                  
                  return _buildPlaylistCard(
                    genre.name,
                    icon,
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: AppColors.homeGradient,
                    ),
                    imageUrl: genre.iconUrl,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Updating the _buildPlaylistCard method to accept an image URL
  Widget _buildPlaylistCard(
    String title,
    IconData icon, {
    LinearGradient? gradient,
    Color iconColor = Colors.white,
    String? imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (imageUrl != null && ImageHelpers.isValidImageUrl(imageUrl))
              ImageHelpers.buildSafeNetworkImage(
                imageUrl: imageUrl,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(4),
                fallbackWidget: Icon(icon, color: iconColor),
              )
            else
              Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: FontUsageGuide.authFieldLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final userName = user?.getName() ?? 'User';
    final userEmail = user?.getEmail() ?? '';
    
    // Get the PocketBase URL
    final pocketBaseUrl = ref.watch(pocketBaseInitProvider).valueOrNull?.baseUrl;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Profile',
                      style: FontUsageGuide.homeSectionHeader,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // User profile card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with glow effect
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.6),
                            AppColors.primary.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                      child: UserAvatar(
                        user: user,
                        baseUrl: pocketBaseUrl,
                        size: 64,
                        iconSize: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: FontUsageGuide.modalTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userEmail,
                            style: FontUsageGuide.authFieldLabel.copyWith(color: Colors.grey.shade400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    // View Profile button
                    _buildProfileAction(
                      icon: Icons.person_outline,
                      title: 'View Profile',
                      subtitle: 'Manage your profile information',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.router.push(const EditProfileRoute());
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Sign Out button
                    _buildProfileAction(
                      icon: Icons.logout_outlined,
                      title: 'Sign Out',
                      subtitle: 'Sign out from your account',
                      color: Colors.red.shade400,
                      isDestructive: true,
                      onTap: () async {
                        Navigator.of(context).pop();
                        // Show confirmation dialog
                        _showLogoutConfirmation(context, ref);
                      },
                    ),
                  ],
                ),
              ),
              
              // Bottom safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build profile action buttons
  Widget _buildProfileAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive 
              ? Colors.red.shade900.withValues(alpha: 0.1)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive 
                ? Colors.red.shade800.withValues(alpha: 0.3)
                : Colors.grey.shade800,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade800.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FontUsageGuide.authButtonText.copyWith(
                      color: isDestructive ? Colors.red.shade400 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: FontUsageGuide.listMetadata.copyWith(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade600,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show logout confirmation
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sign Out',
            style: FontUsageGuide.modalTitle.copyWith(fontSize: 20),
          ),
          content: Text(
            'Are you sure you want to sign out from your account?',
            style: FontUsageGuide.modalBody.copyWith(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: FontUsageGuide.modalButton.copyWith(color: Colors.grey.shade400),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                );
                
                // Logout logic
                await ref.read(authControllerProvider.notifier).logout();
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // Dismiss loading
                  context.router.replace(const AuthOptionsRoute());
                }
              },
              child: Text(
                'Sign Out',
                style: FontUsageGuide.modalButton.copyWith(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Remaining method implementations would follow...
  Widget _buildYourTopMixes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Shorts',
            style: FontUsageGuide.homeSectionHeader,
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final shortsState = ref.watch(shortsProvider);
            
            // Show loading state or when clearing filter
            if (shortsState.isLoading || 
                (shortsState.currentGenreFilter != null && _hasClearedFilterOnReturn)) {
              return const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            
            // Show error state
            if (shortsState.error != null) {
              return SizedBox(
                height: 240,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load shorts',
                        style: FontUsageGuide.authErrorText,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Show empty state
            if (shortsState.shorts.isEmpty) {
              return SizedBox(
                height: 240,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        color: Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No shorts available',
                        style: FontUsageGuide.authFieldLabel.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Debug: Log current shorts state
            debugPrint('🏠 Home screen: Building shorts section');
            debugPrint('🏠 Current genre filter: ${shortsState.currentGenreFilter}');
            debugPrint('🏠 Has cleared filter flag: $_hasClearedFilterOnReturn');
            debugPrint('🏠 Total shorts: ${shortsState.shorts.length}');
            debugPrint('🏠 Shorts IDs: ${shortsState.shorts.map((s) => s.id).take(5).toList()}');
            
            // Group shorts by genre to avoid duplicates
            final shortsGroupedByGenre = <String, Map<String, dynamic>>{};
            
            for (final short in shortsState.shorts) {
              // Get genre info from expanded data
              final genreInfo = _getGenreInfoFromShort(short);
              final genreName = genreInfo['name'] as String;
              final genreId = genreInfo['id'] as String;
              
              if (!shortsGroupedByGenre.containsKey(genreName)) {
                shortsGroupedByGenre[genreName] = {
                  'id': genreId,
                  'name': genreName,
                  'shorts': <dynamic>[],
                };
              }
              shortsGroupedByGenre[genreName]!['shorts'].add(short);
            }
            
            // Convert to list and take up to 6 genre categories
            final genreEntries = shortsGroupedByGenre.entries.take(6).toList();
            
            // Debug: Log grouping results
            debugPrint('🏠 Genre groups found: ${genreEntries.map((e) => e.key).toList()}');
            
            return SizedBox(
              height: 260,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                itemCount: genreEntries.length,
                itemBuilder: (context, index) {
                  final entry = genreEntries[index];
                  final genreName = entry.key;
                  final genreData = entry.value;
                  final genreId = genreData['id'] as String;
                  final genreShorts = genreData['shorts'] as List<dynamic>;
                  final firstShort = genreShorts.first;
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < genreEntries.length - 1 ? 12 : 0,
                    ),
                    child: _buildShortsVideoCard(
                      context,
                      genreName,
                      firstShort,
                      () {
                        // Navigate to shorts screen with specific genre
                        context.router.push(ShortsRoute(initialGenreId: genreId));
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
  
  /// Extract genre info from short data
  Map<String, String> _getGenreInfoFromShort(dynamic short) {
    try {
      // Debug: Print short data to understand structure
      debugPrint('📹 Short data: ${short.toString()}');
      
      // If it's a Shorts object from our model
      if (short.runtimeType.toString().contains('Shorts')) {
         // Try to access genresId to get genre from genre provider
         final genreId = short.genresId;
         debugPrint('📹 Genre ID: $genreId');
         
         if (genreId != null && genreId.isNotEmpty) {
           final genreState = ref.read(genreProvider);
           debugPrint('📹 Available genres: ${genreState.genres.map((g) => '${g.id}: ${g.name}').toList()}');
           
            try {
              final genre = genreState.genres.firstWhere((g) => g.id == genreId);
              debugPrint('📹 Found genre: ${genre.name}');
              return {
                'id': genreId,
                'name': genre.name,
              };
            } catch (e) {
              debugPrint('📹 Genre not found for ID: $genreId');
              // Genre not found, return fallback with ID
              return {
                'id': genreId,
                'name': 'Music',
              };
            }
         }
         
         // If no genre ID, try to get artist name as category
         try {
           if (short.artistName != null && short.artistName.isNotEmpty) {
             return {
               'id': short.artistId ?? '',
               'name': '${short.artistName}',
             };
           }
         } catch (e) {
           debugPrint('📹 Error accessing artist name: $e');
         }
       }
       
       // Final fallback
       return {
         'id': '',
         'name': 'Music',
       };
    } catch (e) {
      debugPrint('❌ Error getting genre info: $e');
      return {
        'id': '',
        'name': 'Shorts',
      };
    }
  }

  Widget _buildRecentListening(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recently Played',
            style: FontUsageGuide.homeSectionHeader,
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            // Watch new play history provider
            final playHistoryState = ref.watch(playHistoryProvider);
            
            // Show loading indicator
            if (playHistoryState.isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Show error
            if (playHistoryState.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Text(
                    'Error: ${playHistoryState.error}',
                    style: FontUsageGuide.authErrorText,
                  ),
                ),
              );
            }
            
            // Show empty state
            if (playHistoryState.recentlyPlayed.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No recently played songs',
                    style: FontUsageGuide.authFieldLabel.copyWith(color: Colors.grey),
                  ),
                ),
              );
            }
            
            // Show list of recently played songs
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playHistoryState.recentlyPlayed.length,
              itemBuilder: (context, index) {
                final song = playHistoryState.recentlyPlayed[index];
                
                return Column(
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final playerState = ref.watch(playerControllerProvider);
                        final isCurrentSong = playerState.currentSong?.id == song.id;
                        final isPlaying = isCurrentSong && playerState.isPlaying;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              // Song number with play indicator
                              SizedBox(
                                width: 24,
                                child: isPlaying
                                    ? const Icon(
                                        Icons.volume_up,
                                        color: Colors.red,
                                        size: 16,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: FontUsageGuide.authButtonText.copyWith(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                              const SizedBox(width: 12),

                              // Use SongItemWidget for consistency
                              Expanded(
                                child: SongItemWidget(
                                  song: song,
                                  subtitle: 'Song • ${song.artist}',
                                  contentPadding: EdgeInsets.zero,
                                  isCurrentSong: isCurrentSong,
                                  isPlaying: isPlaying,
                                  onTap: () {
                                    // Use playSongById to load complete song data without playlist context
                                    ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
                                    
                                    // Color extraction will be handled automatically by mini_player when song changes
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (index < playHistoryState.recentlyPlayed.length - 1)
                      const SizedBox(height: 4),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildShortsVideoCard(
    BuildContext context,
    String genreName,
    dynamic short,
    VoidCallback onTap,
  ) {
    final String title = '${genreName.substring(0, 1).toUpperCase()}${genreName.substring(1)} Shorts';
    
    return SizedBox(
      width: 140, // Increased back to larger size
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail with fixed aspect ratio for portrait videos - FULL coverage
          Container(
            width: 140, // Width tetap
            height: 220, // Height ditambah untuk lebih vertical
                                child: Consumer(
                      builder: (context, ref, child) {
                        // Use global video audio manager for better coordination
                        final videoAudioState = ref.watch(videoAudioManagerProvider);
                        final playerState = ref.watch(playerControllerProvider);
                        
                        // Update global state when music playing status changes
                        if (playerState.isPlaying != videoAudioState.isMusicPlaying) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (playerState.isPlaying) {
                              ref.read(videoAudioManagerProvider.notifier).musicStarted();
                            } else {
                              ref.read(videoAudioManagerProvider.notifier).musicStopped();
                            }
                          });
                        }
                        
                        return VideoThumbnailWidget(
                          videoUrl: short.videoUrl ?? '',
                          width: 140,
                          height: 220,
                          borderRadius: BorderRadius.circular(8),
                          onTap: onTap,
                          shouldPause: videoAudioState.shouldPauseVideos,
                          autoPlay: true,
                          enableLooping: true,
                          showPlayIcon: false, // No play icon for auto-playing preview
                        );
                      },
                    ),
          ),
          
          SizedBox(height: 8),
          
          // Genre title only
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              style: FontUsageGuide.modalTitle.copyWith(
                fontSize: 13,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}



