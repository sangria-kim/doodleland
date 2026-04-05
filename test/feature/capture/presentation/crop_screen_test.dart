import 'dart:io';
import 'dart:typed_data';

import 'package:doodleland/feature/capture/data/image_processor.dart';
import 'package:doodleland/feature/capture/presentation/crop_screen.dart';
import 'package:doodleland/feature/capture/presentation/crop_screen_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

class _FakeImageProcessor extends ImageProcessor {
  _FakeImageProcessor({required EditableImageData editableImage})
    : _editableImage = editableImage;

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
          home: CropScreen(
            args: CropScreenArgs(sourceImagePath: sourceImagePath),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  }

  String readRatioText(WidgetTester tester) {
    final ratioText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('crop-ratio-text')),
        matching: find.byType(Text),
      ),
    );
    return ratioText.data ?? '';
  }

  testWidgets(
    'renders portrait layout with overlay actions and compact labels',
    (WidgetTester tester) async {
      await pumpCropScreen(tester, logicalSize: const Size(390, 844));

      expect(
        find.byKey(const ValueKey('crop-portrait-layout')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('crop-close-btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop-rotate-btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop-reset-btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('crop-apply-btn')), findsOneWidget);

      expect(find.text('이미지 자르기'), findsNothing);
      expect(find.text('고정 비율'), findsNothing);
      expect(find.text('비율'), findsNothing);
      expect(find.text('동작'), findsNothing);

      expect(find.byKey(const ValueKey('aspect-free')), findsOneWidget);
      expect(find.byKey(const ValueKey('aspect-square')), findsOneWidget);
      expect(find.byKey(const ValueKey('aspect-ratio4x3')), findsOneWidget);
      expect(find.byKey(const ValueKey('aspect-ratio16x9')), findsOneWidget);
      expect(find.byKey(const ValueKey('aspect-original')), findsNothing);
    },
  );

  testWidgets('renders landscape layout with right vertical ratio buttons', (
    WidgetTester tester,
  ) async {
    await pumpCropScreen(tester, logicalSize: const Size(844, 390));

    expect(find.byKey(const ValueKey('crop-landscape-layout')), findsOneWidget);

    final freeCenter = tester.getCenter(
      find.byKey(const ValueKey('aspect-free')),
    );
    final squareCenter = tester.getCenter(
      find.byKey(const ValueKey('aspect-square')),
    );
    final ratio4x3Center = tester.getCenter(
      find.byKey(const ValueKey('aspect-ratio4x3')),
    );

    expect((freeCenter.dx - squareCenter.dx).abs(), lessThan(2));
    expect((squareCenter.dx - ratio4x3Center.dx).abs(), lessThan(2));
    expect(squareCenter.dy, greaterThan(freeCenter.dy));
    expect(ratio4x3Center.dy, greaterThan(squareCenter.dy));
  });

  testWidgets('renders tablet layout with same control structure', (
    WidgetTester tester,
  ) async {
    await pumpCropScreen(tester, logicalSize: const Size(1024, 768));

    expect(find.byKey(const ValueKey('crop-tablet-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('crop-apply-btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('aspect-ratio16x9')), findsOneWidget);
  });

  testWidgets('updates ratio chip with value-only text on fixed ratio select', (
    WidgetTester tester,
  ) async {
    await pumpCropScreen(tester, logicalSize: const Size(390, 844));

    expect(readRatioText(tester), '자유');

    await tester.tap(find.byKey(const ValueKey('aspect-square')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(readRatioText(tester), '1:1');
  });

  testWidgets(
    'shows reset confirmation dialog and applies reset only on confirm',
    (WidgetTester tester) async {
      await pumpCropScreen(tester, logicalSize: const Size(390, 844));

      await tester.tap(find.byKey(const ValueKey('aspect-ratio4x3')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(readRatioText(tester), '4:3');

      await tester.tap(find.byKey(const ValueKey('crop-reset-btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('변경사항을 모두 취소하고 원본 이미지로 복원 할까요?'), findsOneWidget);
      expect(find.text('원본 복원'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(readRatioText(tester), '4:3');

      await tester.tap(find.byKey(const ValueKey('crop-reset-btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('원본 복원'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(readRatioText(tester), '자유');
    },
  );
}
