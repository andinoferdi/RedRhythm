import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'genre.freezed.dart';
part 'genre.g.dart';

@freezed
class Genre with _$Genre {
  const factory Genre({
    required String id,
    required String name,
    required String description,
    String? image,
    required DateTime created,
    required DateTime updated,
  }) = _Genre;

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);

  factory Genre.fromRecord(RecordModel record) {
    return Genre(
      id: record.id,
      name: record.data['name'] ?? '',
      description: record.data['description'] ?? '',
      image: record.data['image'],
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
  }
}

// Extension for additional computed properties
extension GenreExtension on Genre {
  /// Get the full image URL for the genre
  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    // This will be constructed with PocketBase service
    return image!;
  }
} 