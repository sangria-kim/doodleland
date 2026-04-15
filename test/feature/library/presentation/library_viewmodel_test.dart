import 'dart:async';
import 'dart:io';

import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/feature/library/data/character_repository.dart';
import 'package:doodleland/feature/library/domain/delete_character_usecase.dart';
import 'package:doodleland/feature/library/domain/get_characters_usecase.dart';
import 'package:doodleland/feature/library/presentation/library_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCharacterRepository implements CharacterRepository {
  _FakeCharacterRepository({List<Character> characters = const []})
    : _characters = List<Character>.from(characters);

  final List<Character> _characters;
  Completer<bool>? removeCompleter;

  @override
  Future<List<Character>> getCharacters() async =>
      List<Character>.unmodifiable(_characters);

  @override
  Future<Character> getCharacterById(int id) async =>
      _characters.firstWhere((character) => character.id == id);

  @override
  Future<int> saveCharacter({
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
  }) async {
    throw UnsupportedError('not used in library viewmodel tests');
  }

  @override
  Future<bool> removeCharacter(int id) async {
    final pending = removeCompleter;
    if (pending != null) {
      final result = await pending.future;
      if (!result) {
        return false;
      }
    }

    final before = _characters.length;
    _characters.removeWhere((character) => character.id == id);
    return _characters.length < before;
  }
}

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'library-viewmodel-test',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<Character> makeCharacter(int id, {String? name}) async {
    Future<String> createPath(String label) async {
      final file = File('${tempDirectory.path}/$label-$id.png');
      await file.writeAsBytes([1]);
      return file.path;
    }

    return Character(
      id: id,
      name: name ?? 'sample-$id',
      originalImagePath: await createPath('original'),
      transparentImagePath: await createPath('transparent'),
      thumbnailPath: await createPath('thumbnail'),
      width: 120,
      height: 120,
      createdAt: DateTime(2026, 1, id),
    );
  }

  test('loadCharacters populates latest repository data', () async {
    final repository = _FakeCharacterRepository(
      characters: [await makeCharacter(1), await makeCharacter(2)],
    );
    final viewModel = LibraryViewModel(
      getCharactersUseCase: GetCharactersUseCase(
        characterRepository: repository,
      ),
      deleteCharacterUseCase: DeleteCharacterUseCase(
        characterRepository: repository,
      ),
    );

    await viewModel.loadCharacters();

    expect(viewModel.state.isLoading, isFalse);
    expect(viewModel.state.hasLoaded, isTrue);
    expect(viewModel.state.characters, hasLength(2));
  });

  test('deleteCharacter removes item from current state on success', () async {
    final repository = _FakeCharacterRepository(
      characters: [
        await makeCharacter(1, name: 'alpha'),
        await makeCharacter(2),
      ],
    );
    final viewModel = LibraryViewModel(
      getCharactersUseCase: GetCharactersUseCase(
        characterRepository: repository,
      ),
      deleteCharacterUseCase: DeleteCharacterUseCase(
        characterRepository: repository,
      ),
    );
    await viewModel.loadCharacters();

    final deleted = await viewModel.deleteCharacter(
      viewModel.state.characters.first,
    );

    expect(deleted, isTrue);
    expect(viewModel.state.deletingCharacterId, isNull);
    expect(viewModel.state.characters.map((item) => item.name), ['sample-2']);
  });

  test(
    'deleteCharacter ignores duplicate delete requests while pending',
    () async {
      final repository = _FakeCharacterRepository(
        characters: [await makeCharacter(1)],
      )..removeCompleter = Completer<bool>();
      final viewModel = LibraryViewModel(
        getCharactersUseCase: GetCharactersUseCase(
          characterRepository: repository,
        ),
        deleteCharacterUseCase: DeleteCharacterUseCase(
          characterRepository: repository,
        ),
      );
      await viewModel.loadCharacters();
      final character = viewModel.state.characters.single;

      final firstDelete = viewModel.deleteCharacter(character);
      final secondDelete = await viewModel.deleteCharacter(character);

      expect(viewModel.state.deletingCharacterId, character.id);
      expect(secondDelete, isFalse);

      repository.removeCompleter!.complete(true);
      final firstResult = await firstDelete;

      expect(firstResult, isTrue);
      expect(viewModel.state.deletingCharacterId, isNull);
      expect(viewModel.state.characters, isEmpty);
    },
  );
}
