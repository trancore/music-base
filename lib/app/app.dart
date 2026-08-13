import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class MusicBaseApp extends ConsumerWidget {
  const MusicBaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final themeMode = settings?.themeMode ?? ThemeMode.system;
    final accentColor = settings?.accentColor ?? defaultAccentColor;

    return MaterialApp.router(
      title: 'Music Base',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, accentColor),
      darkTheme: buildTheme(Brightness.dark, accentColor),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
