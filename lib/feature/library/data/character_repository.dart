import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/character_dao.dart';

abstract class CharacterRepository {
  Future<List<Character>> getCharacters();

  Future<Character> getCharacterById(int id);

  Future<int> saveCharacter({
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
  });

  Future<bool> removeCharacter(int id);
}

class CharacterRepositoryImpl implements CharacterRepository {
  const CharacterRepositoryImpl(this._dao);

  final CharacterDao _dao;

  @override
  Future<List<Character>> getCharacters() => _dao.getAllCharacters();

  @override
  Future<Character> getCharacterById(int id) {
    return _dao
        .getCharacterById(id)
        .then(
          (character) => character ?? (throw StateError('character not found')),
        );
  }

  @override
  Future<int> saveCharacter({
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
  }) => _dao.insertCharacter(
    name: name,
    originalImagePath: originalImagePath,
    transparentImagePath: transparentImagePath,
    thumbnailPath: thumbnailPath,
    width: width,
    height: height,
  );

  @override
  Future<bool> removeCharacter(int id) => _dao.deleteCharacter(id);
}

final characterRepositoryProvider = Provider<CharacterRepository>(
  (ref) => CharacterRepositoryImpl(ref.watch(characterDaoProvider)),
);
