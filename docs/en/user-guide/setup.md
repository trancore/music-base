# Setup

## Music library location

Configure the music library with a local directory or an SMB share provided by the user or administrator. The exact path depends on the environment.

```text
Local directory example: `D:\Music`
SMB share example: `\\<server>\<share>\[subfolder]`
```

You can change the location in Settings. Select a local directory, or enter the SMB host, share, and optional subfolder. For an SMB source, enter the username and password and choose **Test connection and save**.

## Credentials

If the SMB share requires authentication, enter the SMB username and password. The password is stored in the platform secure credential store and is never written to logs or source code. If the connection test fails, check the host, share, credentials, and network connection.

## Android

The Android runner is now included and uses the same Flutter application shell. The current SMB feature provides connection testing, settings storage, library scanning, and direct playback from SMB. CD ripping remains a Windows-only feature.
