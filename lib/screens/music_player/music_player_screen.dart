import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/player_controller.dart';
import '../../states/player_state.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/song_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helpers.dart';
import '../../utils/color_extractor.dart';
import '../../providers/dynamic_color_provider.dart';
import '../../routes/app_router.dart';
import '../../providers/artist_select_provider.dart';
import '../../utils/font_usage_guide.dart';
import '../../utils/responsive_helper.dart';

@RoutePage()
class MusicPlayerScreen extends ConsumerStatefulWidget {
  final Song? song;

  const MusicPlayerScreen({this.song, super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen>
    with TickerProviderStateMixin {
  Artist? _currentArtist;
  bool _isLoadingArtist = false;
  List<Song> _artistSongs = [];
  bool _isLoadingArtistSongs = false;
  Map<String, List<Song>> _artistSongsCache = {}; // Cache untuk avoid loading flicker
  late ArtistRepository _artistRepository;
  late SongRepository _songRepository;

  // Store the original song to keep Jelajahi Artist consistent
  Song? _originalSong;
  String? _originalArtistName;

  // Animation controllers for fade effects
  late AnimationController _albumFadeController;
  late AnimationController _backgroundFadeController;
  late Animation<double> _albumFadeAnimation;
  late Animation<double> _backgroundFadeAnimation;

  // Track current song for animation triggers
  String? _currentSongId;

  @override
  void initState() {
    super.initState();
    _artistRepository = ArtistRepository(PocketBaseService());
    _songRepository = SongRepository(PocketBaseService());

    // Initialize animation controllers
    _albumFadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _backgroundFadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Initialize animations
    _albumFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _albumFadeController,
      curve: Curves.easeInOut,
    ));

    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundFadeController,
      curve: Curves.easeInOut,
    ));

    // Start with animations at full opacity
    _albumFadeController.value = 1.0;
    _backgroundFadeController.value = 1.0;
  }

  @override
  void dispose() {
    _albumFadeController.dispose();
    _backgroundFadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MusicPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If widget.song changes (user navigated to music player with different song)
    // reset the original song reference
    if (widget.song != null &&
        oldWidget.song?.id != widget.song?.id &&
        _originalSong?.id != widget.song?.id) {
      _originalSong = widget.song;
      _originalArtistName = widget.song?.artist;

      // Reload artist info and songs for new original song
      if (_originalArtistName != null) {
        _loadArtistInfo(_originalArtistName!);
        _loadArtistSongs(_originalArtistName!, _originalSong!.id);
      }
    }
  }

  Future<void> _loadArtistInfo(String artistName) async {
    if (_isLoadingArtist) return;

    setState(() {
      _isLoadingArtist = true;
    });

    try {
      final artist = await _artistRepository.getArtistByName(artistName);
      if (mounted) {
        setState(() {
          _currentArtist = artist;
          _isLoadingArtist = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingArtist = false;
        });
      }
    }
  }

  Future<void> _loadArtistSongs(String artistName, String currentSongId) async {
    if (_isLoadingArtistSongs) return;

    // Check cache first untuk avoid flickering
    final cacheKey = '${artistName}_$currentSongId';
    if (_artistSongsCache.containsKey(cacheKey)) {
      setState(() {
        _artistSongs = _artistSongsCache[cacheKey]!;
        _isLoadingArtistSongs = false;
      });
      return;
    }

    // Show loading only if no cached data
    setState(() {
      _isLoadingArtistSongs = true;
      // Don't clear _artistSongs if we have data to avoid flicker
      if (_artistSongs.isEmpty) {
        _artistSongs = [];
      }
    });

    try {
      final songs = await _songRepository.getSongsByArtistName(
        artistName,
        excludeSongId: currentSongId,
      );
      if (mounted) {
        // Cache the result
        _artistSongsCache[cacheKey] = songs;
        
        setState(() {
          _artistSongs = songs;
          _isLoadingArtistSongs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingArtistSongs = false;
        });
      }
    }
  }

  Future<void> _toggleFollowArtist(Artist artist, bool isCurrentlyFollowing) async {
    try {
      if (isCurrentlyFollowing) {
        // Unfollow artist
        final success = await ref.read(artistSelectProvider.notifier).removeArtistSelection(artist.id);
        
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Telah berhenti mengikuti "${artist.name}"',
                      style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // Follow artist
        final success = await ref.read(artistSelectProvider.notifier).addArtistSelection(artist.id);
        
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kini mengikuti "${artist.name}"',
                      style: FontUsageGuide.authButtonText.copyWith(color: Colors.black),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyFollowing 
                  ? 'Gagal berhenti mengikuti artis: $e'
                  : 'Gagal mengikuti artis: $e'
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final currentSong = playerState.currentSong ?? widget.song;

    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'No song is currently playing',
            style: FontUsageGuide.emptyStateMessage,
          ),
        ),
      );
    }

    // Check if song changed and trigger fade animation
    if (_currentSongId != null && _currentSongId != currentSong.id) {
      _triggerSongChangeAnimation(currentSong);
      _currentSongId = currentSong.id;
    } else if (_currentSongId == null) {
      // First time loading
      _currentSongId = currentSong.id;
      _albumFadeController.value = 1.0;
      _backgroundFadeController.value = 1.0;
    }

    // Initialize or update original song based on current song
    if (_originalSong == null) {
      // First load - prioritize widget.song if available, otherwise use currentSong
      _originalSong = widget.song ?? currentSong;
      _originalArtistName = _originalSong?.artist;

      // Load artist info and songs based on original song
      if (_originalArtistName != null) {
        _loadArtistInfo(_originalArtistName!);
        _loadArtistSongs(_originalArtistName!, _originalSong!.id);
      }
    } else if (_originalSong?.id != currentSong.id) {
      // Song changed via next/previous - update original song reference
      _originalSong = currentSong;
      _originalArtistName = currentSong.artist;

      // Reload artist info and songs for new song only if artist changed
      if (_originalArtistName != null) {
        _loadArtistInfo(_originalArtistName!);
        // Only reload artist songs if artist actually changed
        if (_currentArtist?.name != _originalArtistName) {
          _loadArtistSongs(_originalArtistName!, currentSong.id);
        }
      }
    }

    // Extract dynamic colors from current song's album art
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dynamicColorProvider.notifier)
          .extractColorsFromSong(currentSong);
    });

    // Update artist info for "Tentang artis" section based on current song
    // but keep Jelajahi Artist section based on original song
    if (_currentArtist?.name != currentSong.artist) {
      _loadArtistInfo(currentSong.artist);
      // Don't reload artist songs - keep them based on original song
    }

    // Get dynamic colors
    final colors =
        dynamicColorState.colors ?? ColorExtractor.getDefaultColors();

    return Scaffold(
      backgroundColor:
          const Color(0xFF000000), // Background hitam asli aplikasi
      body: Stack(
        children: [
          // Background with gradient
          AnimatedBuilder(
            animation: _backgroundFadeAnimation,
            builder: (context, child) {
              return Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.backgroundStart
                          .withValues(alpha: _backgroundFadeAnimation.value),
                      colors.backgroundStart.withValues(
                          alpha: _backgroundFadeAnimation.value * 0.8),
                      colors.backgroundStart.withValues(
                          alpha: _backgroundFadeAnimation.value * 0.4),
                      const Color(0xFF1A1A1A).withValues(
                          alpha: _backgroundFadeAnimation.value * 0.6),
                      const Color(0xFF000000),
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.8, 1.0],
                  ),
                ),
              );
            },
          ),

          // Scrollable Content with top padding for fixed header
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: ResponsiveHelper.getHeaderHeight(context) + 10, // Responsive header height with spacing
              left: ResponsiveHelper.getResponsiveSpacing(context, 20.0),
              right: ResponsiveHelper.getResponsiveSpacing(context, 20.0),
              bottom: ResponsiveHelper.getSafeBottomPadding(context) + 40.0,
            ),
            child: Column(
              children: [
                // Album Art
                FadeTransition(
                  opacity: _albumFadeAnimation,
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.greyDark,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          ImageHelpers.buildSafeNetworkImage(
                            imageUrl: currentSong.albumArtUrl,
                            width: 280,
                            height: 280,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(20),
                            showLoadingIndicator: true,
                            fallbackWidget: _buildFallbackAlbumArt(),
                          ),
                          if (playerState.isBuffering)
                            Container(
                              height: 280,
                              width: 280,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Song info
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to album screen if albumId is available
                        if (currentSong.albumId != null && currentSong.albumId!.isNotEmpty) {
                          context.router.push(AlbumRoute(
                            albumId: currentSong.albumId!,
                            albumTitle: currentSong.albumName,
                          ));
                        } else {
                          // Fallback: navigate to album screen with title only
                          context.router.push(AlbumRoute(
                            albumId: '',
                            albumTitle: currentSong.albumName,
                          ));
                        }
                      },
                      child: Text(
                        currentSong.title,
                        style: FontUsageGuide.playerMainSongTitle.copyWith(
                          color: colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // Navigate to artist detail screen
                        context.router.push(ArtistDetailRoute(
                          artistId: '',
                          artistName: currentSong.artist,
                        ));
                      },
                      child: Text(
                        currentSong.artist,
                        style: FontUsageGuide.playerMainArtistName.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Playback controls
                Column(
                  children: [
                    // Slider
                    Builder(
                      builder: (context) {
                        final maxDuration = currentSong.duration.inSeconds.toDouble();
                        final currentPosition = playerState.currentPosition.inSeconds.toDouble();
                        
                        // Ensure current position doesn't exceed max duration
                        final clampedPosition = currentPosition.clamp(0.0, maxDuration);
                        
                        return Slider(
                          value: clampedPosition,
                          max: maxDuration > 0 ? maxDuration : 1.0, // Prevent zero max
                          activeColor: Colors.white,
                          inactiveColor:
                              colors.textSecondary.withValues(alpha: 0.3),
                          onChanged: (value) {
                            ref.read(playerControllerProvider.notifier).seekTo(
                                  Duration(seconds: value.toInt()),
                                );
                          },
                        );
                      },
                    ),

                    // Time indicators
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerState.currentPosition),
                            style: FontUsageGuide.playerDuration.copyWith(color: colors.textSecondary),
                          ),
                          Text(
                            _formatDuration(currentSong.duration),
                            style: FontUsageGuide.playerDuration.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final playerState =
                                ref.watch(playerControllerProvider);
                            final hasContext = playerState.currentPlaylistId != null || 
                                             playerState.currentArtistId != null;

                            return IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: hasContext
                                    ? (playerState.shuffleMode
                                        ? Colors.red
                                        : Colors.white)
                                    : Colors.grey,
                                size: 24,
                              ),
                              onPressed: hasContext
                                  ? () {
                                      ref
                                          .read(
                                              playerControllerProvider.notifier)
                                          .toggleShuffle();
                                    }
                                  : null,
                            );
                          },
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final playerState =
                                ref.watch(playerControllerProvider);
                            final hasQueue = playerState.queue.isNotEmpty;
                            final currentIndex = playerState.currentIndex;
                            final canGoPrevious = hasQueue && currentIndex > 0;

                            return IconButton(
                              icon: Icon(
                                Icons.skip_previous,
                                color:
                                    canGoPrevious ? Colors.white : Colors.grey,
                                size: 36,
                              ),
                              onPressed: canGoPrevious
                                  ? () async {
                                      try {
                                        await ref
                                            .read(playerControllerProvider
                                                .notifier)
                                            .skipPrevious();
                                      } catch (e) {
                                        debugPrint(
                                            'Error in skip previous: $e');
                                      }
                                    }
                                  : null,
                            );
                          },
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              playerState.isBuffering
                                  ? Icons.hourglass_empty
                                  : playerState.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                              color: Colors.black,
                              size: 36,
                            ),
                            onPressed: () {
                              if (playerState.isBuffering) {
                                return;
                              }

                              if (playerState.isPlaying) {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .pause();
                              } else {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .resume();
                              }
                            },
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final playerState =
                                ref.watch(playerControllerProvider);
                            final hasQueue = playerState.queue.isNotEmpty;
                            final currentIndex = playerState.currentIndex;
                            final queueLength = playerState.queue.length;
                            final canGoNext =
                                hasQueue && currentIndex < queueLength - 1;

                            return IconButton(
                              icon: Icon(
                                Icons.skip_next,
                                color: canGoNext ? Colors.white : Colors.grey,
                                size: 36,
                              ),
                              onPressed: canGoNext
                                  ? () async {
                                      try {
                                        await ref
                                            .read(playerControllerProvider
                                                .notifier)
                                            .skipNext();
                                      } catch (e) {
                                        debugPrint('Error in skip next: $e');
                                      }
                                    }
                                  : null,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            playerState.repeatMode == RepeatMode.off
                                ? Icons.repeat
                                : playerState.repeatMode == RepeatMode.one
                                    ? Icons.repeat_one
                                    : Icons.repeat,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            ref
                                .read(playerControllerProvider.notifier)
                                .toggleRepeatMode();
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // About Artist Section
                _buildAboutArtistSection(currentSong),

                // Lyrics Preview Section
                _buildLyricsPreviewSection(currentSong),

                // Jelajahi Artist Section
                if (_originalSong != null && _originalArtistName != null)
                  _buildJelajahiArtistSection(_originalSong!),
              ],
            ),
          ),

          // Fixed Header at the top using ResponsiveHelper
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ResponsiveHelper.buildSafeHeader(
              context: context,
              gradientColors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button with proper touch target
                    ResponsiveHelper.buildTouchableButton(
                      onTap: () => context.router.maybePop(),
                      margin: const EdgeInsets.only(left: 4),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    // Now Playing text with proper constraints
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Now Playing',
                          style: FontUsageGuide.appBarTitle.copyWith(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Three-dot menu button with proper touch target
                    ResponsiveHelper.buildTouchableButton(
                      onTap: () {
                        // TODO: Show menu options
                      },
                      margin: const EdgeInsets.only(right: 4),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsPreviewSection(Song currentSong) {
    final hasLyrics =
        currentSong.lyrics != null && currentSong.lyrics!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lyrics preview container (Spotify-style)
        GestureDetector(
          onTap: () {
            // Navigate to full-screen lyrics
            context.router.push(LyricsRoute(song: currentSong));
          },
          child: hasLyrics
              ? _buildLyricsPreview(currentSong)
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greyDark.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildNoLyricsPreview(),
                ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLyricsPreview(Song song) {
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final colors =
        dynamicColorState.colors ?? ColorExtractor.getDefaultColors();

    // Get first few lines of lyrics for preview
    final lyricsLines = song.lyrics!.split('\n');
    final previewLines =
        lyricsLines.take(3).where((line) => line.trim().isNotEmpty).toList();
    final previewText = previewLines.join('\n');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.primary, // Keep solid color for lyrics readability
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // "Lyrics" text overlay
          Positioned(
            top: 16,
            left: 20,
            child: Text(
              'Lyrics',
              style: FontUsageGuide.modalTitle.copyWith(
                shadows: [
                  const Shadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Content with padding
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 50, 20, 20), // Top padding for "Lyrics" text
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview text with smooth Spotify-style fade-out
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.white,
                        Color(0x88FFFFFF), // Semi-transparent
                        Color(0x44FFFFFF), // More transparent
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.65, 0.8, 0.9, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Text(
                    previewText,
                    style: FontUsageGuide.homeSectionHeader.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.4,
                      shadows: [
                        const Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.clip,
                  ),
                ),

                const SizedBox(height: 16),

                // Show more button with white background
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tampilkan Lirik',
                            style: FontUsageGuide.modalButton.copyWith(
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: colors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLyricsPreview() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 24,
              color: AppColors.greyLight,
            ),
            const SizedBox(width: 12),
                          Expanded(
                child: Text(
                  'No lyrics available for this song',
                  style: FontUsageGuide.emptyStateTitle.copyWith(
                    color: AppColors.greyLight,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // View anyway button
        Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greyDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Detail',
                    style: FontUsageGuide.navigationLabel.copyWith(
                      color: AppColors.greyLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.greyLight,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutArtistSection(Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Artist info container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A), // Solid grey background
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isLoadingArtist
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildLoadingArtistState(),
                )
              : _currentArtist != null
                  ? _buildArtistContent(_currentArtist!, currentSong)
                  : _buildFallbackArtistContent(currentSong),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadingArtistState() {
    return const Column(
      children: [
        SizedBox(height: 20),
        CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
        SizedBox(height: 16),
        Text(
          'Loading artist info...',
          style: TextStyle(
            color: AppColors.greyLight,
            fontSize: 14,
            fontFamily: 'Gotham',
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildArtistContent(Artist artist, Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width artist image with overlay text (Spotify-style)
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            color: AppColors.greyDark,
          ),
          child: Stack(
            children: [
              // Artist image filling container without cropping
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  color: AppColors.greyDark,
                  child: ImageHelpers.buildSafeNetworkImage(
                    imageUrl: artist.imageUrl,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit
                        .fitWidth, // Fit width untuk mengisi lebar penuh tanpa crop berlebihan
                    fallbackWidget: Container(
                      color: AppColors.greyDark,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 60,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No Artist Image',
                            style: TextStyle(
                              color: AppColors.greyLight,
                              fontSize: 14,
                              fontFamily: 'Gotham',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),

              // "Tentang artis" text overlay
              Positioned(
                top: 16,
                left: 16,
                child: Text(
                  'Tentang artis',
                  style: FontUsageGuide.modalTitle.copyWith(
                    shadows: [
                      const Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Artist info below image
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          style: FontUsageGuide.homeSectionHeader,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '9,3 jt pendengar bulanan', // Static for now
                          style: FontUsageGuide.metadata,
                        ),
                      ],
                    ),
                  ),

                  // Follow/Unfollow button
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedArtists = ref.watch(artistSelectProvider);
                      final isFollowing = selectedArtists.any((artistSelect) => 
                          artistSelect.artistName == artist.name);
                      
                      return GestureDetector(
                        onTap: () => _toggleFollowArtist(artist, isFollowing),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            isFollowing ? 'Mengikuti' : 'Ikuti',
                            style: FontUsageGuide.navigationLabel.copyWith(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Artist bio from PocketBase
              Text(
                artist.bio.isNotEmpty
                    ? artist.bio
                    : 'No biography available for this artist.',
                style: FontUsageGuide.emptyStateMessage.copyWith(
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // "lihat semua" text
              GestureDetector(
                onTap: () {
                  // Navigate to artist detail page
                  context.router.push(ArtistDetailRoute(
                    artistId: artist.id,
                    artistName: artist.name,
                  ));
                },
                child: Text(
                  'lihat semua',
                  style: FontUsageGuide.linkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackArtistContent(Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width fallback image with overlay text
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            color: AppColors.greyDark,
          ),
          child: Stack(
            children: [
              // Fallback content
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 60,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Artist Image',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 14,
                      fontFamily: 'Gotham',
                    ),
                  ),
                ],
              ),

              // "Tentang artis" text overlay
              Positioned(
                top: 16,
                left: 16,
                child: Text(
                  'Tentang artis',
                  style: FontUsageGuide.modalTitle.copyWith(
                    shadows: [
                      const Shadow(
                        color: Colors.black54,
                        offset: Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Artist info below image
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.artist,
                          style: FontUsageGuide.homeSectionHeader,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Artist information not available',
                          style: FontUsageGuide.emptyStateMessage,
                        ),
                      ],
                    ),
                  ),

                  // Follow button (disabled for fallback content)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Ikuti',
                      style: FontUsageGuide.navigationLabel.copyWith(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Fallback message
              Text(
                'Artist information is not available in the database yet. Check back later for more details about this artist.',
                style: FontUsageGuide.emptyStateMessage.copyWith(
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJelajahiArtistSection(Song currentSong) {
    // Use original artist name for consistent Jelajahi Artist section
    final displayArtistName = _originalArtistName ?? currentSong.artist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Jelajahi ',
                style: FontUsageGuide.homeSectionHeader,
              ),
              Text(
                displayArtistName,
                style: FontUsageGuide.homeSectionHeader.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal scrollable song list
        SizedBox(
          height: 200, // Fixed height for horizontal scroll
          child: _isLoadingArtistSongs && _artistSongs.isEmpty
              ? _buildLoadingArtistSongs()
              : _artistSongs.isEmpty
                  ? _buildEmptyArtistSongs(displayArtistName)
                  : Stack(
                      children: [
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: _artistSongs.length,
                          itemBuilder: (context, index) {
                            final song = _artistSongs[index];
                            return _buildArtistSongCard(
                                song, index == 0, index == _artistSongs.length - 1);
                          },
                        ),
                        // Show subtle loading indicator on top if refreshing
                        if (_isLoadingArtistSongs && _artistSongs.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingArtistSongs() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: 5, // Show 5 loading placeholders
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 8,
            right: index == 4 ? 0 : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album art placeholder
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Title placeholder
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.greyDark,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 4),

              // Artist placeholder
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.greyDark.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyArtistSongs(String artistName) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greyDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.music_note_outlined,
                size: 28,
                color: AppColors.greyLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada lagu lain dari',
              style: FontUsageGuide.emptyStateMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              artistName,
              style: FontUsageGuide.authFieldLabel.copyWith(
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'Coba lagi nanti untuk lebih banyak lagu',
              style: FontUsageGuide.metadata,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistSongCard(Song song, bool isFirst, bool isLast) {
    final playerState = ref.watch(playerControllerProvider);
    final isCurrentSong = playerState.currentSong?.id == song.id;

    return GestureDetector(
      onTap: () {
        if (isCurrentSong) {
          // If this is the current song, toggle play/pause
          if (playerState.isPlaying) {
            ref.read(playerControllerProvider.notifier).pause();
          } else {
            ref.read(playerControllerProvider.notifier).resume();
          }
        } else {
          // Play the selected song but don't update the original song reference
          // This keeps the Jelajahi Artist section consistent
          ref.read(playerControllerProvider.notifier).playSong(song);
        }
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.only(
          left: isFirst ? 0 : 8,
          right: isLast ? 0 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art with play indicator
            Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.greyDark,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageHelpers.buildSafeNetworkImage(
                      imageUrl: song.albumArtUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      showLoadingIndicator: true,
                      fallbackWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.greyDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.music_note,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrentSong && playerState.isPlaying
                              ? AppColors.primary.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentSong && playerState.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: isCurrentSong && playerState.isPlaying
                              ? Colors.white
                              : Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Current song indicator
                if (isCurrentSong)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Song title
            Text(
              song.title,
              style: FontUsageGuide.listSongTitle.copyWith(
                color: isCurrentSong ? AppColors.primary : Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Duration
            Text(
              _formatDuration(song.duration),
              style: FontUsageGuide.metadata,
            ),
          ],
        ),
      ),
    );
  }

  /// Build fallback album art when image fails to load
  Widget _buildFallbackAlbumArt() {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.greyDark,
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.music_note,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Album Art',
            style: FontUsageGuide.authFieldLabel.copyWith(
              color: AppColors.greyLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  void _triggerSongChangeAnimation(Song currentSong) async {
    // Set opacity to 0 immediately for smooth transition
    _albumFadeController.value = 0.0;
    _backgroundFadeController.value = 0.0;

    // Small delay to ensure color extraction happens
    await Future.delayed(const Duration(milliseconds: 50));

    // Fade in the new content
    _albumFadeController.forward();
    _backgroundFadeController.forward();
  }
}




