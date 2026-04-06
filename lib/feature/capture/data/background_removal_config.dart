class BackgroundRemovalConfig {
  const BackgroundRemovalConfig({
    this.maxProcessingDimension = 1500,
    this.weakThresholdOffset = 2,
    this.strongThresholdOffset = 34,
    this.strokeDilateRadius = 1,
    this.strokeCloseRadius = 1,
    this.smallComponentBasePixels = 20,
    this.smallComponentRatio = 0.00024,
    this.maxRecoveryRatio = 0.012,
    this.recoveryMinComponentPixels = 4,
    this.recoveryMaxComponentRatio = 0.008,
    this.recoveryMinSupportRatio = 0.35,
    this.recoveryMinLuminanceVariance = 18.0,
    this.outlineInkMinDarknessDelta = 30,
    this.outlineInkMaxSaturation = 88,
    this.outlineBarrierCloseRadius = 2,
    this.outlineModeMinCoverage = 0.008,
    this.outlineModeMinInteriorRatio = 0.02,
    this.outlineModeMaxInteriorRatio = 0.82,
  });

  final int maxProcessingDimension;
  final int weakThresholdOffset;
  final int strongThresholdOffset;
  final int strokeDilateRadius;
  final int strokeCloseRadius;
  final int smallComponentBasePixels;
  final double smallComponentRatio;
  final double maxRecoveryRatio;
  final int recoveryMinComponentPixels;
  final double recoveryMaxComponentRatio;
  final double recoveryMinSupportRatio;
  final double recoveryMinLuminanceVariance;
  final int outlineInkMinDarknessDelta;
  final int outlineInkMaxSaturation;
  final int outlineBarrierCloseRadius;
  final double outlineModeMinCoverage;
  final double outlineModeMinInteriorRatio;
  final double outlineModeMaxInteriorRatio;
}

const BackgroundRemovalConfig defaultBackgroundRemovalConfig =
    BackgroundRemovalConfig();

const bool debugBackgroundRemoval = bool.fromEnvironment(
  'DEBUG_BG_REMOVAL',
  defaultValue: true,
);
