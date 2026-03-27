import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/core/database/character_dao.dart';

void main() {
  late AppDatabase database;
  late CharacterDao characterDao;

  setUp(() {
    database = AppDatabase.connect(NativeDatabase.memory());
    characterDao = CharacterDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('insert and query character', () async {
    final id = await characterDao.insertCharacter(
      name: 'test',
      originalImagePath: '/tmp/original.png',
      transparentImagePath: '/tmp/transparent.png',
      thumbnailPath: '/tmp/thumb.png',
      width: 240,
      height: 320,
    );

    final all = await characterDao.getAllCharacters();
    expect(all, hasLength(1));
    expect(all.first.id, id);
    expect(all.first.name, 'test');
  });

  test('delete character by id', () async {
    final id = await characterDao.insertCharacter(
      name: 'to delete',
      originalImagePath: '/tmp/original.png',
      transparentImagePath: '/tmp/transparent.png',
      thumbnailPath: '/tmp/thumb.png',
      width: 120,
      height: 120,
    );

    final deleted = await characterDao.deleteCharacter(id);
    final all = await characterDao.getAllCharacters();
    expect(deleted, isTrue);
    expect(all, isEmpty);
  });
}
