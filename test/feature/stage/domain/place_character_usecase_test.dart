import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/feature/stage/domain/model/motion_preset.dart';
import 'package:doodleland/feature/stage/domain/place_character_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sets the default and requested ground baseline', () async {
    final useCase = const PlaceCharacterUseCase();
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
      motionPreset: MotionPreset.floating,
    );

    expect(defaultPlaced.position.dx, equals(0.5));
    expect(defaultPlaced.position.dy, equals(0.8));

    final customPlaced = await useCase.call(
      character: character,
      motionPreset: MotionPreset.floating,
      groundY: 0.75,
    );

    expect(customPlaced.position.dx, equals(0.5));
    expect(customPlaced.position.dy, equals(0.75));
  });
}
