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
    final initialPosition = _initialPositionForMotion(
      objectMotion: objectMotion,
      normalizedGroundY: normalizedGroundY,
    );
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
      stageMotion: _stageMotionFor(objectMotion),
      stageRuntime: StageMotionRuntimeState.initial(
        position: initialPosition,
        speed: initialSpeed,
      ),
      touchPreset: TouchPreset.defaultBounce,
      scale: 1.0,
      zIndex: zIndex ?? 0,
    );
  }

  StageMotion _stageMotionFor(MotionPreset objectMotion) {
    return switch (objectMotion) {
      MotionPreset.fluttering => const StageMotion(
        pathType: StageMotionPathType.verticalLeafFall,
      ),
      _ => const StageMotion(),
    };
  }

  Offset _initialPositionForMotion({
    required MotionPreset objectMotion,
    required double normalizedGroundY,
  }) {
    return switch (objectMotion) {
      MotionPreset.fluttering => Offset(
        0.1 + _random.nextDouble() * 0.8,
        -0.08,
      ),
      _ => Offset(0.5, normalizedGroundY.clamp(0.0, 1.0)),
    };
  }
}

final placeCharacterUseCaseProvider = Provider<PlaceCharacterUseCase>(
  (ref) => PlaceCharacterUseCase(),
);
