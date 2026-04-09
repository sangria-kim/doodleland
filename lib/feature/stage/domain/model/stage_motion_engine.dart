import 'dart:math' as math;
import 'dart:ui';

import 'stage_motion.dart';

class StageMotionEngine {
  const StageMotionEngine({this.basePixelsPerSecond = 180});

  final double basePixelsPerSecond;

  StageMotionRuntimeState tick({
    required StageMotion motion,
    required StageMotionRuntimeState runtime,
    required Size stageSize,
    required Size objectSize,
    required Duration delta,
  }) {
    if (!motion.enabled || runtime.isPaused || delta <= Duration.zero) {
      return runtime;
    }

    return switch (motion.pathType) {
      StageMotionPathType.horizontalPingPong => _tickHorizontalPingPong(
        runtime: runtime,
        stageSize: stageSize,
        objectSize: objectSize,
        delta: delta,
      ),
      StageMotionPathType.verticalLeafFall => _tickVerticalLeafFall(
        runtime: runtime,
        stageSize: stageSize,
        objectSize: objectSize,
        delta: delta,
      ),
    };
  }

  StageMotionRuntimeState pauseForDrag(StageMotionRuntimeState runtime) {
    return runtime.copyWith(isPaused: true);
  }

  StageMotionRuntimeState applyDragPosition({
    required StageMotionRuntimeState runtime,
    required Offset draggedPosition,
    required Size stageSize,
    required Size objectSize,
  }) {
    return runtime.copyWith(
      position: clampPosition(
        position: draggedPosition,
        stageSize: stageSize,
        objectSize: objectSize,
      ),
    );
  }

  StageMotionRuntimeState resumeFromDrag({
    required StageMotionRuntimeState runtime,
    required Offset droppedPosition,
    required Size stageSize,
    required Size objectSize,
  }) {
    return runtime.copyWith(
      position: clampPosition(
        position: droppedPosition,
        stageSize: stageSize,
        objectSize: objectSize,
      ),
      isPaused: false,
    );
  }

  Offset clampPosition({
    required Offset position,
    required Size stageSize,
    required Size objectSize,
  }) {
    final minX = _minX(stageSize, objectSize);
    final maxX = _maxX(stageSize, objectSize);
    final minY = _minY(stageSize, objectSize);
    final maxY = _maxY(stageSize, objectSize);

    return Offset(position.dx.clamp(minX, maxX), position.dy.clamp(minY, maxY));
  }

  StageMotionRuntimeState _tickHorizontalPingPong({
    required StageMotionRuntimeState runtime,
    required Size stageSize,
    required Size objectSize,
    required Duration delta,
  }) {
    final safeWidth = math.max(stageSize.width, 1.0);
    final deltaSeconds = delta.inMicroseconds / Duration.microsecondsPerSecond;
    final normalizedDeltaX =
        (basePixelsPerSecond * runtime.speed * deltaSeconds) / safeWidth;

    final signedDeltaX = switch (runtime.direction) {
      StageMotionDirection.leftToRight => normalizedDeltaX,
      StageMotionDirection.rightToLeft => -normalizedDeltaX,
    };

    var nextX = runtime.position.dx + signedDeltaX;
    var nextDirection = runtime.direction;

    final minX = _minX(stageSize, objectSize);
    final maxX = _maxX(stageSize, objectSize);

    if (nextX >= maxX) {
      nextX = maxX;
      nextDirection = StageMotionDirection.rightToLeft;
    } else if (nextX <= minX) {
      nextX = minX;
      nextDirection = StageMotionDirection.leftToRight;
    }

    return runtime.copyWith(
      position: Offset(nextX, runtime.position.dy),
      direction: nextDirection,
      isFlippedHorizontally: runtime.isFlippedHorizontally,
    );
  }

  StageMotionRuntimeState _tickVerticalLeafFall({
    required StageMotionRuntimeState runtime,
    required Size stageSize,
    required Size objectSize,
    required Duration delta,
  }) {
    final safeHeight = math.max(stageSize.height, 1.0);
    final deltaSeconds = delta.inMicroseconds / Duration.microsecondsPerSecond;
    final normalizedDeltaY =
        (basePixelsPerSecond * runtime.speed * deltaSeconds) / safeHeight;
    final minY = _minLeafFallY(stageSize, objectSize);
    final maxY = _maxLeafFallY(stageSize, objectSize);
    final travelHeight = (maxY - minY).clamp(0.0001, 10.0);

    final rawY = runtime.position.dy + normalizedDeltaY;
    if (rawY >= maxY) {
      final overflowY = (rawY - maxY) % travelHeight;
      final nextY = minY + overflowY;
      return runtime.copyWith(
        position: Offset(runtime.position.dx, nextY),
        isFlippedHorizontally: runtime.isFlippedHorizontally,
      );
    }

    return runtime.copyWith(
      position: Offset(runtime.position.dx, rawY),
      isFlippedHorizontally: runtime.isFlippedHorizontally,
    );
  }

  double _minLeafFallY(Size stageSize, Size objectSize) {
    final safeHeight = math.max(stageSize.height, 1.0);
    final normalizedHalfHeight = (objectSize.height / safeHeight) / 2;
    return -(normalizedHalfHeight * 0.9);
  }

  double _maxLeafFallY(Size stageSize, Size objectSize) {
    final safeHeight = math.max(stageSize.height, 1.0);
    final normalizedHalfHeight = (objectSize.height / safeHeight) / 2;
    return 1 + (normalizedHalfHeight * 2.0);
  }

  double _minX(Size stageSize, Size objectSize) {
    final safeWidth = math.max(stageSize.width, 1.0);
    final objectWidth = objectSize.width.clamp(0.0, safeWidth);
    final movableWidth = safeWidth - objectWidth;
    if (movableWidth <= 0) {
      return 0.0;
    }

    final overflowRatio = objectWidth / (2 * movableWidth);
    return -overflowRatio;
  }

  double _maxX(Size stageSize, Size objectSize) {
    final safeWidth = math.max(stageSize.width, 1.0);
    final objectWidth = objectSize.width.clamp(0.0, safeWidth);
    final movableWidth = safeWidth - objectWidth;
    if (movableWidth <= 0) {
      return 1.0;
    }

    final overflowRatio = objectWidth / (2 * movableWidth);
    return 1 + overflowRatio;
  }

  double _minY(Size stageSize, Size objectSize) {
    final halfHeight = objectSize.height / 2;
    final safeHeight = math.max(stageSize.height, 1.0);
    final normalizedHalfHeight = halfHeight / safeHeight;
    return normalizedHalfHeight.clamp(0.0, 1.0);
  }

  double _maxY(Size stageSize, Size objectSize) {
    final min = _minY(stageSize, objectSize);
    return (1 - min).clamp(min, 1.0);
  }
}
