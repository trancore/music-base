# Playback and display

Select a FLAC or MP3 file from the library to play it. In addition to local files, tracks on the configured SMB share can be played directly. The current implementation supports play, pause, stop, seeking, previous/next track, volume control, and mute.

Internet radio stations play from the direct audio stream URLs saved on the Radio screen. Live streams have no total duration, so the playback dock shows elapsed time since playback started. Seeking, track navigation, and shuffle are unavailable while a radio station is playing.

Use “Play library” to add the whole library to the playback queue. Double-click a track to start playback. The playback dock stays fixed at the top of the screen and remains available across routes. The queue supports previous/next navigation, shuffle, and repeat. The top level of the Playlists screen can contain both folders and playlists. Folders can be created, renamed, moved, nested to any depth, and deleted when empty. Drag a playlist to reorder it within a level or move it into another folder or back to the top level. Expand a playlist to view its tracks; multiple playlists can remain expanded. A regular playlist lets you filter the library by title, artist, album, or source path, select tracks, and reorder them. An auto playlist saves matching text for the same fields and displays the tracks that match the current library. Its editor previews the matching count and tracks while the condition is changed. Results update when the library is rescanned.

Choose “Import playlist files” to read UTF-8 `.m3u`/`.m3u8` files or MusicBee version 4 binary `.mbp` playlists. You can select multiple files at once; the app asks you to confirm each file and its destination in sequence. Skipping or failing one file does not stop the remaining files. You can choose the top level or an existing folder as each destination. Extended M3U files containing `#EXTM3U` and `#EXTINF`, absolute paths, and paths relative to the playlist file are supported. For MBP files, the app reads the stored absolute paths and track order. Before importing, the app shows exact matches and unavailable tracks. If the playlist source root differs from the current library, you can select a root mapping that has been verified against tracks in the library cache. Imported order is preserved, and unavailable paths remain in the playlist so they can recover after switching or rescanning the source. The filename becomes the initial playlist name. Importing does not move or modify audio files.

Playback errors are shown in the UI so another track can be selected without closing the app. The playback dock displays a real-time spectrum on supported platforms and waveform data from local audio files elsewhere. SMB tracks and files that cannot be analyzed use a playback-position fallback.

On Android, the real-time spectrum uses the playback session. Windows uses process loopback for this application, and macOS 14.2 or later filters audio capture to this application. Audio from other applications or the complete system mix is not analyzed. If capture permission is denied or a platform capture API is unavailable, the app falls back to waveform or playback-position visualization.

On desktop, the playback queue is shown at the bottom of the sidebar while tracks are queued. Select a track in the list to start playback from that position.

On Android, playback continues in the background and exposes play/pause, previous, and next controls through the media notification and lock screen. The Android app must be started once before those controls are available.

## Waveform / spectrum visualizer

During playback, the visualizer displays logarithmically spaced frequency bands. On desktop, it applies a Hann window to a 2048-sample FFT, maps 20 Hz–20 kHz into 128 bands, converts magnitudes to dB, and smooths the result over time. Android FFT data is converted to the same display shape. If analysis or live capture is unavailable, it falls back to a playback-position and animation-based display. Processing stays in memory and does not create recording files.

On desktop, the playback queue appears at the bottom of the sidebar. Select a queued track to start playback from that track. On mobile, playback is centered around the playback dock.

Search by track title, artist, album, or source path before selecting a track to play.

Playback errors are shown in the UI so another track can be selected without closing the app.
