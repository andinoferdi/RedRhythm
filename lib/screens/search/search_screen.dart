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
import '../../providers/song_provider.dart';

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
  List<Song> _recentSearchedSongs = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadRecentSearchedSongs();
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
      _loadRecentSearchedSongs();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }



  Future<void> _loadRecentSearchedSongs() async {
    final authState = ref.read(authControllerProvider);
    List<Song> songs = [];
    
    if (authState.isAuthenticated && authState.user != null) {
      songs = await SearchHistoryUtils.getUserSearchHistory(authState.user!.id);
    }
    
    setState(() {
      _recentSearchedSongs = songs;
    });
  }

  Future<void> _saveRecentSearchedSongs() async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await SearchHistoryUtils.saveUserSearchHistory(authState.user!.id, _recentSearchedSongs);
    }
  }

  Future<void> _addToRecentSearchedSongs(Song song) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await SearchHistoryUtils.addSongToUserHistory(authState.user!.id, song);
      await _loadRecentSearchedSongs();
    }
  }

  Future<void> _removeFromRecentSearchedSongs(Song song) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await SearchHistoryUtils.removeSongFromUserHistory(authState.user!.id, song);
      await _loadRecentSearchedSongs();
    }
  }

  Future<void> _clearAllRecentSearchedSongs() async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await SearchHistoryUtils.clearUserSearchHistory(authState.user!.id);
    } else {
      await SearchHistoryUtils.clearGuestSearchHistory();
    }
    await _loadRecentSearchedSongs();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      // Use new song provider for local search (much faster)
      final songController = ref.read(songProvider.notifier);
      final searchResults = songController.searchSongs(query);

      setState(() {
        _searchResults = searchResults;
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
    // Add song to recent searched songs when played from search results
    _addToRecentSearchedSongs(song);
    // Use playSongById to load complete song data without playlist context (like home screen)
    ref.read(playerControllerProvider.notifier).playSongByIdWithoutPlaylist(song.id);
    
    // Color extraction will be handled automatically by mini_player when song changes
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

    return _buildRecentSearchedSongs();
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
    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        return _buildSongItem(song, index);
      },
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

  Widget _buildRecentSearchedSongs() {
    if (_recentSearchedSongs.isEmpty) {
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
                onPressed: _clearAllRecentSearchedSongs,
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
            itemCount: _recentSearchedSongs.length,
            itemBuilder: (context, index) {
              final song = _recentSearchedSongs[index];
              return _buildRecentSongItem(song);
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
                onPressed: () => _removeFromRecentSearchedSongs(song),
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
} 

