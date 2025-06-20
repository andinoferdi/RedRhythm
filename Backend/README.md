# RedRhythm Backend

PocketBase backend server for RedRhythm music streaming application.

## Features

- User authentication and authorization
- Music library management (songs, albums, artists, genres)
- Playlist management
- Favorites system
- File storage for audio files and album covers
- Real-time data synchronization

## Setup

### Prerequisites

- Download PocketBase from [https://pocketbase.io/](https://pocketbase.io/)
- Place the `pocketbase.exe` file in this directory

### Installation

1. Clone this repository
2. Navigate to the backend directory
3. Run PocketBase:

```bash
# Windows
./pocketbase.exe serve

# Linux/macOS
./pocketbase serve
```

4. Open http://localhost:8090/_/ to access the admin panel
5. Import the database schema from `pb_migrations/` (automatically applied on first run)

### Configuration

- Default port: 8090
- Admin panel: http://localhost:8090/_/
- API endpoint: http://localhost:8090/api/

### Database Schema

The database includes the following collections:
- `users` - User accounts and profiles
- `songs` - Music tracks with metadata
- `albums` - Album information
- `artists` - Artist profiles
- `genres` - Music genres
- `playlists` - User-created playlists
- `favorites` - User favorite songs
- `recent_plays` - Play history tracking

### File Storage

- Audio files: `pb_data/storage/`
- Album covers: `pb_data/storage/`
- User avatars: `pb_data/storage/`

### Development

For development, you can run PocketBase with auto-restart:

```bash
./pocketbase serve --dev
```

### Production

For production deployment:

1. Set up proper domain and SSL
2. Configure environment variables
3. Set up regular database backups
4. Configure proper CORS settings

### API Documentation

PocketBase automatically generates API documentation available at:
http://localhost:8090/_/

### Migration Files

Database schema changes are tracked in `pb_migrations/` directory and automatically applied when starting PocketBase. 