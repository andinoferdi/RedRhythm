import 'package:flutter/material.dart';
import '../screens/library/library_tab_enum.dart';

class LibraryController extends ChangeNotifier {
  LibraryTab _selectedTab = LibraryTab.playlists;
  
  LibraryTab get selectedTab => _selectedTab;

  void selectTab(LibraryTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }
} 