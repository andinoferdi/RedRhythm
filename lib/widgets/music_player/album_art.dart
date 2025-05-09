import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  final String imageUrl;

  const AlbumArt({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width - 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: _getImageProvider(),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      return AssetImage(imageUrl);
    }
  }
} 