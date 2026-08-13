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

part 'app_shell.dart';
part 'desktop_sidebar.dart';

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
