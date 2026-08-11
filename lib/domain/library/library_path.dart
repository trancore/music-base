import 'dart:io';

import 'package:path/path.dart' as p;

bool isPathWithinLibrary(String libraryPath, String candidatePath) {
  final normalizedLibrary = p.normalize(libraryPath);
  final normalizedCandidate = p.normalize(candidatePath);
  final libraryForComparison = Platform.isWindows
      ? normalizedLibrary.toLowerCase()
      : normalizedLibrary;
  final candidateForComparison = Platform.isWindows
      ? normalizedCandidate.toLowerCase()
      : normalizedCandidate;

  return candidateForComparison == libraryForComparison ||
      candidateForComparison.startsWith('$libraryForComparison${p.separator}');
}
