import 'dart:io';

import 'package:doodleland/feature/capture/data/background_remover.dart';
import 'package:doodleland/feature/capture/data/background_removal_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'background-remover-test',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'removes sampled white background and keeps large foreground component',
    () async {
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

      final output = img.decodeImage(
        await File(transparentPath).readAsBytes(),
      )!;
      expect(output, isNotNull);
      expect(result.wasTrimmed, isTrue);
      expect(result.transparentWidth, equals(5));
      expect(result.transparentHeight, equals(5));
      expect(output.width, equals(5));
      expect(output.height, equals(5));
      expect(result.qualityWarningMessage, isNull);
      expect(result.transparentAreaRatio, lessThan(0.95));
      expect(result.transparentAreaRatio, greaterThan(0.05));
    },
  );

  test(
    'returns quality warning when almost all pixels are transparent after removal',
    () async {
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
      expect(result.wasTrimmed, isFalse);
      final output = img.decodeImage(
        await File(transparentPath).readAsBytes(),
      )!;
      expect(output, isNotNull);
      expect(output.width, equals(16));
      expect(output.height, equals(16));
      expect(result.transparentWidth, equals(16));
      expect(result.transparentHeight, equals(16));
    },
  );

  test('does not trim when trimToForeground is false', () async {
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

    final sourcePath = '${tempDirectory.path}/source_nocrop.png';
    final transparentPath = '${tempDirectory.path}/transparent_nocrop.png';
    await File(sourcePath).writeAsBytes(img.encodePng(sourceImage));

    final result = await const BackgroundRemover().removeBackground(
      sourceImagePath: sourcePath,
      destinationImagePath: transparentPath,
      maxDimension: 1500,
      trimToForeground: false,
    );

    final output = img.decodeImage(await File(transparentPath).readAsBytes())!;
    expect(result.wasTrimmed, isFalse);
    expect(result.transparentWidth, equals(20));
    expect(result.transparentHeight, equals(20));
    expect(output.width, equals(20));
    expect(output.height, equals(20));
  });

  test('removes paper background while preserving thin line drawing', () async {
    final sourceImage = img.Image(width: 48, height: 32);
    for (var y = 0; y < sourceImage.height; y++) {
      for (var x = 0; x < sourceImage.width; x++) {
        final paperTint = (x + y).isEven ? 248 : 242;
        sourceImage.setPixelRgba(x, y, paperTint, paperTint, 238, 255);
      }
    }

    for (var x = 10; x < 38; x++) {
      sourceImage.setPixelRgba(x, 9, 83, 130, 214, 255);
      sourceImage.setPixelRgba(x, 22, 83, 130, 214, 255);
    }
    for (var y = 9; y <= 22; y++) {
      sourceImage.setPixelRgba(10, y, 83, 130, 214, 255);
      sourceImage.setPixelRgba(37, y, 83, 130, 214, 255);
    }

    final sourcePath = '${tempDirectory.path}/line_art_source.png';
    final transparentPath = '${tempDirectory.path}/line_art_transparent.png';
    await File(sourcePath).writeAsBytes(img.encodePng(sourceImage));

    final result = await const BackgroundRemover().removeBackground(
      sourceImagePath: sourcePath,
      destinationImagePath: transparentPath,
      trimToForeground: false,
    );

    final output = img.decodeImage(await File(transparentPath).readAsBytes())!;
    expect(result.transparentAreaRatio, greaterThan(0.80));
    expect(output.width, equals(48));
    expect(output.height, equals(32));
    expect(output.getPixel(0, 0).a.round(), equals(0));
    expect(output.getPixel(10, 9).a.round(), equals(255));
  });

  test('writes debug artifacts only when debug session is enabled', () async {
    final sourceImage = img.Image(width: 24, height: 24);
    for (var y = 0; y < sourceImage.height; y++) {
      for (var x = 0; x < sourceImage.width; x++) {
        sourceImage.setPixelRgba(x, y, 250, 248, 244, 255);
      }
    }
    for (var x = 6; x < 18; x++) {
      sourceImage.setPixelRgba(x, 8, 12, 20, 24, 255);
      sourceImage.setPixelRgba(x, 15, 12, 20, 24, 255);
    }
    for (var y = 8; y <= 15; y++) {
      sourceImage.setPixelRgba(6, y, 12, 20, 24, 255);
      sourceImage.setPixelRgba(17, y, 12, 20, 24, 255);
    }

    final sourcePath = '${tempDirectory.path}/debug_source.png';
    final transparentPath = '${tempDirectory.path}/debug_result.png';
    final debugRootPath = '${tempDirectory.path}/debug';
    await File(sourcePath).writeAsBytes(img.encodePng(sourceImage));

    await BackgroundRemover(
      config: defaultBackgroundRemovalConfig,
    ).removeBackground(
      sourceImagePath: sourcePath,
      destinationImagePath: transparentPath,
      trimToForeground: false,
      debugSession: const BackgroundRemovalDebugSession(
        rootDirectoryPath: '',
        fileName: 'disabled.png',
      ),
    );

    expect(await Directory(debugRootPath).exists(), isFalse);

    await BackgroundRemover(
      config: defaultBackgroundRemovalConfig,
    ).removeBackground(
      sourceImagePath: sourcePath,
      destinationImagePath: transparentPath,
      trimToForeground: false,
      debugSession: BackgroundRemovalDebugSession(
        rootDirectoryPath: debugRootPath,
        fileName: 'artifact.png',
      ),
    );

    expect(await File('$debugRootPath/original/artifact.png').exists(), isTrue);
    expect(await File('$debugRootPath/stroke/artifact.png').exists(), isTrue);
    expect(
      await File('$debugRootPath/floodfill/artifact.png').exists(),
      isTrue,
    );
    expect(await File('$debugRootPath/mask/artifact.png').exists(), isTrue);
    expect(await File('$debugRootPath/preview/artifact.png').exists(), isTrue);
  });
}
