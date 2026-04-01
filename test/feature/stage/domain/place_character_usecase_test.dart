import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/feature/stage/domain/model/motion_preset.dart';
import 'package:doodleland/feature/stage/domain/model/stage_motion.dart';
import 'package:doodleland/feature/stage/domain/place_character_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sets the default and requested ground baseline', () async {
    final useCase = PlaceCharacterUseCase();
    final character = Character(
      id: 1,
      name: 'sample',
      originalImagePath: '/tmp/original.png',
      transparentImagePath: '/tmp/transparent.png',
      thumbnailPath: '/tmp/thumbnail.png',
      width: 32,
      height: 32,
      createdAt: DateTime(2026, 1, 1),
    );

    final defaultPlaced = await useCase.call(
      character: character,
      objectMotion: MotionPreset.floating,
    );

    expect(defaultPlaced.position.dx, equals(0.5));
    expect(defaultPlaced.position.dy, equals(0.8));
    expect(
      defaultPlaced.stageRuntime.direction,
      equals(StageMotionDirection.leftToRight),
    );
    expect(defaultPlaced.stageRuntime.speed, inInclusiveRange(0.1, 0.4));

    final customPlaced = await useCase.call(
      character: character,
      objectMotion: MotionPreset.floating,
      groundY: 0.75,
    );

    expect(customPlaced.position.dx, equals(0.5));
    expect(customPlaced.position.dy, equals(0.75));
    expect(customPlaced.stageRuntime.speed, inInclusiveRange(0.1, 0.4));
  });
}
