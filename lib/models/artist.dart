import 'package:pocketbase/pocketbase.dart';

class Artist {
  final String id;
  final String name;
  final String bio;
  final String? imageUrl;
  final DateTime created;
  final DateTime updated;

  Artist({
    required this.id,
    required this.name,
    required this.bio,
    this.imageUrl,
    required this.created,
    required this.updated,
  });

  factory Artist.fromRecord(RecordModel record, PocketBase pb) {
    String? imageUrl;
    
    // Generate image URL if image field exists
    if (record.data['image'] != null && record.data['image'].toString().isNotEmpty) {
      try {
        imageUrl = pb.files.getUrl(record, record.data['image']).toString();
      } catch (e) {

        imageUrl = null;
      }
    }

    return Artist(
      id: record.id,
      name: record.data['name']?.toString() ?? '',
      bio: record.data['bio']?.toString() ?? '',
      imageUrl: imageUrl,
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      imageUrl: json['imageUrl'],
      created: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updated: DateTime.parse(json['updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Artist(id: $id, name: $name, bio: $bio, imageUrl: $imageUrl)';
  }
} 

