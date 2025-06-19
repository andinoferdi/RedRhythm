import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';
import '../models/artist.dart';

class SearchHistoryUtils {
  /// Clear search history for all users (global clear)
  static Future<void> clearAllSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Find all keys that start with search history prefixes
    final searchHistoryKeys = keys.where((key) => 
        key.startsWith('recent_searched_songs_') || 
        key.startsWith('recent_searched_artists_') ||
        key.startsWith('recent_searches_timeline_'));
    
    // Remove all search history entries
    for (final key in searchHistoryKeys) {
      await prefs.remove(key);
    }
  }
  
  /// Clean corrupted search history entries for a specific user
  static Future<void> cleanCorruptedUserHistory(String userId) async {
    try {
      // Get current history
      final currentHistory = await getUserSearchHistoryWithTimestamp(userId);
      
      // Filter out corrupted or invalid entries
      final cleanHistory = <Map<String, dynamic>>[];
      for (final item in currentHistory) {
        try {
          if (item['type'] == 'song') {
            final song = Song.fromJson(Map<String, dynamic>.from(item['data']));
            if (song.title.isNotEmpty && song.title.trim().isNotEmpty) {
              cleanHistory.add(item);
            }
          } else if (item['type'] == 'artist') {
            final artist = Artist.fromJson(Map<String, dynamic>.from(item['data']));
            if (artist.name.isNotEmpty && artist.name.trim().isNotEmpty) {
              cleanHistory.add(item);
            }
          }
        } catch (e) {
          // Skip corrupted items
          continue;
        }
      }
      
      // Save cleaned history
      await saveUserSearchHistoryWithTimestamp(userId, cleanHistory);
      
    } catch (e) {
      // If cleaning fails, clear all history for this user
      await clearUserSearchHistory(userId);
    }
  }
  
  /// Clear search history for a specific user
  static Future<void> clearUserSearchHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final songKey = 'recent_searched_songs_$userId';
    final artistKey = 'recent_searched_artists_$userId';
    final timelineKey = 'recent_searches_timeline_$userId';
    await prefs.remove(songKey);
    await prefs.remove(artistKey);
    await prefs.remove(timelineKey);
  }
  
  /// Clear search history for guest users
  static Future<void> clearGuestSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searched_songs_guest');
    await prefs.remove('recent_searched_artists_guest');
    await prefs.remove('recent_searches_timeline_guest');
  }
  
  /// Get search history for a specific user
  static Future<List<Song>> getUserSearchHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'recent_searched_songs_$userId';
    final songsJson = prefs.getStringList(userKey) ?? [];
    
    return songsJson.map((jsonStr) {
      try {
        final Map<String, dynamic> songMap = Map<String, dynamic>.from(jsonDecode(jsonStr));
        return Song.fromJson(songMap);
      } catch (e) {
        return null;
      }
    }).where((song) => song != null).cast<Song>().toList();
  }
  
  /// Save search history for a specific user
  static Future<void> saveUserSearchHistory(String userId, List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'recent_searched_songs_$userId';
    final songsJson = songs.map((song) => jsonEncode(song.toJson())).toList();
    await prefs.setStringList(userKey, songsJson);
  }
  
  /// Add song to user's search history
  static Future<void> addSongToUserHistory(String userId, Song song) async {
    final currentHistory = await getUserSearchHistory(userId);
    
    // Remove if already exists to avoid duplicates
    currentHistory.removeWhere((s) => s.id == song.id);
    
    // Add to beginning of list
    currentHistory.insert(0, song);
    
    // Keep only last 20 songs
    if (currentHistory.length > 20) {
      currentHistory.removeRange(20, currentHistory.length);
    }
    
    await saveUserSearchHistory(userId, currentHistory);
  }
  
  /// Remove song from user's search history
  static Future<void> removeSongFromUserHistory(String userId, Song song) async {
    final currentHistory = await getUserSearchHistory(userId);
    currentHistory.removeWhere((s) => s.id == song.id);
    await saveUserSearchHistory(userId, currentHistory);
  }

  // ARTIST HISTORY METHODS

  /// Get artist search history for a specific user
  static Future<List<Artist>> getUserArtistHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'recent_searched_artists_$userId';
    final artistsJson = prefs.getStringList(userKey) ?? [];
    
    return artistsJson.map((jsonStr) {
      try {
        final Map<String, dynamic> artistMap = Map<String, dynamic>.from(jsonDecode(jsonStr));
        final artist = Artist.fromJson(artistMap);
        
        // Validate artist data - only return if it has a valid name
        if (artist.name.isNotEmpty && artist.name.trim().isNotEmpty) {
          return artist;
        }
        return null;
      } catch (e) {
        return null;
      }
    }).where((artist) => artist != null).cast<Artist>().toList();
  }
  
  /// Save artist search history for a specific user
  static Future<void> saveUserArtistHistory(String userId, List<Artist> artists) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'recent_searched_artists_$userId';
    final artistsJson = artists.map((artist) => jsonEncode(artist.toJson())).toList();
    await prefs.setStringList(userKey, artistsJson);
  }
  
  /// Add artist to user's search history
  static Future<void> addArtistToUserHistory(String userId, Artist artist) async {
    // Validate artist data before adding
    if (artist.name.isEmpty || artist.name.trim().isEmpty) {
      return; // Don't add invalid artists
    }
    
    final currentHistory = await getUserArtistHistory(userId);
    
    // Remove if already exists to avoid duplicates
    currentHistory.removeWhere((a) => a.id == artist.id);
    
    // Add to beginning of list
    currentHistory.insert(0, artist);
    
    // Keep only last 20 artists
    if (currentHistory.length > 20) {
      currentHistory.removeRange(20, currentHistory.length);
    }
    
    await saveUserArtistHistory(userId, currentHistory);
  }
  
  /// Remove artist from user's search history
  static Future<void> removeArtistFromUserHistory(String userId, Artist artist) async {
    final currentHistory = await getUserArtistHistory(userId);
    currentHistory.removeWhere((a) => a.id == artist.id);
    await saveUserArtistHistory(userId, currentHistory);
  }

  /// Get combined search history with timestamp for a specific user
  static Future<List<Map<String, dynamic>>> getUserSearchHistoryWithTimestamp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'recent_searches_timeline_$userId';
    final searchesJson = prefs.getStringList(userKey) ?? [];
    
    return searchesJson.map((jsonStr) {
      try {
        return Map<String, dynamic>.from(jsonDecode(jsonStr));
      } catch (e) {
        return null;
      }
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
  }

  /// Save combined search history with timestamp for a specific user
  static Future<void> saveUserSearchHistoryWithTimestamp(String userId, List<Map<String, dynamic>> searches) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'recent_searches_timeline_$userId';
    final searchesJson = searches.map((search) => jsonEncode(search)).toList();
    await prefs.setStringList(userKey, searchesJson);
  }

  /// Add search item (song or artist) to user's search history with timestamp
  static Future<void> addSearchItemToUserHistory(String userId, dynamic item) async {
    // Validate data before adding
    if (item is Artist && (item.name.isEmpty || item.name.trim().isEmpty)) {
      return; // Don't add invalid artists
    }
    if (item is Song && (item.title.isEmpty || item.title.trim().isEmpty)) {
      return; // Don't add invalid songs
    }
    
    final currentHistory = await getUserSearchHistoryWithTimestamp(userId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    Map<String, dynamic> searchItem = {
      'timestamp': timestamp,
      'type': item is Song ? 'song' : 'artist',
      'data': item.toJson(),
    };
    
    // Remove if already exists to avoid duplicates
    if (item is Song) {
      currentHistory.removeWhere((s) => s['type'] == 'song' && s['data']['id'] == item.id);
    } else if (item is Artist) {
      currentHistory.removeWhere((s) => s['type'] == 'artist' && s['data']['id'] == item.id);
    }
    
    // Add to beginning of list
    currentHistory.insert(0, searchItem);
    
    // Keep only last 20 items
    if (currentHistory.length > 20) {
      currentHistory.removeRange(20, currentHistory.length);
    }
    
    await saveUserSearchHistoryWithTimestamp(userId, currentHistory);
  }

  /// Remove search item from user's search history
  static Future<void> removeSearchItemFromUserHistory(String userId, dynamic item) async {
    final currentHistory = await getUserSearchHistoryWithTimestamp(userId);
    
    if (item is Song) {
      currentHistory.removeWhere((s) => s['type'] == 'song' && s['data']['id'] == item.id);
    } else if (item is Artist) {
      currentHistory.removeWhere((s) => s['type'] == 'artist' && s['data']['id'] == item.id);
    }
    
    await saveUserSearchHistoryWithTimestamp(userId, currentHistory);
  }

  /// Get combined search history (songs + artists) sorted by timeline for a specific user
  static Future<List<dynamic>> getCombinedUserHistory(String userId) async {
    final historyWithTimestamp = await getUserSearchHistoryWithTimestamp(userId);
    
    // Sort by timestamp (newest first)
    historyWithTimestamp.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    // Convert back to Song/Artist objects
    List<dynamic> combined = [];
    for (final item in historyWithTimestamp) {
      try {
        if (item['type'] == 'song') {
          final song = Song.fromJson(Map<String, dynamic>.from(item['data']));
          // Validate song data
          if (song.title.isNotEmpty && song.title.trim().isNotEmpty) {
            combined.add(song);
          }
        } else if (item['type'] == 'artist') {
          final artist = Artist.fromJson(Map<String, dynamic>.from(item['data']));
          // Validate artist data
          if (artist.name.isNotEmpty && artist.name.trim().isNotEmpty) {
            combined.add(artist);
          }
        }
      } catch (e) {
        // Skip corrupted items
        continue;
      }
    }
    
    return combined;
  }
} 

