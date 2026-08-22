import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/library_providers.dart';
import '../../app/playback_providers.dart';
import '../../app/playlist_providers.dart';
import '../../app/playlist_import_resolver.dart';
import '../../data/playback/library_playback_queue.dart';
import '../../data/playlist/m3u_playlist_parser.dart';
import '../../data/playlist/musicbee_auto_playlist_parser.dart';
import '../../data/playlist/musicbee_playlist_parser.dart';
import '../../domain/library/library_query.dart';
import '../../domain/library/library_path_normalizer.dart';
import '../../domain/library/library_track.dart';
import '../../domain/playlist/playlist.dart';
import 'auto_playlist_preview.dart';

part 'playlist_tree_widgets.dart';
part 'playlist_folder_dialogs.dart';
part 'playlist_card_widgets.dart';
part 'playlist_import_dialog.dart';
part 'playlist_editor_dialog.dart';
part 'automatic_playlist_editor_dialog.dart';

typedef PlaylistFilePicker = Future<List<XFile>> Function();

final playlistFilePickerProvider = Provider<PlaylistFilePicker>((ref) {
  return () => openFiles(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Playlist files',
        extensions: ['m3u', 'm3u8', 'mbp', 'xautopf'],
      ),
    ],
  );
});

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final folders = ref.watch(playlistFoldersProvider);
    final notifier = ref.read(playlistProvider.notifier);
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final playback = isCompact ? ref.watch(playbackServiceProvider) : null;
    final hasActivePlayback =
        playback?.snapshot.currentTrack != null ||
        playback?.snapshot.currentRadioStation != null;

    return Scaffold(
      appBar: AppBar(
        primary: !(isCompact && hasActivePlayback),
        title: const Text('Playlists'),
        actions: [
          IconButton(
            tooltip: 'Create folder',
            onPressed: () => _createFolder(context, notifier),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            tooltip: 'Import playlist files',
            onPressed: () => _importPlaylist(context, ref, notifier),
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            tooltip: 'Create auto playlist',
            onPressed: () => _createAutomaticPlaylist(context, ref, notifier),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Create playlist',
            onPressed: () => _createPlaylist(context, ref, notifier),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: playlists.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => folders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
            data: (folderItems) => items.isEmpty && folderItems.isEmpty
                ? Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.queue_music_outlined, size: 42),
                            const SizedBox(height: 12),
                            const Text(
                              'No playlists yet',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a folder, playlist, or import a playlist file.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _PlaylistTree(
                    playlists: items,
                    folders: folderItems,
                    onMovePlaylist: notifier.movePlaylist,
                    onEditPlaylist: (playlist) => playlist.isAutomatic
                        ? _editAutomaticPlaylist(
                            context,
                            ref,
                            notifier,
                            playlist,
                          )
                        : _editPlaylist(context, ref, notifier, playlist),
                    onDeletePlaylist: notifier.delete,
                    onCreateFolder: (parentId) =>
                        _createFolder(context, notifier, parentId: parentId),
                    onEditFolder: (folder) =>
                        _editFolder(context, notifier, folder, folderItems),
                    onDeleteFolder: (folder) =>
                        _deleteFolder(context, notifier, folder),
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlaylist(context, ref, notifier),
        icon: const Icon(Icons.playlist_add),
        label: const Text('New playlist'),
      ),
    );
  }

  Future<void> _createFolder(
    BuildContext context,
    PlaylistNotifier notifier, {
    String? parentId,
  }) async {
    final name = await _showFolderNameDialog(context, title: 'New folder');
    if (name != null) {
      await notifier.createFolder(name, parentFolderId: parentId);
    }
  }

  Future<void> _editFolder(
    BuildContext context,
    PlaylistNotifier notifier,
    PlaylistFolder folder,
    List<PlaylistFolder> folders,
  ) async {
    final result = await showDialog<_FolderEditorResult>(
      context: context,
      builder: (context) =>
          _FolderEditorDialog(folder: folder, folders: folders),
    );
    if (result != null) {
      await notifier.updateFolder(
        folder.id,
        result.name,
        parentFolderId: result.parentFolderId,
        moveToRoot: result.parentFolderId == null,
      );
    }
  }

  Future<void> _deleteFolder(
    BuildContext context,
    PlaylistNotifier notifier,
    PlaylistFolder folder,
  ) async {
    final deleted = await notifier.deleteFolder(folder.id);
    if (!context.mounted || deleted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Move or delete the folder contents before deleting it.'),
      ),
    );
  }

  Future<String?> _showFolderNameDialog(
    BuildContext context, {
    required String title,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _FolderNameDialog(title: title),
    );
  }

  Future<void> _createPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_PlaylistEditorResult>(
      context: context,
      builder: (context) => _PlaylistEditorDialog(
        tracks: tracks,
        title: 'New playlist',
        confirmLabel: 'Create',
      ),
    );
    if (result != null) {
      await notifier.create(result.name, result.tracks);
    }
  }

  Future<void> _createAutomaticPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_AutomaticPlaylistEditorResult>(
      context: context,
      builder: (context) => _AutomaticPlaylistEditorDialog(
        title: 'New auto playlist',
        confirmLabel: 'Create',
        tracks: tracks,
      ),
    );
    if (result != null) {
      await notifier.createAutomatic(result.name, result.query);
    }
  }

  Future<void> _editAutomaticPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
    Playlist playlist,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_AutomaticPlaylistEditorResult>(
      context: context,
      builder: (context) => _AutomaticPlaylistEditorDialog(
        title: 'Edit auto playlist',
        confirmLabel: 'Save',
        playlist: playlist,
        tracks: tracks,
      ),
    );
    if (result != null) {
      await notifier.updateAutomatic(playlist.id, result.name, result.query);
    }
  }

  Future<void> _importPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
  ) async {
    final files = await ref.read(playlistFilePickerProvider)();
    if (files.isEmpty) return;

    var importedPlaylists = 0;
    var importedTracks = 0;
    var availableTracks = 0;
    var skippedPlaylists = 0;
    final failures = <String>[];
    for (final file in files) {
      if (!context.mounted) return;
      try {
        final result = await _importPlaylistFile(context, ref, notifier, file);
        if (!context.mounted) return;
        if (result == null) {
          skippedPlaylists++;
        } else {
          importedPlaylists++;
          importedTracks += result.trackCount;
          availableTracks += result.availableCount;
        }
      } on Object catch (error) {
        failures.add('${p.basename(file.path)}: $error');
      }
    }

    if (!context.mounted) return;
    final details = <String>[
      '$importedPlaylists imported',
      if (skippedPlaylists > 0) '$skippedPlaylists skipped',
      if (failures.isNotEmpty) '${failures.length} failed',
    ].join(' · ');
    final shownFailures = failures.take(3).join(' | ');
    final remainingFailures = failures.length - 3;
    final failureDetails = failures.isEmpty
        ? ''
        : ' $shownFailures'
              '${remainingFailures > 0 ? ' | +$remainingFailures more' : ''}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$details ($importedTracks tracks, $availableTracks available).'
          '$failureDetails',
        ),
      ),
    );
  }

  Future<_PlaylistFileImportOutcome?> _importPlaylistFile(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
    XFile file,
  ) async {
    final bytes = await file.readAsBytes();
    final extension = p.extension(file.path).toLowerCase();
    if (extension == '.xautopf') {
      final imported = const MusicBeeAutoPlaylistParser().parseBytes(
        bytes,
        sourcePath: file.path,
      );
      final matches = (await _loadAllLibraryTracks(
        ref,
      )).where((track) => imported.rule.matches(artist: track.artist)).length;
      await notifier.createAutomatic(
        imported.name,
        imported.rule.value,
        autoRule: imported.rule,
      );
      return _PlaylistFileImportOutcome(
        trackCount: matches,
        availableCount: matches,
      );
    }
    final ({String name, List<String> trackPaths}) imported;
    if (extension == '.mbp') {
      final result = const MusicBeePlaylistParser().parseBytes(
        bytes,
        sourcePath: file.path,
      );
      imported = (name: result.name, trackPaths: result.trackPaths);
    } else {
      final result = const M3uPlaylistParser().parseBytes(
        bytes,
        sourcePath: file.path,
      );
      imported = (name: result.name, trackPaths: result.trackPaths);
    }
    if (imported.trackPaths.isEmpty) {
      throw const FormatException('The playlist contains no track paths.');
    }
    final preview = await ref
        .read(playlistImportResolverProvider)
        .resolve(name: imported.name, paths: imported.trackPaths);
    final folders = await ref.read(playlistRepositoryProvider).loadFolders();
    if (!context.mounted) return null;
    final confirmation = await showDialog<_PlaylistImportConfirmationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _PlaylistImportConfirmationDialog(preview: preview, folders: folders),
    );
    if (!context.mounted || confirmation == null) return null;
    final selectedMapping = confirmation.mapping;
    await notifier.importPlaylist(
      imported.name,
      preview.resolvedPaths(selectedMapping),
      parentFolderId: confirmation.parentFolderId,
    );
    return _PlaylistFileImportOutcome(
      trackCount: imported.trackPaths.length,
      availableCount: preview.availableCount(selectedMapping),
    );
  }

  Future<void> _editPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlaylistNotifier notifier,
    Playlist playlist,
  ) async {
    final tracks = await _loadAllLibraryTracks(ref);
    if (!context.mounted) return;
    final result = await showDialog<_PlaylistEditorResult>(
      context: context,
      builder: (context) => _PlaylistEditorDialog(
        tracks: tracks,
        playlist: playlist,
        title: 'Edit playlist',
        confirmLabel: 'Save',
      ),
    );
    if (result != null) {
      await notifier.updatePlaylist(playlist.id, result.name, result.tracks);
    }
  }

  Future<List<LibraryTrack>> _loadAllLibraryTracks(WidgetRef ref) async {
    final repository = ref.read(libraryRepositoryProvider);
    final sourceKey = await repository.loadSourcePath();
    final tracks = <LibraryTrack>[];
    LibraryCursor? cursor;
    do {
      final page = await repository.queryTracks(
        LibraryQuery(sourceKey: sourceKey, pageSize: 500, cursor: cursor),
      );
      tracks.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return List.unmodifiable(tracks);
  }
}
