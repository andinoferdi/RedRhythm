enum LibraryTab {
  playlists,
  artists,
  albums,
  podcasts
}

extension LibraryTabExtension on LibraryTab {
  String get label {
    switch (this) {
      case LibraryTab.playlists:
        return 'Playlists';
      case LibraryTab.artists:
        return 'Artists';
      case LibraryTab.albums:
        return 'Albums';
      case LibraryTab.podcasts:
        return 'Podcasts & Shows';
    }
  }
}
