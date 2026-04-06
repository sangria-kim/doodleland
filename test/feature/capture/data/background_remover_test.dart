import 'dart:io';
import 'dart:typed_data';

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

      final result = await const RuleBasedBackgroundRemover().removeBackground(
        sourceImagePath: sourcePath,
        destinationImagePath: transparentPath,
        maxDimension: 1500,
      );

      final output = img.decodeImage(
        await File(transparentPath).readAsBytes(),
      )!;
      expect(output, isNotNull);
      expect(result.wasTrimmed, isTrue);
      expect(result.transparentWidth, inInclusiveRange(5, 12));
      expect(result.transparentHeight, inInclusiveRange(5, 12));
      expect(output.width, equals(result.transparentWidth));
      expect(output.height, equals(result.transparentHeight));
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

      final result = await const RuleBasedBackgroundRemover().removeBackground(
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

    final result = await const RuleBasedBackgroundRemover().removeBackground(
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

    final result = await const RuleBasedBackgroundRemover().removeBackground(
      sourceImagePath: sourcePath,
      destinationImagePath: transparentPath,
      trimToForeground: false,
    );

    final output = img.decodeImage(await File(transparentPath).readAsBytes())!;
    expect(result.transparentAreaRatio, greaterThan(0.70));
    expect(output.width, equals(48));
    expect(output.height, equals(32));
    expect(output.getPixel(0, 0).a.round(), equals(0));
    expect(output.getPixel(10, 9).a.round(), equals(255));
  });

  test(
    'suppresses gray paper and edge shadows while keeping color strokes',
    () async {
      final sourceImage = img.Image(width: 96, height: 96);
      for (var y = 0; y < sourceImage.height; y++) {
        for (var x = 0; x < sourceImage.width; x++) {
          final base = 206 + ((x + y) % 10);
          sourceImage.setPixelRgba(x, y, base, base - 2, base - 4, 255);
        }
      }

      for (var y = 0; y < sourceImage.height; y++) {
        for (var x = 0; x < 22; x++) {
          sourceImage.setPixelRgba(x, y, 168, 165, 162, 255);
        }
      }
      for (var y = 68; y < sourceImage.height; y++) {
        for (var x = 64; x < sourceImage.width; x++) {
          sourceImage.setPixelRgba(x, y, 178, 175, 170, 255);
        }
      }

      for (var x = 28; x <= 70; x++) {
        sourceImage.setPixelRgba(x, 24, 60, 140, 72, 255);
        sourceImage.setPixelRgba(x, 36, 62, 144, 74, 255);
      }
      for (var y = 24; y <= 66; y++) {
        sourceImage.setPixelRgba(24, y, 158, 62, 56, 255);
        sourceImage.setPixelRgba(72, y, 160, 64, 58, 255);
      }
      for (var y = 40; y <= 76; y++) {
        final startX = 34 + ((y - 40) ~/ 3);
        final endX = 62 - ((y - 40) ~/ 4);
        for (var x = startX; x <= endX; x++) {
          sourceImage.setPixelRgba(x, y, 180, 84, 88, 255);
        }
      }

      final sourcePath = '${tempDirectory.path}/gray_paper_source.png';
      final transparentPath =
          '${tempDirectory.path}/gray_paper_transparent.png';
      await File(sourcePath).writeAsBytes(img.encodePng(sourceImage));

      final result = await const RuleBasedBackgroundRemover().removeBackground(
        sourceImagePath: sourcePath,
        destinationImagePath: transparentPath,
        trimToForeground: false,
      );

      final output = img.decodeImage(
        await File(transparentPath).readAsBytes(),
      )!;
      expect(result.transparentAreaRatio, greaterThan(0.60));
      expect(output.getPixel(24, 30).a.round(), equals(255));
      expect(output.getPixel(50, 56).a.round(), equals(255));
    },
  );

  test(
    'preserves enclosed interior colors when dark outline is dominant',
    () async {
      final sourceImage = img.Image(width: 96, height: 72);
      for (var y = 0; y < sourceImage.height; y++) {
        for (var x = 0; x < sourceImage.width; x++) {
          sourceImage.setPixelRgba(x, y, 246, 245, 240, 255);
        }
      }

      for (var y = 4; y < 18; y++) {
        for (var x = 4; x < 18; x++) {
          final tint = 220 + ((x + y) % 12);
          sourceImage.setPixelRgba(x, y, 210, tint, 232, 255);
        }
      }
      for (var y = 50; y < 68; y++) {
        for (var x = 78; x < 94; x++) {
          sourceImage.setPixelRgba(x, y, 226, 226, 226, 255);
        }
      }

      for (var x = 20; x <= 75; x++) {
        for (var t = 0; t < 3; t++) {
          sourceImage.setPixelRgba(x, 18 + t, 22, 24, 30, 255);
          sourceImage.setPixelRgba(x, 53 - t, 22, 24, 30, 255);
        }
      }
      for (var y = 18; y <= 53; y++) {
        for (var t = 0; t < 3; t++) {
          sourceImage.setPixelRgba(20 + t, y, 22, 24, 30, 255);
          sourceImage.setPixelRgba(75 - t, y, 22, 24, 30, 255);
        }
      }

      for (var y = 22; y <= 49; y++) {
        for (var x = 24; x <= 71; x++) {
          final variation = ((x * 3 + y * 5) % 16) - 8;
          sourceImage.setPixelRgba(
            x,
            y,
            (232 + variation).clamp(0, 255),
            (216 + variation).clamp(0, 255),
            (238 + variation).clamp(0, 255),
            255,
          );
        }
      }

      final remover = const RuleBasedBackgroundRemover();
      final result = await remover.remove(
        Uint8List.fromList(img.encodePng(sourceImage)),
        trimToForeground: false,
      );
      expect(result.success, isTrue);

      final output = img.decodeImage(result.outputImageBytes)!;
      expect(output.getPixel(30, 30).a.round(), equals(255));
      expect(output.getPixel(68, 42).a.round(), equals(255));
      expect(output.getPixel(6, 6).a.round(), equals(0));
      expect(output.getPixel(86, 60).a.round(), equals(0));
      expect(result.transparentAreaRatio, greaterThan(0.50));
      expect(result.transparentAreaRatio, lessThan(0.95));
    },
  );

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

    await RuleBasedBackgroundRemover(
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

    await RuleBasedBackgroundRemover(
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
    expect(
      await File('$debugRootPath/paper_profile/artifact.png').exists(),
      isTrue,
    );
    expect(
      await File('$debugRootPath/line_mask/artifact.png').exists(),
      isTrue,
    );
    expect(
      await File('$debugRootPath/color_mask/artifact.png').exists(),
      isTrue,
    );
    expect(
      await File('$debugRootPath/edge_preservation_mask/artifact.png').exists(),
      isTrue,
    );
    expect(
      await File('$debugRootPath/merged_mask/artifact.png').exists(),
      isTrue,
    );
    expect(
      await File('$debugRootPath/final_alpha_result/artifact.png').exists(),
      isTrue,
    );
  });
}
