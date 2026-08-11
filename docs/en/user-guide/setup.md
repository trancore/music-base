# Setup

## Music library location

Configure the music library with a local directory or an SMB share provided by the user or administrator. The exact path depends on the environment.

```text
Local directory example: `D:\Music`
SMB share example: `\\<server>\<share>\[subfolder]`
```

You can change the location in Settings. In the local library section, choose a directory, or enter the SMB host, share, and optional subfolder. For an SMB source, enter the username and password and choose **Test connection and save**. Remove the saved source and password with **Clear saved SMB settings**. The home screen also provides local directory selection and rescanning.

## Credentials

If the SMB share requires authentication, enter the SMB username and password. The password is stored in the platform secure credential store and is never written to logs or source code. If the connection test fails, check the host, share, credentials, and network connection.

## macOS

The macOS runner supports local and SMB libraries, playback, playlists, metadata, and the visualizer. macOS 14.2 or later is required. The first local-folder selection grants access to that folder; the app stores a security-scoped bookmark so the folder can be rescanned after restarting. Network access and audio-capture permission are required for SMB playback and the real-time spectrum.

CD ripping is not available on macOS.

## Android

The Android runner is now included and uses the same Flutter application shell. The current SMB feature provides connection testing, settings storage, library scanning, and direct playback from SMB. CD ripping remains a Windows-only feature.
