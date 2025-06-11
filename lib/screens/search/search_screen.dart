import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../utils/app_colors.dart';
import '../../models/song.dart';
import '../../repositories/song_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/custom_bottom_nav.dart';
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
  List<Song> _playedSongsHistory = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('played_songs_history') ?? [];
    final songs = historyJson.map((jsonStr) {
      try {
        final Map<String, dynamic> songMap = Map<String, dynamic>.from(jsonDecode(jsonStr));
        return Song.fromJson(songMap);
      } catch (e) {
        return null;
      }
    }).where((song) => song != null).cast<Song>().toList();
    
    setState(() {
      _playedSongsHistory = songs;
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _playedSongsHistory.map((song) => jsonEncode(song.toJson())).toList();
    await prefs.setStringList('played_songs_history', historyJson);
  }

  Future<void> _addSongToHistory(Song song) async {
    // Remove if already exists
    _playedSongsHistory.removeWhere((s) => s.id == song.id);
    // Add to front
    _playedSongsHistory.insert(0, song);
    // Keep only last 20 songs
    if (_playedSongsHistory.length > 20) {
      _playedSongsHistory = _playedSongsHistory.take(20).toList();
    }
    
    await _saveSearchHistory();
    setState(() {});
  }

  Future<void> _removeFromHistory(Song song) async {
    _playedSongsHistory.removeWhere((s) => s.id == song.id);
    await _saveSearchHistory();
    setState(() {});
  }

  Future<void> _clearAllHistory() async {
    _playedSongsHistory.clear();
    await _saveSearchHistory();
    setState(() {});
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final repository = SongRepository(pbService);
      final searchResults = await repository.searchSongs(query);

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

  void _onHistoryTap(Song song) {
    // Play the song from history
    _playSongFromHistory(song);
  }

  void _playSong(Song song, int index) {
    ref.read(playerControllerProvider.notifier).playQueue(_searchResults, index);
    // Add to history when played from search results
    _addSongToHistory(song);
  }

  void _playSongFromHistory(Song song) {
    ref.read(playerControllerProvider.notifier).playQueue([song], 0);
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

    return _buildSearchHistory();
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

  Widget _buildSearchHistory() {
    if (_playedSongsHistory.isEmpty) {
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
                onPressed: _clearAllHistory,
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
            itemCount: _playedSongsHistory.length,
            itemBuilder: (context, index) {
              final song = _playedSongsHistory[index];
              return _buildHistoryItem(song);
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

  Widget _buildHistoryItem(Song song) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.grey[800],
          child: song.albumArtUrl.isNotEmpty
              ? Image.network(
                  song.albumArtUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.music_note, color: Colors.white);
                  },
                )
              : const Icon(Icons.music_note, color: Colors.white),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isCurrentSong ? Colors.red : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            onPressed: () => _removeFromHistory(song),
          ),
        ],
      ),
      onTap: () => _onHistoryTap(song),
    );
  }

  Widget _buildSongItem(Song song, int index) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentSong && playerState.isPlaying;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.grey[800],
          child: song.albumArtUrl.isNotEmpty
              ? Image.network(
                  song.albumArtUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.music_note, color: Colors.white);
                  },
                )
              : const Icon(Icons.music_note, color: Colors.white),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isCurrentSong ? Colors.red : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      trailing: isPlaying
          ? const AnimatedSoundBars(
              color: Colors.red,
              size: 20.0,
              isAnimating: true,
            )
          : null,
      onTap: () => _playSong(song, index),
    );
  }
} 