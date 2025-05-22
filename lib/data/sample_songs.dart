import '../models/song.dart';

/// Sample songs data for testing and UI development
class SampleSongs {
  /// Sample lofi playlist songs
  static final List<Song> lofiPlaylist = [
    Song(
      id: 'lofi1',
      title: 'Midnight Coffee',
      artist: 'ChillBeats',
      albumArtUrl: 'https://picsum.photos/id/1025/300/300',
      durationInSeconds: 240,
      albumName: 'Lofi Study Beats',
      lyrics: ['Instrumental music', 'No lyrics'],
    ),
    Song(
      id: 'lofi2',
      title: 'Rainy Window',
      artist: 'LofiLab',
      albumArtUrl: 'https://picsum.photos/id/1015/300/300',
      durationInSeconds: 195,
      albumName: 'Calm Rain',
      lyrics: ['Instrumental music', 'No lyrics'],
    ),
    Song(
      id: 'lofi3',
      title: 'City Lights',
      artist: 'Sleepy Tunes',
      albumArtUrl: 'https://picsum.photos/id/1035/300/300',
      durationInSeconds: 275,
      albumName: 'Urban Lofi',
      lyrics: ['Instrumental music', 'No lyrics'],
    ),
    Song(
      id: 'lofi4',
      title: 'Sunset Dreams',
      artist: 'ChillBeats',
      albumArtUrl: 'https://picsum.photos/id/1019/300/300',
      durationInSeconds: 210,
      albumName: 'Evening Vibes',
      lyrics: ['Instrumental music', 'No lyrics'],
    ),
    Song(
      id: 'lofi5',
      title: 'Morning Mist',
      artist: 'RelaxBeats',
      albumArtUrl: 'https://picsum.photos/id/1039/300/300',
      durationInSeconds: 228,
      albumName: 'Morning Coffee',
      lyrics: ['Instrumental music', 'No lyrics'],
    ),
  ];

  /// Sample hip hop playlist songs
  static final List<Song> hipHopPlaylist = [
    Song(
      id: 'hh1',
      title: 'City Groove',
      artist: 'Urban Flow',
      albumArtUrl: 'https://picsum.photos/id/1062/300/300',
      durationInSeconds: 235,
      albumName: 'Street Life',
      lyrics: ['Verse 1', 'Hook', 'Verse 2', 'Hook', 'Verse 3', 'Outro'],
    ),
    Song(
      id: 'hh2',
      title: 'Midnight Run',
      artist: 'Beat Master',
      albumArtUrl: 'https://picsum.photos/id/1079/300/300',
      durationInSeconds: 250,
      albumName: 'Night Rhythms',
      lyrics: ['Intro', 'Verse 1', 'Hook', 'Verse 2', 'Hook', 'Outro'],
    ),
  ];

  /// Sample pop playlist songs
  static final List<Song> popPlaylist = [
    Song(
      id: 'pop1',
      title: 'Summer Days',
      artist: 'Melody Makers',
      albumArtUrl: 'https://picsum.photos/id/1080/300/300',
      durationInSeconds: 215,
      albumName: 'Sunny Vibes',
      lyrics: ['Verse 1', 'Pre-Chorus', 'Chorus', 'Verse 2', 'Pre-Chorus', 'Chorus', 'Bridge', 'Chorus'],
    ),
    Song(
      id: 'pop2',
      title: 'Dance All Night',
      artist: 'Party People',
      albumArtUrl: 'https://picsum.photos/id/1071/300/300',
      durationInSeconds: 227,
      albumName: 'Weekend Anthems',
      lyrics: ['Intro', 'Verse 1', 'Chorus', 'Verse 2', 'Chorus', 'Bridge', 'Chorus', 'Outro'],
    ),
  ];
} 