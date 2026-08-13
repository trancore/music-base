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
  });

  final Uint8List? bytes;
  final double size;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
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
          : Image.memory(image, width: size, height: size, fit: BoxFit.cover),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
}
