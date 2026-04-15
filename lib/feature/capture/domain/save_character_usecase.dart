import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;

import '../../../core/storage/character_storage_paths.dart';
import '../data/background_removal_config.dart';
import '../../library/data/character_repository.dart';
import '../data/background_remover.dart';

const double _preprocessedInputNonOpaqueThreshold = 0.05;

class SaveCharacterUseCase {
  const SaveCharacterUseCase({
    required CharacterRepository characterRepository,
    required CharacterStoragePathFactory characterStoragePathFactory,
    BackgroundRemover? backgroundRemover,
  }) : _characterRepository = characterRepository,
       _characterStoragePathFactory = characterStoragePathFactory,
       _backgroundRemover =
           backgroundRemover ?? const RuleBasedBackgroundRemover();

  final CharacterRepository _characterRepository;
  final CharacterStoragePathFactory _characterStoragePathFactory;
  final BackgroundRemover _backgroundRemover;

  Future<SaveCharacterResult> call({required String sourceImagePath}) async {
    final source = File(sourceImagePath);
    if (!await source.exists()) {
      throw StateError('원본 이미지가 존재하지 않습니다.');
    }

    final bytes = await source.readAsBytes();
    final inputAnalysis = _analyzeSaveInput(bytes);

    final storagePaths = await _characterStoragePathFactory.create();
    final originalImagePath = await storagePaths.originalImagePath();
    final transparentImagePath = await storagePaths.transparentImagePath();
    final thumbnailPath = await storagePaths.thumbnailImagePath();

    await source.copy(originalImagePath);
    var transparentImageBytes = inputAnalysis.normalizedPngBytes;
    var transparentWidth = inputAnalysis.width;
    var transparentHeight = inputAnalysis.height;
    String? qualityWarningMessage;

    if (!inputAnalysis.shouldPassthroughBackgroundRemoval) {
      final removalResult = await _backgroundRemover.remove(
        bytes,
        trimToForeground: false,
        debugSession: await _buildDebugSession(
          storagePaths: storagePaths,
          transparentImagePath: transparentImagePath,
        ),
      );
      if (!removalResult.success) {
        throw StateError('그림을 인식하지 못했어요');
      }
      transparentImageBytes = removalResult.outputImageBytes;
      transparentWidth = removalResult.outputWidth;
      transparentHeight = removalResult.outputHeight;
      qualityWarningMessage = removalResult.qualityWarningMessage;
    }

    await File(transparentImagePath).writeAsBytes(transparentImageBytes);
    await _saveThumbnailImage(
      sourceImageBytes: transparentImageBytes,
      destinationImagePath: thumbnailPath,
    );

    final savedId = await _characterRepository.saveCharacter(
      name: '그림 ${DateTime.now().toIso8601String()}',
      originalImagePath: originalImagePath,
      transparentImagePath: transparentImagePath,
      thumbnailPath: thumbnailPath,
      width: transparentWidth,
      height: transparentHeight,
    );

    return SaveCharacterResult(
      characterId: savedId,
      qualityWarningMessage: qualityWarningMessage,
    );
  }

  Future<void> _saveThumbnailImage({
    required Uint8List sourceImageBytes,
    required String destinationImagePath,
  }) async {
    final pngBytes = await Isolate.run(
      () => _renderThumbnailPng(sourceImageBytes: sourceImageBytes, width: 200),
    );

    await File(destinationImagePath).writeAsBytes(pngBytes);
  }

  Future<BackgroundRemovalDebugSession?> _buildDebugSession({
    required CharacterStoragePaths storagePaths,
    required String transparentImagePath,
  }) async {
    if (!kDebugMode || !debugBackgroundRemoval) {
      return null;
    }

    final rootDirectory = await storagePaths.debugRootDirectory;
    final fileName = transparentImagePath.split(Platform.pathSeparator).last;
    return BackgroundRemovalDebugSession(
      rootDirectoryPath: rootDirectory.path,
      fileName: fileName,
    );
  }
}

_SaveInputAnalysis _analyzeSaveInput(Uint8List sourceBytes) {
  final decodedImage = image.decodeImage(sourceBytes);
  if (decodedImage == null) {
    throw StateError('이미지 디코드에 실패했습니다.');
  }

  final totalPixels = decodedImage.width * decodedImage.height;
  var nonOpaquePixels = 0;
  for (var y = 0; y < decodedImage.height; y++) {
    for (var x = 0; x < decodedImage.width; x++) {
      if (decodedImage.getPixel(x, y).a.round() < 255) {
        nonOpaquePixels++;
      }
    }
  }

  final nonOpaquePixelRatio = totalPixels == 0
      ? 0.0
      : nonOpaquePixels / totalPixels;
  return _SaveInputAnalysis(
    normalizedPngBytes: Uint8List.fromList(image.encodePng(decodedImage)),
    width: decodedImage.width,
    height: decodedImage.height,
    nonOpaquePixelRatio: nonOpaquePixelRatio,
  );
}

class SaveCharacterResult {
  const SaveCharacterResult({
    required this.characterId,
    this.qualityWarningMessage,
  });

  final int characterId;
  final String? qualityWarningMessage;
}

class _SaveInputAnalysis {
  const _SaveInputAnalysis({
    required this.normalizedPngBytes,
    required this.width,
    required this.height,
    required this.nonOpaquePixelRatio,
  });

  final Uint8List normalizedPngBytes;
  final int width;
  final int height;
  final double nonOpaquePixelRatio;

  bool get shouldPassthroughBackgroundRemoval =>
      nonOpaquePixelRatio >= _preprocessedInputNonOpaqueThreshold;
}

List<int> _renderThumbnailPng({
  required Uint8List sourceImageBytes,
  int width = 200,
}) {
  final sourceImage = image.decodeImage(sourceImageBytes);
  if (sourceImage == null) {
    throw StateError('이미지 디코드에 실패했습니다.');
  }

  final resizedImage = image.copyResize(sourceImage, width: width);
  return image.encodePng(resizedImage);
}

final saveCharacterUseCaseProvider = Provider<SaveCharacterUseCase>((ref) {
  return SaveCharacterUseCase(
    characterRepository: ref.watch(characterRepositoryProvider),
    characterStoragePathFactory: const CharacterStoragePathFactory(),
    backgroundRemover: ref.watch(backgroundRemoverProvider),
  );
});
