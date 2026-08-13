part of 'cd_drive_page.dart';

class _CdRipTarget {
  const _CdRipTarget({
    required this.track,
    required this.outputPath,
    this.title,
    this.artist,
    this.album,
    this.releaseDate,
  });

  final CdTrack track;
  final String outputPath;
  final String? title;
  final String? artist;
  final String? album;
  final String? releaseDate;
}

class _CdDriveCard extends StatelessWidget {
  const _CdDriveCard(
    this.drive, {
    required this.selected,
    required this.tracksFuture,
    required this.selectedTracks,
    required this.onSelectDrive,
    required this.onToggleTrack,
  });

  final CdDrive drive;
  final bool selected;
  final Future<List<CdTrack>>? tracksFuture;
  final Set<int> selectedTracks;
  final VoidCallback onSelectDrive;
  final void Function(CdTrack track, bool checked) onToggleTrack;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(drive.mediaLoaded ? Icons.album : Icons.album_outlined),
        title: Text('${drive.driveLetter} ${drive.name}'),
        subtitle: Text(drive.mediaLoaded ? 'Media loaded' : 'No media loaded'),
        trailing: drive.mediaLoaded
            ? OutlinedButton(
                onPressed: onSelectDrive,
                child: Text(selected ? 'Selected' : 'Select'),
              )
            : null,
        children: [
          if (tracksFuture != null)
            FutureBuilder<List<CdTrack>>(
              future: tracksFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text('Unable to read tracks: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.data!.isEmpty) {
                  return const ListTile(title: Text('No tracks found.'));
                }
                return Column(
                  children: [
                    for (final track in snapshot.data!)
                      CheckboxListTile(
                        value: selectedTracks.contains(track.number),
                        onChanged: (checked) {
                          if (checked != null) onToggleTrack(track, checked);
                        },
                        secondary: Text('${track.number}'),
                        title: Text(
                          track.duration == null
                              ? 'Track ${track.number}'
                              : 'Track ${track.number} · ${_formatTrackDuration(track.duration!)}',
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

String _formatTrackDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
