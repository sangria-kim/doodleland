import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import 'background_removal_config.dart';

class RemovalResult {
  const RemovalResult({
    required this.success,
    required this.outputImageBytes,
    this.maskBytes,
    this.debugData,
    required this.transparentAreaRatio,
    this.qualityWarningMessage,
    required this.outputWidth,
    required this.outputHeight,
    this.wasTrimmed = false,
    this.errorMessage,
  });

  RemovalResult.failure({this.errorMessage, this.debugData})
    : success = false,
      outputImageBytes = Uint8List(0),
      maskBytes = null,
      transparentAreaRatio = 0,
      qualityWarningMessage = null,
      outputWidth = 0,
      outputHeight = 0,
      wasTrimmed = false;

  final bool success;
  final Uint8List outputImageBytes;
  final Uint8List? maskBytes;
  final Map<String, Object?>? debugData;

  final double transparentAreaRatio;
  final String? qualityWarningMessage;
  final int outputWidth;
  final int outputHeight;
  final bool wasTrimmed;
  final String? errorMessage;
}

abstract class BackgroundRemover {
  Future<RemovalResult> remove(
    Uint8List croppedImageBytes, {
    int? maxDimension,
    bool trimToForeground = false,
    BackgroundRemovalDebugSession? debugSession,
  });
}

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
  paperProfile('paper_profile'),
  lineMask('line_mask'),
  colorMask('color_mask'),
  edgePreservationMask('edge_preservation_mask'),
  mergedMask('merged_mask'),
  finalAlphaResult('final_alpha_result');

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

class RuleBasedBackgroundRemover implements BackgroundRemover {
  const RuleBasedBackgroundRemover({
    this.config = defaultBackgroundRemovalConfig,
  });

  final BackgroundRemovalConfig config;

  @override
  Future<RemovalResult> remove(
    Uint8List croppedImageBytes, {
    int? maxDimension,
    bool trimToForeground = false,
    BackgroundRemovalDebugSession? debugSession,
  }) async {
    if (croppedImageBytes.isEmpty) {
      return RemovalResult.failure(errorMessage: '이미지가 비어 있습니다.');
    }

    try {
      final result = await Isolate.run(
        () => _removeBackgroundInIsolate(
          sourceBytes: croppedImageBytes,
          trimToForeground: trimToForeground,
          config: config,
          maxDimension: maxDimension ?? config.maxProcessingDimension,
          debugArtifacts: debugSession?.artifacts ?? const [],
        ),
      );

      if (debugSession != null && debugSession.isEnabled) {
        await _writeDebugArtifacts(
          debugSession: debugSession,
          debugImages: result.debugImages,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[capture] remover=RuleBasedBackgroundRemover '
          'success=${result.success} trimmed=${result.wasTrimmed} '
          'ratio=${result.transparentAreaRatio.toStringAsFixed(3)}',
        );
      }

      return RemovalResult(
        success: result.success,
        outputImageBytes: Uint8List.fromList(result.pngBytes),
        maskBytes: result.maskPngBytes == null
            ? null
            : Uint8List.fromList(result.maskPngBytes!),
        debugData: result.debugData,
        transparentAreaRatio: result.transparentAreaRatio,
        qualityWarningMessage: result.qualityWarningMessage,
        outputWidth: result.outputWidth,
        outputHeight: result.outputHeight,
        wasTrimmed: result.wasTrimmed,
        errorMessage: result.errorMessage,
      );
    } catch (error) {
      return RemovalResult.failure(errorMessage: '$error');
    }
  }

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
    final result = await remove(
      bytes,
      maxDimension: maxDimension,
      trimToForeground: trimToForeground,
      debugSession: debugSession,
    );
    if (!result.success) {
      throw StateError(result.errorMessage ?? '배경 제거에 실패했습니다.');
    }

    await File(destinationImagePath).parent.create(recursive: true);
    await File(destinationImagePath).writeAsBytes(result.outputImageBytes);

    return BackgroundRemovalResult(
      transparentAreaRatio: result.transparentAreaRatio,
      qualityWarningMessage: result.qualityWarningMessage,
      transparentWidth: result.outputWidth,
      transparentHeight: result.outputHeight,
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
    final saturations = Uint8List(totalPixels);
    final luminances = Uint8List(totalPixels);
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
        final darkness = max(0, paper.luminance - luminance - 12);
        var darknessWeight = 1.35;
        if (saturation <= 8 && distance <= paper.distanceTolerance + 10) {
          darknessWeight = 0.55;
        }
        if (saturation <= 8 && darkness >= 46) {
          darknessWeight = max(darknessWeight, 1.0);
        }
        final score = max(
          distance.toDouble(),
          darkness * darknessWeight + saturation * 0.65,
        ).round().clamp(0, 255);
        scores[index] = score;
        distances[index] = distance;
        saturations[index] = saturation;
        luminances[index] = luminance;
        histogram[score]++;
      }
    }

    return _ForegroundScoreMap(
      scores: scores,
      paperDistances: distances,
      saturations: saturations,
      luminances: luminances,
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

  static List<bool> _refineLineSeedMask(
    List<bool> strongMask, {
    required _ForegroundScoreMap scoreMap,
    required _PaperProfile paper,
    required int strongThreshold,
  }) {
    return List<bool>.generate(strongMask.length, (index) {
      if (!strongMask[index]) {
        return false;
      }

      final saturation = scoreMap.saturations[index];
      final paperDistance = scoreMap.paperDistances[index];
      final score = scoreMap.scores[index];
      final clearlyDifferentFromPaper =
          paperDistance >= paper.distanceTolerance + 8;
      final coloredStroke = saturation >= 8;
      final strongDarkStroke =
          score >= strongThreshold + 14 &&
          paperDistance >= paper.distanceTolerance + 4;

      return clearlyDifferentFromPaper || coloredStroke || strongDarkStroke;
    }, growable: false);
  }

  // ignore: unused_element
  static List<bool> _buildColorMask(
    _ForegroundScoreMap scoreMap, {
    required _PaperProfile paper,
    required int weakThreshold,
  }) {
    return List<bool>.generate(scoreMap.scores.length, (index) {
      final saturation = scoreMap.saturations[index];
      final paperDistance = scoreMap.paperDistances[index];
      final luminance = scoreMap.luminances[index];
      final darkness = max(0, paper.luminance - luminance);

      final highSaturationCandidate =
          saturation >= 16 &&
          paperDistance >= max(18, paper.distanceTolerance - 8);
      final darkColorCandidate =
          saturation >= 10 &&
          darkness >= 18 &&
          paperDistance >= max(12, weakThreshold - 2);
      final lowSaturationDarkCandidate =
          saturation >= 6 && darkness >= 28 && paperDistance >= 18;

      return highSaturationCandidate ||
          darkColorCandidate ||
          lowSaturationDarkCandidate;
    }, growable: false);
  }

  static List<bool> _unionMasks(List<List<bool>> masks) {
    if (masks.isEmpty) {
      return const <bool>[];
    }

    final length = masks.first.length;
    final union = List<bool>.filled(length, false);
    for (var index = 0; index < length; index++) {
      var isForeground = false;
      for (final mask in masks) {
        if (mask[index]) {
          isForeground = true;
          break;
        }
      }
      union[index] = isForeground;
    }
    return union;
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

  static List<bool> _buildLineProtectionMask(
    int width,
    int height, {
    required List<bool> lineSeedMask,
    required Uint8List paperDistances,
    required Uint8List saturations,
    required Uint8List scores,
    required _PaperProfile paper,
    required int strongThreshold,
  }) {
    final lineBand = _dilateMask(lineSeedMask, width, height, radius: 1);
    return List<bool>.generate(lineBand.length, (index) {
      if (!lineBand[index]) {
        return false;
      }

      final saturation = saturations[index];
      final paperDistance = paperDistances[index];
      final score = scores[index];
      final isLikelyInk =
          score >= strongThreshold - 2 ||
          saturation >= 8 ||
          paperDistance >= paper.distanceTolerance + 10;
      return isLikelyInk;
    }, growable: false);
  }

  static List<bool> _floodFillOutsideByBarrier(
    int width,
    int height, {
    required List<bool> barrierMask,
  }) {
    final total = width * height;
    final outside = List<bool>.filled(total, false);
    final queue = ListQueue<int>();

    void enqueue(int index) {
      if (outside[index] || barrierMask[index]) {
        return;
      }
      outside[index] = true;
      queue.add(index);
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

    return outside;
  }

  static _OutlineGuidedMaskResult _buildOutlineGuidedInteriorMask(
    int width,
    int height, {
    required _ForegroundScoreMap scoreMap,
    required _PaperProfile paper,
    required int strongThreshold,
    required BackgroundRemovalConfig config,
  }) {
    final total = width * height;
    final outlineSeedMask = List<bool>.generate(total, (index) {
      final score = scoreMap.scores[index];
      final saturation = scoreMap.saturations[index];
      final luminance = scoreMap.luminances[index];
      final darknessDelta = paper.luminance - luminance;
      final strongInk = score >= strongThreshold;
      final darkOutlineInk =
          darknessDelta >= config.outlineInkMinDarknessDelta &&
          saturation <= config.outlineInkMaxSaturation &&
          score >= strongThreshold - 10;
      return strongInk || darkOutlineInk;
    }, growable: false);

    final outlineBarrierMask = _closeMask(
      _dilateMask(outlineSeedMask, width, height, radius: 1),
      width,
      height,
      radius: config.outlineBarrierCloseRadius,
    );
    final outsideMask = _floodFillOutsideByBarrier(
      width,
      height,
      barrierMask: outlineBarrierMask,
    );
    final interiorMask = List<bool>.generate(
      total,
      (index) => !outsideMask[index],
      growable: false,
    );

    var outlinePixels = 0;
    var interiorPixels = 0;
    for (var index = 0; index < total; index++) {
      if (outlineBarrierMask[index]) {
        outlinePixels++;
      }
      if (interiorMask[index]) {
        interiorPixels++;
      }
    }

    final outlineCoverage = total == 0 ? 0.0 : outlinePixels / total;
    final interiorRatio = total == 0 ? 0.0 : interiorPixels / total;
    final shouldApply =
        outlineCoverage >= config.outlineModeMinCoverage &&
        interiorRatio >= config.outlineModeMinInteriorRatio &&
        interiorRatio <= config.outlineModeMaxInteriorRatio;
    if (!shouldApply) {
      return _OutlineGuidedMaskResult(
        mask: List<bool>.filled(total, false),
        applied: false,
        outlineCoverage: outlineCoverage,
        interiorRatio: interiorRatio,
      );
    }

    final guidedInteriorMask = List<bool>.generate(total, (index) {
      if (!interiorMask[index]) {
        return false;
      }
      final paperDistance = scoreMap.paperDistances[index];
      final saturation = scoreMap.saturations[index];
      final score = scoreMap.scores[index];
      return outlineBarrierMask[index] ||
          paperDistance >= paper.distanceTolerance + 2 ||
          saturation >= 6 ||
          score >= strongThreshold - 10;
    }, growable: false);

    return _OutlineGuidedMaskResult(
      mask: guidedInteriorMask,
      applied: true,
      outlineCoverage: outlineCoverage,
      interiorRatio: interiorRatio,
    );
  }

  static List<bool> _floodFillBackground(
    img.Image image, {
    required List<bool> barrierMask,
    required Uint8List scores,
    required Uint8List paperDistances,
    required Uint8List saturations,
    required Uint8List luminances,
    required int weakThreshold,
    required int strongThreshold,
    required _PaperProfile paper,
  }) {
    final width = image.width;
    final height = image.height;
    final total = width * height;
    final visited = List<bool>.filled(total, false);
    final queue = ListQueue<int>();
    final backgroundScoreThreshold = min(255, strongThreshold + 16);
    final paperDistanceThreshold = min(
      255,
      max(paper.distanceTolerance + 20, weakThreshold + 10),
    );
    final loosePaperDistanceThreshold = min(
      255,
      max(paper.distanceTolerance + 34, weakThreshold + 24),
    );
    const lowSaturationThreshold = 34;
    const luminanceDeltaThreshold = 68;

    bool canVisit(int index) {
      if (barrierMask[index]) {
        return false;
      }

      final score = scores[index];
      final paperDistance = paperDistances[index];
      if (score <= backgroundScoreThreshold &&
          paperDistance <= paperDistanceThreshold) {
        return true;
      }

      final saturation = saturations[index];
      final luminance = luminances[index];
      final luminanceDelta = (luminance - paper.luminance).abs();
      final looseBackgroundCandidate =
          paperDistance <= loosePaperDistanceThreshold &&
          saturation <= lowSaturationThreshold &&
          luminanceDelta <= luminanceDeltaThreshold;
      return looseBackgroundCandidate;
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

  // ignore: unused_element
  static List<bool> _suppressEdgeConnectedBackgroundLikeComponents(
    int width,
    int height,
    List<bool> mask, {
    required Uint8List paperDistances,
    required Uint8List saturations,
    required Uint8List scores,
    required _PaperProfile paper,
    required int strongThreshold,
  }) {
    final total = width * height;
    final visited = List<bool>.filled(total, false);
    final output = List<bool>.from(mask, growable: false);
    final queue = ListQueue<int>();

    for (var start = 0; start < total; start++) {
      if (!mask[start] || visited[start]) {
        continue;
      }

      var touchesEdge = false;
      var count = 0;
      var strongInkCount = 0;
      var saturationSum = 0;
      var distanceSum = 0;
      final component = <int>[];
      visited[start] = true;
      queue.add(start);

      while (queue.isNotEmpty) {
        final index = queue.removeFirst();
        component.add(index);
        count++;
        final x = index % width;
        final y = index ~/ width;
        if (x == 0 || y == 0 || x == width - 1 || y == height - 1) {
          touchesEdge = true;
        }

        final saturation = saturations[index];
        final paperDistance = paperDistances[index];
        final score = scores[index];
        saturationSum += saturation;
        distanceSum += paperDistance;
        if (score >= strongThreshold || saturation >= 24) {
          strongInkCount++;
        }

        if (x > 0) {
          final next = index - 1;
          if (!visited[next] && mask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
        if (x < width - 1) {
          final next = index + 1;
          if (!visited[next] && mask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
        if (y > 0) {
          final next = index - width;
          if (!visited[next] && mask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
        if (y < height - 1) {
          final next = index + width;
          if (!visited[next] && mask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
      }

      if (!touchesEdge || count == 0) {
        continue;
      }

      final avgSaturation = saturationSum / count;
      final avgDistance = distanceSum / count;
      final strongInkRatio = strongInkCount / count;
      final isLargeEdgeComponent = count >= (total * 0.08).round();
      final removeLargeBackgroundLike =
          isLargeEdgeComponent && strongInkRatio < 0.14 && avgSaturation < 22;
      final keepEdgeComponent =
          !removeLargeBackgroundLike &&
          (strongInkRatio >= 0.1 ||
              avgDistance >= paper.distanceTolerance + 30 ||
              avgSaturation >= 22);

      if (!keepEdgeComponent) {
        for (final index in component) {
          output[index] = false;
        }
      }
    }

    return output;
  }

  static List<bool> _stripBorderPaperLikePixels(
    int width,
    int height,
    List<bool> mask, {
    required Uint8List paperDistances,
    required Uint8List saturations,
    required Uint8List scores,
    required _PaperProfile paper,
    required int strongThreshold,
  }) {
    final total = width * height;
    final output = List<bool>.from(mask, growable: false);
    final visited = List<bool>.filled(total, false);
    final queue = ListQueue<int>();
    final maxPaperDistance = paper.distanceTolerance + 52;
    final maxScore = strongThreshold + 30;
    const maxSaturation = 38;

    bool isBorderPaperLike(int index) {
      if (!output[index]) {
        return false;
      }
      return saturations[index] <= maxSaturation &&
          paperDistances[index] <= maxPaperDistance &&
          scores[index] <= maxScore;
    }

    void enqueue(int index) {
      if (visited[index] || !isBorderPaperLike(index)) {
        return;
      }
      visited[index] = true;
      queue.add(index);
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
      output[index] = false;
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

    return output;
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

  static _RecoveryResult _recoverForegroundComponents(
    int width,
    int height, {
    required List<bool> baseMask,
    required List<bool> floodfillMask,
    required List<bool> lineSeedMask,
    required List<bool> strongMask,
    required _ForegroundScoreMap scoreMap,
    required _PaperProfile paper,
    required int weakThreshold,
    required int strongThreshold,
    required BackgroundRemovalConfig config,
  }) {
    final total = width * height;
    final recoveryBudgetPixels = max(
      0,
      (total * config.maxRecoveryRatio).round(),
    );
    if (recoveryBudgetPixels == 0) {
      return _RecoveryResult(
        mask: List<bool>.filled(total, false),
        recoveredPixels: 0,
      );
    }

    final anchorCoreMask = _unionMasks([baseMask, lineSeedMask, strongMask]);
    final candidateMask = List<bool>.filled(total, false);
    final visited = List<bool>.filled(total, false);
    final queue = ListQueue<int>();
    final components = <_RecoveryComponent>[];
    final minComponentPixels = max(1, config.recoveryMinComponentPixels);
    final maxComponentPixels = max(
      minComponentPixels + 1,
      (total * config.recoveryMaxComponentRatio).round(),
    );

    bool hasAnchorNeighbor(int index) {
      final x = index % width;
      final y = index ~/ width;
      for (var dy = -1; dy <= 1; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= height) {
          continue;
        }
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= width || (dx == 0 && dy == 0)) {
            continue;
          }
          if (anchorCoreMask[ny * width + nx]) {
            return true;
          }
        }
      }
      return false;
    }

    for (var index = 0; index < total; index++) {
      if (baseMask[index] ||
          floodfillMask[index] ||
          !hasAnchorNeighbor(index)) {
        continue;
      }
      final paperDistance = scoreMap.paperDistances[index];
      final saturation = scoreMap.saturations[index];
      final score = scoreMap.scores[index];
      final isCandidate =
          paperDistance >= paper.distanceTolerance + 6 ||
          (saturation >= 10 && score >= weakThreshold + 6) ||
          score >= strongThreshold;
      candidateMask[index] = isCandidate;
    }

    for (var start = 0; start < total; start++) {
      if (!candidateMask[start] || visited[start]) {
        continue;
      }

      final component = <int>[];
      var touchesEdge = false;
      var supportPixels = 0;
      var scoreSum = 0.0;
      var distanceSum = 0.0;
      var saturationSum = 0.0;
      var luminanceSum = 0.0;
      var luminanceSquareSum = 0.0;

      visited[start] = true;
      queue.add(start);

      while (queue.isNotEmpty) {
        final index = queue.removeFirst();
        component.add(index);
        final x = index % width;
        final y = index ~/ width;

        if (x == 0 || y == 0 || x == width - 1 || y == height - 1) {
          touchesEdge = true;
        }

        if (hasAnchorNeighbor(index)) {
          supportPixels++;
        }

        final score = scoreMap.scores[index].toDouble();
        final distance = scoreMap.paperDistances[index].toDouble();
        final saturation = scoreMap.saturations[index].toDouble();
        final luminance = scoreMap.luminances[index].toDouble();
        scoreSum += score;
        distanceSum += distance;
        saturationSum += saturation;
        luminanceSum += luminance;
        luminanceSquareSum += luminance * luminance;

        if (x > 0) {
          final left = index - 1;
          if (candidateMask[left] && !visited[left]) {
            visited[left] = true;
            queue.add(left);
          }
        }
        if (x < width - 1) {
          final right = index + 1;
          if (candidateMask[right] && !visited[right]) {
            visited[right] = true;
            queue.add(right);
          }
        }
        if (y > 0) {
          final top = index - width;
          if (candidateMask[top] && !visited[top]) {
            visited[top] = true;
            queue.add(top);
          }
        }
        if (y < height - 1) {
          final bottom = index + width;
          if (candidateMask[bottom] && !visited[bottom]) {
            visited[bottom] = true;
            queue.add(bottom);
          }
        }
      }

      final count = component.length;
      if (touchesEdge ||
          count < minComponentPixels ||
          count > maxComponentPixels) {
        continue;
      }

      final supportRatio = supportPixels / count;
      if (supportRatio < config.recoveryMinSupportRatio) {
        continue;
      }

      final avgScore = scoreSum / count;
      final avgDistance = distanceSum / count;
      final avgSaturation = saturationSum / count;
      final avgLuminance = luminanceSum / count;
      final luminanceVariance = max(
        0.0,
        (luminanceSquareSum / count) - avgLuminance * avgLuminance,
      );
      final survivesThreshold =
          avgDistance >= paper.distanceTolerance + 8 ||
          avgScore >= strongThreshold + 2 ||
          avgSaturation >= 14;
      final preservesTexture =
          luminanceVariance >= config.recoveryMinLuminanceVariance ||
          avgSaturation >= 12;
      if (!survivesThreshold || !preservesTexture) {
        continue;
      }

      final componentScore =
          supportRatio * 120 +
          (avgDistance - (paper.distanceTolerance + 6)).clamp(0, 60) * 0.8 +
          (avgScore - weakThreshold).clamp(0, 120) * 0.35 +
          min(40, luminanceVariance) * 0.4 +
          min(30, avgSaturation) * 0.3;
      components.add(
        _RecoveryComponent(pixels: component, score: componentScore),
      );
    }

    if (components.isEmpty) {
      return _RecoveryResult(
        mask: List<bool>.filled(total, false),
        recoveredPixels: 0,
        budgetPixels: recoveryBudgetPixels,
      );
    }

    components.sort((a, b) => b.score.compareTo(a.score));
    final recoveredMask = List<bool>.filled(total, false);
    var recoveredPixels = 0;
    var recoveredComponents = 0;
    for (final component in components) {
      final componentPixels = component.pixels.length;
      if (recoveredPixels + componentPixels > recoveryBudgetPixels &&
          recoveredPixels > 0) {
        continue;
      }
      for (final index in component.pixels) {
        recoveredMask[index] = true;
      }
      recoveredPixels += componentPixels;
      recoveredComponents++;
      if (recoveredPixels >= recoveryBudgetPixels) {
        break;
      }
    }

    return _RecoveryResult(
      mask: recoveredMask,
      recoveredPixels: recoveredPixels,
      recoveredComponents: recoveredComponents,
      budgetPixels: recoveryBudgetPixels,
    );
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
    required this.success,
    required this.pngBytes,
    required this.transparentAreaRatio,
    this.qualityWarningMessage,
    required this.outputWidth,
    required this.outputHeight,
    this.wasTrimmed = false,
    this.maskPngBytes,
    this.errorMessage,
    this.debugData,
    this.debugImages = const {},
  });

  final bool success;
  final List<int> pngBytes;
  final double transparentAreaRatio;
  final String? qualityWarningMessage;
  final int outputWidth;
  final int outputHeight;
  final bool wasTrimmed;
  final List<int>? maskPngBytes;
  final String? errorMessage;
  final Map<String, Object?>? debugData;
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
    required this.saturations,
    required this.luminances,
    required this.otsuThreshold,
  });

  final Uint8List scores;
  final Uint8List paperDistances;
  final Uint8List saturations;
  final Uint8List luminances;
  final int otsuThreshold;
}

class _RecoveryResult {
  const _RecoveryResult({
    required this.mask,
    required this.recoveredPixels,
    this.recoveredComponents = 0,
    this.budgetPixels = 0,
  });

  final List<bool> mask;
  final int recoveredPixels;
  final int recoveredComponents;
  final int budgetPixels;
}

class _OutlineGuidedMaskResult {
  const _OutlineGuidedMaskResult({
    required this.mask,
    required this.applied,
    required this.outlineCoverage,
    required this.interiorRatio,
  });

  final List<bool> mask;
  final bool applied;
  final double outlineCoverage;
  final double interiorRatio;
}

class _RecoveryComponent {
  const _RecoveryComponent({required this.pixels, required this.score});

  final List<int> pixels;
  final double score;
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

img.Image _buildPaperProfilePreview(img.Image source, _PaperProfile paper) {
  final output = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  for (var y = 0; y < output.height; y++) {
    for (var x = 0; x < output.width; x++) {
      output.setPixelRgba(x, y, paper.r, paper.g, paper.b, 255);
    }
  }
  return output;
}

Map<BackgroundRemovalDebugArtifact, List<int>> _buildDebugArtifacts({
  required img.Image source,
  required _PaperProfile paper,
  required List<bool> lineMask,
  required List<bool> colorMask,
  required List<bool> edgeMask,
  required List<bool> mergedMask,
  required img.Image finalAlphaImage,
}) {
  return {
    BackgroundRemovalDebugArtifact.original: img.encodePng(source),
    BackgroundRemovalDebugArtifact.paperProfile: img.encodePng(
      _buildPaperProfilePreview(source, paper),
    ),
    BackgroundRemovalDebugArtifact.lineMask: img.encodePng(
      _buildMaskImage(source.width, source.height, lineMask),
    ),
    BackgroundRemovalDebugArtifact.colorMask: img.encodePng(
      _buildMaskImage(source.width, source.height, colorMask),
    ),
    BackgroundRemovalDebugArtifact.edgePreservationMask: img.encodePng(
      _buildMaskImage(source.width, source.height, edgeMask),
    ),
    BackgroundRemovalDebugArtifact.mergedMask: img.encodePng(
      _buildMaskImage(source.width, source.height, mergedMask),
    ),
    BackgroundRemovalDebugArtifact.finalAlphaResult: img.encodePng(
      finalAlphaImage,
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
    return const _BackgroundRemovalResult(
      success: false,
      pngBytes: <int>[],
      transparentAreaRatio: 0,
      outputWidth: 0,
      outputHeight: 0,
      errorMessage: '이미지 디코드에 실패했습니다.',
    );
  }

  final resized = RuleBasedBackgroundRemover._resizeForProcessing(
    source,
    maxDimension,
  );
  final paper = RuleBasedBackgroundRemover._samplePaperProfile(resized);
  final scoreMap = RuleBasedBackgroundRemover._buildForegroundScoreMap(
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

  final strongMask = RuleBasedBackgroundRemover._buildThresholdMask(
    scoreMap.scores,
    strongThreshold,
  );
  final weakMask = RuleBasedBackgroundRemover._buildThresholdMask(
    scoreMap.scores,
    weakThreshold,
  );
  final lineSeedMask = RuleBasedBackgroundRemover._refineLineSeedMask(
    strongMask,
    scoreMap: scoreMap,
    paper: paper,
    strongThreshold: strongThreshold,
  );
  final lineMask = RuleBasedBackgroundRemover._closeMask(
    RuleBasedBackgroundRemover._dilateMask(
      lineSeedMask,
      resized.width,
      resized.height,
      radius: config.strokeDilateRadius,
    ),
    resized.width,
    resized.height,
    radius: config.strokeCloseRadius,
  );
  final outlineGuidedMaskResult =
      RuleBasedBackgroundRemover._buildOutlineGuidedInteriorMask(
        resized.width,
        resized.height,
        scoreMap: scoreMap,
        paper: paper,
        strongThreshold: strongThreshold,
        config: config,
      );
  final floodfillMask = RuleBasedBackgroundRemover._floodFillBackground(
    resized,
    barrierMask: lineMask,
    scores: scoreMap.scores,
    paperDistances: scoreMap.paperDistances,
    saturations: scoreMap.saturations,
    luminances: scoreMap.luminances,
    weakThreshold: weakThreshold,
    strongThreshold: strongThreshold,
    paper: paper,
  );
  final aggressiveForegroundSeedMask = List<bool>.generate(
    weakMask.length,
    (index) => weakMask[index] && !floodfillMask[index],
    growable: false,
  );
  final aggressiveBaseMask = RuleBasedBackgroundRemover._removeSmallComponents(
    resized.width,
    resized.height,
    aggressiveForegroundSeedMask,
    config: config,
  );
  final lineProtectionMask =
      RuleBasedBackgroundRemover._buildLineProtectionMask(
        resized.width,
        resized.height,
        lineSeedMask: lineSeedMask,
        paperDistances: scoreMap.paperDistances,
        saturations: scoreMap.saturations,
        scores: scoreMap.scores,
        paper: paper,
        strongThreshold: strongThreshold,
      );
  final recoveryResult =
      RuleBasedBackgroundRemover._recoverForegroundComponents(
        resized.width,
        resized.height,
        baseMask: aggressiveBaseMask,
        floodfillMask: floodfillMask,
        lineSeedMask: lineSeedMask,
        strongMask: strongMask,
        scoreMap: scoreMap,
        paper: paper,
        weakThreshold: weakThreshold,
        strongThreshold: strongThreshold,
        config: config,
      );
  final mergedMask = RuleBasedBackgroundRemover._unionMasks([
    aggressiveBaseMask,
    lineProtectionMask,
    recoveryResult.mask,
    outlineGuidedMaskResult.mask,
  ]);
  final finalMask = RuleBasedBackgroundRemover._removeSmallComponents(
    resized.width,
    resized.height,
    mergedMask,
    config: config,
  );
  final borderStrippedMask =
      RuleBasedBackgroundRemover._stripBorderPaperLikePixels(
        resized.width,
        resized.height,
        finalMask,
        paperDistances: scoreMap.paperDistances,
        saturations: scoreMap.saturations,
        scores: scoreMap.scores,
        paper: paper,
        strongThreshold: strongThreshold,
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
      final alpha = borderStrippedMask[index] ? 255 : 0;
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
  final qualityWarningMessage =
      RuleBasedBackgroundRemover._qualityWarningMessage(transparentAreaRatio);
  final maskImage = _buildMaskImage(
    resized.width,
    resized.height,
    borderStrippedMask,
  );
  final maskPngBytes = img.encodePng(maskImage);

  final selectedArtifacts = debugArtifacts.toSet();
  final builtArtifacts = selectedArtifacts.isEmpty
      ? const <BackgroundRemovalDebugArtifact, List<int>>{}
      : _buildDebugArtifacts(
          source: resized,
          paper: paper,
          lineMask: lineMask,
          colorMask: outlineGuidedMaskResult.mask,
          edgeMask: lineProtectionMask,
          mergedMask: borderStrippedMask,
          finalAlphaImage: outputImage,
        );
  final debugImages = {
    for (final artifact in selectedArtifacts)
      if (builtArtifacts.containsKey(artifact))
        artifact: builtArtifacts[artifact]!,
  };
  final debugData = <String, Object?>{
    'otsuThreshold': scoreMap.otsuThreshold,
    'weakThreshold': weakThreshold,
    'strongThreshold': strongThreshold,
    'recoveryBudgetPixels': recoveryResult.budgetPixels,
    'recoveryPixels': recoveryResult.recoveredPixels,
    'recoveryComponents': recoveryResult.recoveredComponents,
    'outlineGuidedApplied': outlineGuidedMaskResult.applied,
    'outlineCoverage': outlineGuidedMaskResult.outlineCoverage,
    'outlineInteriorRatio': outlineGuidedMaskResult.interiorRatio,
  };

  if (!trimToForeground) {
    return _BackgroundRemovalResult(
      success: true,
      pngBytes: img.encodePng(outputImage),
      transparentAreaRatio: transparentAreaRatio,
      qualityWarningMessage: qualityWarningMessage,
      outputWidth: outputImage.width,
      outputHeight: outputImage.height,
      wasTrimmed: false,
      maskPngBytes: maskPngBytes,
      debugData: debugData,
      debugImages: debugImages,
    );
  }

  final bounds = _findForegroundBounds(
    borderStrippedMask,
    resized.width,
    resized.height,
  );
  if (!bounds.hasForeground) {
    return _BackgroundRemovalResult(
      success: true,
      pngBytes: img.encodePng(outputImage),
      transparentAreaRatio: transparentAreaRatio,
      qualityWarningMessage: qualityWarningMessage,
      outputWidth: outputImage.width,
      outputHeight: outputImage.height,
      wasTrimmed: false,
      maskPngBytes: maskPngBytes,
      debugData: debugData,
      debugImages: debugImages,
    );
  }

  final trimmed = img.copyCrop(
    outputImage,
    x: bounds.minX,
    y: bounds.minY,
    width: bounds.maxX - bounds.minX + 1,
    height: bounds.maxY - bounds.minY + 1,
  );
  return _BackgroundRemovalResult(
    success: true,
    pngBytes: img.encodePng(trimmed),
    transparentAreaRatio: transparentAreaRatio,
    qualityWarningMessage: qualityWarningMessage,
    outputWidth: trimmed.width,
    outputHeight: trimmed.height,
    wasTrimmed: true,
    maskPngBytes: maskPngBytes,
    debugData: debugData,
    debugImages: debugImages,
  );
}

final backgroundRemoverProvider = Provider<BackgroundRemover>((_) {
  return const RuleBasedBackgroundRemover(
    config: defaultBackgroundRemovalConfig,
  );
});
