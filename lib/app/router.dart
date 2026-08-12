import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/home/home_page.dart';
import '../presentation/cd/cd_drive_page.dart';
import '../presentation/metadata/musicbrainz_search_page.dart';
import '../presentation/playlists/playlists_page.dart';
import '../presentation/settings/settings_page.dart';
import 'cd_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/playlists',
            builder: (context, state) => const PlaylistsPage(),
          ),
          GoRoute(
            path: '/metadata',
            builder: (context, state) => const MusicBrainzSearchPage(),
          ),
          GoRoute(
            path: '/cd',
            builder: (context, state) => const CdDrivePage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final supportsCdRipping = ref
        .watch(windowsCapabilitiesProvider)
        .supportsCdRipping;
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.library_music_outlined),
        selectedIcon: Icon(Icons.library_music),
        label: Text('Library'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.queue_music_outlined),
        selectedIcon: Icon(Icons.queue_music),
        label: Text('Playlists'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome),
        label: Text('Metadata'),
      ),
    ];
    final paths = <String>['/', '/playlists', '/metadata'];
    if (supportsCdRipping) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.album_outlined),
          selectedIcon: Icon(Icons.album),
          label: Text('CD import'),
        ),
      );
      paths.add('/cd');
    }
    destinations.add(
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    );
    paths.add('/settings');
    final selectedIndex = paths.indexOf(location);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            onDestinationSelected: (index) => context.go(paths[index]),
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
