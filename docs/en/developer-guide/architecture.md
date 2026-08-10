# Architecture

Keep UI, state management, domain logic, data access, and platform-specific code separated. The initial implementation uses Riverpod for state management and dependency injection, and go_router for navigation.

## Directory structure

- `lib/app/`: application startup, provider composition, themes, and routing
- `lib/domain/`: models and abstract interfaces such as application settings
- `lib/data/`: SharedPreferences settings storage, local directory scanning, audio playback, and the Drift library database
- `lib/presentation/`: screens and UI components
- `lib/platform/`: boundaries for Windows and other platform-specific behavior

Local file access, SMB access, audio playback, MusicBrainz integration, tag handling, CD ripping, and audio analysis should have independent service boundaries. External service responses and platform APIs must not be passed directly to the UI.

## Persistence

Settings are stored with SharedPreferences. Library cache data is stored in a Drift SQLite database; the initial schema provides a foundation for source path, title, artist, album, and last-seen timestamp. Audio files are never copied into the database. Files in the selected local directory or SMB share remain the source of truth.

The local directory scanner walks subdirectories recursively and currently treats FLAC and MP3 files as library candidates. Additional formats and tag parsing belong behind the scanner and metadata service boundaries.

Audio playback is accessed through the `PlaybackService` abstraction. The current implementation uses just_audio and its Windows implementation to play files by path. The UI observes service state instead of depending directly on the playback engine.

Disconnected shares, authentication failures, and missing files are recoverable errors and must not crash the UI or the whole service layer.

CD detection and ripping are Windows-specific. Android provides local directory or SMB library access and playback. Windows-only CD processing must not be mixed directly into shared domain code.
