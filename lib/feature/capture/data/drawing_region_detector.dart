import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

class DetectionResult {
  const DetectionResult({
    required this.detected,
    required this.boundingBox,
    required this.confidence,
    this.debugData,
  });

  final bool detected;
  final Rect boundingBox;
  final double confidence;
  final Map<String, Object?>? debugData;

  static const DetectionResult fallback = DetectionResult(
    detected: false,
    boundingBox: Rect.fromLTWH(0, 0, 1, 1),
    confidence: 0,
  );
}

abstract class DrawingRegionDetector {
  Future<DetectionResult> detect(Uint8List inputImageBytes);
}

class RuleBasedDrawingRegionDetector implements DrawingRegionDetector {
  const RuleBasedDrawingRegionDetector({this.maxProcessingDimension = 1500});

  final int maxProcessingDimension;

  @override
  Future<DetectionResult> detect(Uint8List inputImageBytes) async {
    if (inputImageBytes.isEmpty) {
      return DetectionResult.fallback;
    }

    final detection = await Isolate.run(
      () => _detectInIsolate(
        inputImageBytes: inputImageBytes,
        maxProcessingDimension: maxProcessingDimension,
      ),
    );

    if (kDebugMode) {
      debugPrint(
        '[capture] detector=RuleBasedDrawingRegionDetector '
        'detected=${detection.detected} confidence=${detection.confidence.toStringAsFixed(2)}',
      );
    }

    return detection;
  }
}

class _PaperProfile {
  const _PaperProfile({
    required this.r,
    required this.g,
    required this.b,
    required this.luminance,
    required this.distanceTolerance,
  });

  final int r;
  final int g;
  final int b;
  final int luminance;
  final int distanceTolerance;
}

class _EdgeSample {
  const _EdgeSample({
    required this.r,
    required this.g,
    required this.b,
    required this.luminance,
    required this.saturation,
  });

  final int r;
  final int g;
  final int b;
  final int luminance;
  final int saturation;
}

class _ForegroundScoreMap {
  const _ForegroundScoreMap({
    required this.scores,
    required this.paperDistances,
    required this.otsuThreshold,
  });

  final Uint8List scores;
  final Uint8List paperDistances;
  final int otsuThreshold;
}

DetectionResult _detectInIsolate({
  required Uint8List inputImageBytes,
  required int maxProcessingDimension,
}) {
  final source = img.decodeImage(inputImageBytes);
  if (source == null) {
    return DetectionResult.fallback;
  }

  final processed = _resizeForProcessing(source, maxProcessingDimension);
  final paper = _samplePaperProfile(processed);
  final scoreMap = _buildForegroundScoreMap(processed, paper: paper);
  final weakThreshold = max(12, (scoreMap.otsuThreshold - 8).clamp(0, 255));
  final strongThreshold = max(
    weakThreshold + 1,
    (scoreMap.otsuThreshold + 18).clamp(0, 255),
  );

  final strongMask = _buildThresholdMask(scoreMap.scores, strongThreshold);
  final weakMask = _buildThresholdMask(scoreMap.scores, weakThreshold);
  final strokeMask = _closeMask(
    _dilateMask(strongMask, processed.width, processed.height, radius: 1),
    processed.width,
    processed.height,
    radius: 1,
  );
  final floodfillMask = _floodFillBackground(
    processed,
    strokeBarrierMask: strokeMask,
    scores: scoreMap.scores,
    paperDistances: scoreMap.paperDistances,
    weakThreshold: weakThreshold,
    strongThreshold: strongThreshold,
    paper: paper,
  );
  final foregroundSeedMask = List<bool>.generate(
    weakMask.length,
    (index) => weakMask[index] && !floodfillMask[index],
    growable: false,
  );
  final foregroundMask = _removeSmallComponents(
    processed.width,
    processed.height,
    foregroundSeedMask,
  );

  final bounds = _findForegroundBounds(
    foregroundMask,
    processed.width,
    processed.height,
  );

  if (!bounds.hasForeground) {
    return DetectionResult(
      detected: false,
      boundingBox: const Rect.fromLTWH(0, 0, 1, 1),
      confidence: 0,
      debugData: kDebugMode
          ? <String, Object?>{
              'reason': 'foreground_not_found',
              'otsuThreshold': scoreMap.otsuThreshold,
            }
          : null,
    );
  }

  final marginX = max(1, (processed.width * 0.02).round());
  final marginY = max(1, (processed.height * 0.02).round());
  final minX = max(0, bounds.minX - marginX);
  final minY = max(0, bounds.minY - marginY);
  final maxX = min(processed.width - 1, bounds.maxX + marginX);
  final maxY = min(processed.height - 1, bounds.maxY + marginY);

  final normalized = Rect.fromLTRB(
    minX / processed.width,
    minY / processed.height,
    (maxX + 1) / processed.width,
    (maxY + 1) / processed.height,
  );
  final normalizedArea =
      (normalized.width.clamp(0, 1) * normalized.height.clamp(0, 1)).toDouble();
  final confidence = normalizedArea.clamp(0.2, 0.98);

  return DetectionResult(
    detected: true,
    boundingBox: normalized,
    confidence: confidence,
    debugData: kDebugMode
        ? <String, Object?>{
            'otsuThreshold': scoreMap.otsuThreshold,
            'weakThreshold': weakThreshold,
            'strongThreshold': strongThreshold,
            'normalizedBoundingBox': {
              'left': normalized.left,
              'top': normalized.top,
              'right': normalized.right,
              'bottom': normalized.bottom,
            },
          }
        : null,
  );
}

img.Image _resizeForProcessing(img.Image source, int maxDimension) {
  final maxSide = max(source.width, source.height);
  if (maxSide <= maxDimension) {
    return source;
  }
  final scale = maxDimension / maxSide;
  final width = max(1, (source.width * scale).round());
  final height = max(1, (source.height * scale).round());
  return img.copyResize(
    source,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );
}

_PaperProfile _samplePaperProfile(img.Image image) {
  final width = image.width;
  final height = image.height;
  final step = max(1, max(width, height) ~/ 28);
  final samples = <_EdgeSample>[];

  void sample(int x, int y) {
    final pixel = image.getPixel(x, y);
    final r = pixel.r.round();
    final g = pixel.g.round();
    final b = pixel.b.round();
    final luminance = ((r + g + b) / 3).round();
    final saturation = (max(r, max(g, b)) - min(r, min(g, b))).toInt();
    samples.add(
      _EdgeSample(
        r: r,
        g: g,
        b: b,
        luminance: luminance,
        saturation: saturation,
      ),
    );
  }

  for (var x = 0; x < width; x += step) {
    sample(x, 0);
    sample(x, height - 1);
  }
  for (var y = 0; y < height; y += step) {
    sample(0, y);
    sample(width - 1, y);
  }

  if (samples.isEmpty) {
    final pixel = image.getPixel(0, 0);
    return _PaperProfile(
      r: pixel.r.round(),
      g: pixel.g.round(),
      b: pixel.b.round(),
      luminance: ((pixel.r + pixel.g + pixel.b) / 3).round(),
      distanceTolerance: 32,
    );
  }

  final sortedLuminance = samples.map((sample) => sample.luminance).toList()
    ..sort();
  final cutoff = sortedLuminance[((sortedLuminance.length - 1) * 0.65).round()];
  final brightCandidates = samples
      .where((sample) => sample.luminance >= cutoff && sample.saturation <= 72)
      .toList();
  final selected = brightCandidates.isEmpty ? samples : brightCandidates;

  int median(List<int> values) {
    values.sort();
    return values[values.length ~/ 2];
  }

  final r = median(selected.map((sample) => sample.r).toList());
  final g = median(selected.map((sample) => sample.g).toList());
  final b = median(selected.map((sample) => sample.b).toList());
  final luminance = ((r + g + b) / 3).round();
  final distances =
      selected
          .map(
            (sample) => _colorDistance(sample.r, sample.g, sample.b, r, g, b),
          )
          .toList()
        ..sort();
  final tolerance = distances[((distances.length - 1) * 0.9).round()].clamp(
    24,
    72,
  );

  return _PaperProfile(
    r: r,
    g: g,
    b: b,
    luminance: luminance,
    distanceTolerance: tolerance,
  );
}

_ForegroundScoreMap _buildForegroundScoreMap(
  img.Image image, {
  required _PaperProfile paper,
}) {
  final totalPixels = image.width * image.height;
  final scores = Uint8List(totalPixels);
  final distances = Uint8List(totalPixels);
  final histogram = List<int>.filled(256, 0);

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final index = y * image.width + x;
      final pixel = image.getPixel(x, y);
      final r = pixel.r.round();
      final g = pixel.g.round();
      final b = pixel.b.round();
      final distance = _colorDistance(r, g, b, paper.r, paper.g, paper.b);
      final luminance = ((r + g + b) / 3).round();
      final saturation = (max(r, max(g, b)) - min(r, min(g, b))).toInt();
      final darkness = max(0, paper.luminance - luminance);
      final score = max(
        distance.toDouble(),
        darkness * 1.35 + saturation * 0.65,
      ).round().clamp(0, 255);
      scores[index] = score;
      distances[index] = distance;
      histogram[score]++;
    }
  }

  return _ForegroundScoreMap(
    scores: scores,
    paperDistances: distances,
    otsuThreshold: _computeOtsuThreshold(histogram, totalPixels),
  );
}

List<bool> _buildThresholdMask(Uint8List scores, int threshold) {
  return List<bool>.generate(
    scores.length,
    (index) => scores[index] >= threshold,
    growable: false,
  );
}

List<bool> _dilateMask(
  List<bool> mask,
  int width,
  int height, {
  required int radius,
}) {
  if (radius <= 0) {
    return List<bool>.from(mask, growable: false);
  }
  final dilated = List<bool>.filled(mask.length, false);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var hit = false;
      for (var dy = -radius; dy <= radius && !hit; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= height) {
          continue;
        }
        for (var dx = -radius; dx <= radius; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= width) {
            continue;
          }
          if (mask[ny * width + nx]) {
            hit = true;
            break;
          }
        }
      }
      dilated[y * width + x] = hit;
    }
  }
  return dilated;
}

List<bool> _erodeMask(
  List<bool> mask,
  int width,
  int height, {
  required int radius,
}) {
  if (radius <= 0) {
    return List<bool>.from(mask, growable: false);
  }
  final eroded = List<bool>.filled(mask.length, false);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var keep = true;
      for (var dy = -radius; dy <= radius && keep; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= height) {
          keep = false;
          break;
        }
        for (var dx = -radius; dx <= radius; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= width || !mask[ny * width + nx]) {
            keep = false;
            break;
          }
        }
      }
      eroded[y * width + x] = keep;
    }
  }
  return eroded;
}

List<bool> _closeMask(
  List<bool> mask,
  int width,
  int height, {
  required int radius,
}) {
  if (radius <= 0) {
    return List<bool>.from(mask, growable: false);
  }
  final expanded = _dilateMask(mask, width, height, radius: radius);
  return _erodeMask(expanded, width, height, radius: radius);
}

List<bool> _floodFillBackground(
  img.Image image, {
  required List<bool> strokeBarrierMask,
  required Uint8List scores,
  required Uint8List paperDistances,
  required int weakThreshold,
  required int strongThreshold,
  required _PaperProfile paper,
}) {
  final width = image.width;
  final height = image.height;
  final total = width * height;
  final visited = List<bool>.filled(total, false);
  final queue = ListQueue<int>();
  final backgroundScoreThreshold = min(255, strongThreshold + 8);
  final paperDistanceThreshold = min(
    255,
    max(paper.distanceTolerance + 12, weakThreshold + 4),
  );

  bool canVisit(int index) {
    if (strokeBarrierMask[index]) {
      return false;
    }
    return scores[index] <= backgroundScoreThreshold &&
        paperDistances[index] <= paperDistanceThreshold;
  }

  void enqueue(int index) {
    if (!visited[index] && canVisit(index)) {
      visited[index] = true;
      queue.add(index);
    }
  }

  for (var x = 0; x < width; x++) {
    enqueue(x);
    enqueue((height - 1) * width + x);
  }
  for (var y = 0; y < height; y++) {
    enqueue(y * width);
    enqueue(y * width + (width - 1));
  }

  while (queue.isNotEmpty) {
    final index = queue.removeFirst();
    final x = index % width;
    final y = index ~/ width;

    if (x > 0) {
      enqueue(index - 1);
    }
    if (x < width - 1) {
      enqueue(index + 1);
    }
    if (y > 0) {
      enqueue(index - width);
    }
    if (y < height - 1) {
      enqueue(index + width);
    }
  }

  return visited;
}

List<bool> _removeSmallComponents(
  int width,
  int height,
  List<bool> foregroundMask,
) {
  final total = width * height;
  final visited = List<bool>.filled(total, false);
  final cleaned = List<bool>.filled(total, false);
  final queue = ListQueue<int>();
  final minComponentSize = max(10, (total * 0.00012).round());

  for (var start = 0; start < total; start++) {
    if (!foregroundMask[start] || visited[start]) {
      continue;
    }

    final component = <int>[];
    visited[start] = true;
    queue.add(start);

    while (queue.isNotEmpty) {
      final index = queue.removeFirst();
      component.add(index);
      final x = index % width;
      final y = index ~/ width;

      if (x > 0) {
        final next = index - 1;
        if (!visited[next] && foregroundMask[next]) {
          visited[next] = true;
          queue.add(next);
        }
      }
      if (x < width - 1) {
        final next = index + 1;
        if (!visited[next] && foregroundMask[next]) {
          visited[next] = true;
          queue.add(next);
        }
      }
      if (y > 0) {
        final next = index - width;
        if (!visited[next] && foregroundMask[next]) {
          visited[next] = true;
          queue.add(next);
        }
      }
      if (y < height - 1) {
        final next = index + width;
        if (!visited[next] && foregroundMask[next]) {
          visited[next] = true;
          queue.add(next);
        }
      }
    }

    if (component.length >= minComponentSize) {
      for (final index in component) {
        cleaned[index] = true;
      }
    }
  }

  return cleaned;
}

({int minX, int minY, int maxX, int maxY, bool hasForeground})
_findForegroundBounds(List<bool> mask, int width, int height) {
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final index = y * width + x;
      if (!mask[index]) {
        continue;
      }
      minX = min(minX, x);
      minY = min(minY, y);
      maxX = max(maxX, x);
      maxY = max(maxY, y);
    }
  }

  return (
    minX: minX,
    minY: minY,
    maxX: maxX,
    maxY: maxY,
    hasForeground: maxX >= 0 && maxY >= 0,
  );
}

int _colorDistance(int r, int g, int b, int baseR, int baseG, int baseB) {
  final dr = r - baseR;
  final dg = g - baseG;
  final db = b - baseB;
  return sqrt(dr * dr + dg * dg + db * db).round().clamp(0, 255);
}

int _computeOtsuThreshold(List<int> histogram, int totalPixels) {
  if (totalPixels <= 0) {
    return 0;
  }

  var totalSum = 0.0;
  for (var i = 0; i < histogram.length; i++) {
    totalSum += i * histogram[i];
  }

  var backgroundWeight = 0.0;
  var backgroundSum = 0.0;
  var bestVariance = -1.0;
  var bestThreshold = 0;

  for (var threshold = 0; threshold < histogram.length; threshold++) {
    backgroundWeight += histogram[threshold];
    if (backgroundWeight == 0) {
      continue;
    }
    final foregroundWeight = totalPixels - backgroundWeight;
    if (foregroundWeight == 0) {
      break;
    }
    backgroundSum += threshold * histogram[threshold];
    final backgroundMean = backgroundSum / backgroundWeight;
    final foregroundMean = (totalSum - backgroundSum) / foregroundWeight;
    final variance =
        backgroundWeight *
        foregroundWeight *
        pow(backgroundMean - foregroundMean, 2);
    if (variance > bestVariance) {
      bestVariance = variance.toDouble();
      bestThreshold = threshold;
    }
  }

  return bestThreshold;
}

final drawingRegionDetectorProvider = Provider<DrawingRegionDetector>((_) {
  return const RuleBasedDrawingRegionDetector();
});
