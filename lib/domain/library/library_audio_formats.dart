import 'package:path/path.dart' as p;

/// File extensions indexed by the local and SMB library scanners.
const kSupportedLibraryExtensions = {'.flac', '.mp3', '.ogg', '.3gp', '.mp4'};

/// Short user-facing list of supported formats.
const kSupportedLibraryFormatsDescription = 'FLAC, MP3, OGG, 3GP, and MP4';

/// User-facing list of supported file extensions.
const kSupportedLibraryExtensionsDescription =
    '.flac, .mp3, .ogg, .3gp, and .mp4';

bool isSupportedLibraryExtension(String path) =>
    kSupportedLibraryExtensions.contains(p.extension(path).toLowerCase());
