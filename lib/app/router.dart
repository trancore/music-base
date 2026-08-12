import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/home/home_page.dart';
import '../presentation/cd/cd_drive_page.dart';
import '../presentation/playlists/playlists_page.dart';
import '../presentation/settings/settings_page.dart';
import '../presentation/playback/playback_dock.dart';
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
    ];
    final paths = <String>['/', '/playlists'];
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
      return Scaffold(
        body: Column(
          children: [
            if (playback.snapshot.currentTrack != null)
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
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            destinations: destinations,
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            onDestinationSelected: (index) => context.go(paths[index]),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (playback.snapshot.currentTrack != null)
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
    );
  }
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
  });

  final List<_AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

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
