import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/home/home_page.dart';
import '../presentation/cd/cd_drive_page.dart';
import '../presentation/playlists/playlists_page.dart';
import '../presentation/radio/radio_page.dart';
import '../presentation/settings/settings_page.dart';
import '../presentation/playback/playback_dock.dart';
import '../domain/playback/playback_service.dart';
import 'cd_providers.dart';
import 'playback_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _page(const HomePage(), state),
          ),
          GoRoute(
            path: '/playlists',
            pageBuilder: (context, state) =>
                _page(const PlaylistsPage(), state),
          ),
          GoRoute(
            path: '/radio',
            pageBuilder: (context, state) => _page(const RadioPage(), state),
          ),
          GoRoute(
            path: '/cd',
            pageBuilder: (context, state) => _page(const CdDrivePage(), state),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _page(const SettingsPage(), state),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _page(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(0.025, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}

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

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.playback,
  });

  final List<_AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 18, 24),
            child: Row(
              children: [
                Icon(Icons.graphic_eq, color: colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Music Base',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: NavigationRail(
              extended: true,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
          ),
          if (playback.snapshot.queue.isNotEmpty)
            _SidebarQueue(playback: playback),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'LOCAL MUSIC PLAYER',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarQueue extends StatelessWidget {
  const _SidebarQueue({required this.playback});

  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
    final snapshot = playback.snapshot;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.queue_music,
                size: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Playback queue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${snapshot.queueTotal ?? snapshot.queue.length}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.queue.length,
              itemBuilder: (context, index) {
                final track = snapshot.queue[index];
                final isCurrent = index == snapshot.currentIndex;
                return InkWell(
                  onTap: snapshot.queueTotal == null
                      ? () => playback.playQueue(
                          snapshot.queue,
                          initialIndex: index,
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(
                          isCurrent
                              ? Icons.play_arrow
                              : Icons.music_note_outlined,
                          size: 16,
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            track.title ?? track.sourcePath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
