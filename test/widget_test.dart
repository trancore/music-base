import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_base/app/app.dart';
import 'package:music_base/app/providers.dart';

void main() {
  testWidgets('renders the Music Base library shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MusicBaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Music Base'), findsOneWidget);
    expect(find.text('Music library'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
  });
}
