import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song.dart';

class SearchHistoryUtils {
  /// Clear search history for all users (global clear)
  static Future<void> clearAllSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Find all keys that start with 'recent_searched_songs_'
    final searchHistoryKeys = keys.where((key) => key.startsWith('recent_searched_songs_'));
    
    // Remove all search history entries
    for (final key in searchHistoryKeys) {
      await prefs.remove(key);
    }
  }
  
  /// Clear search history for a specific user
  static Future<void> clearUserSearchHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = 'recent_searched_songs_$userId';
    await prefs.remove(userKey);
  }
  
  /// Clear search history for guest users
  static Future<void> clearGuestSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searched_songs_guest');
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
} 