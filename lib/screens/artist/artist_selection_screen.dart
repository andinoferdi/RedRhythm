import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/artist_controller.dart';
import '../../models/artist.dart';
import '../../utils/app_colors.dart';
import '../../widgets/shimmer_widget.dart';
import '../../utils/image_helpers.dart';
import '../../providers/artist_select_provider.dart';

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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'DM Sans',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontFamily: 'DM Sans',
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DM Sans',
                      ),
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
        childAspectRatio: 0.8,
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
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[800],
                        child: ImageHelpers.buildSafeNetworkImage(
                          imageUrl: artist.imageUrl,
                          width: 80,
                          height: 80,
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
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                artist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'DM Sans',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(String artistName) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          artistName.isNotEmpty ? artistName[0].toUpperCase() : 'A',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Column(
          children: [
            ShimmerImagePlaceholder(
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(40),
            ),
            const SizedBox(height: 8),
            ShimmerImagePlaceholder(
              width: 60,
              height: 12,
              borderRadius: BorderRadius.circular(6),
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
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontFamily: 'DM Sans',
            ),
          ),

        ],
      ),
    );
  }
}


