import 'dart:convert';
import 'dart:io';

import 'package:doodleland/core/settings/data/file_settings_repository.dart';
import 'package:doodleland/core/settings/domain/play_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late FileSettingsRepository repository;
  late File file;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('settings-test-');
    repository = FileSettingsRepository(directory: () async => directory);
    file = File('${directory.path}/${FileSettingsRepository.fileName}');
  });
  tearDown(() => directory.delete(recursive: true));

  test('first run defaults without creating a file', () async {
    final result = await repository.load();
    expect(result.settings, const PlaySettings());
    expect(result.restoreError, isNull);
    expect(await file.exists(), isFalse);
  });

  test('full snapshot round trips through a fresh repository', () async {
    const settings = PlaySettings(
      musicEnabled: false,
      effectsEnabled: false,
      voiceEnabled: false,
      reduceEffects: true,
    );
    await repository.save(settings);
    final fresh = FileSettingsRepository(directory: () async => directory);
    expect((await fresh.load()).settings, settings);
    expect((jsonDecode(await file.readAsString()) as Map).length, 5);
    expect(await File('${file.path}.tmp').exists(), isFalse);
  });

  test(
    'missing and invalid booleans fall back independently; unknown keys ignored',
    () async {
      await file.writeAsString(
        jsonEncode({
          'schema': 1,
          'musicEnabled': false,
          'voiceEnabled': 'false',
          'reduceEffects': 1,
          'unknown': true,
        }),
      );
      final result = await repository.load();
      expect(result.settings, const PlaySettings(musicEnabled: false));
      expect(result.restoreError, isNull);
    },
  );

  for (final invalid in [
    '{broken',
    '[]',
    'null',
    '{"schema":2,"voiceEnabled":false}',
    '{"voiceEnabled":false}',
  ]) {
    test(
      'invalid data reports restore error without overwriting: $invalid',
      () async {
        await file.writeAsString(invalid);
        final result = await repository.load();
        expect(result.settings, const PlaySettings());
        expect(result.restoreError, isNotNull);
        expect(await file.readAsString(), invalid);
      },
    );
  }

  test('directory lookup/read failure is recoverable', () async {
    final failing = FileSettingsRepository(
      directory: () async => throw const FileSystemException('unavailable'),
    );
    final result = await failing.load();
    expect(result.restoreError, isA<FileSystemException>());
    expect(result.settings, const PlaySettings());
  });

  test('failure before replace preserves the last valid snapshot', () async {
    const saved = PlaySettings(voiceEnabled: false);
    await repository.save(saved);
    await Directory('${file.path}.tmp').create();
    await expectLater(
      repository.save(const PlaySettings()),
      throwsA(isA<FileSystemException>()),
    );
    expect((await repository.load()).settings, saved);
    await Directory('${file.path}.tmp').delete();
    await repository.save(const PlaySettings(reduceEffects: true));
    expect((await repository.load()).settings.reduceEffects, isTrue);
  });
}
