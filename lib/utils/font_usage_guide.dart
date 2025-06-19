import 'package:flutter/material.dart';
import 'typography.dart';

/// Font Usage Guide for RedRhythm
/// 
/// This file provides practical examples and guidelines for consistent
/// typography usage throughout the RedRhythm music streaming app.
class FontUsageGuide {
  FontUsageGuide._();

  /// CONTEXT-SPECIFIC RECOMMENDATIONS
  /// 
  /// Use these specific styles for different UI contexts to maintain consistency

  // ==== AUTHENTICATION SCREENS ====
  
  /// Welcome screen large title: "Let's get you in"
  static const TextStyle authWelcomeTitle = AppTypography.displayMedium;
  
  /// Auth subtitle: "Welcome back to your music world"
  static const TextStyle authSubtitle = AppTypography.bodyLarge;
  
  /// Login/Register button text
  static const TextStyle authButtonText = AppTypography.labelLarge;
  
  /// Form field labels
  static const TextStyle authFieldLabel = AppTypography.titleSmall;
  
  /// Form field input text
  static const TextStyle authFieldInput = AppTypography.bodyMedium;
  
  /// Error messages
  static const TextStyle authErrorText = AppTypography.error;

  // ==== HOME SCREEN ====
  
  /// "Welcome back, [Name]!" greeting
  static const TextStyle homeGreeting = AppTypography.headlineMedium;
  
  /// Section headers: "Continue Listening", "Your Top Mixes"
  static const TextStyle homeSectionHeader = AppTypography.sectionHeader;
  
  /// Album/playlist titles in grid
  static const TextStyle homeAlbumTitle = AppTypography.titleMedium;
  
  /// Artist names in grid
  static const TextStyle homeArtistName = AppTypography.artistName;

  // ==== MUSIC PLAYER SCREEN ====
  
  /// Main song title in player
  static const TextStyle playerMainSongTitle = AppTypography.playerSongTitle;
  
  /// Artist name in player
  static const TextStyle playerMainArtistName = AppTypography.playerArtistName;
  
  /// Duration timestamps (0:32 / 3:45)
  static const TextStyle playerDuration = AppTypography.metadata;
  
  /// Player controls (next, previous buttons - if they have text)
  static const TextStyle playerControls = AppTypography.labelSmall;

  // ==== LIBRARY SCREEN ====
  
  /// Screen title "Your Library"
  static const TextStyle libraryTitle = AppTypography.headlineLarge;
  
  /// Filter tabs (Recently Played, Artists, Albums)
  static const TextStyle libraryTabs = AppTypography.labelMedium;
  
  /// Playlist names in list
  static const TextStyle libraryPlaylistName = AppTypography.titleMedium;
  
  /// "X songs" count under playlist
  static const TextStyle librarySongCount = AppTypography.metadata;

  // ==== SONG LISTS ====
  
  /// Song title in list item
  static const TextStyle listSongTitle = AppTypography.songTitle;
  
  /// Artist name in list item
  static const TextStyle listArtistName = AppTypography.artistName;
  
  /// Song duration, play count
  static const TextStyle listMetadata = AppTypography.metadata;

  // ==== SEARCH SCREEN ====
  
  /// Search bar placeholder
  static const TextStyle searchPlaceholder = AppTypography.bodyMedium;
  
  /// "Recent searches" section header
  static const TextStyle searchSectionHeader = AppTypography.titleLarge;
  
  /// Search result song titles
  static const TextStyle searchResultTitle = AppTypography.songTitle;
  
  /// Search result artist names
  static const TextStyle searchResultArtist = AppTypography.artistName;
  
  /// Metadata text (duration, album info, etc.)
  static const TextStyle metadata = AppTypography.metadata;

  // ==== ERROR & EMPTY STATES ====
  
  /// Error state titles ("Oops! Terjadi kesalahan")
  static const TextStyle errorTitle = AppTypography.headlineSmall;
  
  /// Error messages
  static const TextStyle errorMessage = AppTypography.metadata;
  
  /// Empty state titles ("Tidak ada hasil")
  static const TextStyle emptyStateTitle = AppTypography.headlineSmall;
  
  /// Empty state messages
  static const TextStyle emptyStateMessage = AppTypography.metadata;
  
  /// Link text (e.g., "Clear all", "View more")
  static const TextStyle linkText = AppTypography.labelMedium;

  // ==== NAVIGATION ====
  
  /// Bottom nav labels
  static const TextStyle navigationLabel = AppTypography.navigation;
  
  /// App bar titles
  static const TextStyle appBarTitle = AppTypography.headlineMedium;

  // ==== MODALS & DIALOGS ====
  
  /// Modal/dialog titles
  static const TextStyle modalTitle = AppTypography.headlineSmall;
  
  /// Modal body text
  static const TextStyle modalBody = AppTypography.bodyMedium;
  
  /// Modal action buttons
  static const TextStyle modalButton = AppTypography.labelMedium;

  // ==== PREMIUM/SPECIAL FEATURES ====
  
  /// "RedRhythm Premium" branding
  static const TextStyle premiumBranding = AppTypography.displaySmall;
  
  /// Feature descriptions
  static const TextStyle featureDescription = AppTypography.bodyLarge;
  
  /// Price text
  static const TextStyle priceText = AppTypography.titleLarge;

  /// RESPONSIVE HELPERS
  /// 
  /// Use these methods for responsive font sizing

  /// Get song title with responsive sizing
  static TextStyle getResponsiveSongTitle(BuildContext context) {
    final baseSize = listSongTitle.fontSize ?? 16.0;
    final responsiveSize = AppTypography.getResponsiveFontSize(context, baseSize);
    return listSongTitle.copyWith(fontSize: responsiveSize);
  }

  /// Get artist name with responsive sizing
  static TextStyle getResponsiveArtistName(BuildContext context) {
    final baseSize = listArtistName.fontSize ?? 14.0;
    final responsiveSize = AppTypography.getResponsiveFontSize(context, baseSize);
    return listArtistName.copyWith(fontSize: responsiveSize);
  }

  /// COLOR VARIATIONS
  /// 
  /// Common color variations for different states

  /// Song title when currently playing (red accent)
  static TextStyle get playingSongTitle => 
    AppTypography.withColor(listSongTitle, const Color(0xFFE71E27));

  /// Disabled text (40% opacity)
  static TextStyle get disabledText => 
    AppTypography.disabled(AppTypography.bodyMedium);

  /// Selected/active text (with red accent)
  static TextStyle get selectedText => 
    AppTypography.active(AppTypography.titleMedium, const Color(0xFFE71E27));

  /// Secondary text (70% opacity white)
  static TextStyle get secondaryText => 
    AppTypography.withOpacity(AppTypography.bodyMedium, 0.7);

  /// USAGE EXAMPLES
  /// 
  /// Practical code examples for common scenarios

  /// Example: Song list item
  static Widget buildSongListItem(String songTitle, String artistName, {bool isPlaying = false}) {
    return ListTile(
      title: Text(
        songTitle,
        style: isPlaying ? playingSongTitle : listSongTitle,
      ),
      subtitle: Text(
        artistName,
        style: listArtistName,
      ),
    );
  }

  /// Example: Section header with consistent styling
  static Widget buildSectionHeader(String title) {
    return Text(
      title,
      style: homeSectionHeader,
    );
  }

  /// Example: Form field with proper typography
  static Widget buildFormField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: authFieldLabel),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.withOpacity(AppTypography.bodyMedium, 0.6),
          ),
        ),
      ],
    );
  }

  /// ACCESSIBILITY CONSIDERATIONS
  /// 
  /// All text styles include proper line heights and letter spacing for:
  /// - Better readability on small screens
  /// - Improved accessibility for users with visual impairments
  /// - Consistent text rhythm and visual hierarchy
  /// 
  /// Font weights are used strategically:
  /// - FontWeight.w900 (Black): Only for hero text
  /// - FontWeight.w700 (Bold): Headlines, buttons, emphasis
  /// - FontWeight.w500 (Medium): Subtitles, secondary emphasis
  /// - FontWeight.w400 (Regular): Body text, descriptions
  /// 
  /// Line heights follow accessibility guidelines:
  /// - 1.1-1.2: Display text (large sizes)
  /// - 1.25-1.35: Headlines
  /// - 1.4-1.5: Body text (comfortable reading)

  /// MIGRATION TIPS
  /// 
  /// To migrate existing code:
  /// 
  /// 1. Replace direct TextStyles with FontUsageGuide constants:
  ///    OLD: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Gotham')
  ///    NEW: FontUsageGuide.listSongTitle
  /// 
  /// 2. Use semantic names instead of sizes:
  ///    OLD: fontSize: 24, fontWeight: FontWeight.bold
  ///    NEW: FontUsageGuide.homeSectionHeader
  /// 
  /// 3. Leverage color variations:
  ///    OLD: TextStyle(color: Colors.red) when playing
  ///    NEW: FontUsageGuide.playingSongTitle
  /// 
  /// 4. Add responsive sizing where needed:
  ///    NEW: FontUsageGuide.getResponsiveSongTitle(context)
}

/// Extension methods for easier usage
extension TextStyleExtensions on TextStyle {
  /// Make text style red for playing state
  TextStyle get asPlaying => AppTypography.withColor(this, const Color(0xFFE71E27));
  
  /// Make text style disabled
  TextStyle get asDisabled => AppTypography.disabled(this);
  
  /// Make text style with custom opacity
  TextStyle withOpacity(double opacity) => AppTypography.withOpacity(this, opacity);
  
  /// Make text style with custom color
  TextStyle withColor(Color color) => AppTypography.withColor(this, color);
} 