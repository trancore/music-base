import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/playback/audio_analysis_service.dart';
import '../../domain/playback/playback_service.dart';
import '../../domain/playback/realtime_spectrum_service.dart';
import '../../domain/library/library_track.dart';
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
        artwork: track?.artwork,
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

class _CompactPlaybackDock extends StatelessWidget {
  const _CompactPlaybackDock({
    required this.playback,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.isPlaying,
    required this.isRadio,
    required this.audioAnalysis,
    required this.realtimeSpectrum,
  });

  final PlaybackService playback;
  final String title;
  final String subtitle;
  final Uint8List? artwork;
  final bool isPlaying;
  final bool isRadio;
  final AudioAnalysisService audioAnalysis;
  final RealtimeSpectrumService realtimeSpectrum;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _MobileNowPlayingSheet(
            playback: playback,
            audioAnalysis: audioAnalysis,
            realtimeSpectrum: realtimeSpectrum,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                _ArtworkTile(
                  bytes: artwork,
                  size: 40,
                  fallback: isRadio ? Icons.radio : Icons.music_note,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: isPlaying ? playback.pause : playback.resume,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: 'Stop',
                  onPressed: playback.stop,
                  icon: const Icon(Icons.stop_outlined),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNowPlayingSheet extends StatelessWidget {
  const _MobileNowPlayingSheet({
    required this.playback,
    required this.audioAnalysis,
    required this.realtimeSpectrum,
  });

  final PlaybackService playback;
  final AudioAnalysisService audioAnalysis;
  final RealtimeSpectrumService realtimeSpectrum;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: playback,
      builder: (context, _) {
        final snapshot = playback.snapshot;
        final station = snapshot.currentRadioStation;
        final track = snapshot.currentTrack;
        final title = station?.name ?? track?.title ?? track?.sourcePath ?? '';
        final subtitle = station != null
            ? 'Internet radio'
            : track?.artist ?? track?.album ?? 'Now playing';
        final artworkSize = (MediaQuery.sizeOf(context).height * 0.27)
            .clamp(140.0, 220.0)
            .toDouble();
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ArtworkTile(
                  bytes: track?.artwork,
                  size: artworkSize,
                  fallback: station == null ? Icons.music_note : Icons.radio,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                if (track != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PlaybackVisualizer(
                      snapshot: snapshot,
                      audioAnalysis: audioAnalysis,
                      realtimeSpectrum: realtimeSpectrum,
                      height: 112,
                    ),
                  ),
                _SeekBar(snapshot: snapshot, playback: playback),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                      onPressed: snapshot.isPlaying
                          ? playback.pause
                          : playback.resume,
                      icon: Icon(
                        snapshot.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      tooltip: 'Stop',
                      onPressed: playback.stop,
                      icon: const Icon(Icons.stop),
                    ),
                    IconButton(
                      tooltip: snapshot.isMuted ? 'Unmute' : 'Mute',
                      onPressed: playback.toggleMute,
                      icon: Icon(
                        snapshot.isMuted ? Icons.volume_off : Icons.volume_up,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      snapshot.isMuted ? Icons.volume_off : Icons.volume_down,
                      size: 18,
                    ),
                    Expanded(
                      child: Slider(
                        value: snapshot.volume,
                        onChanged: snapshot.isMuted ? null : playback.setVolume,
                      ),
                    ),
                    const Icon(Icons.volume_up, size: 18),
                  ],
                ),
                if (snapshot.queue.length > 1)
                  _MobileQueue(snapshot: snapshot, playback: playback),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileQueue extends StatelessWidget {
  const _MobileQueue({required this.snapshot, required this.playback});

  final PlaybackSnapshot snapshot;
  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.queue_music, size: 20),
            const SizedBox(width: 8),
            Text(
              'Up next',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${snapshot.queue.length} songs',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < snapshot.queue.length; index++)
          _QueueTrackTile(
            track: snapshot.queue[index],
            index: index,
            isCurrent: index == snapshot.currentIndex,
            onTap: () =>
                playback.playQueue(snapshot.queue, initialIndex: index),
          ),
      ],
    );
  }
}

class _QueueTrackTile extends StatelessWidget {
  const _QueueTrackTile({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
  });

  final LibraryTrack track;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(
      width: 40,
      height: 40,
      child: track.artwork == null
          ? CircleAvatar(child: Text('${index + 1}'))
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(track.artwork!, fit: BoxFit.cover),
            ),
    ),
    title: Text(
      track.title ?? track.sourcePath,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
      ),
    ),
    subtitle: Text(
      [
        if (track.artist case final artist? when artist.trim().isNotEmpty)
          artist,
        if (track.album case final album? when album.trim().isNotEmpty) album,
      ].join('  •  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: isCurrent
        ? Icon(Icons.equalizer, color: Theme.of(context).colorScheme.primary)
        : null,
    onTap: onTap,
  );
}

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
