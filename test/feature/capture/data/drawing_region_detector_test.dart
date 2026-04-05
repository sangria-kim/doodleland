import 'dart:ui' show Rect;
import 'dart:typed_data';

import 'package:doodleland/feature/capture/data/drawing_region_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('detects centered drawing region and returns normalized bbox', () async {
    final source = img.Image(width: 200, height: 120);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 248, 246, 240, 255);
      }
    }

    for (var y = 30; y < 92; y++) {
      for (var x = 60; x < 152; x++) {
        source.setPixelRgba(x, y, 28, 46, 180, 255);
      }
    }

    final detector = const RuleBasedDrawingRegionDetector();
    final result = await detector.detect(
      Uint8List.fromList(img.encodePng(source)),
    );

    expect(result.detected, isTrue);
    expect(result.boundingBox.left, lessThan(0.40));
    expect(result.boundingBox.right, greaterThan(0.70));
    expect(result.boundingBox.top, lessThan(0.35));
    expect(result.boundingBox.bottom, greaterThan(0.70));
  });

  test('returns detected false for near-uniform blank image', () async {
    final source = img.Image(width: 160, height: 120);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }

    final detector = const RuleBasedDrawingRegionDetector();
    final result = await detector.detect(
      Uint8List.fromList(img.encodePng(source)),
    );

    expect(result.detected, isFalse);
    expect(result.boundingBox, const Rect.fromLTWH(0, 0, 1, 1));
  });
}
