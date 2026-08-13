# Architecture

Keep UI, state management, domain logic, data access, and platform-specific code separated. The initial implementation uses Riverpod for state management and dependency injection, and go_router for navigation. The app shell uses a desktop sidebar and a top-fixed playback dock on wider screens, and a top-fixed playback dock with bottom navigation below 700px. Routes share a short fade-and-horizontal-slide transition.

## Directory structure

- `lib/app/`: application startup, provider composition, themes, and routing
- `lib/domain/`: models and abstract interfaces such as application settings
- `lib/data/`: SharedPreferences settings storage, local directory scanning, audio playback, and the Drift library database
- `lib/presentation/`: screens and UI components
- `lib/platform/`: boundaries for Windows and other platform-specific behavior

Local file access, SMB access, audio playback, MusicBrainz integration, tag handling, CD ripping, and audio analysis should have independent service boundaries. External service responses and platform APIs must not be passed directly to the UI.

## Persistence

Settings are stored with SharedPreferences. Library cache data is stored in a Drift SQLite database with source path, title, artist, album, file fingerprint, and last-seen timestamp. FTS5 search, keyset pagination, hash-deduplicated artwork, and lazy artwork loading support up to 100,000 tracks without materializing the whole library in memory. Audio files are never copied into the database. Files in the selected local directory or SMB share remain the source of truth.

Library rescans run asynchronously without replacing the UI state with a loading state, so the previously loaded cache page remains available until completion. After success, track and group data are reloaded. On failure, the cache stays visible and the failure is exposed as a recoverable warning.

Album and artist views are aggregated in SQLite and the groups themselves use keyset pagination. Opening or playing a group reuses the track query with an album or artist constraint, so grouped browsing does not materialize the complete library in memory.

The cache also stores FLAC disc and track numbers plus a metadata parser version. The SMB scanner walks FLAC metadata-block headers with range reads and fetches only Vorbis Comments and PICTURE data up to 2 MB. A cached track with an older parser version is reprocessed on the next scan even when its file fingerprint is unchanged.

The local directory scanner walks subdirectories recursively and currently treats FLAC and MP3 files as library candidates. Local scans read embedded MP3 ID3 and FLAC Vorbis metadata through `audio_metadata_reader`, including artwork up to 2 MB, then fall back to path-derived metadata when tags are unavailable. Metadata and artwork are cached in the Drift library table. Additional formats and tag parsing belong behind the scanner and metadata service boundaries.

Audio playback is accessed through the `PlaybackService` abstraction. The current implementation uses just_audio, its Windows implementation, and the native Darwin implementation to play files by path. Play-all order is stored in a temporary SQLite queue and only the track at the current position is resolved. The UI observes service state instead of depending directly on the playback engine.

Internet radio stations are represented by `InternetRadioStation` and managed through `RadioStationRepository`. Station data is stored in SharedPreferences and converted to `AudioSource.uri` for playback. Web page URLs are not treated as stream URLs; the input is validated and tested with just_audio before saving.

Radio Browser search is isolated behind `RadioBrowserService`. The implementation uses the API's `url_resolved` and `lastcheckok` fields, maps responses into app models before exposing them to the UI, and sends an identifying User-Agent with each request.

Audio analysis is accessed through the `AudioAnalysisService` abstraction. Local tracks use `audio_decoder` to extract amplitude data, while SMB tracks and analysis failures use the playback-position fallback. The UI does not depend directly on the analysis engine. A real spectrum analyzer can be added as another implementation behind this service boundary.

Frequency-spectrum calculation is isolated in the pure-Dart `calculateSpectrum` domain function. It bounds each input frame to 2,048 samples and the output to 128 bands so Windows and Android PCM adapters can reuse it safely.

The Android `RealtimeSpectrumService` passes the Android AudioSession ID exposed by `just_audio` through a MethodChannel to the native `android.media.audiofx.Visualizer`, then publishes FFT callbacks to Flutter through an EventChannel. On macOS 14.2 or later, ScreenCaptureKit is filtered to this application process before in-memory PCM frames are sent through its EventChannel. If a native capture API cannot be started or permission is denied, the UI falls back to the regular visualizer.

The Windows `RealtimeSpectrumService` implementation uses Windows process loopback to capture only PCM rendered by this application and its child processes, then sends frames to Flutter through an EventChannel. It does not capture other applications or the complete system mix. Flutter feeds each frame into `calculateSpectrum`. Frames are processed only in memory and are never saved as recordings.

Playlists and playlist folders are persisted through the `PlaylistRepository` abstraction. SharedPreferences stores either a manual playlist's name and source paths or an auto playlist's name and match query, together with a `parentFolderId` and sibling `sortOrder`. Folders are stored in a separate JSON list with the same parent reference and ordering fields, forming a recursive tree. Manual playlists use the normalized-path index to resolve against the complete active-source cache, while auto playlists apply their saved query directly to the database. Neither depends on the library screen's current page or filters. `M3uPlaylistParser` converts UTF-8 M3U/M3U8 content, while `MusicBeePlaylistParser` converts binary MusicBee version 4 MBP content, into app path lists independently of file selection and UI state. Root mappings are offered only when candidate tracks exist in the current cache, and unresolved paths are retained for later recovery. Legacy persisted entries load as top-level manual playlists. Playlist data never copies the audio files.

MusicBrainz integration is accessed through `MusicBrainzService`. The API client maps JSON responses to `MusicBrainzRelease` models and applies an identifying User-Agent, a maximum request rate of one request per second, and an in-memory search-result cache.

SMB connectivity is accessed through the `SmbService` abstraction. Host, share, subfolder, and username are stored as settings, while the password is stored with `flutter_secure_storage`. The SMB scanner recursively walks the share, filters FLAC/MP3 files, and caches them in the library database as a separate operation from connection testing. SMB playback maps `StreamAudioSource` range requests to SMB partial reads, so the audio file is played without copying it into the app.

Disconnected shares, authentication failures, and missing files are recoverable errors and must not crash the UI or the whole service layer.

CD detection and ripping are Windows-specific. `DefaultWindowsCapabilities` gates the platform behavior; Android and macOS hide the CD import menu and show an explanatory page if the route is opened directly. Windows-only CD processing must not be mixed directly into shared domain code.

On macOS, local directory access is maintained through a security-scoped bookmark stored alongside the configured path. When the user explicitly selects a new folder in the picker, the new bookmark is saved before scanning; rescans validate the saved bookmark against the configured path. The Runner requests user-selected read/write and network-client Sandbox entitlements, while SMB credentials remain in the platform secure credential store.

CD output plans are created by `CdImportPlanner`. It validates the MusicBrainz release's total track count against the physical CD before mapping the selected subset, derives FLAC/MP3 filenames and tag candidates, and refuses existing target paths before any file is written. Drive reading and encoding are invoked through a Windows-specific service.

Windows CD drive detection is isolated behind `CdDriveService`. The Windows implementation queries drive letters, device names, and media-loaded state from PowerShell's `Win32_CDROMDrive`. Android and non-Windows environments report the capability as unavailable.

CD track listing is isolated behind `CdTrackService`; the Windows implementation obtains track count and lengths from the CD Audio MCI API. MCI and PowerShell execution remain in the Windows data layer, while shared code receives only `CdTrack` models.

Audio extraction is isolated behind `CdRippingService`. The Windows implementation invokes external `ffmpeg.exe` with the CD drive, track number, and FLAC/MP3 codec, while `-n` and a preflight existence check prevent overwrites. `CdRippingCancellationToken` can stop the active process. Missing ffmpeg and process failures are recoverable errors.

After a successful import, `CdDrivePage` rescans the configured local library when the output directory is inside that library. SMB sources and output directories outside the configured library are not changed automatically.
