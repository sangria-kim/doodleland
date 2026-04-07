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
        placeCharacterUseCaseProvider.overrideWith((_) => fakeUseCase),
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
      objectMotion: MotionPreset.floating,
    );

    expect(isAdded, isTrue);
    expect(fakeUseCase.capturedGroundY, equals(selectedBackground.groundY));
    expect(
      container
          .read(stageViewModelProvider)
          .placedCharacters
          .single
          .position
          .dy,
      equals(0.86),
    );
  });

  test('passes incremental zIndex when placing multiple characters', () async {
    final fakeUseCase = _FakePlaceCharacterUseCase();
    final container = ProviderContainer(
      overrides: [
        placeCharacterUseCaseProvider.overrideWith((_) => fakeUseCase),
      ],
    );
    addTearDown(container.dispose);

    final vm = container.read(stageViewModelProvider.notifier);
    await vm.placeCharacter(
      character: _buildCharacter(id: 21, name: 'first'),
      objectMotion: MotionPreset.floating,
    );
    await vm.placeCharacter(
      character: _buildCharacter(id: 22, name: 'second'),
      objectMotion: MotionPreset.bouncing,
    );

    expect(fakeUseCase.capturedZIndexes, equals([0, 1]));
    expect(
      container
          .read(stageViewModelProvider)
          .placedCharacters
          .map((character) => character.zIndex)
          .toList(),
      equals([0, 1]),
    );
  });

  test('rejects adding an eleventh character when stage is full', () async {
    final fakeUseCase = _FakePlaceCharacterUseCase();
    final container = ProviderContainer(
      overrides: [
        placeCharacterUseCaseProvider.overrideWith((_) => fakeUseCase),
      ],
    );
    addTearDown(container.dispose);

    final vm = container.read(stageViewModelProvider.notifier);
    for (var index = 0; index < 10; index += 1) {
      final isAdded = await vm.placeCharacter(
        character: _buildCharacter(id: 100 + index, name: 'character-$index'),
        objectMotion: MotionPreset.floating,
      );
      expect(isAdded, isTrue);
    }

    final overflowAdded = await vm.placeCharacter(
      character: _buildCharacter(id: 999, name: 'overflow'),
      objectMotion: MotionPreset.rolling,
    );

    expect(overflowAdded, isFalse);
    expect(fakeUseCase.callCount, equals(10));
    expect(
      container.read(stageViewModelProvider).placedCharacters,
      hasLength(10),
    );
    expect(
      container.read(stageViewModelProvider).errorMessage,
      equals('무대가 꽉 찼어요!'),
    );
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
      objectMotion: MotionPreset.floating,
    );

    final targetId = container
        .read(stageViewModelProvider)
        .placedCharacters
        .single
        .instanceId;
    final moved = vm.updateCharacterPosition(
      instanceId: targetId,
      position: const Offset(1.7, -0.2),
    );

    expect(moved, isTrue);
    final updated = container
        .read(stageViewModelProvider)
        .placedCharacters
        .single;
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
      objectMotion: MotionPreset.floating,
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
      objectMotion: MotionPreset.floating,
    );

    final firstId = container
        .read(stageViewModelProvider)
        .placedCharacters
        .first
        .instanceId;
    vm.bringCharacterToFront(firstId);

    final updated = container.read(stageViewModelProvider).placedCharacters;
    final frontCharacter = updated.firstWhere(
      (character) => character.instanceId == firstId,
    );
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
      objectMotion: MotionPreset.floating,
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
      objectMotion: MotionPreset.floating,
    );

    final targetId = container
        .read(stageViewModelProvider)
        .placedCharacters
        .first
        .instanceId;
    final removed = vm.removeCharacter(targetId);
    final remaining = container.read(stageViewModelProvider).placedCharacters;

    expect(removed, isTrue);
    expect(remaining.length, equals(1));
    expect(
      remaining.any((character) => character.instanceId == targetId),
      isFalse,
    );
  });

  test(
    'marks character as removing and ignores duplicate remove requests',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final vm = container.read(stageViewModelProvider.notifier);
      await vm.placeCharacter(
        character: Character(
          id: 17,
          name: 'sample-remove',
          originalImagePath: '/tmp/original.png',
          transparentImagePath: '/tmp/transparent.png',
          thumbnailPath: '/tmp/thumbnail.png',
          width: 32,
          height: 32,
          createdAt: DateTime(2026, 1, 1),
        ),
        objectMotion: MotionPreset.floating,
      );

      final targetId = container
          .read(stageViewModelProvider)
          .placedCharacters
          .single
          .instanceId;
      final started = vm.requestCharacterRemoval(targetId);
      final startedAgain = vm.requestCharacterRemoval(targetId);
      final stateAfterRequest = container.read(stageViewModelProvider);
      final targetAfterRequest = stateAfterRequest.placedCharacters.singleWhere(
        (character) => character.instanceId == targetId,
      );

      expect(started, isTrue);
      expect(startedAgain, isFalse);
      expect(
        targetAfterRequest.removalState,
        equals(PlacedCharacterRemovalState.removing),
      );
      expect(targetAfterRequest.stageRuntime.isPaused, isTrue);

      final movedWhileRemoving = vm.updateCharacterPosition(
        instanceId: targetId,
        position: const Offset(0.2, 0.2),
      );
      expect(movedWhileRemoving, isFalse);
    },
  );

  test(
    'removes character only when remove animation completion is committed',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final vm = container.read(stageViewModelProvider.notifier);
      await vm.placeCharacter(
        character: Character(
          id: 18,
          name: 'sample-complete-remove',
          originalImagePath: '/tmp/original.png',
          transparentImagePath: '/tmp/transparent.png',
          thumbnailPath: '/tmp/thumbnail.png',
          width: 32,
          height: 32,
          createdAt: DateTime(2026, 1, 1),
        ),
        objectMotion: MotionPreset.floating,
      );

      final targetId = container
          .read(stageViewModelProvider)
          .placedCharacters
          .single
          .instanceId;
      final started = vm.requestCharacterRemoval(targetId);
      final stillOnStage = container
          .read(stageViewModelProvider)
          .placedCharacters
          .any((character) => character.instanceId == targetId);
      final completed = vm.completeCharacterRemoval(targetId);
      final existsAfterCompletion = container
          .read(stageViewModelProvider)
          .placedCharacters
          .any((character) => character.instanceId == targetId);

      expect(started, isTrue);
      expect(stillOnStage, isTrue);
      expect(completed, isTrue);
      expect(existsAfterCompletion, isFalse);
    },
  );

  test(
    'applies tap, drag, and remove transitions for placed characters',
    () async {
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
        objectMotion: MotionPreset.floating,
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
        objectMotion: MotionPreset.floating,
      );

      final ids = container
          .read(stageViewModelProvider)
          .placedCharacters
          .map((item) {
            return item.instanceId;
          })
          .toList(growable: false);
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
    },
  );
}

class _FakePlaceCharacterUseCase extends PlaceCharacterUseCase {
  double? capturedGroundY;
  final List<int> capturedZIndexes = [];
  int callCount = 0;

  @override
  Future<PlacedCharacter> call({
    required Character character,
    required MotionPreset objectMotion,
    double? groundY,
    int? zIndex,
  }) async {
    callCount += 1;
    capturedGroundY = groundY;
    if (zIndex != null) {
      capturedZIndexes.add(zIndex);
    }
    return super.call(
      character: character,
      objectMotion: objectMotion,
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

Character _buildCharacter({required int id, required String name}) {
  return Character(
    id: id,
    name: name,
    originalImagePath: '/tmp/original.png',
    transparentImagePath: '/tmp/transparent.png',
    thumbnailPath: '/tmp/thumbnail.png',
    width: 32,
    height: 32,
    createdAt: DateTime(2026, 1, 1),
  );
}
