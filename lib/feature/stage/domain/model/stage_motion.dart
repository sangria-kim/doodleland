import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum StageMotionPathType { horizontalPingPong }

enum StageMotionDirection { leftToRight, rightToLeft }

@immutable
class StageMotion {
  const StageMotion({
    this.enabled = true,
    this.pathType = StageMotionPathType.horizontalPingPong,
  });

  final bool enabled;
  final StageMotionPathType pathType;

  StageMotion copyWith({bool? enabled, StageMotionPathType? pathType}) {
    return StageMotion(
      enabled: enabled ?? this.enabled,
      pathType: pathType ?? this.pathType,
    );
  }
}

@immutable
class StageMotionRuntimeState {
  const StageMotionRuntimeState({
    required this.position,
    required this.direction,
    required this.speed,
    required this.isFlippedHorizontally,
    this.isPaused = false,
  });

  static const double minSlowSpeed = 0.1;
  static const double maxSlowSpeed = 0.4;

  final Offset position;
  final StageMotionDirection direction;
  final double speed;
  final bool isFlippedHorizontally;
  final bool isPaused;

  factory StageMotionRuntimeState.initial({
    required Offset position,
    required double speed,
  }) {
    return StageMotionRuntimeState(
      position: position,
      direction: StageMotionDirection.leftToRight,
      speed: speed,
      isFlippedHorizontally: false,
      isPaused: false,
    );
  }

  static double randomSlowSpeed(math.Random random) {
    final range = maxSlowSpeed - minSlowSpeed;
    return minSlowSpeed + random.nextDouble() * range;
  }

  StageMotionRuntimeState copyWith({
    Offset? position,
    StageMotionDirection? direction,
    double? speed,
    bool? isFlippedHorizontally,
    bool? isPaused,
  }) {
    return StageMotionRuntimeState(
      position: position ?? this.position,
      direction: direction ?? this.direction,
      speed: speed ?? this.speed,
      isFlippedHorizontally:
          isFlippedHorizontally ?? this.isFlippedHorizontally,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
