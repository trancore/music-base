part of 'playback_dock.dart';

class _CompactPlaybackDock extends StatelessWidget {
  const _CompactPlaybackDock({
    required this.playback,
    required this.title,
    required this.subtitle,
    required this.track,
    required this.errorMessage,
    required this.isPlaying,
    required this.isRadio,
    required this.audioAnalysis,
    required this.realtimeSpectrum,
  });

  final PlaybackService playback;
  final String title;
  final String subtitle;
  final LibraryTrack? track;
  final String? errorMessage;
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
                _PlaybackArtworkTile(
                  track: track,
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
                      if (errorMessage case final error?) ...[
                        const SizedBox(height: 2),
                        Text(
                          error,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
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

class _MobileNowPlayingSheet extends ConsumerWidget {
  const _MobileNowPlayingSheet({
    required this.playback,
    required this.audioAnalysis,
    required this.realtimeSpectrum,
  });

  final PlaybackService playback;
  final AudioAnalysisService audioAnalysis;
  final RealtimeSpectrumService realtimeSpectrum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                _PlaybackArtworkTile(
                  track: station == null ? track : null,
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
                if (snapshot.errorMessage case final error?) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
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
                    if (station == null)
                      IconButton(
                        tooltip: 'Previous',
                        onPressed: playback.skipPrevious,
                        icon: const Icon(Icons.skip_previous),
                      ),
                    IconButton.filled(
                      tooltip: snapshot.isPlaying ? 'Pause' : 'Play',
                      onPressed: snapshot.isPlaying
                          ? playback.pause
                          : playback.resume,
                      icon: Icon(
                        snapshot.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    if (station == null)
                      IconButton(
                        tooltip: 'Next',
                        onPressed: playback.skipNext,
                        icon: const Icon(Icons.skip_next),
                      ),
                    const SizedBox(width: 8),
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
                if ((snapshot.queueTotal ?? snapshot.queue.length) > 1)
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
              '${snapshot.queueTotal ?? snapshot.queue.length} songs',
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
            onTap: snapshot.queueTotal == null
                ? () => playback.playQueue(snapshot.queue, initialIndex: index)
                : null,
          ),
      ],
    );
  }
}

class _QueueTrackTile extends ConsumerWidget {
  const _QueueTrackTile({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
  });

  final LibraryTrack track;
  final int index;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(
      width: 40,
      height: 40,
      child: _PlaybackArtworkTile(
        track: track,
        size: 40,
        fallback: Icons.music_note,
        borderRadius: 8,
        showIndexFallback: index + 1,
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
