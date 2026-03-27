import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/character_repository.dart';

class DeleteCharacterUseCase {
  const DeleteCharacterUseCase({required CharacterRepository characterRepository})
      : _characterRepository = characterRepository;

  final CharacterRepository _characterRepository;

  Future<bool> call(Character character) async {
    final isDeleted = await _characterRepository.removeCharacter(character.id);
    if (!isDeleted) {
      return false;
    }

    await Future.wait([
      _deleteFile(character.originalImagePath),
      _deleteFile(character.transparentImagePath),
      _deleteFile(character.thumbnailPath),
    ]);

    return true;
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 파일이 이미 사라졌거나 접근 권한이 없는 경우에도 삭제 처리 자체는 계속 진행합니다.
    }
  }
}

final deleteCharacterUseCaseProvider = Provider<DeleteCharacterUseCase>(
  (ref) => DeleteCharacterUseCase(
    characterRepository: ref.watch(characterRepositoryProvider),
  ),
);
