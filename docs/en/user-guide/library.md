# Music library

Select a local music directory from Settings and the app scans it recursively. FLAC and MP3 files are currently included. Embedded MP3 ID3 and FLAC Vorbis metadata is preferred when available. For files without readable tags, common `Artist/Album/01 - Title.flac` layouts are used to infer the artist, album, and title; other files use the filename as the title.

The paths and basic track information are cached in the local database. The selected library location remains the source of truth; audio files are never copied into the database.

Use the **Search library** field on the home screen to filter the cached tracks by title, artist, album, or file path. Search is case-insensitive and applies immediately while typing. The track list is a table: click the Title, Artist, Album, or Source header to toggle ascending and descending order. Double-click a track to play it.

The library heading, search field, and table header stay fixed while browsing. When there are many tracks, only the track rows scroll inside the table.

When artist or album information can be inferred, it is shown in the library table. The source path remains visible as a secondary field. The artwork column keeps a fixed width when artwork is unavailable.

Embedded album artwork up to 2 MB is cached with the library entry and shown as a thumbnail. Larger or unreadable artwork is skipped.

If the selected location is unavailable or scanning fails, the app shows an error with a **Retry** button. After checking the source, retry the scan from the home screen. After an SMB share has been tested and saved in Settings, you can scan it from the Library screen. SMB tracks can be played directly through range reads.

Cached information can be shown while the library location is unavailable, but playback requires access to the selected location.
