# Setup

Select **User guide** under **Help** on the Settings screen to open this documentation in the default browser. An internet connection is required.

## Language

Choose **Language** under **Appearance** in Settings. **System** follows the operating system language; **English** and **日本語** select a language explicitly. Short navigation labels and product-oriented headings such as **Library**, **Playlists**, and **Settings** remain in English for a consistent interface.

## Music library location

Configure the music library with a local directory or an SMB share provided by the user or administrator. The exact path depends on the environment.

```text
Local directory example: `D:\Music`
SMB share example: `\\<server>\<share>\[subfolder]`
```

Change the location from Settings. In the local library section, choose a directory, or enter the SMB host, share, and optional subfolder. For an SMB source, enter the username and password and choose **Connect, save, and scan**. After the connection test and save succeed, the app immediately scans the share for supported audio files (FLAC, MP3, OGG, 3GP, and MP4). To rescan an existing SMB source, choose **Scan library**. Remove the saved source and password with **Clear saved SMB settings**.

## Credentials

If the SMB share requires authentication, enter the SMB username and password. The password is stored in the platform secure credential store and is never written to logs or source code. After “Test connection and save” succeeds, the app saves the settings and automatically scans the configured subfolder. If the connection test fails, check the host, share, credentials, and network connection.

## macOS

The macOS runner supports local and SMB libraries, playback, playlists, metadata, and the visualizer. macOS 14.2 or later is required. The first local-folder selection grants access to that folder; the app stores a security-scoped bookmark so the folder can be rescanned after restarting. Network access is required for SMB playback. If macOS asks for local-network access on the first connection, allow it. If it was denied, allow Music Base under System Settings → Privacy & Security → Local Network. Audio-capture permission is required for the real-time spectrum.

CD ripping is not available on macOS.

## Android

The Android runner is now included and uses the same Flutter application shell. The current SMB feature provides connection testing, settings storage, library scanning, and direct playback from SMB. CD ripping remains a Windows-only feature.
