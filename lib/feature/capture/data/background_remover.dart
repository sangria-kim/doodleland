import 'dart:io';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

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

class BackgroundRemover {
  const BackgroundRemover();

  Future<BackgroundRemovalResult> removeBackground({
    required String sourceImagePath,
    required String destinationImagePath,
    int maxDimension = 1500,
    int colorThreshold = 32,
    bool trimToForeground = true,
  }) async {
    final sourceFile = File(sourceImagePath);
    if (!await sourceFile.exists()) {
      throw StateError('원본 이미지가 존재하지 않습니다.');
    }

    final bytes = await sourceFile.readAsBytes();
    final result = await Isolate.run(
      () => _removeBackgroundInIsolate(
        sourceBytes: bytes,
        maxDimension: maxDimension,
        colorThreshold: colorThreshold,
        trimToForeground: trimToForeground,
      ),
    );

    await File(destinationImagePath).parent.create(recursive: true);
    await File(destinationImagePath).writeAsBytes(result.pngBytes);

    return BackgroundRemovalResult(
      transparentAreaRatio: result.transparentAreaRatio,
      qualityWarningMessage: result.qualityWarningMessage,
      transparentWidth: result.transparentWidth,
      transparentHeight: result.transparentHeight,
      wasTrimmed: result.wasTrimmed,
    );
  }

  static img.Image _resizeForProcessing(img.Image source, int maxDimension) {
    final maxSide = max(source.width, source.height);
    if (maxSide <= maxDimension) return source;

    final scale = maxDimension / maxSide;
    final newWidth = max(1, (source.width * scale).round());
    final newHeight = max(1, (source.height * scale).round());

    return img.copyResize(
      source,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.average,
    );
  }

  static _EdgeProfile _sampleEdgeProfile(img.Image image) {
    final width = image.width;
    final height = image.height;
    final step = max(1, max(width, height) ~/ 24);
    final samples = <({int r, int g, int b})>[];

    void sample(int x, int y) {
      final pixel = image.getPixel(x, y);
      samples.add((
        r: pixel.r.round(),
        g: pixel.g.round(),
        b: pixel.b.round(),
      ));
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
      return _EdgeProfile(
        r: (pixel.r).round(),
        g: (pixel.g).round(),
        b: (pixel.b).round(),
        recommendedThreshold: 32,
      );
    }

    int median(List<int> values) {
      values.sort();
      return values[values.length ~/ 2];
    }

    final medianR = median(samples.map((sample) => sample.r).toList());
    final medianG = median(samples.map((sample) => sample.g).toList());
    final medianB = median(samples.map((sample) => sample.b).toList());

    final distances = samples
        .map(
          (sample) => sqrt(
            pow(sample.r - medianR, 2) +
                pow(sample.g - medianG, 2) +
                pow(sample.b - medianB, 2),
          ),
        )
        .toList()
      ..sort();
    final variationDistance =
        distances[((distances.length - 1) * 0.9).round()];

    return _EdgeProfile(
      r: medianR,
      g: medianG,
      b: medianB,
      recommendedThreshold:
          variationDistance.round().clamp(32, 120) + 12,
    );
  }

  static List<bool> _buildForegroundMask(
    img.Image image, {
    required int backgroundR,
    required int backgroundG,
    required int backgroundB,
    required int thresholdSquared,
  }) {
    final width = image.width;
    final height = image.height;
    final pixels = List<bool>.filled(width * height, false);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final dr = pixel.r.round() - backgroundR;
        final dg = pixel.g.round() - backgroundG;
        final db = pixel.b.round() - backgroundB;
        final distanceSq = dr * dr + dg * dg + db * db;
        final index = y * width + x;
        pixels[index] = distanceSq > thresholdSquared;
      }
    }
    return pixels;
  }

  static List<bool> _removeBackgroundLeakage(
    img.Image image, {
    required List<bool> initialMask,
    required int backgroundR,
    required int backgroundG,
    required int backgroundB,
    required int floodFillThresholdSquared,
  }) {
    final width = image.width;
    final height = image.height;
    final total = width * height;
    final backgroundVisited = List<bool>.filled(total, false);
    final queue = ListQueue<int>();

    bool isBackgroundByColor(int x, int y, int idx) {
      if (initialMask[idx]) {
        return false;
      }
      final pixel = image.getPixel(x, y);
      final dr = pixel.r.round() - backgroundR;
      final dg = pixel.g.round() - backgroundG;
      final db = pixel.b.round() - backgroundB;
      final distanceSq = dr * dr + dg * dg + db * db;
      return distanceSq <= floodFillThresholdSquared;
    }

    for (var x = 0; x < width; x++) {
      final top = x;
      if (isBackgroundByColor(top % width, 0, top)) {
        queue.add(top);
        backgroundVisited[top] = true;
      }
      final bottom = (height - 1) * width + x;
      if (isBackgroundByColor(bottom % width, height - 1, bottom)) {
        queue.add(bottom);
        backgroundVisited[bottom] = true;
      }
    }
    for (var y = 0; y < height; y++) {
      final left = y * width;
      if (isBackgroundByColor(0, y, left)) {
        queue.add(left);
        backgroundVisited[left] = true;
      }
      final right = y * width + (width - 1);
      if (isBackgroundByColor(width - 1, y, right)) {
        queue.add(right);
        backgroundVisited[right] = true;
      }
    }

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final x = idx % width;
      final y = idx ~/ width;

      if (x > 0) {
        final next = idx - 1;
        if (!backgroundVisited[next]) {
          if (isBackgroundByColor(x - 1, y, next)) {
            backgroundVisited[next] = true;
            queue.add(next);
          }
        }
      }
      if (x < width - 1) {
        final next = idx + 1;
        if (!backgroundVisited[next]) {
          if (isBackgroundByColor(x + 1, y, next)) {
            backgroundVisited[next] = true;
            queue.add(next);
          }
        }
      }
      if (y > 0) {
        final next = idx - width;
        if (!backgroundVisited[next]) {
          if (isBackgroundByColor(x, y - 1, next)) {
            backgroundVisited[next] = true;
            queue.add(next);
          }
        }
      }
      if (y < height - 1) {
        final next = idx + width;
        if (!backgroundVisited[next]) {
          if (isBackgroundByColor(x, y + 1, next)) {
            backgroundVisited[next] = true;
            queue.add(next);
          }
        }
      }
    }

    final finalForeground = List<bool>.filled(total, false);
    for (var i = 0; i < total; i++) {
      finalForeground[i] = initialMask[i] && !backgroundVisited[i];
    }
    return finalForeground;
  }

  static List<bool> _removeNoiseByComponent(
    int width,
    int height,
    List<bool> foregroundMask,
  ) {
    final total = width * height;
    final visited = List<bool>.filled(total, false);
    final queue = ListQueue<int>();
    final cleaned = List<bool>.filled(total, false);
    final minComponentSize = (total * 0.00015).clamp(6, 64).round();

    for (var start = 0; start < total; start++) {
      if (!foregroundMask[start] || visited[start]) {
        continue;
      }
      final component = <int>[];
      queue.add(start);
      visited[start] = true;

      while (queue.isNotEmpty) {
        final idx = queue.removeFirst();
        component.add(idx);

        final x = idx % width;
        final y = idx ~/ width;

        if (x > 0) {
          final next = idx - 1;
          if (!visited[next] && foregroundMask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
        if (x < width - 1) {
          final next = idx + 1;
          if (!visited[next] && foregroundMask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
        if (y > 0) {
          final next = idx - width;
          if (!visited[next] && foregroundMask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
        if (y < height - 1) {
          final next = idx + width;
          if (!visited[next] && foregroundMask[next]) {
            visited[next] = true;
            queue.add(next);
          }
        }
      }

      if (component.length >= minComponentSize) {
        for (final idx in component) {
          cleaned[idx] = true;
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
  });

  final List<int> pngBytes;
  final double transparentAreaRatio;
  final String? qualityWarningMessage;
  final int transparentWidth;
  final int transparentHeight;
  final bool wasTrimmed;
}

class _EdgeProfile {
  const _EdgeProfile({
    required this.r,
    required this.g,
    required this.b,
    required this.recommendedThreshold,
  });

  final int r;
  final int g;
  final int b;
  final int recommendedThreshold;
}

class _MaskSelection {
  const _MaskSelection({
    required this.alphaValues,
    required this.transparentAreaRatio,
  });

  final List<int> alphaValues;
  final double transparentAreaRatio;
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
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
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

_BackgroundRemovalResult _removeBackgroundInIsolate({
  required Uint8List sourceBytes,
  required int maxDimension,
  required int colorThreshold,
  required bool trimToForeground,
}) {
  final source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw StateError('이미지 디코드에 실패했습니다.');
  }

  final resized = BackgroundRemover._resizeForProcessing(source, maxDimension);
  final background = BackgroundRemover._sampleEdgeProfile(resized);
  final alphaSelection = _selectForegroundMask(
    resized,
    backgroundR: background.r,
    backgroundG: background.g,
    backgroundB: background.b,
    baseThreshold: max(colorThreshold, background.recommendedThreshold),
  );
  final alphaValues = alphaSelection.alphaValues;

  final outputImage = img.Image(
    width: resized.width,
    height: resized.height,
    numChannels: 4,
  );
  final totalPixels = resized.width * resized.height;
  var transparentPixels = 0;

  for (var y = 0; y < resized.height; y++) {
    for (var x = 0; x < resized.width; x++) {
      final index = y * resized.width + x;
      final pixel = resized.getPixel(x, y);
      final alpha = alphaValues[index];
      if (alpha <= 8) {
        transparentPixels++;
      }
      outputImage.setPixelRgba(
        x,
        y,
        (pixel.r).round(),
        (pixel.g).round(),
        (pixel.b).round(),
        alpha,
      );
    }
  }

  final transparentAreaRatio =
      totalPixels == 0 ? 0.0 : alphaSelection.transparentAreaRatio;
  final qualityWarningMessage = BackgroundRemover._qualityWarningMessage(
    transparentAreaRatio,
  );

  if (!trimToForeground) {
    return _BackgroundRemovalResult(
      pngBytes: img.encodePng(outputImage),
      transparentAreaRatio: transparentAreaRatio,
      qualityWarningMessage: qualityWarningMessage,
      transparentWidth: outputImage.width,
      transparentHeight: outputImage.height,
      wasTrimmed: false,
    );
  }

  final bounds = _findForegroundBounds(
    alphaValues.map((alpha) => alpha >= 32).toList(growable: false),
    resized.width,
    resized.height,
  );
  if (bounds.hasForeground) {
    final trimmedWidth = bounds.maxX - bounds.minX + 1;
    final trimmedHeight = bounds.maxY - bounds.minY + 1;
    final trimmedImage = img.copyCrop(
      outputImage,
      x: bounds.minX,
      y: bounds.minY,
      width: trimmedWidth,
      height: trimmedHeight,
    );
    return _BackgroundRemovalResult(
      pngBytes: img.encodePng(trimmedImage),
      transparentAreaRatio: transparentAreaRatio,
      qualityWarningMessage: qualityWarningMessage,
      transparentWidth: trimmedImage.width,
      transparentHeight: trimmedImage.height,
      wasTrimmed: true,
    );
  }

  return _BackgroundRemovalResult(
    pngBytes: img.encodePng(outputImage),
    transparentAreaRatio: transparentAreaRatio,
    qualityWarningMessage: qualityWarningMessage,
    transparentWidth: outputImage.width,
    transparentHeight: outputImage.height,
    wasTrimmed: false,
  );
}

_MaskSelection _selectForegroundMask(
  img.Image image, {
  required int backgroundR,
  required int backgroundG,
  required int backgroundB,
  required int baseThreshold,
}) {
  final totalPixels = image.width * image.height;
  final backgroundLuma = (backgroundR + backgroundG + backgroundB) / 3.0;
  final lowThreshold = max(24, (baseThreshold * 0.95).round());
  final highThreshold = max(lowThreshold + 18, (baseThreshold * 2.2).round());
  final alphaValues = List<int>.filled(totalPixels, 0);
  var transparentPixels = 0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final index = y * image.width + x;
      final pixel = image.getPixel(x, y);
      final red = pixel.r.round();
      final green = pixel.g.round();
      final blue = pixel.b.round();
      final colorDistance = sqrt(
        pow(red - backgroundR, 2) +
            pow(green - backgroundG, 2) +
            pow(blue - backgroundB, 2),
      );
      final channelMax = max(red, max(green, blue));
      final channelMin = min(red, min(green, blue));
      final saturation = channelMax - channelMin;
      final luminance = (red + green + blue) / 3.0;
      final darkness = max(0.0, backgroundLuma - luminance);
      final inkScore = max(
        colorDistance,
        darkness * 1.35 + saturation * 0.65,
      );

      final alpha = inkScore <= lowThreshold
          ? 0
          : inkScore >= highThreshold
              ? 255
              : (pow(
                    (inkScore - lowThreshold) /
                        (highThreshold - lowThreshold),
                    1.6,
                  ) *
                  255)
                  .round();
      alphaValues[index] = alpha;
      if (alpha <= 8) {
        transparentPixels++;
      }
    }
  }

  return _MaskSelection(
    alphaValues: alphaValues,
    transparentAreaRatio: totalPixels == 0 ? 0.0 : transparentPixels / totalPixels,
  );
}
