class BackgroundRemovalConfig {
  const BackgroundRemovalConfig({
    this.maxProcessingDimension = 1500,
    this.weakThresholdOffset = -8,
    this.strongThresholdOffset = 18,
    this.strokeDilateRadius = 1,
    this.strokeCloseRadius = 1,
    this.smallComponentBasePixels = 10,
    this.smallComponentRatio = 0.00012,
  });

  final int maxProcessingDimension;
  final int weakThresholdOffset;
  final int strongThresholdOffset;
  final int strokeDilateRadius;
  final int strokeCloseRadius;
  final int smallComponentBasePixels;
  final double smallComponentRatio;
}

const BackgroundRemovalConfig defaultBackgroundRemovalConfig =
    BackgroundRemovalConfig();

const bool debugBackgroundRemoval = bool.fromEnvironment(
  'DEBUG_BG_REMOVAL',
  defaultValue: true,
);
