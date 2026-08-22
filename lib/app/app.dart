import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/settings/app_locale.dart';
import '../l10n/generated/app_localizations.dart';
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
    final locale = switch (settings?.locale) {
      AppLocale.english => const Locale('en'),
      AppLocale.japanese => const Locale('ja'),
      _ => null,
    };

    return MaterialApp.router(
      title: 'Music Base',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, accentColor),
      darkTheme: buildTheme(Brightness.dark, accentColor),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
