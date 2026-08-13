part of 'router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final supportsCdRipping = ref
        .watch(windowsCapabilitiesProvider)
        .supportsCdRipping;
    final destinations = <_AppDestination>[
      const _AppDestination(
        Icons.library_music_outlined,
        Icons.library_music,
        'Library',
        '/',
      ),
      const _AppDestination(
        Icons.queue_music_outlined,
        Icons.queue_music,
        'Playlists',
        '/playlists',
      ),
      const _AppDestination(
        Icons.radio_outlined,
        Icons.radio,
        'Radio',
        '/radio',
      ),
    ];
    final paths = <String>['/', '/playlists', '/radio'];
    if (supportsCdRipping) {
      destinations.add(
        const _AppDestination(
          Icons.album_outlined,
          Icons.album,
          'CD import',
          '/cd',
        ),
      );
      paths.add('/cd');
    }
    destinations.add(
      const _AppDestination(
        Icons.settings_outlined,
        Icons.settings,
        'Settings',
        '/settings',
      ),
    );
    paths.add('/settings');
    final selectedIndex = paths.indexOf(location);
    final playback = ref.watch(playbackServiceProvider);
    final audioAnalysis = ref.watch(audioAnalysisServiceProvider);
    final realtimeSpectrum = ref.watch(realtimeSpectrumServiceProvider);
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    if (isCompact) {
      return _AppShellFrame(
        loading: playback.snapshot.isLoading,
        child: Scaffold(
          body: Column(
            children: [
              if (playback.snapshot.currentTrack != null ||
                  playback.snapshot.currentRadioStation != null)
                PlaybackDock(
                  playback: playback,
                  audioAnalysis: audioAnalysis,
                  realtimeSpectrum: realtimeSpectrum,
                  compact: true,
                ),
              Expanded(child: child),
              NavigationBar(
                selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                onDestinationSelected: (index) => context.go(paths[index]),
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return _AppShellFrame(
      loading: playback.snapshot.isLoading,
      child: Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              destinations: destinations,
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (index) => context.go(paths[index]),
              playback: playback,
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  if (playback.snapshot.currentTrack != null ||
                      playback.snapshot.currentRadioStation != null)
                    PlaybackDock(
                      playback: playback,
                      audioAnalysis: audioAnalysis,
                      realtimeSpectrum: realtimeSpectrum,
                      compact: false,
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppShellFrame extends StatelessWidget {
  const _AppShellFrame({required this.child, required this.loading});

  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (loading)
        Positioned(
          left: 24,
          right: 24,
          bottom: 20,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation: 8,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading audio stream…',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _AppDestination {
  const _AppDestination(this.icon, this.selectedIcon, this.label, this.path);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
}
