import 'dart:ui';

import 'package:doodleland/feature/stage/presentation/stage_viewmodel.dart';
import 'package:doodleland/feature/stage/domain/model/motion_preset.dart';
import 'package:doodleland/feature/stage/domain/model/stage_background.dart';
import 'package:doodleland/feature/stage/domain/model/placed_character.dart';
import 'package:doodleland/feature/stage/domain/place_character_usecase.dart';
import 'package:doodleland/feature/stage/data/scene_repository.dart';
import 'package:doodleland/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('selected background is initialized and can be changed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(stageViewModelProvider).selectedBackground;
    expect(initial.id, equals(defaultStageBackgrounds.first.id));
    expect(initial.groundY, equals(defaultStageBackgrounds.first.groundY));

    final target = defaultStageBackgrounds[3];
    container.read(stageViewModelProvider.notifier).selectBackground(target);
    final updated = container.read(stageViewModelProvider).selectedBackground;

    expect(updated.id, equals(target.id));
    expect(updated.name, equals(target.name));
  });

  test('places character at selected background baseline', () async {
    final fakeUseCase = _FakePlaceCharacterUseCase();
    const selectedBackground = StageBackground(
      id: 'grounded',
      name: 'grounded',
      assetPath: 'assets/backgrounds/forest.png',
      groundY: 0.86,
    );

    final container = ProviderContainer(
      overrides: [
        sceneRepositoryProvider.overrideWith(
          (_) => _FakeStageRepository(selectedBackground),
        ),
        placeCharacterUseCaseProvider.overrideWith(
          (_) => fakeUseCase,
        ),
      ],
    );
    addTearDown(container.dispose);

    final vm = container.read(stageViewModelProvider.notifier);
    final isAdded = await vm.placeCharacter(
      character: Character(
        id: 1,
        name: 'sample',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );

    expect(isAdded, isTrue);
    expect(fakeUseCase.capturedGroundY, equals(selectedBackground.groundY));
    expect(container.read(stageViewModelProvider).placedCharacters.single.position.dy, equals(0.86));
  });

  test('updates character position and clamps to normalized bounds', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final vm = container.read(stageViewModelProvider.notifier);
    await vm.placeCharacter(
      character: Character(
        id: 10,
        name: 'sample',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );

    final targetId = container.read(stageViewModelProvider).placedCharacters.single.instanceId;
    final moved = vm.updateCharacterPosition(
      instanceId: targetId,
      position: const Offset(1.7, -0.2),
    );

    expect(moved, isTrue);
    final updated = container.read(stageViewModelProvider).placedCharacters.single;
    expect(updated.position.dx, equals(1.0));
    expect(updated.position.dy, equals(0.0));
  });

  test('brings character to front by increasing zIndex', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final vm = container.read(stageViewModelProvider.notifier);
    await vm.placeCharacter(
      character: Character(
        id: 11,
        name: 'sample-1',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );
    await vm.placeCharacter(
      character: Character(
        id: 12,
        name: 'sample-2',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );

    final firstId = container.read(stageViewModelProvider).placedCharacters.first.instanceId;
    vm.bringCharacterToFront(firstId);

    final updated = container.read(stageViewModelProvider).placedCharacters;
    final frontCharacter = updated.firstWhere((character) => character.instanceId == firstId);
    expect(frontCharacter.zIndex, equals(2));
  });

  test('removes a character by instanceId', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final vm = container.read(stageViewModelProvider.notifier);
    await vm.placeCharacter(
      character: Character(
        id: 13,
        name: 'sample-1',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );
    await vm.placeCharacter(
      character: Character(
        id: 14,
        name: 'sample-2',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );

    final targetId = container.read(stageViewModelProvider).placedCharacters.first.instanceId;
    final removed = vm.removeCharacter(targetId);
    final remaining = container.read(stageViewModelProvider).placedCharacters;

    expect(removed, isTrue);
    expect(remaining.length, equals(1));
    expect(remaining.any((character) => character.instanceId == targetId), isFalse);
  });

  test('applies tap, drag, and remove transitions for placed characters', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final vm = container.read(stageViewModelProvider.notifier);
    await vm.placeCharacter(
      character: Character(
        id: 15,
        name: 'sample-1',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );
    await vm.placeCharacter(
      character: Character(
        id: 16,
        name: 'sample-2',
        originalImagePath: '/tmp/original.png',
        transparentImagePath: '/tmp/transparent.png',
        thumbnailPath: '/tmp/thumbnail.png',
        width: 32,
        height: 32,
        createdAt: DateTime(2026, 1, 1),
      ),
      motionPreset: MotionPreset.floating,
    );

    final ids = container.read(stageViewModelProvider).placedCharacters.map((item) {
      return item.instanceId;
    }).toList(growable: false);
    final tappedId = ids[0];
    final removedId = ids[1];

    vm.bringCharacterToFront(tappedId);
    expect(
      container
          .read(stageViewModelProvider)
          .placedCharacters
          .firstWhere((character) => character.instanceId == tappedId)
          .zIndex,
      equals(2),
    );

    final moved = vm.updateCharacterPosition(
      instanceId: tappedId,
      position: const Offset(1.9, -0.1),
    );
    expect(moved, isTrue);
    final tappedAfterMove = container
        .read(stageViewModelProvider)
        .placedCharacters
        .firstWhere((character) => character.instanceId == tappedId);
    expect(tappedAfterMove.position.dx, equals(1.0));
    expect(tappedAfterMove.position.dy, equals(0.0));

    final removed = vm.removeCharacter(removedId);
    expect(removed, isTrue);
    final remaining = container.read(stageViewModelProvider).placedCharacters;
    expect(remaining.length, equals(1));
    expect(remaining.first.instanceId, equals(tappedId));
  });
}

class _FakePlaceCharacterUseCase extends PlaceCharacterUseCase {
  double? capturedGroundY;

  @override
  Future<PlacedCharacter> call({
    required Character character,
    required MotionPreset motionPreset,
    double? groundY,
    int? zIndex,
  }) async {
    capturedGroundY = groundY;
    return super.call(
      character: character,
      motionPreset: motionPreset,
      groundY: groundY,
      zIndex: zIndex,
    );
  }
}

class _FakeStageRepository extends SceneRepository {
  _FakeStageRepository(this._background);

  final StageBackground _background;

  @override
  StageBackground get defaultBackground => _background;

  @override
  List<StageBackground> get availableBackgrounds => [_background];
}
