import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/character_repository.dart';

class GetCharactersUseCase {
  const GetCharactersUseCase({required CharacterRepository characterRepository})
      : _characterRepository = characterRepository;

  final CharacterRepository _characterRepository;

  Future<List<Character>> call() {
    return _characterRepository.getCharacters();
  }
}

final getCharactersUseCaseProvider = Provider<GetCharactersUseCase>(
  (ref) => GetCharactersUseCase(
    characterRepository: ref.watch(characterRepositoryProvider),
  ),
);
