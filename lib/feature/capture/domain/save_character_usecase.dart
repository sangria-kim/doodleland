import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;

import '../../../core/storage/character_storage_paths.dart';
import '../../library/data/character_repository.dart';
import '../data/background_remover.dart';

class SaveCharacterUseCase {
  const SaveCharacterUseCase({
    required CharacterRepository characterRepository,
    required CharacterStoragePathFactory characterStoragePathFactory,
    BackgroundRemover? backgroundRemover,
  })  : _characterRepository = characterRepository,
        _characterStoragePathFactory = characterStoragePathFactory,
        _backgroundRemover = backgroundRemover ?? const BackgroundRemover();

  final CharacterRepository _characterRepository;
  final CharacterStoragePathFactory _characterStoragePathFactory;
  final BackgroundRemover _backgroundRemover;

  Future<SaveCharacterResult> call({required String sourceImagePath}) async {
    final source = File(sourceImagePath);
    if (!await source.exists()) {
      throw StateError('원본 이미지가 존재하지 않습니다.');
    }

    final bytes = await source.readAsBytes();
    final decodedImage = image.decodeImage(bytes);
    if (decodedImage == null) {
      throw StateError('이미지 디코드에 실패했습니다.');
    }
    final width = decodedImage.width;
    final height = decodedImage.height;

    final storagePaths = await _characterStoragePathFactory.create();
    final originalImagePath = await storagePaths.originalImagePath();
    final transparentImagePath = await storagePaths.transparentImagePath();
    final thumbnailPath = await storagePaths.thumbnailImagePath();

    await source.copy(originalImagePath);
    final removalResult = await _backgroundRemover.removeBackground(
      sourceImagePath: sourceImagePath,
      destinationImagePath: transparentImagePath,
    );
    await _saveThumbnailImage(
      sourceImage: decodedImage,
      destinationImagePath: thumbnailPath,
    );

    final savedId = await _characterRepository.saveCharacter(
      name: '그림 ${DateTime.now().toIso8601String()}',
      originalImagePath: originalImagePath,
      transparentImagePath: transparentImagePath,
      thumbnailPath: thumbnailPath,
      width: width,
      height: height,
    );

    return SaveCharacterResult(
      characterId: savedId,
      qualityWarningMessage: removalResult.qualityWarningMessage,
    );
  }

  Future<void> _saveThumbnailImage({
    required image.Image sourceImage,
    required String destinationImagePath,
  }) async {
    final resizedImage = image.copyResize(sourceImage, width: 200);
    await File(destinationImagePath).writeAsBytes(
      image.encodePng(resizedImage),
    );
  }
}

class SaveCharacterResult {
  const SaveCharacterResult({
    required this.characterId,
    this.qualityWarningMessage,
  });

  final int characterId;
  final String? qualityWarningMessage;
}

final saveCharacterUseCaseProvider = Provider<SaveCharacterUseCase>((ref) {
  return SaveCharacterUseCase(
    characterRepository: ref.watch(characterRepositoryProvider),
    characterStoragePathFactory: const CharacterStoragePathFactory(),
    backgroundRemover: const BackgroundRemover(),
  );
});
