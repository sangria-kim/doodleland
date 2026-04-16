import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/core/audio/stage_audio_controller.dart';
import 'package:doodleland/feature/home/presentation/home_screen.dart';
import 'package:doodleland/feature/library/data/character_repository.dart';
import 'package:doodleland/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../test_helpers/fake_stage_audio.dart';

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

StageAudioController _buildAudioController({
  FakeStageBgmPlayer? bgmPlayer,
  FakeStageSfxPlayer? sfxPlayer,
  FakeStageVoicePlayer? voicePlayer,
}) {
  return StageAudioController(
    bgmPlayer: bgmPlayer ?? FakeStageBgmPlayer(),
    sfxPlayer: sfxPlayer ?? FakeStageSfxPlayer(),
    voicePlayer: voicePlayer ?? FakeStageVoicePlayer(),
  );
}

void main() {
  testWidgets('start play goes to capture when library is empty', (
    WidgetTester tester,
  ) async {
    final controller = _buildAudioController();
    addTearDown(controller.dispose);
    final router = GoRouter(
      observers: [AppRouter.homeRouteObserver],
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/capture',
          builder: (context, state) => const Scaffold(body: Text('capture')),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const Scaffold(body: Text('library')),
        ),
        GoRoute(
          path: '/stage/background',
          builder: (context, state) =>
              const Scaffold(body: Text('stage background')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWith(
            (ref) => _FakeCharacterRepository(const []),
          ),
          stageAudioControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('놀이 시작'));
    await tester.pumpAndSettle();

    expect(find.text('capture'), findsOneWidget);
  });

  testWidgets('start stage flow directly when library has characters', (
    WidgetTester tester,
  ) async {
    final controller = _buildAudioController();
    addTearDown(controller.dispose);
    final router = GoRouter(
      observers: [AppRouter.homeRouteObserver],
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/capture',
          builder: (context, state) => const Scaffold(body: Text('capture')),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const Scaffold(body: Text('library')),
        ),
        GoRoute(
          path: '/stage/background',
          builder: (context, state) =>
              const Scaffold(body: Text('stage background')),
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
          stageAudioControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('놀이 시작'));
    await tester.pumpAndSettle();

    expect(find.text('stage background'), findsOneWidget);
  });

  testWidgets('open library from home action', (WidgetTester tester) async {
    final controller = _buildAudioController();
    addTearDown(controller.dispose);
    final router = GoRouter(
      observers: [AppRouter.homeRouteObserver],
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/capture',
          builder: (context, state) => const Scaffold(body: Text('capture')),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const Scaffold(body: Text('library')),
        ),
        GoRoute(
          path: '/stage/background',
          builder: (context, state) =>
              const Scaffold(body: Text('stage background')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWith(
            (ref) => _FakeCharacterRepository(const []),
          ),
          stageAudioControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('내 그림'));
    await tester.pumpAndSettle();

    expect(find.text('library'), findsOneWidget);
  });

  testWidgets('plays home entry voice on first render only once', (
    WidgetTester tester,
  ) async {
    final voicePlayer = FakeStageVoicePlayer();
    final controller = _buildAudioController(voicePlayer: voicePlayer);
    addTearDown(controller.dispose);
    final router = GoRouter(
      observers: [AppRouter.homeRouteObserver],
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/library',
          builder: (context, state) => const Scaffold(body: Text('library')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWith(
            (ref) => _FakeCharacterRepository(const []),
          ),
          stageAudioControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(
      voicePlayer.playedAssets,
      equals(['audio/main/main_entry_voice_01.m4a']),
    );

    await tester.pump();

    expect(
      voicePlayer.playedAssets,
      equals(['audio/main/main_entry_voice_01.m4a']),
    );
  });

  testWidgets('plays next home entry voice when returning from another route', (
    WidgetTester tester,
  ) async {
    final voicePlayer = FakeStageVoicePlayer();
    final controller = _buildAudioController(voicePlayer: voicePlayer);
    addTearDown(controller.dispose);
    final router = GoRouter(
      observers: [AppRouter.homeRouteObserver],
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/library',
          builder: (context, state) => const Scaffold(body: Text('library')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWith(
            (ref) => _FakeCharacterRepository(const []),
          ),
          stageAudioControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 그림'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(
      voicePlayer.playedAssets,
      equals([
        'audio/main/main_entry_voice_01.m4a',
        'audio/main/main_entry_voice_02.m4a',
      ]),
    );
  });
}
