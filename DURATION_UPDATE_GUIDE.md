# 🎵 Song Duration Auto-Update Guide

## Overview

Fitur ini akan secara otomatis mendeteksi dan mengupdate durasi lagu di database berdasarkan durasi file MP3 yang sebenarnya.

## Cara Menggunakan

### Method 1: Manual Bulk Update (Recommended)

1. Buka aplikasi RedRhythm
2. Pergi ke tab **Library**
3. **Long press** pada tulisan "Library" di header
4. Pilih **"Update Song Durations"**
5. Klik **"Start Update"**
6. Tunggu sampai proses selesai

### Method 2: Automatic on Play (Already Active)

- Setiap kali lagu diputar, jika duration = 0, sistem akan otomatis:
  - Mendeteksi durasi sebenarnya dari file MP3
  - Mengupdate database
  - Memperbarui tampilan

## Technical Details

### Files Created/Modified:

- `lib/services/audio_duration_service.dart` - Service untuk deteksi durasi
- `lib/controllers/duration_controller.dart` - Controller dengan Riverpod
- `lib/screens/admin/duration_update_screen.dart` - UI untuk bulk update
- `lib/controllers/player_controller.dart` - Auto update saat play

### Features:

- 🎯 **Smart Detection**: Hanya update lagu dengan duration = 0
- 📊 **Progress Tracking**: Real-time progress dengan statistik
- 🔄 **Auto Retry**: Retry logic untuk koneksi yang tidak stabil
- 🛡️ **Error Handling**: Comprehensive error handling
- ⚡ **Performance**: Delay antar request untuk tidak overwhelm server

### Logic Flow:

```
1. Query songs where duration = 0
2. For each song:
   - Get MP3 file URL
   - Use JustAudio to detect duration
   - Update PocketBase record
   - Update progress UI
3. Show completion statistics
```

## Database Schema

Column `duration` di tabel `songs` sekarang akan berisi durasi dalam detik (integer).

## Admin Access

Long press pada "Library" text di header untuk mengakses admin options.

## Notes

- Proses ini membutuhkan koneksi internet untuk akses file MP3
- Durasi akan terdeteksi dalam hitungan detik
- Sistem akan skip lagu yang sudah memiliki durasi valid
- Progress disimpan dalam state management (Riverpod)
