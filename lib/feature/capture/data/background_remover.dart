import 'dart:io';
import 'dart:collection';
import 'dart:math';

import 'package:image/image.dart' as img;

class BackgroundRemovalResult {
  const BackgroundRemovalResult({
    required this.transparentAreaRatio,
    this.qualityWarningMessage,
  });

  final double transparentAreaRatio;
  final String? qualityWarningMessage;
}

class BackgroundRemover {
  const BackgroundRemover();

  Future<BackgroundRemovalResult> removeBackground({
    required String sourceImagePath,
    required String destinationImagePath,
    int maxDimension = 1500,
    int colorThreshold = 32,
  }) async {
    final sourceFile = File(sourceImagePath);
    if (!await sourceFile.exists()) {
      throw StateError('원본 이미지가 존재하지 않습니다.');
    }

    final bytes = await sourceFile.readAsBytes();
    final source = img.decodeImage(bytes);
    if (source == null) {
      throw StateError('이미지 디코드에 실패했습니다.');
    }

    final resized = _resizeForProcessing(source, maxDimension);
    final background = _sampleEdgeColor(resized);
    final backgroundThresholdSq = colorThreshold * colorThreshold;
    final floodFillThresholdSq = (colorThreshold + 12) * (colorThreshold + 12);
    final initialForegroundMask = _buildForegroundMask(
      resized,
      backgroundR: background.r,
      backgroundG: background.g,
      backgroundB: background.b,
      thresholdSquared: backgroundThresholdSq,
    );
    final cleanedForegroundMask = _removeBackgroundLeakage(
      resized,
      initialMask: initialForegroundMask,
      backgroundR: background.r,
      backgroundG: background.g,
      backgroundB: background.b,
      floodFillThresholdSquared: floodFillThresholdSq,
    );
    final alphaMask = _removeNoiseByComponent(
      resized.width,
      resized.height,
      cleanedForegroundMask,
    );

    final outputImage = img.Image(width: resized.width, height: resized.height);
    final totalPixels = resized.width * resized.height;
    var transparentPixels = 0;

    for (var y = 0; y < resized.height; y++) {
      for (var x = 0; x < resized.width; x++) {
        final index = y * resized.width + x;
        final pixel = resized.getPixel(x, y);
        final alpha = alphaMask[index] ? 255 : 0;
        if (!alphaMask[index]) {
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

    final pngBytes = img.encodePng(outputImage);
    await File(destinationImagePath).parent.create(recursive: true);
    await File(destinationImagePath).writeAsBytes(pngBytes);

    final transparentAreaRatio = transparentPixels / totalPixels;

    return BackgroundRemovalResult(
      transparentAreaRatio: transparentAreaRatio,
      qualityWarningMessage: _qualityWarningMessage(transparentAreaRatio),
    );
  }

  img.Image _resizeForProcessing(img.Image source, int maxDimension) {
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

  ({int r, int g, int b}) _sampleEdgeColor(img.Image image) {
    final width = image.width;
    final height = image.height;
    final step = max(1, max(width, height) ~/ 24);

    int totalR = 0;
    int totalG = 0;
    int totalB = 0;
    int count = 0;

    void sample(int x, int y) {
      final pixel = image.getPixel(x, y);
      totalR += (pixel.r).round();
      totalG += (pixel.g).round();
      totalB += (pixel.b).round();
      count += 1;
    }

    for (var x = 0; x < width; x += step) {
      sample(x, 0);
      sample(x, height - 1);
    }
    for (var y = 0; y < height; y += step) {
      sample(0, y);
      sample(width - 1, y);
    }

    if (count == 0) {
      final pixel = image.getPixel(0, 0);
      return (
        r: (pixel.r).round(),
        g: (pixel.g).round(),
        b: (pixel.b).round(),
      );
    }

    return (
      r: totalR ~/ count,
      g: totalG ~/ count,
      b: totalB ~/ count,
    );
  }

  List<bool> _buildForegroundMask(
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

  List<bool> _removeBackgroundLeakage(
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

  List<bool> _removeNoiseByComponent(
    int width,
    int height,
    List<bool> foregroundMask,
  ) {
    final total = width * height;
    final visited = List<bool>.filled(total, false);
    final queue = ListQueue<int>();
    final cleaned = List<bool>.filled(total, false);
    final minComponentSize = (total * 0.0012).clamp(12, 200).round();

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

  String? _qualityWarningMessage(double transparentAreaRatio) {
    if (transparentAreaRatio < 0.05) {
      return '배경 제거 후 투명영역이 5% 미만입니다. 배경과 피사체 색상 대비를 확인해 주세요.';
    }
    if (transparentAreaRatio > 0.95) {
      return '배경 제거 후 투명영역이 95% 초과입니다. 배경과 피사체가 구분되지 않을 수 있습니다.';
    }
    return null;
  }
}
