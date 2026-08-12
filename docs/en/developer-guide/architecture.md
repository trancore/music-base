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

Playlists are persisted through the `PlaylistRepository` abstraction. The current implementation stores playlist names and source paths in SharedPreferences, then resolves those paths against the current library cache when a playlist is played. Playlist data never copies the audio files.

MusicBrainz integration is accessed through `MusicBrainzService`. The API client maps JSON responses to `MusicBrainzRelease` models and applies an identifying User-Agent, a maximum request rate of one request per second, and an in-memory search-result cache.

SMB connectivity is accessed through the `SmbService` abstraction. Host, share, subfolder, and username are stored as settings, while the password is stored with `flutter_secure_storage`. The SMB scanner recursively walks the share, filters FLAC/MP3 files, and caches them in the library database as a separate operation from connection testing. SMB playback maps `StreamAudioSource` range requests to SMB partial reads, so the audio file is played without copying it into the app.

Disconnected shares, authentication failures, and missing files are recoverable errors and must not crash the UI or the whole service layer.

CD detection and ripping are Windows-specific. Android provides local directory or SMB library access and playback. Windows-only CD processing must not be mixed directly into shared domain code.

CD output plans are created by `CdImportPlanner`. It validates the MusicBrainz track count against the CD tracks, derives FLAC/MP3 filenames and tag candidates, and refuses existing target paths before any file is written. Drive reading and encoding are invoked through a Windows-specific service.

Windows CD drive detection is isolated behind `CdDriveService`. The Windows implementation queries drive letters, device names, and media-loaded state from PowerShell's `Win32_CDROMDrive`. Android and non-Windows environments report the capability as unavailable.

CD track listing is isolated behind `CdTrackService`; the Windows implementation obtains track count and lengths from the CD Audio MCI API. MCI and PowerShell execution remain in the Windows data layer, while shared code receives only `CdTrack` models.
