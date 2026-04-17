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

double _expectedHomeButtonHeight(double screenHeight) {
  return screenHeight * 0.20;
}

double _expectedHomeButtonWidth(double screenWidth) {
  return screenWidth.clamp(0.0, 1080.0) * 0.25;
}

double _expectedHomeButtonGap(double screenWidth) {
  return screenWidth * 0.02;
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

  testWidgets('home menus are arranged in one responsive row', (
    WidgetTester tester,
  ) async {
    final controller = _buildAudioController();
    addTearDown(controller.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const screenSize = Size(1200, 1600);
    await tester.binding.setSurfaceSize(screenSize);

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

    final menuButtons = find.byType(InkWell);
    expect(menuButtons, findsNWidgets(3));

    final menuRenderBoxes = menuButtons
        .evaluate()
        .map((e) => e.renderObject as RenderBox)
        .toList();
    final expectedHeight = _expectedHomeButtonHeight(screenSize.height);
    final expectedWidth = _expectedHomeButtonWidth(screenSize.width);
    final expectedGap = _expectedHomeButtonGap(screenSize.width);

    for (final renderBox in menuRenderBoxes) {
      expect(renderBox.size.height, closeTo(expectedHeight, 1.0));
      expect(renderBox.size.width, closeTo(expectedWidth, 1.0));
    }

    final yPositions = menuRenderBoxes
        .map((renderBox) => renderBox.localToGlobal(Offset.zero).dy)
        .toList();
    final xPositions = menuRenderBoxes
        .map((renderBox) => renderBox.localToGlobal(Offset.zero).dx)
        .toList();

    expect((yPositions[0] - yPositions[1]).abs(), lessThan(1.0));
    expect((yPositions[0] - yPositions[2]).abs(), lessThan(1.0));
    expect(xPositions[0] < xPositions[1], isTrue);
    expect(xPositions[1] < xPositions[2], isTrue);
    expect((xPositions[1] - xPositions[0] - expectedWidth).abs(), closeTo(expectedGap, 1.0));
    expect((xPositions[2] - xPositions[1] - expectedWidth).abs(), closeTo(expectedGap, 1.0));
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
