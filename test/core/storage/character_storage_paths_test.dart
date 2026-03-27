import 'dart:io';

import 'package:doodleland/core/storage/character_storage_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory baseDirectory;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp('character-storage-test');
  });

  tearDown(() async {
    if (await baseDirectory.exists()) {
      await baseDirectory.delete(recursive: true);
    }
  });

  test('directories for original/transparent/thumbnail are created', () async {
    final paths = CharacterStoragePaths(baseDirectory: baseDirectory);

    final original = await paths.originalDirectory;
    final transparent = await paths.transparentDirectory;
    final thumbnail = await paths.thumbnailDirectory;

    expect(await original.exists(), isTrue);
    expect(await transparent.exists(), isTrue);
    expect(await thumbnail.exists(), isTrue);
    expect(original.path, '${baseDirectory.path}/characters/original');
    expect(transparent.path, '${baseDirectory.path}/characters/transparent');
    expect(thumbnail.path, '${baseDirectory.path}/characters/thumbnail');
  });

  test('generated image paths use expected extension and prefix', () async {
    final paths = CharacterStoragePaths(baseDirectory: baseDirectory);
    final originalPath = await paths.originalImagePath();
    final transparentPath = await paths.transparentImagePath(extension: 'webp');
    final thumbnailPath = await paths.thumbnailImagePath(extension: 'jpg');

    expect(originalPath, contains('${baseDirectory.path}/characters/original/original_'));
    expect(originalPath, endsWith('.png'));
    expect(transparentPath, contains('/characters/transparent/transparent_'));
    expect(transparentPath, endsWith('.webp'));
    expect(thumbnailPath, contains('/characters/thumbnail/thumbnail_'));
    expect(thumbnailPath, endsWith('.jpg'));
  });
}
