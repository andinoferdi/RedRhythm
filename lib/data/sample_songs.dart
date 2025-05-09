import '../models/song.dart';

class SampleSongs {
  static const Song grainySong = Song(
    id: '1',
    title: 'grainy days',
    artist: 'moody.',
    albumArtUrl: 'https://via.placeholder.com/300/FF5252/FFFFFF?text=Lofi+Art',
    duration: Duration(minutes: 2, seconds: 43),
    albumName: 'Late Night Vibes',
    lyrics: [
      'You never look at the sky',
      'Cause you think it\'s too high',
      'You never look at the stars',
      'Cause you think they\'re too far',
      'But I\'ve been trying to tell you',
      'That everything you need',
      'Is right in front of you',
      'Just open up your eyes and see',
      'These grainy days will pass',
      'The sun will shine again',
      'Just hold on through the storm',
      'And breathe through the pain',
    ],
    playlistId: 'lofi_loft',
  );

  static const List<Song> lofiPlaylist = [
    grainySong,
    Song(
      id: '2',
      title: 'midnight coffee',
      artist: 'sleepy sounds',
      albumArtUrl: 'https://via.placeholder.com/300/5D4037/FFFFFF?text=Coffee',
      duration: Duration(minutes: 3, seconds: 21),
      albumName: 'Chill Study Beats',
      lyrics: [
        'Midnight strikes the clock',
        'Coffee\'s getting cold',
        'Pages turn slowly',
        'As the night grows old',
        'Streetlights through the window',
        'Cast shadows on the wall',
        'The city never sleeps',
        'But time seems to stall',
      ],
      playlistId: 'lofi_loft',
    ),
    Song(
      id: '3',
      title: 'rainy window',
      artist: 'ambient flow',
      albumArtUrl: 'https://via.placeholder.com/300/42A5F5/FFFFFF?text=Rain',
      duration: Duration(minutes: 4, seconds: 15),
      albumName: 'Weather Beats',
      lyrics: [
        'Droplets race down the glass',
        'Each one charting a path',
        'The world outside distorted',
        'Through water and steam',
        'Cozy inside my room',
        'While the storm rages on',
        'This moment suspended',
        'Between reality and dream',
      ],
      playlistId: 'lofi_loft',
    ),
  ];
} 