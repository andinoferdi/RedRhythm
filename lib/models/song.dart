class Song {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final Duration duration;
  final String albumName;
  final List<String> lyrics;
  final String playlistId;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.duration,
    required this.albumName,
    required this.lyrics,
    required this.playlistId,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtUrl,
    Duration? duration,
    String? albumName,
    List<String>? lyrics,
    String? playlistId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      duration: duration ?? this.duration,
      albumName: albumName ?? this.albumName,
      lyrics: lyrics ?? this.lyrics,
      playlistId: playlistId ?? this.playlistId,
    );
  }
} 