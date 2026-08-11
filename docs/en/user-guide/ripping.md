# CD ripping

CD ripping is available only on Windows. The Windows app can rip CD tracks to either FLAC or MP3 and save them to the configured music library. The Android app does not show the CD import menu.

MusicBrainz is used to find album candidates. Review track names, artist, album, release year, and track order before importing. If no match is found, edit the metadata manually.

The import plan lets you review FLAC or MP3, the destination, track order, and tag candidates. You can select the entire album or only some tracks. Selecting a MusicBrainz release saves the matching track title, artist, album, and release date as tags. If existing files are found, the import stops before starting and lists them; files are never overwritten. CD drive detection and actual encoding are Windows-specific features.

The CD import screen shows CD drives detected by Windows and whether media is loaded. While the screen is open, it polls periodically and reports CD insertion or removal. When media is loaded, you can select a drive and tracks, choose an output directory and FLAC or MP3, then start the import. Multiple tracks are processed sequentially with progress and cancellation support. If the destination is inside the configured local library, the library is rescanned automatically after a successful import.

Import execution requires `ffmpeg.exe` on Windows. Tracks are converted to FLAC or MP3, and an existing destination file is never overwritten. Progress is shown while importing; cancelling stops the active ffmpeg process and prevents the next track from starting. Without a selected MusicBrainz release, imports use names such as `Track 01.flac` or `Track 01.mp3`.
