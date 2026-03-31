import 'dart:io';
import 'dart:typed_data';

import 'package:doodleland/feature/capture/data/image_processor.dart';
import 'package:doodleland/feature/capture/presentation/crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

class _FakeImageProcessor extends ImageProcessor {
  _FakeImageProcessor({
    required EditableImageData editableImage,
  }) : _editableImage = editableImage;

  final EditableImageData _editableImage;

  @override
  Future<EditableImageData> loadEditableImage(String sourceImagePath) async {
    return _editableImage;
  }

  @override
  Future<EditableImageData> rotateClockwise(Uint8List sourceBytes) async {
    return EditableImageData(
      bytes: _editableImage.bytes,
      width: _editableImage.height,
      height: _editableImage.width,
    );
  }
}

void main() {
  late Directory tempDirectory;
  late String sourceImagePath;
  late EditableImageData editableImage;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('crop-screen-test');
    final source = image.Image(width: 160, height: 90);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 240, 240, 240, 255);
      }
    }
    sourceImagePath = '${tempDirectory.path}/sample.png';
    final bytes = Uint8List.fromList(image.encodePng(source));
    await File(sourceImagePath).writeAsBytes(bytes);
    editableImage = EditableImageData(bytes: bytes, width: 160, height: 90);
  });

  tearDown(() async {
    await TestWidgetsFlutterBinding.ensureInitialized().runAsync(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
  });

  Future<void> pumpCropScreen(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imageProcessorProvider.overrideWith(
            (_) => _FakeImageProcessor(editableImage: editableImage),
          ),
        ],
        child: MaterialApp(
          home: CropScreen(sourceImagePath: sourceImagePath),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('renders portrait layout with ratio panel and actions', (
    WidgetTester tester,
  ) async {
    await pumpCropScreen(tester, logicalSize: const Size(390, 844));

    expect(find.byKey(const ValueKey('crop-portrait-layout')), findsOneWidget);
    expect(find.text('비율'), findsOneWidget);
    expect(find.text('동작'), findsOneWidget);
    expect(find.text('원본 16:9'), findsOneWidget);
  });

  testWidgets('renders landscape layout with left ratio panel', (
    WidgetTester tester,
  ) async {
    await pumpCropScreen(tester, logicalSize: const Size(844, 390));

    expect(find.byKey(const ValueKey('crop-landscape-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('aspect-free')), findsOneWidget);
    expect(find.text('회전'), findsOneWidget);
  });

  testWidgets('renders tablet layout with side action panel', (
    WidgetTester tester,
  ) async {
    await pumpCropScreen(tester, logicalSize: const Size(1024, 768));

    expect(find.byKey(const ValueKey('crop-tablet-layout')), findsOneWidget);
    expect(find.text('동작'), findsOneWidget);
    expect(find.text('비율'), findsOneWidget);
  });

  testWidgets('updates ratio label when free mode is selected', (
    WidgetTester tester,
  ) async {
    await pumpCropScreen(tester, logicalSize: const Size(390, 844));

    await tester.tap(find.byKey(const ValueKey('aspect-free')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final ratioText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('crop-ratio-text')),
        matching: find.byType(Text),
      ),
    );
    expect(ratioText.data, startsWith('자유'));
  });
}
