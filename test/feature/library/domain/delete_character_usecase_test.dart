import 'dart:io';

import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/feature/library/data/character_repository.dart';
import 'package:doodleland/feature/library/domain/delete_character_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository();

  final Map<int, Character> _characters = {};
  bool shouldDelete = true;

  void seed(Character character) {
    _characters[character.id] = character;
  }

  @override
  Future<List<Character>> getCharacters() async => _characters.values.toList(growable: false);

  @override
  Future<Character> getCharacterById(int id) async => _characters[id]!;

  @override
  Future<int> saveCharacter({
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
  }) async {
    throw UnsupportedError('used only for delete flow tests');
  }

  @override
  Future<bool> removeCharacter(int id) async {
    if (!shouldDelete) {
      return false;
    }
    return _characters.remove(id) != null;
  }
}

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('delete-character-usecase-test');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<Character> _makeCharacter(int id) async {
    final original = File('${tempDirectory.path}/original_$id.png');
    final transparent = File('${tempDirectory.path}/transparent_$id.png');
    final thumbnail = File('${tempDirectory.path}/thumbnail_$id.png');
    await original.writeAsBytes([1]);
    await transparent.writeAsBytes([1]);
    await thumbnail.writeAsBytes([1]);

    return Character(
      id: id,
      name: 'sample-$id',
      originalImagePath: original.path,
      transparentImagePath: transparent.path,
      thumbnailPath: thumbnail.path,
      width: 16,
      height: 16,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('deletes related files when repository delete succeeds', () async {
    final repository = FakeCharacterRepository();
    final useCase = DeleteCharacterUseCase(characterRepository: repository);
    final character = await _makeCharacter(1);
    repository.seed(character);

    final isDeleted = await useCase.call(character);

    expect(isDeleted, isTrue);
    expect(await File(character.originalImagePath).exists(), isFalse);
    expect(await File(character.transparentImagePath).exists(), isFalse);
    expect(await File(character.thumbnailPath).exists(), isFalse);
  });

  test('returns false and keeps files when repository delete fails', () async {
    final repository = FakeCharacterRepository()..shouldDelete = false;
    final useCase = DeleteCharacterUseCase(characterRepository: repository);
    final character = await _makeCharacter(2);
    repository.seed(character);

    final isDeleted = await useCase.call(character);

    expect(isDeleted, isFalse);
    expect(await File(character.originalImagePath).exists(), isTrue);
    expect(await File(character.transparentImagePath).exists(), isTrue);
    expect(await File(character.thumbnailPath).exists(), isTrue);
  });
}
