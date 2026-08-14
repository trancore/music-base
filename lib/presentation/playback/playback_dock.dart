import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/library_providers.dart';
import '../../domain/playback/audio_analysis_service.dart';
import '../../domain/playback/playback_service.dart';
import '../../domain/playback/realtime_spectrum_service.dart';
import '../../domain/library/library_track.dart';
import 'playback_visualizer.dart';

part 'mobile_playback_dock.dart';
part 'playback_dock_widgets.dart';

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
    final station = snapshot.currentRadioStation;
    if (track == null && station == null) return const SizedBox.shrink();
    final isRadio = station != null;
    final duration = snapshot.duration;
    final position = isRadio || snapshot.position <= duration
        ? snapshot.position
        : duration;

    if (compact) {
      return _CompactPlaybackDock(
        playback: playback,
        title: isRadio ? station.name : track!.title ?? track.sourcePath,
        subtitle: isRadio
            ? 'Internet radio'
            : track?.artist ?? track?.album ?? 'Now playing',
        track: isRadio ? null : track,
        errorMessage: snapshot.errorMessage,
        isPlaying: snapshot.isPlaying,
        isRadio: isRadio,
        audioAnalysis: audioAnalysis,
        realtimeSpectrum: realtimeSpectrum,
      );
    }

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
          6,
          compact ? 12 : 24,
          compact ? 6 : 8,
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact
                            ? MediaQuery.sizeOf(context).width * 0.38
                            : double.infinity,
                      ),
                      child: Text(
                        isRadio
                            ? station.name
                            : [
                                track!.title ?? track.sourcePath,
                                if (track.artist case final artist?
                                    when artist.trim().isNotEmpty)
                                  artist,
                              ].join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                if (!compact && !isRadio) ...[
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
                if (!compact && isRadio)
                  IconButton(
                    tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                    onPressed: snapshot.isPlaying
                        ? playback.pause
                        : playback.resume,
                    icon: Icon(
                      snapshot.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (snapshot.errorMessage case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  error,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            if (!isRadio) ...[
              Text(
                'Waveform / spectrum visualizer',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              PlaybackVisualizer(
                snapshot: snapshot,
                audioAnalysis: audioAnalysis,
                realtimeSpectrum: realtimeSpectrum,
                height: 112,
              ),
              SizedBox(
                height: 34,
                child: Slider(
                  value: duration.inMilliseconds == 0
                      ? 0
                      : position.inMilliseconds.toDouble(),
                  max: duration.inMilliseconds == 0
                      ? 1
                      : duration.inMilliseconds.toDouble(),
                  onChanged: duration.inMilliseconds == 0
                      ? null
                      : (value) => playback.seek(
                          Duration(milliseconds: value.round()),
                        ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  station.description ?? 'Live internet radio',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Row(
              children: [
                if (!isRadio)
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
                if (!isRadio)
                  IconButton(
                    tooltip: 'Next',
                    onPressed: playback.skipNext,
                    icon: const Icon(Icons.skip_next),
                  ),
                if (!isRadio)
                  IconButton(
                    tooltip: 'Shuffle',
                    onPressed: playback.toggleShuffle,
                    color: snapshot.shuffleEnabled
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    icon: const Icon(Icons.shuffle),
                  ),
                if (!isRadio)
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
                  width: compact ? 112 : 168,
                  height: 48,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: snapshot.volume,
                      onChanged: snapshot.isMuted ? null : playback.setVolume,
                    ),
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
