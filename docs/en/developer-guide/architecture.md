# Architecture

Keep UI, state management, domain logic, data access, and platform-specific code separated.

Local file access, SMB access, audio playback, MusicBrainz integration, tag handling, CD ripping, and audio analysis should have independent service boundaries. Audio files in the selected local directory or SMB share are the source of truth; the local database caches library information.

CD detection and ripping are Windows-specific. Android provides local directory or SMB library access and playback.
