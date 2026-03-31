import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';

class EditableImageData {
  const EditableImageData({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  double get aspectRatio => width / height;
}

class ImageProcessor {
  const ImageProcessor({
    Future<Directory> Function()? temporaryDirectoryLoader,
  }) : _temporaryDirectoryLoader = temporaryDirectoryLoader;

  final Future<Directory> Function()? _temporaryDirectoryLoader;

  Future<EditableImageData> loadEditableImage(String sourceImagePath) async {
    final file = File(sourceImagePath);
    if (!await file.exists()) {
      throw StateError('원본 이미지가 존재하지 않습니다.');
    }

    final bytes = await file.readAsBytes();
    return parseEditableImage(bytes);
  }

  Future<EditableImageData> parseEditableImage(Uint8List bytes) async {
    return Isolate.run(() => _decodeEditableImage(bytes));
  }

  Future<EditableImageData> rotateClockwise(Uint8List sourceBytes) async {
    return Isolate.run(() => _rotateEditableImage(sourceBytes));
  }

  Future<String> writeTemporaryPng(Uint8List pngBytes) async {
    final baseDirectory =
        await (_temporaryDirectoryLoader?.call() ?? getTemporaryDirectory());
    final targetDirectory = Directory('${baseDirectory.path}/capture_crop');
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final path =
        '${targetDirectory.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(pngBytes, flush: true);
    return path;
  }

  static EditableImageData _decodeEditableImage(Uint8List bytes) {
    final decoded = image.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('이미지 디코드에 실패했습니다.');
    }

    return EditableImageData(
      bytes: bytes,
      width: decoded.width,
      height: decoded.height,
    );
  }

  static EditableImageData _rotateEditableImage(Uint8List sourceBytes) {
    final decoded = image.decodeImage(sourceBytes);
    if (decoded == null) {
      throw StateError('이미지 디코드에 실패했습니다.');
    }

    final rotated = image.copyRotate(decoded, angle: 90);
    final rotatedBytes = Uint8List.fromList(image.encodePng(rotated));
    return EditableImageData(
      bytes: rotatedBytes,
      width: rotated.width,
      height: rotated.height,
    );
  }
}

final imageProcessorProvider = Provider<ImageProcessor>((_) {
  return const ImageProcessor();
});
