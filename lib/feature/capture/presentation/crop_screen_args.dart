import '../data/drawing_region_detector.dart';

class CropScreenArgs {
  const CropScreenArgs({
    required this.sourceImagePath,
    this.detectionResult = DetectionResult.fallback,
  });

  final String sourceImagePath;
  final DetectionResult detectionResult;
}
