import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;

import '../../../core/storage/character_storage_paths.dart';
import '../../library/data/character_repository.dart';

class SaveCharacterUseCase {
  const SaveCharacterUseCase({
    required CharacterRepository characterRepository,
    required CharacterStoragePathFactory characterStoragePathFactory,
  })  : _characterRepository = characterRepository,
        _characterStoragePathFactory = characterStoragePathFactory;

  final CharacterRepository _characterRepository;
  final CharacterStoragePathFactory _characterStoragePathFactory;

  Future<int> call({required String sourceImagePath}) async {
    final source = File(sourceImagePath);
    if (!await source.exists()) {
      throw StateError('원본 이미지가 존재하지 않습니다.');
    }

    final bytes = await source.readAsBytes();
    final decodedImage = image.decodeImage(bytes);
    final width = decodedImage?.width ?? 0;
    final height = decodedImage?.height ?? 0;

    final storagePaths = await _characterStoragePathFactory.create();
    final originalImagePath = await storagePaths.originalImagePath();
    final transparentImagePath = await storagePaths.transparentImagePath();
    final thumbnailPath = await storagePaths.thumbnailImagePath(extension: 'jpg');

    await Future.wait([
      source.copy(originalImagePath),
      source.copy(transparentImagePath),
      source.copy(thumbnailPath),
    ]);

    return _characterRepository.saveCharacter(
      name: '그림 ${DateTime.now().toIso8601String()}',
      originalImagePath: originalImagePath,
      transparentImagePath: transparentImagePath,
      thumbnailPath: thumbnailPath,
      width: width,
      height: height,
    );
  }
}

final saveCharacterUseCaseProvider = Provider<SaveCharacterUseCase>((ref) {
  return SaveCharacterUseCase(
    characterRepository: ref.watch(characterRepositoryProvider),
    characterStoragePathFactory: const CharacterStoragePathFactory(),
  );
});
