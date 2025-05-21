import 'package:flutter/material.dart';
import '../routes.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final double? bottomPadding;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Use a fixed padding value to ensure consistency across all screens
    final padding = bottomPadding ?? MediaQuery.of(context).padding.bottom;
    
    // Use Material's BottomNavigationBar which has better built-in sizing
    return Container(
      // Prevent overflow by ensuring there's no padding causing extra height
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      // Use a more reasonable height - revert to a size that works but isn't too large
      height: 60 + padding + 0.5, // Add 0.5 to account for the fractional overflow
      padding: EdgeInsets.only(bottom: padding),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFE71E27),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        type: BottomNavigationBarType.fixed,
        elevation: 0, // Remove default shadow as we're providing our own
        onTap: (index) {
          if (index != currentIndex) {
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                break;
              case 1:
                Navigator.of(context).pushReplacementNamed(AppRoutes.explore);
                break;
              case 2:
                Navigator.of(context).pushReplacementNamed(AppRoutes.library);
                break;
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
