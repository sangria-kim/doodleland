import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

class CharacterDao extends DatabaseAccessor<AppDatabase> {
  CharacterDao(this._database) : super(_database);

  final AppDatabase _database;

  Future<int> insertCharacter({
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
    DateTime? createdAt,
  }) {
    final companion = CharactersCompanion.insert(
      name: name,
      originalImagePath: originalImagePath,
      transparentImagePath: transparentImagePath,
      thumbnailPath: thumbnailPath,
      width: width,
      height: height,
      createdAt: Value(createdAt ?? DateTime.now()),
    );
    return _database.into(_database.characters).insert(companion);
  }

  Future<List<Character>> getAllCharacters() {
    final query = _database.select(_database.characters)
      ..orderBy([(character) => OrderingTerm.desc(character.createdAt)]);
    return query.get();
  }

  Future<Character?> getCharacterById(int id) {
    final query = _database.select(_database.characters)
      ..where((character) => character.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<bool> deleteCharacter(int id) async {
    final rows = await (_database.delete(
      _database.characters,
    )..where((character) => character.id.equals(id))).go();
    return rows > 0;
  }
}

final characterDaoProvider = Provider<CharacterDao>(
  (ref) => CharacterDao(ref.watch(appDatabaseProvider)),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
