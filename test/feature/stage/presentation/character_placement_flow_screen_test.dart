import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/core/presentation/character_thumbnail_card.dart';
import 'package:doodleland/feature/library/data/character_repository.dart';
import 'package:doodleland/feature/stage/domain/model/motion_preset.dart';
import 'package:doodleland/feature/stage/presentation/character_placement_flow_screen.dart';
import 'package:doodleland/feature/stage/presentation/character_placement_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _character = Character(
  id: 1,
  name: '테스트 그림',
  originalImagePath: '',
  transparentImagePath: '',
  thumbnailPath: '',
  width: 32,
  height: 32,
  createdAt: DateTime(2026),
);

class _Repository implements CharacterRepository {
  @override
  Future<List<Character>> getCharacters() async => [_character];
  @override
  Future<bool> removeCharacter(int id) async => true;
  @override
  Future<int> saveCharacter({
    required String name,
    required String originalImagePath,
    required String transparentImagePath,
    required String thumbnailPath,
    required int width,
    required int height,
  }) async => throw UnimplementedError();
}

void main() {
  Future<void> openFlow(
    WidgetTester tester,
    ValueChanged<CharacterPlacementSelection?> onResult,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () async => onResult(
                await context.push<CharacterPlacementSelection>('/placement'),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/placement',
          builder: (context, state) => const CharacterPlacementFlowScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final motion in MotionPreset.values) {
    testWidgets('returns selected character with ${motion.name}', (
      tester,
    ) async {
      CharacterPlacementSelection? result;
      await openFlow(tester, (value) => result = value);
      await tester.tap(find.byType(CharacterThumbnailCard));
      await tester.pump();
      await tester.tap(find.text('다음: 움직임 고르기'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(motion.label));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('등장하기'));
      await tester.pumpAndSettle();
      expect(result?.character, _character);
      expect(result?.objectMotion, motion);
    });
  }

  testWidgets(
    'back from motion returns to selection and cancel returns no result',
    (tester) async {
      var returned = false;
      CharacterPlacementSelection? result;
      await openFlow(tester, (value) {
        returned = true;
        result = value;
      });
      await tester.tap(find.byType(CharacterThumbnailCard));
      await tester.pump();
      await tester.tap(find.text('다음: 움직임 고르기'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('뒤로 가기'));
      await tester.pumpAndSettle();
      expect(returned, isFalse);
      expect(find.text('다음: 움직임 고르기'), findsOneWidget);
      await tester.tap(find.byTooltip('뒤로 가기'));
      await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(result, isNull);
    },
  );
}
