import 'dart:io';
import 'dart:typed_data';

import 'package:doodleland/feature/capture/data/image_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'image-processor-test',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('rotateClockwise swaps width and height', () async {
    final source = image.Image(width: 8, height: 5);
    final bytes = Uint8List.fromList(image.encodePng(source));
    const processor = ImageProcessor();

    final rotated = await processor.rotateClockwise(bytes);

    expect(rotated.width, 5);
    expect(rotated.height, 8);
  });

  test('writeTemporaryPng stores result in capture_crop directory', () async {
    final source = image.Image(width: 4, height: 4);
    final bytes = Uint8List.fromList(image.encodePng(source));
    final processor = ImageProcessor(
      temporaryDirectoryLoader: () async => tempDirectory,
    );

    final outputPath = await processor.writeTemporaryPng(bytes);

    expect(outputPath, contains('${tempDirectory.path}/capture_crop/'));
    expect(await File(outputPath).exists(), isTrue);
  });
}
