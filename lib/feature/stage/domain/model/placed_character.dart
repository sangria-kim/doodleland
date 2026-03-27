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
  final MotionPreset motionPreset;
  final TouchPreset touchPreset;
  final Offset position;
  final double scale;
  final int zIndex;
}
