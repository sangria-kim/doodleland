import 'dart:io';
import 'dart:typed_data';

import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/core/storage/character_storage_paths.dart';
import 'package:doodleland/feature/capture/data/background_remover.dart';
import 'package:doodleland/feature/capture/domain/save_character_usecase.dart';
import 'package:doodleland/feature/library/data/character_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository();

  final List<Character> _characters = [];
  int _nextId = 1;

  @override
  Future<List<Character>> getCharacters() async =>
      List.unmodifiable(_characters);

  @override
  Future<Character> getCharacterById(int id) async {
    return _characters.firstWhere((character) => character.id == id);
  }

  @override
  Future<int> saveCharacter({
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
  }) async {
    final next = _nextId++;
    final character = Character(
      id: next,
      name: name,
      originalImagePath: originalImagePath,
      transparentImagePath: transparentImagePath,
      thumbnailPath: thumbnailPath,
      width: width,
      height: height,
      createdAt: DateTime.now(),
    );
    _characters.add(character);
    return next;
  }

  @override
  Future<bool> removeCharacter(int id) async {
    final before = _characters.length;
    _characters.removeWhere((character) => character.id == id);
    return _characters.length < before;
  }
}

class TestStoragePathFactory extends CharacterStoragePathFactory {
  TestStoragePathFactory(this.baseDirectory);

  final Directory baseDirectory;

  @override
  Future<CharacterStoragePaths> create() async {
    return CharacterStoragePaths(
      baseDirectory: baseDirectory,
      rootDirectoryName: 'capture',
    );
  }
}

class SpyBackgroundRemover implements BackgroundRemover {
  SpyBackgroundRemover({required this.result});

  final RemovalResult result;
  int removeCallCount = 0;
  Uint8List? lastInputBytes;

  @override
  Future<RemovalResult> remove(
    Uint8List croppedImageBytes, {
    int? maxDimension,
    bool trimToForeground = false,
    BackgroundRemovalDebugSession? debugSession,
  }) async {
    removeCallCount++;
    lastInputBytes = Uint8List.fromList(croppedImageBytes);
    return result;
  }
}

void main() {
  late Directory tempDirectory;
  late String sourceImagePath;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('capture-usecase');
    final source = img.Image(width: 16, height: 9);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    for (var y = 4; y < 7; y++) {
      for (var x = 5; x < 11; x++) {
        source.setPixelRgba(x, y, 10, 10, 10, 255);
      }
    }
    final imageBytes = img.encodePng(source);
    sourceImagePath = '${tempDirectory.path}/source.png';
    await File(sourceImagePath).writeAsBytes(imageBytes);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('save usecase copies source image and inserts repository row', () async {
    final repository = FakeCharacterRepository();
    final useCase = SaveCharacterUseCase(
      characterRepository: repository,
      characterStoragePathFactory: TestStoragePathFactory(tempDirectory),
    );

    final result = await useCase.call(sourceImagePath: sourceImagePath);

    final savedCharacters = await repository.getCharacters();
    expect(result.characterId, 1);
    expect(result.qualityWarningMessage, isNull);
    expect(savedCharacters, hasLength(1));
    expect(savedCharacters.first.width, 16);
    expect(savedCharacters.first.height, 9);
    expect(
      await File(savedCharacters.first.originalImagePath).exists(),
      isTrue,
    );
    expect(
      await File(savedCharacters.first.transparentImagePath).exists(),
      isTrue,
    );
    expect(await File(savedCharacters.first.thumbnailPath).exists(), isTrue);
  });

  test('skips background remover for preprocessed transparent input', () async {
    final transparentInput = img.Image(width: 12, height: 8, numChannels: 4);
    for (var y = 0; y < transparentInput.height; y++) {
      for (var x = 0; x < transparentInput.width; x++) {
        transparentInput.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
    for (var y = 2; y < 7; y++) {
      for (var x = 3; x < 9; x++) {
        transparentInput.setPixelRgba(x, y, 10, 140, 240, 255);
      }
    }
    final transparentInputPath = '${tempDirectory.path}/preprocessed.png';
    await File(
      transparentInputPath,
    ).writeAsBytes(img.encodePng(transparentInput));

    final repository = FakeCharacterRepository();
    final spyRemover = SpyBackgroundRemover(
      result: RemovalResult.failure(errorMessage: 'should not be called'),
    );
    final useCase = SaveCharacterUseCase(
      characterRepository: repository,
      characterStoragePathFactory: TestStoragePathFactory(tempDirectory),
      backgroundRemover: spyRemover,
    );

    final result = await useCase.call(sourceImagePath: transparentInputPath);

    final savedCharacter = (await repository.getCharacters()).single;
    final storedTransparent = img.decodeImage(
      await File(savedCharacter.transparentImagePath).readAsBytes(),
    )!;
    final storedThumbnail = img.decodeImage(
      await File(savedCharacter.thumbnailPath).readAsBytes(),
    )!;

    expect(result.characterId, 1);
    expect(result.qualityWarningMessage, isNull);
    expect(spyRemover.removeCallCount, 0);
    expect(savedCharacter.width, transparentInput.width);
    expect(savedCharacter.height, transparentInput.height);
    expect(storedTransparent.width, transparentInput.width);
    expect(storedTransparent.height, transparentInput.height);
    expect(storedTransparent.getPixel(0, 0).a.round(), equals(0));
    expect(storedTransparent.getPixel(5, 4).a.round(), equals(255));
    expect(storedThumbnail.getPixel(0, 0).a.round(), equals(0));
    expect(
      storedThumbnail
          .getPixel(storedThumbnail.width ~/ 2, storedThumbnail.height ~/ 2)
          .a
          .round(),
      greaterThan(0),
    );
  });

  test(
    'uses remover output dimensions for stored transparent metadata',
    () async {
      final transparentOutput = img.Image(width: 7, height: 5, numChannels: 4);
      for (var y = 0; y < transparentOutput.height; y++) {
        for (var x = 0; x < transparentOutput.width; x++) {
          transparentOutput.setPixelRgba(x, y, 20, 30, 40, x == 0 ? 0 : 255);
        }
      }
      final spyRemover = SpyBackgroundRemover(
        result: RemovalResult(
          success: true,
          outputImageBytes: Uint8List.fromList(
            img.encodePng(transparentOutput),
          ),
          transparentAreaRatio: 1 / transparentOutput.width,
          outputWidth: transparentOutput.width,
          outputHeight: transparentOutput.height,
        ),
      );
      final repository = FakeCharacterRepository();
      final useCase = SaveCharacterUseCase(
        characterRepository: repository,
        characterStoragePathFactory: TestStoragePathFactory(tempDirectory),
        backgroundRemover: spyRemover,
      );

      final result = await useCase.call(sourceImagePath: sourceImagePath);

      final savedCharacter = (await repository.getCharacters()).single;
      final storedTransparent = img.decodeImage(
        await File(savedCharacter.transparentImagePath).readAsBytes(),
      )!;

      expect(result.characterId, 1);
      expect(spyRemover.removeCallCount, 1);
      expect(spyRemover.lastInputBytes, isNotNull);
      expect(savedCharacter.width, transparentOutput.width);
      expect(savedCharacter.height, transparentOutput.height);
      expect(storedTransparent.width, transparentOutput.width);
      expect(storedTransparent.height, transparentOutput.height);
      expect(storedTransparent.getPixel(0, 0).a.round(), equals(0));
    },
  );

  test(
    'save usecase keeps transparent background in extracted thumbnail',
    () async {
      final repository = FakeCharacterRepository();
      final useCase = SaveCharacterUseCase(
        characterRepository: repository,
        characterStoragePathFactory: TestStoragePathFactory(tempDirectory),
      );

      await useCase.call(sourceImagePath: sourceImagePath);

      final savedCharacter = (await repository.getCharacters()).single;
      final thumbnail = img.decodeImage(
        await File(savedCharacter.thumbnailPath).readAsBytes(),
      )!;

      expect(thumbnail.width, equals(200));
      expect(
        thumbnail.height,
        equals((savedCharacter.height * 200 / savedCharacter.width).round()),
      );
      expect(thumbnail.getPixel(0, 0).a.round(), equals(0));
      expect(
        thumbnail
            .getPixel(thumbnail.width ~/ 2, thumbnail.height ~/ 2)
            .a
            .round(),
        greaterThan(0),
      );
    },
  );

  test(
    'returns warning when background is mostly transparent after removal',
    () async {
      final whiteBackground = img.Image(width: 10, height: 10);
      for (var y = 0; y < whiteBackground.height; y++) {
        for (var x = 0; x < whiteBackground.width; x++) {
          whiteBackground.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
      final source = File('${tempDirectory.path}/white.png');
      await source.writeAsBytes(img.encodePng(whiteBackground));

      final repository = FakeCharacterRepository();
      final useCase = SaveCharacterUseCase(
        characterRepository: repository,
        characterStoragePathFactory: TestStoragePathFactory(tempDirectory),
      );

      final result = await useCase.call(sourceImagePath: source.path);

      expect(result.characterId, 1);
      expect(result.qualityWarningMessage, isNotNull);
      expect(result.qualityWarningMessage, isNotEmpty);
    },
  );

  test('throws when source image is missing', () async {
    final repository = FakeCharacterRepository();
    final useCase = SaveCharacterUseCase(
      characterRepository: repository,
      characterStoragePathFactory: TestStoragePathFactory(tempDirectory),
    );

    await expectLater(
      () =>
          useCase.call(sourceImagePath: '${tempDirectory.path}/not-found.png'),
      throwsA(isA<StateError>()),
    );
  });
}
