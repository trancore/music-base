import 'package:flutter/material.dart';

import '../../domain/library/library_search.dart';
import '../../domain/library/library_track.dart';

class AutoPlaylistPreview extends StatelessWidget {
  const AutoPlaylistPreview({
    required this.tracks,
    required this.query,
    super.key,
  });

  final List<LibraryTrack> tracks;
  final String query;

  @override
  Widget build(BuildContext context) {
    final previewTracks = query.trim().isEmpty
        ? const <LibraryTrack>[]
        : filterLibraryTracks(tracks, query);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Preview (${previewTracks.length} matches)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: const Key('auto-playlist-preview'),
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: previewTracks.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No tracks match this condition.'),
                  ),
                )
              : ListView.builder(
                  itemCount: previewTracks.length,
                  itemBuilder: (context, index) {
                    final track = previewTracks[index];
                    final details = [
                      track.artist,
                      track.album,
                    ].whereType<String>().where((value) => value.isNotEmpty);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.music_note_outlined),
                      title: Text(
                        track.title ?? track.sourcePath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: details.isEmpty
                          ? null
                          : Text(
                              details.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
