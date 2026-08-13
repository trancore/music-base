import '../domain/library/library_path_normalizer.dart';
import '../domain/library/library_repository.dart';

class PlaylistRootMappingCandidate {
  const PlaylistRootMappingCandidate({
    required this.sourcePrefix,
    required this.targetRoot,
    required this.resolvedPaths,
  });

  final String sourcePrefix;
  final String targetRoot;
  final Map<int, String> resolvedPaths;

  int get resolvedCount => resolvedPaths.length;
}

class PlaylistImportPreview {
  const PlaylistImportPreview({
    required this.name,
    required this.originalPaths,
    required this.exactPaths,
    required this.mappingCandidates,
  });

  final String name;
  final List<String> originalPaths;
  final Map<int, String> exactPaths;
  final List<PlaylistRootMappingCandidate> mappingCandidates;

  List<String> resolvedPaths([PlaylistRootMappingCandidate? mapping]) => [
    for (var index = 0; index < originalPaths.length; index++)
      exactPaths[index] ??
          mapping?.resolvedPaths[index] ??
          originalPaths[index],
  ];

  int availableCount([PlaylistRootMappingCandidate? mapping]) =>
      {...exactPaths.keys, ...?mapping?.resolvedPaths.keys}.length;
}

class PlaylistImportResolver {
  const PlaylistImportResolver(this._repository);

  final LibraryRepository _repository;

  Future<PlaylistImportPreview> resolve({
    required String name,
    required List<String> paths,
  }) async {
    final exactTracks = await _repository.resolveTrackPaths(paths);
    final exactByPath = {
      for (final track in exactTracks)
        normalizeLibraryComparisonPath(track.sourcePath): track.sourcePath,
    };
    final exactPaths = <int, String>{};
    final unresolved = <int>[];
    for (var index = 0; index < paths.length; index++) {
      final resolved =
          exactByPath[normalizeLibraryComparisonPath(paths[index])];
      if (resolved == null) {
        unresolved.add(index);
      } else {
        exactPaths[index] = resolved;
      }
    }

    final targetRoot = await _repository.loadSourcePath();
    if (unresolved.isEmpty || targetRoot == null || targetRoot.trim().isEmpty) {
      return PlaylistImportPreview(
        name: name,
        originalPaths: List.unmodifiable(paths),
        exactPaths: Map.unmodifiable(exactPaths),
        mappingCandidates: const [],
      );
    }

    final prefixes = <String>{};
    for (final index in unresolved) {
      final path = paths[index].trim().replaceAll('\\', '/');
      for (var offset = 0; offset < path.length; offset++) {
        if (path.codeUnitAt(offset) == 0x2f && offset > 1) {
          prefixes.add(path.substring(0, offset));
        }
      }
    }

    final candidatePathByKey = <String, String>{};
    final candidateKeys = <String, Map<int, String>>{};
    for (final prefix in prefixes) {
      final pathsByIndex = <int, String>{};
      for (final index in unresolved) {
        final path = paths[index].trim().replaceAll('\\', '/');
        if (!_hasPathPrefix(path, prefix)) continue;
        final relative = path.substring(prefix.length).replaceFirst('/', '');
        if (relative.isEmpty) continue;
        final candidate = joinLibraryPath(targetRoot, relative);
        final key = normalizeLibraryComparisonPath(candidate);
        candidatePathByKey[key] = candidate;
        pathsByIndex[index] = key;
      }
      if (pathsByIndex.isNotEmpty) candidateKeys[prefix] = pathsByIndex;
    }

    final candidateTracks = await _repository.resolveTrackPaths(
      candidatePathByKey.values,
    );
    final resolvedCandidates = {
      for (final track in candidateTracks)
        normalizeLibraryComparisonPath(track.sourcePath): track.sourcePath,
    };
    final mappings = <PlaylistRootMappingCandidate>[];
    for (final entry in candidateKeys.entries) {
      final resolved = <int, String>{};
      for (final candidate in entry.value.entries) {
        final actualPath = resolvedCandidates[candidate.value];
        if (actualPath != null) resolved[candidate.key] = actualPath;
      }
      if (resolved.isNotEmpty) {
        mappings.add(
          PlaylistRootMappingCandidate(
            sourcePrefix: entry.key,
            targetRoot: targetRoot,
            resolvedPaths: Map.unmodifiable(resolved),
          ),
        );
      }
    }
    mappings.sort((left, right) {
      final count = right.resolvedCount.compareTo(left.resolvedCount);
      if (count != 0) return count;
      return left.sourcePrefix.length.compareTo(right.sourcePrefix.length);
    });

    return PlaylistImportPreview(
      name: name,
      originalPaths: List.unmodifiable(paths),
      exactPaths: Map.unmodifiable(exactPaths),
      mappingCandidates: List.unmodifiable(mappings.take(5)),
    );
  }
}

bool _hasPathPrefix(String path, String prefix) {
  final windows = RegExp(r'^[a-zA-Z]:/').hasMatch(path);
  final comparablePath = windows ? path.toLowerCase() : path;
  final comparablePrefix = windows ? prefix.toLowerCase() : prefix;
  return comparablePath.startsWith('$comparablePrefix/');
}
