import 'package:flutter/material.dart';

class LyricsView extends StatelessWidget {
  final List<String> lyrics;

  const LyricsView({
    super.key,
    required this.lyrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Fixed height to prevent overflow
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 0, 0, 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true, // Use minimal space
        physics: const BouncingScrollPhysics(), // Smooth scrolling
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: lyrics.length,
        itemBuilder: (context, index) {
          final bool isActive = index < 2; // First two lines are active
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              lyrics[index],
              style: TextStyle(
                color: isActive ? Colors.red : Colors.grey,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
