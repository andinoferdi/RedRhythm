import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../utils/app_colors.dart';
import '../../utils/search_history_utils.dart';
import '../../utils/image_helpers.dart';
import '../../models/song.dart';
import '../../routes/app_router.dart';

import '../../controllers/player_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/artist_controller.dart';
import '../../providers/song_provider.dart';
import '../../models/artist.dart';
import '../../repositories/artist_repository.dart';
import '../../services/pocketbase_service.dart';

import '../../widgets/mini_player.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/song_item_widget.dart';
import '../../widgets/animated_sound_bars.dart';


@RoutePage()
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Song> _searchResults = [];
  List<Artist> _artistSearchResults = [];
  List<dynamic> _recentSearches = []; // Changed to dynamic to support both songs and artists
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;
  String? _currentUserId;
  late ArtistRepository _artistRepository;

  @override
  void initState() {
    super.initState();
    _artistRepository = ArtistRepository(PocketBaseService());
    _loadRecentSearches();
    _searchFocusNode.requestFocus();
    
    // Load songs using new provider
    Future.microtask(() {
      ref.read(songProvider.notifier).loadSongs();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if user has changed and reload search history if needed
    final authState = ref.read(authControllerProvider);
    final newUserId = authState.isAuthenticated && authState.user != null ? authState.user!.id : null;
    
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      _loadRecentSearches();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }



  Future<void> _loadRecentSearches() async {
    final authState = ref.read(authControllerProvider);
    List<dynamic> searches = [];
    
    if (authState.isAuthenticated && authState.user != null) {
      // Load both songs and artists from search history
      final songs = await SearchHistoryUtils.getUserSearchHistory(authState.user!.id);
      searches.addAll(songs);
      // TODO: Add artist history loading when implemented
    }
    
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _addToRecentSearches(dynamic item) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      if (item is Song) {
        await SearchHistoryUtils.addSongToUserHistory(authState.user!.id, item);
      }
      // TODO: Add artist to history when implemented
      await _loadRecentSearches();
    }
  }

  Future<void> _removeFromRecentSearches(dynamic item) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      if (item is Song) {
        await SearchHistoryUtils.removeSongFromUserHistory(authState.user!.id, item);
      }
      // TODO: Remove artist from history when implemented
      await _loadRecentSearches();
    }
  }

  Future<void> _clearAllRecentSearches() async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await SearchHistoryUtils.clearUserSearchHistory(authState.user!.id);
    } else {
      await SearchHistoryUtils.clearGuestSearchHistory();
    }
    await _loadRecentSearches();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      // Search both songs and artists
      final songController = ref.read(songProvider.notifier);
      final songResults = songController.searchSongs(query);
      
      final artistResults = await _artistRepository.searchArtists(query);

      setState(() {
        _searchResults = songResults;
        _artistSearchResults = artistResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search: $e';
        _isLoading = false;
      });
    }
  }

  void _playSong(Song song, int index) {
    // Add song to recent searches when played from search results
    _addToRecentSearches(song);
    // Use playSongById to load complete song data without playlist context (like home screen)
    ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
    
    // Color extraction will be handled automatically by mini_player when song changes
  }

  void _openArtistDetail(Artist artist) {
    // Add artist to recent searches
    _addToRecentSearches(artist);
    // Navigate to artist detail screen
    context.router.push(ArtistDetailRoute(
      artistId: artist.id,
      artistName: artist.name,
    ));
  }

  void _playSongFromRecent(Song song) {
    // Use playSongById to load complete song data without playlist context (like home screen)
    ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
    
    // Color extraction will be handled automatically by mini_player when song changes
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _buildSearchContent(),
          ),
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Explore tab index
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSearchHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.router.maybePop(),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari lagu, artis, atau album',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _artistSearchResults = [];
                                _hasSearched = false;
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    } else {
                      setState(() {
                        _searchResults = [];
                        _artistSearchResults = [];
                        _hasSearched = false;
                      });
                    }
                  },
                  onSubmitted: _performSearch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_hasSearched) {
      return _buildSearchResults();
    }

          return _buildRecentSearches();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Terjadi kesalahan',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final hasResults = _searchResults.isNotEmpty || _artistSearchResults.isNotEmpty;
    
    if (!hasResults) {
      return _buildEmptyResults();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Artist results section
        if (_artistSearchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Artis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._artistSearchResults.map((artist) => _buildArtistItem(artist)),
          const SizedBox(height: 16),
        ],
        
        // Song results section
        if (_searchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Lagu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._searchResults.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return _buildSongItem(song, index);
          }),
        ],
      ],
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci yang berbeda',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return _buildEmptyHistory();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pencarian terkini',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearAllRecentSearches,
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final item = _recentSearches[index];
              if (item is Song) {
                return _buildRecentSongItem(item);
              } else if (item is Artist) {
                return _buildRecentArtistItem(item);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Kamu belum mencari apapun',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai cari lagu, artis, atau album favoritmu',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSongItem(Song song) {
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(playerControllerProvider);
        final isCurrentSong = playerState.currentSong?.id == song.id;
        final isPlaying = isCurrentSong && playerState.isPlaying;
        
        return SongItemWidget(
          song: song,
          subtitle: song.artist,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show animated sound bars when playing (same as default SongItemWidget)
              if (isPlaying)
                const AnimatedSoundBars(
                  color: Colors.red,
                  size: 20.0,
                  isAnimating: true,
                )
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
                              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => _removeFromRecentSearches(song),
              ),
            ],
          ),
          onTap: () => _playSongFromRecent(song),
        );
      },
    );
  }

  Widget _buildSongItem(Song song, int index) {
    return Column(
      children: [
        Row(
          children: [
            // Album art
            GestureDetector(
              onTap: () => _playSong(song, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: song.albumArtUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _playSong(song, index),
                    child: Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      // Navigate to artist detail when tapping artist name
                      context.router.push(ArtistDetailRoute(
                        artistId: '',
                        artistName: song.artist,
                      ));
                    },
                    child: Text(
                      song.artist,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'DM Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Play indicator or menu
            Consumer(
              builder: (context, ref, child) {
                final playerState = ref.watch(playerControllerProvider);
                final isCurrentSong = playerState.currentSong?.id == song.id;
                final isPlaying = isCurrentSong && playerState.isPlaying;
                
                if (isPlaying) {
                  return const AnimatedSoundBars(
                    color: Colors.red,
                    size: 20.0,
                    isAnimating: true,
                  );
                }
                return const SizedBox(width: 20);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildArtistItem(Artist artist) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _openArtistDetail(artist),
        child: Row(
          children: [
            // Artist image
            ClipOval(
              child: Container(
                width: 48,
                height: 48,
                color: Colors.grey[800],
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: artist.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Artist info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Artis',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentArtistItem(Artist artist) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Artist image
          ClipOval(
            child: Container(
              width: 48,
              height: 48,
              color: Colors.grey[800],
              child: ImageHelpers.buildSafeNetworkImage(
                imageUrl: artist.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                fallbackWidget: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Artist info
          Expanded(
            child: GestureDetector(
              onTap: () => _openArtistDetail(artist),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Artis',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // Remove button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => _removeFromRecentSearches(artist),
          ),
        ],
      ),
    );
  }
} 

