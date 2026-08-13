# Playback and display

Select a FLAC or MP3 file from the library to play it. In addition to local files, tracks on the configured SMB share can be played directly. The current implementation supports play, pause, stop, seeking, previous/next track, volume control, and mute.

Internet radio stations play from the direct audio stream URLs saved on the Radio screen. Live streams have no total duration, so the playback dock shows elapsed time since playback started. Seeking, track navigation, and shuffle are unavailable while a radio station is playing.

Use “Play library” to add the whole library to the playback queue. Double-click a track to start playback. The playback dock stays fixed at the top of the screen and remains available across routes. The queue supports previous/next navigation, shuffle, and repeat. On the Playlists screen, expand each playlist to view its tracks. Multiple playlists can be expanded at the same time. A regular playlist lets you filter the library by title, artist, album, or source path, select tracks, and reorder them. An auto playlist saves matching text for the same fields and displays the tracks that match the current library. Its editor previews the matching count and tracks while the condition is changed. Results update when the library is rescanned.

Choose “Import M3U playlist” to read a UTF-8 `.m3u` or `.m3u8` file. Extended M3U files containing `#EXTM3U` and `#EXTINF`, absolute paths, and paths relative to the playlist file are supported. Imported order is preserved, paths not found in the current library are counted as unavailable, and the filename becomes the initial playlist name. Importing does not move or modify audio files.

Playback errors are shown in the UI so another track can be selected without closing the app. The playback dock displays a real-time spectrum on supported platforms and waveform data from local audio files elsewhere. SMB tracks and files that cannot be analyzed use a playback-position fallback.

On Android, a real-time spectrum view can use FFT data captured from the playback session. On Windows, the app analyzes PCM data captured from the system output through WASAPI loopback. On macOS 14.2 or later, the app uses macOS system-audio capture and sends PCM frames to the same FFT analyzer. If capture permission is denied or a platform capture API is unavailable, it falls back to waveform or playback-position visualization.

On desktop, the playback queue is shown at the bottom of the sidebar while tracks are queued. Select a track in the list to start playback from that position.

On Android, playback continues in the background and exposes play/pause, previous, and next controls through the media notification and lock screen. The Android app must be started once before those controls are available.

## Waveform / spectrum visualizer

During playback, the visualizer displays logarithmically spaced frequency bands. On desktop, it applies a Hann window to a 2048-sample FFT, maps 20 Hz–20 kHz into 128 bands, converts magnitudes to dB, and smooths the result over time. Android FFT data is converted to the same display shape. If analysis or live capture is unavailable, it falls back to a playback-position and animation-based display. Processing stays in memory and does not create recording files.

On desktop, the playback queue appears at the bottom of the sidebar. Select a queued track to start playback from that track. On mobile, playback is centered around the playback dock.

Search by track title, artist, album, or source path before selecting a track to play.

Playback errors are shown in the UI so another track can be selected without closing the app.
