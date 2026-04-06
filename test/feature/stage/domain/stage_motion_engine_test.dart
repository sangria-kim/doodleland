import 'dart:ui';

import 'package:doodleland/feature/stage/domain/model/stage_motion.dart';
import 'package:doodleland/feature/stage/domain/model/stage_motion_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = StageMotionEngine(basePixelsPerSecond: 300);
  const stageMotion = StageMotion();
  const stageSize = Size(1000, 500);
  const objectSize = Size(100, 100);

  StageMotionRuntimeState buildRuntime({
    required double x,
    required double y,
    required StageMotionDirection direction,
    required bool flipped,
    required bool paused,
    double speed = 0.5,
  }) {
    return StageMotionRuntimeState(
      position: Offset(x, y),
      direction: direction,
      speed: speed,
      isFlippedHorizontally: flipped,
      isPaused: paused,
    );
  }

  test('moves to right first and turns to left after half-out boundary', () {
    final runtime = buildRuntime(
      x: 1.0,
      y: 0.7,
      direction: StageMotionDirection.leftToRight,
      flipped: false,
      paused: false,
      speed: 0.6,
    );

    final next = engine.tick(
      motion: stageMotion,
      runtime: runtime,
      stageSize: stageSize,
      objectSize: objectSize,
      delta: const Duration(seconds: 1),
    );

    expect(next.position.dx, closeTo(1.0555, 0.001));
    expect(next.direction, equals(StageMotionDirection.rightToLeft));
    expect(next.isFlippedHorizontally, isFalse);
  });

  test('turns to right after half-out boundary on the left edge', () {
    final runtime = buildRuntime(
      x: 0.0,
      y: 0.7,
      direction: StageMotionDirection.rightToLeft,
      flipped: false,
      paused: false,
      speed: 0.6,
    );

    final next = engine.tick(
      motion: stageMotion,
      runtime: runtime,
      stageSize: stageSize,
      objectSize: objectSize,
      delta: const Duration(seconds: 1),
    );

    expect(next.position.dx, closeTo(-0.0555, 0.001));
    expect(next.direction, equals(StageMotionDirection.leftToRight));
    expect(next.isFlippedHorizontally, isFalse);
  });

  test('stops auto movement while paused for drag', () {
    final runtime = buildRuntime(
      x: 0.5,
      y: 0.5,
      direction: StageMotionDirection.leftToRight,
      flipped: false,
      paused: false,
      speed: 0.4,
    );
    final paused = engine.pauseForDrag(runtime);
    final afterTick = engine.tick(
      motion: stageMotion,
      runtime: paused,
      stageSize: stageSize,
      objectSize: objectSize,
      delta: const Duration(seconds: 1),
    );

    expect(afterTick.position, equals(paused.position));
    expect(afterTick.direction, equals(paused.direction));
    expect(afterTick.isPaused, isTrue);
  });

  test(
    'resumes from dropped position, keeps direction speed and flip',
    () {
      final runtime = buildRuntime(
        x: 0.8,
        y: 0.6,
        direction: StageMotionDirection.rightToLeft,
        flipped: true,
        paused: true,
        speed: 0.37,
      );

      final resumed = engine.resumeFromDrag(
        runtime: runtime,
        droppedPosition: const Offset(0.45, 0.4),
        stageSize: stageSize,
        objectSize: objectSize,
      );

      expect(resumed.position, equals(const Offset(0.45, 0.4)));
      expect(resumed.direction, equals(StageMotionDirection.rightToLeft));
      expect(resumed.isFlippedHorizontally, isTrue);
      expect(resumed.speed, equals(0.37));
      expect(resumed.isPaused, isFalse);
    },
  );
}
