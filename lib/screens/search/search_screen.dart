import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

import '../../utils/app_colors.dart';
import '../../utils/search_history_utils.dart';
import '../../utils/image_helpers.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../routes/app_router.dart';

import '../../controllers/player_controller.dart';
import '../../controllers/auth_controller.dart';

import '../../providers/song_provider.dart';
import '../../models/artist.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/album_repository.dart';
import '../../services/pocketbase_service.dart';

import '../../widgets/mini_player.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/song_item_widget.dart';
import '../../widgets/animated_sound_bars.dart';
import '../../widgets/spotify_search_bar.dart';


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
  List<Album> _albumSearchResults = [];
  List<dynamic> _recentSearches = []; // Changed to dynamic to support both songs, artists, and albums
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;
  String? _currentUserId;
  late ArtistRepository _artistRepository;
  late AlbumRepository _albumRepository;

  @override
  void initState() {
    super.initState();
    _artistRepository = ArtistRepository(PocketBaseService());
    _albumRepository = AlbumRepository(PocketBaseService());
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
      searches = await SearchHistoryUtils.getCombinedUserHistory(authState.user!.id);
    }
    
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _addToRecentSearches(dynamic item) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await SearchHistoryUtils.addSearchItemToUserHistory(authState.user!.id, item);
      await _loadRecentSearches();
    }
  }

  Future<void> _removeFromRecentSearches(dynamic item) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      await SearchHistoryUtils.removeSearchItemFromUserHistory(authState.user!.id, item);
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
      // Search songs, artists, and albums
      final songController = ref.read(songProvider.notifier);
      final songResults = songController.searchSongs(query);
      
      final artistResults = await _artistRepository.searchArtists(query);
      final albumResults = await _albumRepository.searchAlbums(query);

      setState(() {
        _searchResults = songResults;
        _artistSearchResults = artistResults;
        _albumSearchResults = albumResults;
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

  void _openAlbumDetail(Album album) {
    // Add album to recent searches
    _addToRecentSearches(album);
    // Navigate to album screen
    context.router.push(AlbumRoute(
      albumId: album.id,
      albumTitle: album.title,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.router.maybePop(),
            ),
            Expanded(
              child: SpotifySearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Apa yang ingin kamu dengarkan?',
                autoFocus: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _artistSearchResults = [];
                            _albumSearchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                onChanged: (value) {
                  setState(() {});
                  if (value.trim().isNotEmpty) {
                    _performSearch(value);
                  } else {
                    setState(() {
                      _searchResults = [];
                      _artistSearchResults = [];
                      _albumSearchResults = [];
                      _hasSearched = false;
                    });
                  }
                },
                onSubmitted: _performSearch,
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
              style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Gotham',),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: 'Gotham',),
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
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontFamily: 'Gotham')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final hasResults = _searchResults.isNotEmpty || _artistSearchResults.isNotEmpty || _albumSearchResults.isNotEmpty;
    
    if (!hasResults) {
      return _buildEmptyResults();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Album results section
        if (_albumSearchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Album',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ..._albumSearchResults.map((album) => _buildAlbumItem(album)),
          const SizedBox(height: 16),
        ],
        
        // Artist results section
        if (_artistSearchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Artis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
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
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
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
              style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Gotham',),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci yang berbeda',
              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: 'Gotham',),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
              ),
              TextButton(
                onPressed: _clearAllRecentSearches,
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Gotham'),
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
              } else if (item is Album) {
                return _buildRecentAlbumItem(item);
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
              style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Gotham',),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai cari lagu, artis, atau album favoritmu',
              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontFamily: 'Gotham',),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Consumer(
        builder: (context, ref, child) {
          final playerState = ref.watch(playerControllerProvider);
          final isCurrentSong = playerState.currentSong?.id == song.id;
          final isPlaying = isCurrentSong && playerState.isPlaying;
          
          return SongItemWidget(
            song: song,
            subtitle: song.artist,
            contentPadding: EdgeInsets.zero,
            isCurrentSong: isCurrentSong,
            isPlaying: isPlaying,
            onTap: () => _playSong(song, index),
          );
        },
      ),
    );
  }

  Widget _buildAlbumItem(Album album) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _openAlbumDetail(album),
        child: Row(
          children: [
            // Album cover
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: album.coverImageUrl ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.album,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Album info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gotham',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Album • ${album.artistName}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Gotham',
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
                          fontFamily: 'Gotham',
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
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gotham',
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
                      fontFamily: 'Gotham',
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

  Widget _buildRecentAlbumItem(Album album) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Album cover
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ImageHelpers.buildSafeNetworkImage(
                imageUrl: album.coverImageUrl ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                fallbackWidget: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.album,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Album info
          Expanded(
            child: GestureDetector(
              onTap: () => _openAlbumDetail(album),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gotham',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Album • ${album.artistName}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Gotham',
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
            onPressed: () => _removeFromRecentSearches(album),
          ),
        ],
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
                        fontFamily: 'Gotham',
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
                      fontWeight: FontWeight.w700,
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
                      fontFamily: 'Gotham',
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




