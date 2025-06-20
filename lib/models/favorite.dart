import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'favorite.g.dart';
part 'favorite.freezed.dart';

@freezed
class Favorite with _$Favorite {
  const factory Favorite({
    required String id,
    required String userId,
    required String songId,
    required DateTime createdAt,
  }) = _Favorite;

  factory Favorite.fromJson(Map<String, dynamic> json) => _$FavoriteFromJson(json);
  
  /// Create a Favorite from a PocketBase record
  static Favorite fromRecord(RecordModel record) {
    return Favorite(
      id: record.id,
      userId: record.data['user_id'] as String,
      songId: record.data['song_id'] as String,
      createdAt: DateTime.parse(record.created),
    );
  }
} 