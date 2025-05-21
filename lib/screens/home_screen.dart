import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../routes.dart';
import 'playlist_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../features/auth/auth_controller.dart';
import '../features/play_history/play_history_controller.dart';
import '../models/play_history.dart';
import '../services/pocketbase_service.dart';

// Helper function to check if host is reachable
Future<bool> isHostReachable(String url) async {
  try {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        return http.Response('Timeout', 408);
      },
    );
    print('Host connection test: $url - ${response.statusCode}');
    return response.statusCode < 400;
  } catch (e) {
    print('Host connection error: $url - $e');
    return false;
  }
}

// Test and determine the best PocketBase URL
Future<String> determinePocketBaseUrl() async {
  final List<String> possibleUrls = [
    'http://10.0.2.2:8090',      // Standard Android emulator
    'http://127.0.0.1:8090',     // iOS simulator or local
  ];
  
  // If you're using a physical device, add your computer's IP here
  // possibleUrls.add('http://192.168.1.100:8090');
  
  for (final url in possibleUrls) {
    print('Testing connection to: $url');
    if (await isHostReachable('$url/api/health')) {
      print('Successfully connected to: $url');
      return url;
    }
  }
  
  // Default to Android emulator address if nothing works
  return Platform.isAndroid ? 'http://10.0.2.2:8090' : 'http://127.0.0.1:8090';
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
    print('PocketBase initialized with URL: ${pb.baseUrl}');
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
  
  print('Current userId: $userId'); // Debug log for user ID
  
  if (userId == null) {
    print('User not logged in or userId is null');
    return [];
  }
  
  try {
    print('Attempting to connect to PocketBase at: ${pb.baseUrl}');
    
    // Verify we can reach the server
    final isReachable = await isHostReachable('${pb.baseUrl}/api/collections/user_history/records');
    if (!isReachable) {
      print('WARNING: Cannot reach PocketBase server at ${pb.baseUrl}');
    }
    
    // Direct test to check if record exists without filter
    try {
      final allRecords = await pb.collection('user_history').getFullList();
      print('All user_history records (no filter): ${allRecords.length}');
      
      for (final record in allRecords) {
        print('Record ID: ${record.id}');
        print('  user_id value: ${record.data['user_id']}');
        print('  song_id value: ${record.data['song_id']}');
      }
    } catch (e) {
      print('Error fetching all records: $e');
    }
    
    // First try direct filter on user_id
    var recentlyPlayed = await pb.collection('user_history').getList(
      page: 1,
      perPage: 3,
      filter: 'user_id = "$userId"',
      sort: '-played_at',
      // Start with simpler expand
      expand: 'song_id',
    );
    
    print('Recently played count with direct filter: ${recentlyPlayed.items.length}');
    
    // If nothing found, try getting all history and printing info for debugging
    if (recentlyPlayed.items.isEmpty) {
      print('No history found with direct filter, trying all records...');
      
      // Try with different filter format
      try {
        final altQuery = await pb.collection('user_history').getList(
          page: 1,
          perPage: 10,
          filter: 'user_id.id = "$userId"',
        );
        print('Alternative query results: ${altQuery.items.length}');
      } catch (e) {
        print('Alternative query error: $e');
      }
    }
    
    return recentlyPlayed.items;
  } catch (e, stackTrace) {
    print('Error fetching recently played songs: $e');
    print('Stack trace: $stackTrace');
    return [];
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load play history when screen builds, tapi dengan try-catch
    try {
      // Gunakan Future.microtask untuk menghindari setState selama build
      Future.microtask(() {
        ref.read(playHistoryControllerProvider.notifier).loadRecentlyPlayed();
      });
    } catch (e) {
      print('Error loading play history: $e');
    }
    
    // Get the bottom padding to account for system navigation bars
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      // Use resizeToAvoidBottomInset: false to prevent keyboard from pushing up content
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // We'll handle bottom padding ourselves
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context, ref),
              const SizedBox(height: 16),
              _buildContinueListening(context),
              const SizedBox(height: 30),
              _buildYourTopMixes(context),
              const SizedBox(height: 30),
              _buildRecentListening(context, ref),
              // Add debug button only in development
              _buildDebugSection(context, ref),
              // Add a bottom spacing to account for the navigation bar
              SizedBox(
                  height: 70 + bottomPadding), // Fixed to a more reasonable size
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user?.data['name'] ?? 'User';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 58, // Increased to safely accommodate the content
        padding: const EdgeInsets.only(bottom: 2), // Add bottom padding for extra safety
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
                SizedBox(
                  width: 140, // Slightly reduced to prevent potential overflow
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Keep this to prevent overflow
                    mainAxisAlignment: MainAxisAlignment.center, // Center text vertically
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18, // Slightly reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14, // Slightly reduced font size
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
                GestureDetector(
                  onTap: () {
                    _showProfileMenu(context, ref);
                  },
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueListening(BuildContext context) {
    // Implementation remains the same
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlaylistScreen()),
                  );
                },
                child: _buildPlaylistCard(
                  'Lo-Fi Loft',
                  Icons.headphones,
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF1E1E1E), Color(0xFF0D0D0D)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // For brevity, I'm assuming the other widget methods remain unchanged
  // Other methods would follow here: _buildYourTopMixes, _buildRecentListening, etc.

  Widget _buildPlaylistCard(
    String title,
    IconData icon, {
    LinearGradient? gradient,
    Color iconColor = Colors.white,
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
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Profile Options',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.white),
                title: const Text(
                  'View Profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Add profile view navigation here
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  // Logout logic
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.authOptions,
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Remaining method implementations would follow...
  Widget _buildYourTopMixes(BuildContext context) {
    // Implementation would be here
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlaylistScreen()),
                  );
                },
                child: _buildMixCard(
                  'Lofi Mix',
                  Colors.blue.shade400,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentListening(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recently Played',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            // Temporary fallback to hardcoded data for development
            // Set to false to use real data
            
        
            
            // Watch play history state instead of direct provider
            final playHistoryState = ref.watch(playHistoryControllerProvider);
            
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
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            
            // Show empty state
            if (playHistoryState.recentlyPlayed.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No recently played songs',
                    style: TextStyle(color: Colors.grey),
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
                final history = playHistoryState.recentlyPlayed[index];
                
                return Column(
                  children: [
                    _buildRecentCard(
                      history.songTitle ?? 'Unknown Song', 
                      'Song • ${history.artistName ?? 'Unknown Artist'}',
                      history.albumCoverUrl ?? 'https://via.placeholder.com/300/5D4037/FFFFFF?text=No+Cover'
                    ),
                    if (index < playHistoryState.recentlyPlayed.length - 1)
                      const SizedBox(height: 12),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMixCard(
    String title,
    Color color, {
    required Gradient gradient,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Based on your listening',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard(String title, String subtitle, String imageUrl) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade800,
            image: imageUrl.startsWith('http')
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image: AssetImage(imageUrl),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
      ],
    );
  }

  // DEBUG: Add a debug section for testing
  Widget _buildDebugSection(BuildContext context, WidgetRef ref) {
    // Get current auth state for displaying user ID
    final authState = ref.watch(authControllerProvider);
    final userId = authState.user?.id ?? 'Not logged in';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Tools (User: $userId)',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Manually reload play history
                  ref.read(playHistoryControllerProvider.notifier).loadRecentlyPlayed();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reloading play history...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                child: const Text('Reload History'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Get the current user ID
                    final authState = ref.read(authControllerProvider);
                    final userId = authState.user?.id;
                    
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: Not logged in')),
                      );
                      return;
                    }
                    
                    // Use pocketBaseService directly to avoid provider conflicts
                    final pbInstance = pocketBaseService.pb;
                    
                    // Find a song to use
                    final songs = await pbInstance.collection('songs').getList(page: 1, perPage: 1);
                    if (songs.items.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: No songs found')),
                      );
                      return;
                    }
                    
                    final songId = songs.items[0].id;
                    
                    // Create test history entry
                    await pbInstance.collection('user_history').create(body: {
                      'user_id': userId,
                      'song_id': songId,
                      'play_duration_seconds': 180,
                      'completed': true,
                      'played_at': DateTime.now().toIso8601String(),
                    });
                    
                    // Reload history
                    await ref.read(playHistoryControllerProvider.notifier).loadRecentlyPlayed();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test history created successfully')),
                      );
                    }
                  } catch (e) {
                    print('Error creating test history: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: const Text('Add Test Play'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Force refresh everything
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Force refreshing all data...')),
                    );
                    
                    // 1. Try to initialize PocketBase again
                    await pocketBaseService.initialize();
                    
                    // 2. Print current auth status
                    final pb = pocketBaseService.pb;
                    print('DEBUG: PocketBase URL: ${pb.baseUrl}');
                    print('DEBUG: Auth valid: ${pb.authStore.isValid}');
                    print('DEBUG: User ID: ${pb.authStore.model?.id}');
                    
                    // 3. Reload state
                    await ref.read(playHistoryControllerProvider.notifier).loadRecentlyPlayed();
                    
                    // 4. Verify we can access collections directly
                    final songs = await pb.collection('songs').getList(page: 1, perPage: 1);
                    print('DEBUG: Songs collection accessible: ${songs.items.length} items');
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refresh complete!')),
                    );
                  } catch (e) {
                    print('Error during force refresh: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Force Refresh'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Validating API access...')),
                    );
                    
                    // Run API validation
                    await pocketBaseService.validateAPIAccess();
                    
                    // Test direct user history query
                    final pb = pocketBaseService.pb;
                    print('===== TESTING USER HISTORY QUERY =====');
                    
                    // Get current user ID
                    final userId = pb.authStore.model?.id;
                    if (userId == null) {
                      print('No user ID available');
                      return;
                    }
                    
                    print('Current user ID: $userId');
                    
                    // Try each filter option
                    print('Testing filter: user_id = "$userId"');
                    try {
                      final result = await pb.collection('user_history').getList(
                        page: 1, 
                        perPage: 10,
                        filter: 'user_id = "$userId"',
                      );
                      print('Result: ${result.items.length} items');
                      for (final item in result.items) {
                        print('Item ${item.id}: user_id=${item.data['user_id']}, song_id=${item.data['song_id']}');
                      }
                    } catch (e) {
                      print('Error with filter: $e');
                    }
                    
                    // Check user_history for this user
                    print('Testing all user_history records...');
                    try {
                      final result = await pb.collection('user_history').getFullList();
                      print('Total history records: ${result.length}');
                      for (final item in result) {
                        print('History ${item.id}: user_id=${item.data['user_id']}, matches current user: ${item.data['user_id'] == userId}');
                      }
                    } catch (e) {
                      print('Error checking all history: $e');
                    }
                    
                    print('===== QUERY TEST COMPLETE =====');
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API validation complete - check console')),
                      );
                    }
                  } catch (e) {
                    print('Error during API validation: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Check API & Relations'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
