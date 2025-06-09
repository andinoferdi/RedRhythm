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
      lyrics: 'Instrumental music\nNo lyrics available for this track',
      audioFileName: 'midnight_coffee.mp3',
    ),
    Song(
      id: 'lofi2',
      title: 'Rainy Window',
      artist: 'LofiLab',
      albumArtUrl: 'https://picsum.photos/id/1015/300/300',
      durationInSeconds: 195,
      albumName: 'Calm Rain',
      lyrics: 'Instrumental music\nNo lyrics available for this track',
      audioFileName: 'rainy_window.mp3',
    ),
    Song(
      id: 'lofi3',
      title: 'City Lights',
      artist: 'Sleepy Tunes',
      albumArtUrl: 'https://picsum.photos/id/1035/300/300',
      durationInSeconds: 275,
      albumName: 'Urban Lofi',
      lyrics: 'Instrumental music\nNo lyrics available for this track',
      audioFileName: 'city_lights.mp3',
    ),
    Song(
      id: 'lofi4',
      title: 'Sunset Dreams',
      artist: 'ChillBeats',
      albumArtUrl: 'https://picsum.photos/id/1019/300/300',
      durationInSeconds: 210,
      albumName: 'Evening Vibes',
      lyrics: 'Instrumental music\nNo lyrics available for this track',
      audioFileName: 'sunset_dreams.mp3',
    ),
    Song(
      id: 'lofi5',
      title: 'Morning Mist',
      artist: 'RelaxBeats',
      albumArtUrl: 'https://picsum.photos/id/1039/300/300',
      durationInSeconds: 228,
      albumName: 'Morning Coffee',
      lyrics: 'Instrumental music\nNo lyrics available for this track',
      audioFileName: 'morning_mist.mp3',
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
      lyrics: '''[Verse 1]
Walking through the city streets tonight
Neon lights reflecting off the concrete
Every corner tells a different story
This is where I found my glory

[Hook]
City groove, it's in my soul
Can't stop the rhythm taking control
From the underground to the rooftop high
This is how we touch the sky

[Verse 2]
Concrete jungle, but I call it home
Through these streets I've always roamed
Beat dropping hard, bass line clean
Living life like you've never seen''',
      audioFileName: 'city_groove.mp3',
    ),
    Song(
      id: 'hh2',
      title: 'Midnight Run',
      artist: 'Beat Master',
      albumArtUrl: 'https://picsum.photos/id/1079/300/300',
      durationInSeconds: 250,
      albumName: 'Night Rhythms',
      lyrics: '''[Intro]
Yeah, midnight run, let's go
Turn the volume up, here we flow

[Verse 1]
Racing through the midnight hour
Feel the rhythm, feel the power
City sleeps but we're awake
Every move is what we make

[Hook]
Midnight run, we own the night
Everything's gonna be alright
Keep on moving, don't look back
We're running on the midnight track''',
      audioFileName: 'midnight_run.mp3',
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
      lyrics: '''[Verse 1]
Sunshine streaming through my window
Another perfect day begins
Dancing to the morning tempo
This is where the fun begins

[Pre-Chorus]
Feel the warmth upon my skin
Let the summer dreams begin

[Chorus]
Summer days, they never fade
Memories that we have made
Golden hours, endless nights
Everything's gonna be alright

[Verse 2]
Ocean waves and sandy beaches
Friends and laughter all around
These are moments no one teaches
Pure joy in every sound''',
      audioFileName: 'summer_days.mp3',
    ),
    Song(
      id: 'pop2',
      title: 'Dance All Night',
      artist: 'Party People',
      albumArtUrl: 'https://picsum.photos/id/1071/300/300',
      durationInSeconds: 227,
      albumName: 'Weekend Anthems',
      lyrics: '''[Intro]
Turn it up, turn it loud
We're gonna party with the crowd

[Verse 1]
Friday night, the weekend's here
Put away your stress and fear
Hit the floor, feel the beat
Move your body to the heat

[Chorus]
Dance all night, until the dawn
Keep the party going on
Feel the music in your soul
Let the rhythm take control

[Verse 2]
Lights are flashing, music's loud
We're the kings and queens of this crowd
Every moment feels so right
We're gonna dance all through the night''',
      audioFileName: 'dance_all_night.mp3',
    ),
  ];
} 