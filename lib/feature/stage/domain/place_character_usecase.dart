import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import 'model/motion_preset.dart';
import 'model/placed_character.dart';
import 'model/stage_motion.dart';
import 'model/touch_preset.dart';

class PlaceCharacterUseCase {
  PlaceCharacterUseCase();

  static final math.Random _random = math.Random();

  Future<PlacedCharacter> call({
    required Character character,
    required MotionPreset objectMotion,
    double? groundY,
    int? zIndex,
  }) async {
    final normalizedGroundY = groundY ?? 0.8;
    final initialPosition = Offset(0.5, normalizedGroundY.clamp(0.0, 1.0));
    final initialSpeed = StageMotionRuntimeState.randomSlowSpeed(_random);

    return PlacedCharacter(
      instanceId: '${DateTime.now().microsecondsSinceEpoch}-${character.id}',
      characterId: character.id,
      characterName: character.name,
      transparentImagePath: character.transparentImagePath,
      thumbnailPath: character.thumbnailPath,
      sourceWidth: character.width,
      sourceHeight: character.height,
      objectMotion: objectMotion,
      stageMotion: const StageMotion(),
      stageRuntime: StageMotionRuntimeState.initial(
        position: initialPosition,
        speed: initialSpeed,
      ),
      touchPreset: TouchPreset.defaultBounce,
      scale: 1.0,
      zIndex: zIndex ?? 0,
    );
  }
}

final placeCharacterUseCaseProvider = Provider<PlaceCharacterUseCase>(
  (ref) => PlaceCharacterUseCase(),
);
