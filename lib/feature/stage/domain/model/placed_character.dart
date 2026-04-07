import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'motion_preset.dart';
import 'stage_motion.dart';
import 'touch_preset.dart';

enum PlacedCharacterRemovalState { normal, removing }

@immutable
class PlacedCharacter {
  const PlacedCharacter({
    required this.instanceId,
    required this.characterId,
    required this.characterName,
    required this.transparentImagePath,
    required this.thumbnailPath,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.objectMotion,
    required this.stageMotion,
    required this.stageRuntime,
    required this.touchPreset,
    required this.scale,
    required this.zIndex,
    this.removalState = PlacedCharacterRemovalState.normal,
  });

  final String instanceId;
  final int characterId;
  final String characterName;
  final String transparentImagePath;
  final String thumbnailPath;
  final int sourceWidth;
  final int sourceHeight;
  final MotionPreset objectMotion;
  final StageMotion stageMotion;
  final StageMotionRuntimeState stageRuntime;
  final TouchPreset touchPreset;
  final double scale;
  final int zIndex;
  final PlacedCharacterRemovalState removalState;

  Offset get position => stageRuntime.position;
  bool get isFlippedHorizontally => stageRuntime.isFlippedHorizontally;

  PlacedCharacter copyWith({
    String? instanceId,
    int? characterId,
    String? characterName,
    String? transparentImagePath,
    String? thumbnailPath,
    int? sourceWidth,
    int? sourceHeight,
    MotionPreset? objectMotion,
    StageMotion? stageMotion,
    StageMotionRuntimeState? stageRuntime,
    TouchPreset? touchPreset,
    double? scale,
    int? zIndex,
    PlacedCharacterRemovalState? removalState,
  }) {
    return PlacedCharacter(
      instanceId: instanceId ?? this.instanceId,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      transparentImagePath: transparentImagePath ?? this.transparentImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      sourceWidth: sourceWidth ?? this.sourceWidth,
      sourceHeight: sourceHeight ?? this.sourceHeight,
      objectMotion: objectMotion ?? this.objectMotion,
      stageMotion: stageMotion ?? this.stageMotion,
      stageRuntime: stageRuntime ?? this.stageRuntime,
      touchPreset: touchPreset ?? this.touchPreset,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
      removalState: removalState ?? this.removalState,
    );
  }
}
