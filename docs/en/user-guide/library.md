# Music library

Select a local music directory from Settings and the app scans it recursively. FLAC, MP3, OGG, 3GP, and MP4 files are currently included. Embedded tags are preferred when available through `audio_metadata_reader`. For files without readable tags, common `Artist/Album/01 - Title.flac` layouts are used to infer the artist, album, and title; other files use the filename as the title.

The paths and basic track information are cached in the local database. The selected library location remains the source of truth; audio files are never copied into the database.

The saved cache is displayed immediately at startup and refreshed incrementally in the background. Libraries of up to 100,000 tracks are loaded in pages of 200 as you scroll. Search uses AND-combined word-prefix matching. Artwork is deduplicated in storage and loaded only for visible tracks.

Manual rescans started from Settings also run in the background while the current cache remains visible. Search, browsing, and selection of cached tracks stay available during scanning. A successful scan refreshes the list and artwork; a failed scan keeps the previous cache and reports the error.

If the SMB source cannot be refreshed, the most recently selected local source is used for that app session. If neither source is available, the library shows “Library not found.” The primary SMB source is tried again at the next startup.

Use the **Search library** field on the home screen to filter the cached tracks by title, artist, album, or file path. Search is case-insensitive and applies immediately while typing. The track list is a table: click the Title, Artist, Album, or Source header to toggle ascending and descending order. Double-click a track to play it.

Use **Songs**, **Albums**, and **Artists** at the top of the home screen to change the browsing unit. Albums and artists can be shown as cards or a list; use the view toggle on the right to switch between them. Selecting an item opens its tracks with paged loading. The play button plays every track in that album or artist. The search field filters tracks, album names, or artist names according to the active view.

The library heading, search field, and table header stay fixed while browsing. When there are many tracks, only the track rows scroll inside the table.

When artist or album information can be inferred, it is shown in the library table. The source path remains visible as a secondary field. The artwork column keeps a fixed width when artwork is unavailable.

Embedded album artwork up to 2 MB is cached with the library entry and shown as a thumbnail. Larger or unreadable artwork is skipped.

For local and SMB FLAC files, the app reads embedded artwork together with disc and track numbers. SMB scanning range-reads only the FLAC metadata blocks instead of copying the complete audio file. When embedded artwork is unavailable, `cover.jpg`, `cover.jpeg`, `cover.png`, or `folder.jpg` in the same folder is used. Tracks inside an album are displayed and played by disc number, track number, then source path; tracks without numbers appear after numbered tracks.

The first column of the track list shows the track number. Tracks on the second and later discs use a disc-track label such as `2-7`. Rescan results are applied to the cache only after the complete traversal succeeds, so the previous cache remains available during scanning and after connection failures.

If the selected location is unavailable or scanning fails, the app shows an error with a **Retry** button. After checking the source, retry the scan from the home screen. After an SMB share has been tested and saved in Settings, you can scan it from the Library screen. SMB tracks can be played directly through range reads.

Cached information can be shown while the library location is unavailable, but playback requires access to the selected location.
