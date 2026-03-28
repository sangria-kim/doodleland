import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'motion_preset.dart';
import 'touch_preset.dart';

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
    required this.motionPreset,
    required this.touchPreset,
    required this.position,
    required this.scale,
    required this.zIndex,
  });

  final String instanceId;
  final int characterId;
  final String characterName;
  final String transparentImagePath;
  final String thumbnailPath;
  final int sourceWidth;
  final int sourceHeight;
  final MotionPreset motionPreset;
  final TouchPreset touchPreset;
  final Offset position;
  final double scale;
  final int zIndex;

  PlacedCharacter copyWith({
    String? instanceId,
    int? characterId,
    String? characterName,
    String? transparentImagePath,
    String? thumbnailPath,
    int? sourceWidth,
    int? sourceHeight,
    MotionPreset? motionPreset,
    TouchPreset? touchPreset,
    Offset? position,
    double? scale,
    int? zIndex,
  }) {
    return PlacedCharacter(
      instanceId: instanceId ?? this.instanceId,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      transparentImagePath: transparentImagePath ?? this.transparentImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      sourceWidth: sourceWidth ?? this.sourceWidth,
      sourceHeight: sourceHeight ?? this.sourceHeight,
      motionPreset: motionPreset ?? this.motionPreset,
      touchPreset: touchPreset ?? this.touchPreset,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}
