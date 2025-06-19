import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/artist_controller.dart';
import '../../models/artist.dart';
import '../../utils/app_colors.dart';
import '../../widgets/shimmer_widget.dart';
import '../../utils/image_helpers.dart';
import '../../providers/artist_select_provider.dart';
import '../../widgets/spotify_search_bar.dart';
import '../../utils/font_usage_guide.dart';

@RoutePage()
class ArtistSelectionScreen extends ConsumerStatefulWidget {
  const ArtistSelectionScreen({super.key});

  @override
  ConsumerState<ArtistSelectionScreen> createState() => _ArtistSelectionScreenState();
}

class _ArtistSelectionScreenState extends ConsumerState<ArtistSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedArtists = <String>{};

  @override
  void initState() {
    super.initState();
    // Load artists when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(artistControllerProvider.notifier).loadArtists();
      _loadSelectedArtists();
    });
  }

  void _loadSelectedArtists() async {
    // Load currently selected artists
    final selectedIds = ref.read(artistSelectProvider.notifier).getSelectedArtistIds();
    setState(() {
      _selectedArtists.addAll(selectedIds);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(artistControllerProvider.notifier).searchArtists(query);
  }

  void _toggleArtistSelection(String artistId) {
    setState(() {
      if (_selectedArtists.contains(artistId)) {
        _selectedArtists.remove(artistId);
      } else {
        _selectedArtists.add(artistId);
      }
    });
  }

  void _finishSelection() async {
    try {
      // Get currently selected artists from provider
      final currentlySelected = ref.read(artistSelectProvider.notifier).getSelectedArtistIds();
      
      // Find artists to add (newly selected)
      final toAdd = _selectedArtists.where((id) => !currentlySelected.contains(id)).toList();
      
      // Find artists to remove (deselected)
      final toRemove = currentlySelected.where((id) => !_selectedArtists.contains(id)).toList();
      
      // Add new selections
      if (toAdd.isNotEmpty) {
        await ref.read(artistSelectProvider.notifier).addMultipleArtistSelections(toAdd);
      }
      
      // Remove deselected artists
      for (final artistId in toRemove) {
        await ref.read(artistSelectProvider.notifier).removeArtistSelection(artistId);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilihan artist berhasil disimpan!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Return to previous screen
        context.router.maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pilihan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artistState = ref.watch(artistControllerProvider);
    final displayArtists = _searchController.text.isNotEmpty 
        ? artistState.searchResults 
        : artistState.artists;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.router.maybePop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Pilih artis lain yang kamu suka.',
                          style: FontUsageGuide.homeGreeting,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  SpotifySearchBar(
                    controller: _searchController,
                    hintText: 'Cari artis...',
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),

            // Artists Grid
            Expanded(
              child: artistState.isLoading && displayArtists.isEmpty
                  ? _buildLoadingGrid()
                  : displayArtists.isEmpty
                      ? _buildEmptyState()
                      : _buildArtistsGrid(displayArtists),
            ),

            // Bottom Button
            if (_selectedArtists.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _finishSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Selesai (${_selectedArtists.length})',
                      style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildArtistsGrid(List<Artist> artists) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9, // Increased from 0.8 to give more height
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final isSelected = _selectedArtists.contains(artist.id);
        
        return GestureDetector(
          onTap: () => _toggleArtistSelection(artist.id),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take only necessary space
            children: [
              Stack(
                children: [
                  Container(
                    width: 72, // Reduced from 80 to fit better
                    height: 72, // Reduced from 80 to fit better
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey[800],
                        child: ImageHelpers.buildSafeNetworkImage(
                          imageUrl: artist.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover, // Cover untuk memenuhi lingkaran dengan minimal crop
                          fallbackWidget: _buildPlaceholderImage(artist.name),
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6), // Reduced from 8 to save space
              Flexible( // Use Flexible to allow text to shrink if needed
                child: Text(
                  artist.name,
                  style: FontUsageGuide.listArtistName.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(String artistName) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          artistName.isNotEmpty ? artistName[0].toUpperCase() : 'A',
          style: FontUsageGuide.playerMainSongTitle.copyWith(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9, // Match the main grid
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Column(
          mainAxisSize: MainAxisSize.min, // Match the main grid
          children: [
            ShimmerImagePlaceholder(
              width: 72, // Match the new image size
              height: 72, // Match the new image size
              borderRadius: BorderRadius.circular(36), // Half of width/height
            ),
            const SizedBox(height: 6), // Match the reduced spacing
            Flexible( // Match the main grid structure
              child: ShimmerImagePlaceholder(
                width: 60,
                height: 10, // Slightly smaller to match new text size
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'Tidak ada artist yang ditemukan'
                : 'Belum ada artist',
            style: FontUsageGuide.emptyStateMessage,
          ),

        ],
      ),
    );
  }
}



