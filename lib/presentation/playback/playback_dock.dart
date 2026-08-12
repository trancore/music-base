import 'package:flutter/material.dart';

import '../../domain/playback/audio_analysis_service.dart';
import '../../domain/playback/playback_service.dart';
import '../../domain/playback/realtime_spectrum_service.dart';
import 'playback_visualizer.dart';

class PlaybackDock extends StatelessWidget {
  const PlaybackDock({
    required this.playback,
    required this.audioAnalysis,
    required this.realtimeSpectrum,
    required this.compact,
    super.key,
  });

  final PlaybackService playback;
  final AudioAnalysisService audioAnalysis;
  final RealtimeSpectrumService realtimeSpectrum;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final snapshot = playback.snapshot;
    final track = snapshot.currentTrack;
    if (track == null) return const SizedBox.shrink();
    final duration = snapshot.duration;
    final position = snapshot.position > duration
        ? duration
        : snapshot.position;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 24,
          10,
          compact ? 12 : 24,
          compact ? 8 : 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      track.title ?? track.sourcePath,
                      if (track.artist case final artist?
                          when artist.trim().isNotEmpty)
                        artist,
                    ].join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (!compact) ...[
                  IconButton(
                    tooltip: 'Previous',
                    onPressed: playback.skipPrevious,
                    icon: const Icon(Icons.skip_previous),
                  ),
                  IconButton(
                    tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                    onPressed: snapshot.isPlaying
                        ? playback.pause
                        : playback.resume,
                    icon: Icon(
                      snapshot.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next',
                    onPressed: playback.skipNext,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Waveform / spectrum visualizer',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            PlaybackVisualizer(
              snapshot: snapshot,
              audioAnalysis: audioAnalysis,
              realtimeSpectrum: realtimeSpectrum,
            ),
            Slider(
              value: duration.inMilliseconds == 0
                  ? 0
                  : position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds == 0
                  ? 1
                  : duration.inMilliseconds.toDouble(),
              onChanged: duration.inMilliseconds == 0
                  ? null
                  : (value) =>
                        playback.seek(Duration(milliseconds: value.round())),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous',
                  onPressed: playback.skipPrevious,
                  icon: const Icon(Icons.skip_previous),
                ),
                Text(
                  _formatDuration(position),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (compact)
                  IconButton(
                    tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                    onPressed: snapshot.isPlaying
                        ? playback.pause
                        : playback.resume,
                    icon: Icon(
                      snapshot.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                IconButton(
                  tooltip: 'Stop',
                  onPressed: playback.stop,
                  icon: const Icon(Icons.stop),
                ),
                IconButton(
                  tooltip: 'Next',
                  onPressed: playback.skipNext,
                  icon: const Icon(Icons.skip_next),
                ),
                IconButton(
                  tooltip: 'Shuffle',
                  onPressed: playback.toggleShuffle,
                  color: snapshot.shuffleEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  icon: const Icon(Icons.shuffle),
                ),
                IconButton(
                  tooltip: 'Repeat',
                  onPressed: playback.toggleRepeat,
                  color: snapshot.repeatEnabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  icon: const Icon(Icons.repeat),
                ),
                IconButton(
                  tooltip: snapshot.isMuted ? 'Unmute' : 'Mute',
                  onPressed: playback.toggleMute,
                  icon: Icon(
                    snapshot.isMuted ? Icons.volume_off : Icons.volume_up,
                  ),
                ),
                SizedBox(
                  width: compact ? 80 : 160,
                  child: Slider(
                    value: snapshot.volume,
                    onChanged: snapshot.isMuted ? null : playback.setVolume,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
}
