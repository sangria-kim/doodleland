import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import 'model/motion_preset.dart';
import 'model/placed_character.dart';
import 'model/touch_preset.dart';

class PlaceCharacterUseCase {
  const PlaceCharacterUseCase();

  Future<PlacedCharacter> call({
    required Character character,
    required MotionPreset motionPreset,
    double? groundY,
    int? zIndex,
  }) async {
    final normalizedGroundY = groundY ?? 0.8;
    return PlacedCharacter(
      instanceId: '${DateTime.now().microsecondsSinceEpoch}-${character.id}',
      characterId: character.id,
      characterName: character.name,
      transparentImagePath: character.transparentImagePath,
      thumbnailPath: character.thumbnailPath,
      sourceWidth: character.width,
      sourceHeight: character.height,
      motionPreset: motionPreset,
      touchPreset: TouchPreset.defaultBounce,
      position: Offset(0.5, normalizedGroundY.clamp(0.0, 1.0)),
      scale: 1.0,
      zIndex: zIndex ?? 0,
    );
  }
}

final placeCharacterUseCaseProvider = Provider<PlaceCharacterUseCase>(
  (ref) => const PlaceCharacterUseCase(),
);
