import 'package:flutter/material.dart';
import '../utils/typography.dart';
import '../utils/font_usage_guide.dart';

/// Typography Showcase Widget
/// 
/// This widget demonstrates all typography styles in the RedRhythm app.
/// Use this as a reference and for visual testing of the typography system.
class TypographyShowcase extends StatelessWidget {
  const TypographyShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Typography Showcase',
          style: FontUsageGuide.appBarTitle,
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Styles Section
            _buildSection(
              'Display Styles',
              [
                _buildTextExample('Hero Title', AppTypography.displayLarge),
                _buildTextExample('Welcome Screen', AppTypography.displayMedium),
                _buildTextExample('Premium Branding', AppTypography.displaySmall),
              ],
            ),
            
            // Headline Styles Section
            _buildSection(
              'Headlines',
              [
                _buildTextExample('Screen Title', AppTypography.headlineLarge),
                _buildTextExample('Section Header', AppTypography.headlineMedium),
                _buildTextExample('Modal Title', AppTypography.headlineSmall),
              ],
            ),
            
            // Title Styles Section
            _buildSection(
              'Titles',
              [
                _buildTextExample('Card Title', AppTypography.titleLarge),
                _buildTextExample('List Item Title', AppTypography.titleMedium),
                _buildTextExample('Subtitle', AppTypography.titleSmall),
              ],
            ),
            
            // Body Styles Section
            _buildSection(
              'Body Text (DM Sans)',
              [
                _buildTextExample(
                  'This is large body text used for main content and important descriptions. It uses DM Sans for better readability.',
                  AppTypography.bodyLarge,
                ),
                _buildTextExample(
                  'This is medium body text for regular descriptions and secondary content.',
                  AppTypography.bodyMedium,
                ),
                _buildTextExample(
                  'Small body text for captions and metadata.',
                  AppTypography.bodySmall,
                ),
              ],
            ),
            
            // Label Styles Section
            _buildSection(
              'Labels & UI Elements',
              [
                _buildTextExample('Button Text', AppTypography.labelLarge),
                _buildTextExample('Chip Label', AppTypography.labelMedium),
                _buildTextExample('Navigation Label', AppTypography.labelSmall),
              ],
            ),
            
            // Music-Specific Styles Section
            _buildSection(
              'Music App Specific',
              [
                _buildTextExample('Shape of You', AppTypography.songTitle),
                _buildTextExample('Ed Sheeran', AppTypography.artistName),
                _buildTextExample('3:45 • 2.1M plays', AppTypography.metadata),
                _buildTextExample('Now Playing Song', AppTypography.playerSongTitle),
                _buildTextExample('Artist in Player', AppTypography.playerArtistName),
                _buildTextExample('Your Library', AppTypography.sectionHeader),
              ],
            ),
            
            // Color Variations Section
            _buildSection(
              'Color Variations',
              [
                _buildTextExample('Currently Playing Song', FontUsageGuide.playingSongTitle),
                _buildTextExample('Selected Item', FontUsageGuide.selectedText),
                _buildTextExample('Secondary Text', FontUsageGuide.secondaryText),
                _buildTextExample('Disabled Text', FontUsageGuide.disabledText),
              ],
            ),
            
            // Practical Examples Section
            _buildSection(
              'Practical Examples',
              [
                _buildSongListExample(),
                _buildPlayerExample(),
                _buildLibraryExample(),
              ],
            ),
            
            // Responsive Examples
            _buildSection(
              'Responsive Sizing',
              [
                _buildResponsiveExample(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE71E27),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: AppTypography.labelMedium,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextExample(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Style info
          SizedBox(
            width: 120,
            child: Text(
              '${style.fontSize?.toInt()}px, ${_getWeightName(style.fontWeight)}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text example
          Expanded(
            child: Text(text, style: style),
          ),
        ],
      ),
    );
  }

  Widget _buildSongListExample() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Song List Example', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          FontUsageGuide.buildSongListItem(
            'Blinding Lights',
            'The Weeknd',
            isPlaying: true,
          ),
          FontUsageGuide.buildSongListItem(
            'Watermelon Sugar',
            'Harry Styles',
          ),
          FontUsageGuide.buildSongListItem(
            'Levitating',
            'Dua Lipa',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerExample() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A0D0E), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('Music Player Example', style: AppTypography.titleMedium),
          const SizedBox(height: 20),
          Text('Bohemian Rhapsody', style: FontUsageGuide.playerMainSongTitle),
          const SizedBox(height: 8),
          Text('Queen', style: FontUsageGuide.playerMainArtistName),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1:32', style: FontUsageGuide.playerDuration),
              Text('5:55', style: FontUsageGuide.playerDuration),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryExample() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Library Section Example', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          FontUsageGuide.buildSectionHeader('Recently Played'),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('My Favorites', style: FontUsageGuide.libraryPlaylistName),
            subtitle: Text('23 songs', style: FontUsageGuide.librarySongCount),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveExample(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0D0E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Responsive Sizing Demo', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Text('Screen width: ${screenWidth.toInt()}px', style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          Text(
            'This song title adapts to screen size',
            style: FontUsageGuide.getResponsiveSongTitle(context),
          ),
          Text(
            'This artist name also adapts',
            style: FontUsageGuide.getResponsiveArtistName(context),
          ),
        ],
      ),
    );
  }

  String _getWeightName(FontWeight? weight) {
    switch (weight) {
      case FontWeight.w900:
        return 'Black';
      case FontWeight.w700:
        return 'Bold';
      case FontWeight.w500:
        return 'Medium';
      case FontWeight.w400:
        return 'Regular';
      case FontWeight.w300:
        return 'Light';
      default:
        return 'Regular';
    }
  }
} 