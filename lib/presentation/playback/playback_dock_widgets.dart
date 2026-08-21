part of 'playback_dock.dart';

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.snapshot, required this.playback});

  final PlaybackSnapshot snapshot;
  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
    final canSeek =
        snapshot.currentTrack != null && snapshot.duration.inMilliseconds > 0;
    final max = snapshot.duration.inMilliseconds.toDouble();
    final value = snapshot.position.inMilliseconds
        .clamp(0, snapshot.duration.inMilliseconds)
        .toDouble();
    return Column(
      children: [
        Slider(
          value: canSeek ? value : 0,
          max: canSeek ? max : 1,
          onChanged: canSeek
              ? (next) => playback.seek(Duration(milliseconds: next.round()))
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(snapshot.position)),
            Text(_formatDuration(snapshot.duration)),
          ],
        ),
      ],
    );
  }
}

class _ArtworkTile extends StatelessWidget {
  const _ArtworkTile({
    required this.bytes,
    required this.size,
    required this.fallback,
    this.borderRadius,
  });

  final Uint8List? bytes;
  final double size;
  final IconData fallback;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    final radius = borderRadius ?? size * 0.22;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image == null
          ? Container(
              width: size,
              height: size,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                fallback,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            )
          : RepaintBoundary(
              child: Image.memory(
                image,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
    );
  }
}

class _PlaybackArtworkTile extends ConsumerWidget {
  const _PlaybackArtworkTile({
    required this.track,
    required this.size,
    required this.fallback,
    this.borderRadius,
    this.showIndexFallback,
  });

  final LibraryTrack? track;
  final double size;
  final IconData fallback;
  final double? borderRadius;
  final int? showIndexFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = track;
    if (current == null) {
      return _ArtworkTile(
        bytes: null,
        size: size,
        fallback: fallback,
        borderRadius: borderRadius,
      );
    }

    final legacy = current.artwork;
    if (current.cacheId == null) {
      return _buildTile(context, legacy);
    }

    final artwork = ref.watch(libraryArtworkProvider(current.cacheId!));
    return artwork.when(
      skipLoadingOnReload: true,
      loading: () => _buildTile(context, legacy),
      error: (_, _) => _buildTile(context, legacy),
      data: (bytes) => _buildTile(
        context,
        bytes == null || bytes.isEmpty ? legacy : Uint8List.fromList(bytes),
      ),
    );
  }

  Widget _buildTile(BuildContext context, Uint8List? bytes) {
    if (bytes == null && showIndexFallback != null) {
      return CircleAvatar(child: Text('$showIndexFallback'));
    }
    return _ArtworkTile(
      bytes: bytes,
      size: size,
      fallback: fallback,
      borderRadius: borderRadius,
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
}
