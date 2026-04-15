import 'dart:async';

import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/feature/library/data/character_repository.dart';
import 'package:doodleland/feature/library/presentation/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeCharacterRepository implements CharacterRepository {
  _FakeCharacterRepository({List<Character> characters = const []})
    : _characters = List<Character>.from(characters);

  final List<Character> _characters;
  Completer<List<Character>>? getCharactersCompleter;

  @override
  Future<List<Character>> getCharacters() async {
    final completer = getCharactersCompleter;
    if (completer != null) {
      return completer.future;
    }
    return List<Character>.unmodifiable(_characters);
  }

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
    throw UnsupportedError('not used in library screen tests');
  }

  @override
  Future<bool> removeCharacter(int id) async => true;
}

void main() {
  Widget buildApp(_FakeCharacterRepository repository) {
    final router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/capture',
          builder: (context, state) => const Scaffold(body: Text('capture')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWith((ref) => repository),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('shows loading indicator while characters are loading', (
    WidgetTester tester,
  ) async {
    final repository = _FakeCharacterRepository()
      ..getCharactersCompleter = Completer<List<Character>>();

    await tester.pumpWidget(buildApp(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.getCharactersCompleter!.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty state and moves to capture', (
    WidgetTester tester,
  ) async {
    final repository = _FakeCharacterRepository();

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('아직 저장한 그림이 없어요'), findsOneWidget);
    expect(find.text('그림을 만들어서 나만의 그림책을 채워보세요'), findsOneWidget);

    await tester.tap(find.text('그림 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('capture'), findsOneWidget);
  });
}
