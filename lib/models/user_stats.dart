class UserStats {
  final int songsPlayed;
  final int playlistsCount;
  final int likedSongs; // Actually represents saved albums
  final int following; // Actually represents saved artists

  UserStats({
    required this.songsPlayed,
    required this.playlistsCount,
    required this.likedSongs,
    required this.following,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      songsPlayed: json['songs_played'] ?? 0,
      playlistsCount: json['playlists_count'] ?? 0,
      likedSongs: json['liked_songs'] ?? 0,
      following: json['following'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songs_played': songsPlayed,
      'playlists_count': playlistsCount,
      'liked_songs': likedSongs,
      'following': following,
    };
  }
} 