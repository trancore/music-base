import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/app/cd_providers.dart';
import 'package:music_base/app/musicbrainz_providers.dart';
import 'package:music_base/domain/cd/cd_drive_service.dart';
import 'package:music_base/domain/cd/cd_import_plan.dart';
import 'package:music_base/domain/cd/cd_ripping_service.dart';
import 'package:music_base/domain/cd/cd_track_service.dart';
import 'package:music_base/domain/metadata/musicbrainz_release.dart';
import 'package:music_base/domain/metadata/musicbrainz_service.dart';
import 'package:music_base/presentation/cd/cd_drive_page.dart';

void main() {
  testWidgets('shows a loaded drive and lets the user select a track', (
    tester,
  ) async {
    const drive = CdDrive(
      deviceId: 'D:',
      driveLetter: 'D:',
      name: 'Test Drive',
      mediaLoaded: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cdDriveServiceProvider.overrideWithValue(
            const _FakeCdDriveService([drive]),
          ),
          cdTrackServiceProvider.overrideWithValue(
            const _FakeCdTrackService([CdTrack(number: 1)]),
          ),
          cdRippingServiceProvider.overrideWithValue(
            const _FakeRippingService(),
          ),
          musicBrainzServiceProvider.overrideWithValue(
            const _FakeMusicBrainzService(),
          ),
        ],
        child: const MaterialApp(home: CdDrivePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('D: Test Drive'), findsOneWidget);
    expect(find.text('Media loaded'), findsOneWidget);

    await tester.tap(find.text('Select'));
    await tester.pump();
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.text('Track 1'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(find.text('Start ripping (1)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows an empty state when no drives are detected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cdDriveServiceProvider.overrideWithValue(
            const _FakeCdDriveService([]),
          ),
          cdTrackServiceProvider.overrideWithValue(
            const _FakeCdTrackService([]),
          ),
          cdRippingServiceProvider.overrideWithValue(
            const _FakeRippingService(),
          ),
          musicBrainzServiceProvider.overrideWithValue(
            const _FakeMusicBrainzService(),
          ),
        ],
        child: const MaterialApp(home: CdDrivePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No CD drives detected'), findsOneWidget);
    expect(
      find.text('Connect a CD drive and refresh this page.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });
}

class _FakeCdDriveService implements CdDriveService {
  const _FakeCdDriveService(this.drives);

  final List<CdDrive> drives;

  @override
  Future<List<CdDrive>> listDrives() async => drives;
}

class _FakeCdTrackService implements CdTrackService {
  const _FakeCdTrackService(this.tracks);

  final List<CdTrack> tracks;

  @override
  Future<List<CdTrack>> readTracks(CdDrive drive) async => tracks;
}

class _FakeRippingService implements CdRippingService {
  const _FakeRippingService();

  @override
  Future<void> ripTrack({
    required CdDrive drive,
    required CdTrack track,
    required String outputPath,
    required CdImportFormat format,
    String? title,
    String? artist,
    String? album,
    String? releaseDate,
    CdRippingCancellationToken? cancellationToken,
  }) async {}
}

class _FakeMusicBrainzService implements MusicBrainzService {
  const _FakeMusicBrainzService();

  @override
  Future<MusicBrainzRelease> getRelease(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<MusicBrainzRelease>> searchReleases({
    String? artist,
    String? album,
    int limit = 10,
  }) async => const [];
}
