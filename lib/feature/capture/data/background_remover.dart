import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'background_removal_config.dart';

class BackgroundRemovalResult {
  const BackgroundRemovalResult({
    required this.transparentAreaRatio,
    this.qualityWarningMessage,
    required this.transparentWidth,
    required this.transparentHeight,
    this.wasTrimmed = false,
  });

  final double transparentAreaRatio;
  final String? qualityWarningMessage;
  final int transparentWidth;
  final int transparentHeight;
  final bool wasTrimmed;
}

enum BackgroundRemovalDebugArtifact {
  original('original'),
  stroke('stroke'),
  floodfill('floodfill'),
  mask('mask'),
  preview('preview');

  const BackgroundRemovalDebugArtifact(this.directoryName);

  final String directoryName;
}

class BackgroundRemovalDebugSession {
  const BackgroundRemovalDebugSession({
    required this.rootDirectoryPath,
    required this.fileName,
    this.artifacts = BackgroundRemovalDebugArtifact.values,
  });

  final String rootDirectoryPath;
  final String fileName;
  final List<BackgroundRemovalDebugArtifact> artifacts;

  bool get isEnabled => rootDirectoryPath.isNotEmpty && fileName.isNotEmpty;
}

class BackgroundRemover {
  const BackgroundRemover({this.config = defaultBackgroundRemovalConfig});

  final BackgroundRemovalConfig config;

  Future<BackgroundRemovalResult> removeBackground({
    required String sourceImagePath,
    required String destinationImagePath,
    int? maxDimension,
    bool trimToForeground = true,
    BackgroundRemovalDebugSession? debugSession,
  }) async {
    final sourceFile = File(sourceImagePath);
    if (!await sourceFile.exists()) {
      throw StateError('원본 이미지가 존재하지 않습니다.');
    }

    final bytes = await sourceFile.readAsBytes();
    final result = await Isolate.run(
      () => _removeBackgroundInIsolate(
        sourceBytes: bytes,
        trimToForeground: trimToForeground,
        config: config,
        maxDimension: maxDimension ?? config.maxProcessingDimension,
        debugArtifacts: debugSession?.artifacts ?? const [],
      ),
    );

    await File(destinationImagePath).parent.create(recursive: true);
    await File(destinationImagePath).writeAsBytes(result.pngBytes);

    if (debugSession != null && debugSession.isEnabled) {
      await _writeDebugArtifacts(
        debugSession: debugSession,
        debugImages: result.debugImages,
      );
    }

    return BackgroundRemovalResult(
      transparentAreaRatio: result.transparentAreaRatio,
      qualityWarningMessage: result.qualityWarningMessage,
      transparentWidth: result.transparentWidth,
      transparentHeight: result.transparentHeight,
      wasTrimmed: result.wasTrimmed,
    );
  }

  Future<void> _writeDebugArtifacts({
    required BackgroundRemovalDebugSession debugSession,
    required Map<BackgroundRemovalDebugArtifact, List<int>> debugImages,
  }) async {
    for (final entry in debugImages.entries) {
      final directory = Directory(
        '${debugSession.rootDirectoryPath}/${entry.key.directoryName}',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await File(
        '${directory.path}/${debugSession.fileName}',
      ).writeAsBytes(entry.value);
    }
  }

  static img.Image _resizeForProcessing(img.Image source, int maxDimension) {
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

  static _PaperProfile _samplePaperProfile(img.Image image) {
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
    final luminanceCutoff =
        sortedLuminance[((sortedLuminance.length - 1) * 0.65).round()];

    final brightCandidates = samples
        .where(
          (sample) =>
              sample.luminance >= luminanceCutoff && sample.saturation <= 72,
        )
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

  static _ForegroundScoreMap _buildForegroundScoreMap(
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

  static List<bool> _buildThresholdMask(Uint8List scores, int threshold) {
    return List<bool>.generate(
      scores.length,
      (index) => scores[index] >= threshold,
      growable: false,
    );
  }

  static List<bool> _dilateMask(
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

  static List<bool> _erodeMask(
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

  static List<bool> _closeMask(
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

  static List<bool> _floodFillBackground(
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

  static List<bool> _removeSmallComponents(
    int width,
    int height,
    List<bool> foregroundMask, {
    required BackgroundRemovalConfig config,
  }) {
    final total = width * height;
    final visited = List<bool>.filled(total, false);
    final cleaned = List<bool>.filled(total, false);
    final queue = ListQueue<int>();
    final minComponentSize = max(
      config.smallComponentBasePixels,
      (total * config.smallComponentRatio).round(),
    );

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

  static String? _qualityWarningMessage(double transparentAreaRatio) {
    if (transparentAreaRatio < 0.05) {
      return '배경 제거 후 투명영역이 5% 미만입니다. 배경과 피사체 색상 대비를 확인해 주세요.';
    }
    if (transparentAreaRatio > 0.95) {
      return '배경 제거 후 투명영역이 95% 초과입니다. 배경과 피사체가 구분되지 않을 수 있습니다.';
    }
    return null;
  }
}

class _BackgroundRemovalResult {
  const _BackgroundRemovalResult({
    required this.pngBytes,
    required this.transparentAreaRatio,
    this.qualityWarningMessage,
    required this.transparentWidth,
    required this.transparentHeight,
    this.wasTrimmed = false,
    this.debugImages = const {},
  });

  final List<int> pngBytes;
  final double transparentAreaRatio;
  final String? qualityWarningMessage;
  final int transparentWidth;
  final int transparentHeight;
  final bool wasTrimmed;
  final Map<BackgroundRemovalDebugArtifact, List<int>> debugImages;
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

img.Image _buildMaskImage(
  int width,
  int height,
  List<bool> mask, {
  bool invert = false,
}) {
  final output = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final value = mask[y * width + x] ^ invert ? 255 : 0;
      output.setPixelRgba(x, y, value, value, value, 255);
    }
  }
  return output;
}

img.Image _buildPreviewImage(img.Image source, List<bool> mask) {
  final preview = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final index = y * source.width + x;
      final isForeground = mask[index];
      final pixel = source.getPixel(x, y);
      if (isForeground) {
        preview.setPixelRgba(
          x,
          y,
          pixel.r.round(),
          pixel.g.round(),
          pixel.b.round(),
          255,
        );
      } else {
        preview.setPixelRgba(x, y, 240, 244, 246, 255);
      }
    }
  }
  return preview;
}

Map<BackgroundRemovalDebugArtifact, List<int>> _buildDebugArtifacts({
  required img.Image source,
  required List<bool> strokeMask,
  required List<bool> floodfillMask,
  required List<bool> finalMask,
}) {
  return {
    BackgroundRemovalDebugArtifact.original: img.encodePng(source),
    BackgroundRemovalDebugArtifact.stroke: img.encodePng(
      _buildMaskImage(source.width, source.height, strokeMask),
    ),
    BackgroundRemovalDebugArtifact.floodfill: img.encodePng(
      _buildMaskImage(source.width, source.height, floodfillMask),
    ),
    BackgroundRemovalDebugArtifact.mask: img.encodePng(
      _buildMaskImage(source.width, source.height, finalMask),
    ),
    BackgroundRemovalDebugArtifact.preview: img.encodePng(
      _buildPreviewImage(source, finalMask),
    ),
  };
}

_BackgroundRemovalResult _removeBackgroundInIsolate({
  required Uint8List sourceBytes,
  required bool trimToForeground,
  required BackgroundRemovalConfig config,
  required int maxDimension,
  required List<BackgroundRemovalDebugArtifact> debugArtifacts,
}) {
  final source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw StateError('이미지 디코드에 실패했습니다.');
  }

  final resized = BackgroundRemover._resizeForProcessing(source, maxDimension);
  final paper = BackgroundRemover._samplePaperProfile(resized);
  final scoreMap = BackgroundRemover._buildForegroundScoreMap(
    resized,
    paper: paper,
  );
  final weakThreshold = max(
    12,
    (scoreMap.otsuThreshold + config.weakThresholdOffset).clamp(0, 255),
  );
  final strongThreshold = max(
    max(24, weakThreshold + 1),
    (scoreMap.otsuThreshold + config.strongThresholdOffset).clamp(0, 255),
  );

  final strongMask = BackgroundRemover._buildThresholdMask(
    scoreMap.scores,
    strongThreshold,
  );
  final weakMask = BackgroundRemover._buildThresholdMask(
    scoreMap.scores,
    weakThreshold,
  );
  final dilatedStrokeMask = BackgroundRemover._dilateMask(
    strongMask,
    resized.width,
    resized.height,
    radius: config.strokeDilateRadius,
  );
  final strokeMask = BackgroundRemover._closeMask(
    dilatedStrokeMask,
    resized.width,
    resized.height,
    radius: config.strokeCloseRadius,
  );
  final floodfillMask = BackgroundRemover._floodFillBackground(
    resized,
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
  final foregroundMask = BackgroundRemover._removeSmallComponents(
    resized.width,
    resized.height,
    foregroundSeedMask,
    config: config,
  );

  final outputImage = img.Image(
    width: resized.width,
    height: resized.height,
    numChannels: 4,
  );
  var transparentPixels = 0;
  for (var y = 0; y < resized.height; y++) {
    for (var x = 0; x < resized.width; x++) {
      final index = y * resized.width + x;
      final pixel = resized.getPixel(x, y);
      final alpha = foregroundMask[index] ? 255 : 0;
      if (alpha == 0) {
        transparentPixels++;
      }
      outputImage.setPixelRgba(
        x,
        y,
        pixel.r.round(),
        pixel.g.round(),
        pixel.b.round(),
        alpha,
      );
    }
  }

  final totalPixels = resized.width * resized.height;
  final transparentAreaRatio = totalPixels == 0
      ? 0.0
      : transparentPixels / totalPixels;
  final qualityWarningMessage = BackgroundRemover._qualityWarningMessage(
    transparentAreaRatio,
  );

  final selectedArtifacts = debugArtifacts.toSet();
  final builtArtifacts = selectedArtifacts.isEmpty
      ? const <BackgroundRemovalDebugArtifact, List<int>>{}
      : _buildDebugArtifacts(
          source: resized,
          strokeMask: strokeMask,
          floodfillMask: floodfillMask,
          finalMask: foregroundMask,
        );
  final debugImages = {
    for (final artifact in selectedArtifacts)
      if (builtArtifacts.containsKey(artifact))
        artifact: builtArtifacts[artifact]!,
  };

  if (!trimToForeground) {
    return _BackgroundRemovalResult(
      pngBytes: img.encodePng(outputImage),
      transparentAreaRatio: transparentAreaRatio,
      qualityWarningMessage: qualityWarningMessage,
      transparentWidth: outputImage.width,
      transparentHeight: outputImage.height,
      wasTrimmed: false,
      debugImages: debugImages,
    );
  }

  final bounds = _findForegroundBounds(
    foregroundMask,
    resized.width,
    resized.height,
  );
  if (bounds.hasForeground) {
    final trimmed = img.copyCrop(
      outputImage,
      x: bounds.minX,
      y: bounds.minY,
      width: bounds.maxX - bounds.minX + 1,
      height: bounds.maxY - bounds.minY + 1,
    );
    return _BackgroundRemovalResult(
      pngBytes: img.encodePng(trimmed),
      transparentAreaRatio: transparentAreaRatio,
      qualityWarningMessage: qualityWarningMessage,
      transparentWidth: trimmed.width,
      transparentHeight: trimmed.height,
      wasTrimmed: true,
      debugImages: debugImages,
    );
  }

  return _BackgroundRemovalResult(
    pngBytes: img.encodePng(outputImage),
    transparentAreaRatio: transparentAreaRatio,
    qualityWarningMessage: qualityWarningMessage,
    transparentWidth: outputImage.width,
    transparentHeight: outputImage.height,
    wasTrimmed: false,
    debugImages: debugImages,
  );
}
