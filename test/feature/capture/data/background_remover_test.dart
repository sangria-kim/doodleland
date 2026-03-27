import 'dart:io';

import 'package:doodleland/feature/capture/data/background_remover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('background-remover-test');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('removes sampled white background and keeps large foreground component', () async {
    final sourceImage = img.Image(width: 20, height: 20);
    for (var y = 0; y < sourceImage.height; y++) {
      for (var x = 0; x < sourceImage.width; x++) {
        sourceImage.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    for (var y = 7; y < 12; y++) {
      for (var x = 7; x < 12; x++) {
        sourceImage.setPixelRgba(x, y, 12, 12, 12, 255);
      }
    }

    final sourcePath = '${tempDirectory.path}/source.png';
    final transparentPath = '${tempDirectory.path}/transparent.png';
    await File(sourcePath).writeAsBytes(img.encodePng(sourceImage));

    final result = await const BackgroundRemover().removeBackground(
      sourceImagePath: sourcePath,
      destinationImagePath: transparentPath,
      maxDimension: 1500,
    );

    final output = img.decodeImage(await File(transparentPath).readAsBytes())!;
    expect(output, isNotNull);
    expect(result.qualityWarningMessage, isNull);
    expect(result.transparentAreaRatio, lessThan(0.95));
    expect(result.transparentAreaRatio, greaterThan(0.05));
  });

  test('returns quality warning when almost all pixels are transparent after removal', () async {
    final sourceImage = img.Image(width: 16, height: 16);
    for (var y = 0; y < sourceImage.height; y++) {
      for (var x = 0; x < sourceImage.width; x++) {
        sourceImage.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    final sourcePath = '${tempDirectory.path}/white.png';
    final transparentPath = '${tempDirectory.path}/transparent-white.png';
    await File(sourcePath).writeAsBytes(img.encodePng(sourceImage));

    final result = await const BackgroundRemover().removeBackground(
      sourceImagePath: sourcePath,
      destinationImagePath: transparentPath,
      maxDimension: 1500,
    );

    expect(result.transparentAreaRatio, greaterThan(0.95));
    expect(result.qualityWarningMessage, isNotNull);
    expect(result.qualityWarningMessage, isNotEmpty);
    final output = img.decodeImage(await File(transparentPath).readAsBytes())!;
    expect(output, isNotNull);
  });
}
