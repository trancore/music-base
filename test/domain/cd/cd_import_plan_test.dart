import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/domain/cd/cd_import_plan.dart';
import 'package:music_base/domain/metadata/musicbrainz_release.dart';

void main() {
  const release = MusicBrainzRelease(
    id: 'release-id',
    title: 'Album / Name',
    artist: 'Artist',
    releaseDate: '2020',
    media: [
      MusicBrainzMedium(
        position: 1,
        tracks: [
          MusicBrainzTrack(position: 1, title: 'Intro'),
          MusicBrainzTrack(position: 2, title: 'Song: One'),
        ],
      ),
    ],
  );

  test('creates a sanitized FLAC import plan', () {
    const planner = CdImportPlanner();
    final plan = planner.create(
      release: release,
      cdTracks: const [CdTrack(number: 1), CdTrack(number: 2)],
      outputDirectory: '/Music',
      format: CdImportFormat.flac,
    );

    expect(plan.tracks, hasLength(2));
    expect(
      plan.tracks.first.targetPath,
      '/Music/Artist/Album _ Name/01 - Intro.flac',
    );
    expect(
      plan.tracks[1].targetPath,
      '/Music/Artist/Album _ Name/02 - Song_ One.flac',
    );
    expect(plan.tracks[1].releaseDate, '2020');
  });

  test('rejects track count mismatch and existing output', () {
    const planner = CdImportPlanner();
    expect(
      () => planner.create(
        release: release,
        cdTracks: const [CdTrack(number: 3)],
        outputDirectory: '/Music',
        format: CdImportFormat.mp3,
      ),
      throwsA(isA<CdImportPlanningException>()),
    );
    expect(
      () => planner.create(
        release: release,
        cdTracks: const [CdTrack(number: 1), CdTrack(number: 2)],
        outputDirectory: '/Music',
        format: CdImportFormat.mp3,
        existingPaths: {'/Music/Artist/Album _ Name/01 - Intro.mp3'},
      ),
      throwsA(isA<CdImportPlanningException>()),
    );
  });

  test('maps a selected CD track to its release track position', () {
    const planner = CdImportPlanner();
    final plan = planner.create(
      release: release,
      cdTracks: const [CdTrack(number: 2)],
      outputDirectory: '/Music',
      format: CdImportFormat.flac,
    );

    expect(plan.tracks, hasLength(1));
    expect(plan.tracks.single.sourceTrackNumber, 2);
    expect(plan.tracks.single.title, 'Song: One');
    expect(
      plan.tracks.single.targetPath,
      '/Music/Artist/Album _ Name/02 - Song_ One.flac',
    );
  });
}
