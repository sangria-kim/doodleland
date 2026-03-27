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
