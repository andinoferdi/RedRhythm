import 'package:flutter/material.dart';
import '../models/genre.dart';
import '../repositories/genre_repository.dart';
import '../services/pocketbase_service.dart';
import '../utils/app_colors.dart';
import '../utils/font_usage_guide.dart';
import '../utils/image_helpers.dart';

class DynamicGenreCard extends StatelessWidget {
  final Genre genre;
  final VoidCallback? onTap;

  const DynamicGenreCard({
    super.key,
    required this.genre,
    this.onTap,
  });

  /// Get genre image URL using repository method
  String _getGenreImageUrl() {
    try {
      final genreRepository = GenreRepository(PocketBaseService());
      final imageUrl = genreRepository.getGenreImageUrl(genre);
      print('DEBUG: DynamicGenreCard - Genre image URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('DEBUG: DynamicGenreCard - Error getting genre image URL: $e');
      return '';
    }
  }
  
  /// Get gradient colors based on genre name
  List<Color> _getGenreGradient() {
    final genreName = genre.name.toLowerCase();
    
    if (genreName.contains('rock')) {
      return [
        const Color(0xFF8B0000), // Dark red
        const Color(0xFFDC143C), // Crimson
        const Color(0xFF4B0000), // Very dark red
      ];
    } else if (genreName.contains('pop')) {
      return [
        const Color(0xFFFF69B4), // Hot pink
        const Color(0xFFFF1493), // Deep pink
        const Color(0xFF8B008B), // Dark magenta
      ];
    } else if (genreName.contains('jazz')) {
      return [
        const Color(0xFF4169E1), // Royal blue
        const Color(0xFF000080), // Navy
        const Color(0xFF191970), // Midnight blue
      ];
    } else if (genreName.contains('classical')) {
      return [
        const Color(0xFF9932CC), // Dark orchid
        const Color(0xFF4B0082), // Indigo
        const Color(0xFF2E0854), // Very dark purple
      ];
    } else if (genreName.contains('electronic') || genreName.contains('edm')) {
      return [
        const Color(0xFF00CED1), // Dark turquoise
        const Color(0xFF4169E1), // Royal blue
        const Color(0xFF000080), // Navy
      ];
    } else if (genreName.contains('hip hop') || genreName.contains('rap')) {
      return [
        const Color(0xFF2F4F4F), // Dark slate gray
        const Color(0xFF696969), // Dim gray
        const Color(0xFF000000), // Black
      ];
    } else if (genreName.contains('country')) {
      return [
        const Color(0xFFD2691E), // Chocolate
        const Color(0xFF8B4513), // Saddle brown
        const Color(0xFF654321), // Dark brown
      ];
    } else if (genreName.contains('metal')) {
      return [
        const Color(0xFF2F2F2F), // Dark gray
        const Color(0xFF4A4A4A), // Gray
        const Color(0xFF1A1A1A), // Very dark gray
      ];
    } else {
      // Default gradient
      return [
        AppColors.primary.withValues(alpha: 0.8),
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.6),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGenreGradient();
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[1].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Background image or gradient
            Positioned.fill(
              child: ImageHelpers.buildSafeNetworkImage(
                imageUrl: _getGenreImageUrl(),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                fallbackWidget: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Geometric pattern overlay
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -15,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      // Music note icon as watermark
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Enhanced overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            
            // Genre title with enhanced styling
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    genre.name,
                    style: FontUsageGuide.listSongTitle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 