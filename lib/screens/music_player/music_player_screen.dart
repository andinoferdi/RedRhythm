import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/player_controller.dart';
import '../../states/player_state.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../repositories/artist_repository.dart';
import '../../services/pocketbase_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_helpers.dart';
import '../../routes/app_router.dart';

@RoutePage()
class MusicPlayerScreen extends ConsumerStatefulWidget {
  final Song? song;
  
  const MusicPlayerScreen({this.song, super.key});

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen> {
  Artist? _currentArtist;
  bool _isLoadingArtist = false;
  late ArtistRepository _artistRepository;

  @override
  void initState() {
    super.initState();
    _artistRepository = ArtistRepository(PocketBaseService());
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
      debugPrint('Error loading artist info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentSong = playerState.currentSong ?? widget.song;
    
    if (currentSong == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'No song is currently playing',
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    // Note: Removed automatic playback initiation to prevent interference with existing playback
    // The music player screen should only display current state, not start new playback

    // Load artist info when song changes
    if (_currentArtist?.name != currentSong.artist) {
      _loadArtistInfo(currentSong.artist);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text),
          onPressed: () => context.router.maybePop(),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.text),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Album Art
              Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.greyDark, // Background color for fallback
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Album art image with enhanced error handling
                      ImageHelpers.buildSafeNetworkImage(
                        imageUrl: currentSong.albumArtUrl,
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(20),
                        showLoadingIndicator: true,
                        fallbackWidget: _buildFallbackAlbumArt(),
                      ),
                      
                      // Show loading indicator when buffering
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
              
              const SizedBox(height: 30),
              
              // Song info
              Column(
                children: [
                  Text(
                    currentSong.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSong.artist,
                    style: const TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Playback controls
              Column(
                children: [
                  // Slider
                  Slider(
                    value: playerState.currentPosition.inSeconds.toDouble(),
                    max: currentSong.duration.inSeconds.toDouble(),
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.greyDark,
                    onChanged: (value) {
                      ref.read(playerControllerProvider.notifier).seekTo(
                        Duration(seconds: value.toInt()),
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
                          style: const TextStyle(color: AppColors.greyLight),
                        ),
                        Text(
                          _formatDuration(currentSong.duration),
                          style: const TextStyle(color: AppColors.greyLight),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Always show shuffle button - supports both playlist and general shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: playerState.shuffleMode ? AppColors.primary : AppColors.text,
                          size: 24,
                        ),
                        onPressed: () {
                          ref.read(playerControllerProvider.notifier).toggleShuffle();
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: AppColors.text,
                          size: 36,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(playerControllerProvider.notifier).skipPrevious();
                          } catch (e) {
                            debugPrint('Error skipping to previous song: $e');
                          }
                        },
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isBuffering
                                ? Icons.hourglass_empty
                                : playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.textOnPrimary,
                            size: 36,
                          ),
                          onPressed: () {
                            if (playerState.isBuffering) {
                              // Do nothing while buffering
                              return;
                            }
                            
                            if (playerState.isPlaying) {
                              ref.read(playerControllerProvider.notifier).pause();
                            } else {
                              ref.read(playerControllerProvider.notifier).resume();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: AppColors.text,
                          size: 36,
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(playerControllerProvider.notifier).skipNext();
                          } catch (e) {
                            debugPrint('Error skipping to next song: $e');
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          playerState.repeatMode == RepeatMode.off
                              ? Icons.repeat
                              : playerState.repeatMode == RepeatMode.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                          color: playerState.repeatMode == RepeatMode.off
                              ? AppColors.text
                              : AppColors.primary,
                          size: 24,
                        ),
                        onPressed: () {
                          ref.read(playerControllerProvider.notifier).toggleRepeatMode();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // About Artist Section (Spotify-style) - Above lyrics
              _buildAboutArtistSection(currentSong),
              
              // Lyrics Preview Section (Spotify-style)
              _buildLyricsPreviewSection(currentSong),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLyricsPreviewSection(Song currentSong) {
    final hasLyrics = currentSong.lyrics != null && currentSong.lyrics!.trim().isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Lyrics icon
        Row(
          children: [
            const Icon(
              Icons.lyrics_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Lyrics',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
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
        
        const SizedBox(height: 40),
      ],
    );
  }
  
  Widget _buildLyricsPreview(Song song) {
    // Get first few lines of lyrics for preview
    final lyricsLines = song.lyrics!.split('\n');
    final previewLines = lyricsLines.take(3).where((line) => line.trim().isNotEmpty).toList();
    final previewText = previewLines.join('\n');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE53E3E), // Red primary
            const Color(0xFFD53F8C), // Red-pink
            const Color(0xFFC53030), // Darker red
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53E3E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tampilkan Lirik',
                      style: TextStyle(
                        color: Color(0xFFE53E3E),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFFE53E3E),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
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
            const Expanded(
              child: Text(
                'No lyrics available for this song',
                style: TextStyle(
                  color: AppColors.greyLight,
                  fontSize: 14,
                  fontFamily: 'Poppins',
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
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
        // Header with artist icon
        Row(
          children: [
            const Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Tentang artis',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Artist info container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A), // Solid grey background
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isLoadingArtist
              ? _buildLoadingArtistState()
              : _currentArtist != null
                  ? _buildArtistContent(_currentArtist!, currentSong)
                  : _buildFallbackArtistContent(currentSong),
        ),
        
        const SizedBox(height: 20),
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
            fontFamily: 'Poppins',
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
        // Artist header with image and name
        Row(
          children: [
            // Artist avatar (circular) - using real artist image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greyDark,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: ImageHelpers.buildSafeNetworkImage(
                  imageUrl: artist.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  fallbackWidget: Container(
                    color: AppColors.greyDark,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Artist info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '9,3 jt pendengar bulanan', // Static for now
                    style: const TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            
            // Follow button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.greyLight,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Ikuti',
                style: TextStyle(
                  color: AppColors.greyLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Artist bio from PocketBase
        Text(
          artist.bio.isNotEmpty ? artist.bio : 'No biography available for this artist.',
          style: const TextStyle(
            color: AppColors.greyLight,
            fontSize: 14,
            height: 1.5,
            fontFamily: 'Poppins',
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // "lihat semua" text
        GestureDetector(
          onTap: () {
            // TODO: Navigate to artist detail page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Artist detail page coming soon!'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          child: const Text(
            'lihat semua',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFallbackArtistContent(Song currentSong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Artist header with fallback content
        Row(
          children: [
            // Fallback artist avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greyDark,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Artist info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong.artist,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Artist information not available',
                    style: TextStyle(
                      color: AppColors.greyLight,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Fallback message
        const Text(
          'Artist information is not available in the database yet. Check back later for more details about this artist.',
          style: TextStyle(
            color: AppColors.greyLight,
            fontSize: 14,
            height: 1.5,
            fontFamily: 'Poppins',
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'No Album Art',
            style: TextStyle(
              color: AppColors.greyLight,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
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
}
