# Music library

Select a local music directory from Settings and the app scans it recursively. FLAC and MP3 files are currently included, and the file name is used as the track title until metadata parsing is added.

The paths and basic track information are cached in the local database. The selected library location remains the source of truth; audio files are never copied into the database.

The library search field on the home screen matches cached tracks by title, artist, album, or source path case-insensitively and updates while typing.

If the selected location is unavailable or scanning fails, the app shows a recoverable error so it can be retried. After an SMB share has been tested, you can scan it from the home screen. SMB tracks can be played directly through range reads.

Cached information can be shown while the library location is unavailable, but playback requires access to the selected location.
