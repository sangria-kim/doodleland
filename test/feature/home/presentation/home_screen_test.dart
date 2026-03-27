import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/feature/home/presentation/home_screen.dart';
import 'package:doodleland/feature/library/data/character_repository.dart';
import 'package:doodleland/feature/library/presentation/library_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeCharacterRepository implements CharacterRepository {
  const _FakeCharacterRepository(this.characters);

  final List<Character> characters;

  @override
  Future<Character> getCharacterById(int id) {
    return Future.value(
      characters.firstWhere((character) => character.id == id),
    );
  }

  @override
  Future<List<Character>> getCharacters() async {
    return List.unmodifiable(characters);
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
    return characters.length + 1;
  }

  @override
  Future<bool> removeCharacter(int id) async {
    return true;
  }
}

void main() {
  testWidgets('start play goes to capture when library is empty', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/capture',
          builder: (_, __) => const Scaffold(body: Text('capture')),
        ),
        GoRoute(
          path: '/stage/background',
          builder: (_, __) => const Scaffold(body: Text('stage background')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWith(
            (ref) => _FakeCharacterRepository(const []),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('놀이 시작'));
    await tester.pumpAndSettle();

    expect(find.text('capture'), findsOneWidget);
  });

  testWidgets('start stage flow directly when library has characters', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/capture',
          builder: (_, __) => const Scaffold(body: Text('capture')),
        ),
        GoRoute(
          path: '/stage/background',
          builder: (_, __) => const Scaffold(body: Text('stage background')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWith(
            (_) => _FakeCharacterRepository([
              Character(
                id: 1,
                name: 'sample',
                originalImagePath: '/tmp/original.png',
                transparentImagePath: '/tmp/transparent.png',
                thumbnailPath: '/tmp/thumbnail.png',
                width: 32,
                height: 32,
                createdAt: DateTime(2026, 1, 1),
              ),
            ]),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('놀이 시작'));
    await tester.pumpAndSettle();

    expect(find.text('stage background'), findsOneWidget);
  });
}
