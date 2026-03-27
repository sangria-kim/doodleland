import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/delete_character_usecase.dart';
import '../domain/get_characters_usecase.dart';

@immutable
class LibraryState {
  const LibraryState({
    this.characters = const [],
    this.isLoading = false,
    this.deletingCharacterId,
    this.errorMessage,
    this.hasLoaded = false,
  });

  final List<Character> characters;
  final bool isLoading;
  final int? deletingCharacterId;
  final String? errorMessage;
  final bool hasLoaded;

  LibraryState copyWith({
    List<Character>? characters,
    bool? isLoading,
    int? deletingCharacterId,
    String? errorMessage,
    bool? hasLoaded,
  }) {
    return LibraryState(
      characters: characters ?? this.characters,
      isLoading: isLoading ?? this.isLoading,
      deletingCharacterId: deletingCharacterId,
      errorMessage: errorMessage,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class LibraryViewModel extends StateNotifier<LibraryState> {
  LibraryViewModel({
    required GetCharactersUseCase getCharactersUseCase,
    required DeleteCharacterUseCase deleteCharacterUseCase,
  })  : _getCharactersUseCase = getCharactersUseCase,
        _deleteCharacterUseCase = deleteCharacterUseCase,
        super(const LibraryState());

  final GetCharactersUseCase _getCharactersUseCase;
  final DeleteCharacterUseCase _deleteCharacterUseCase;

  Future<void> loadCharacters() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      hasLoaded: true,
    );

    try {
      final characters = await _getCharactersUseCase();
      state = state.copyWith(isLoading: false, characters: characters);
    } catch (error, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        characters: const [],
      );
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<bool> deleteCharacter(Character character) async {
    if (state.deletingCharacterId != null) {
      return false;
    }
    state = state.copyWith(deletingCharacterId: character.id, errorMessage: null);
    try {
      final deleted = await _deleteCharacterUseCase(character);
      if (!deleted) {
        state = state.copyWith(
          deletingCharacterId: null,
          errorMessage: '해당 그림을 삭제하지 못했습니다.',
        );
        return false;
      }

      final remaining = state.characters
          .where((item) => item.id != character.id)
          .toList(growable: false);
      state = state.copyWith(isLoading: false, characters: remaining, deletingCharacterId: null);
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(
        deletingCharacterId: null,
        errorMessage: '삭제 중 오류가 발생했습니다: $error',
      );
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
      return false;
    }
  }
}

final libraryViewModelProvider =
    StateNotifierProvider<LibraryViewModel, LibraryState>(
  (ref) => LibraryViewModel(
    getCharactersUseCase: ref.watch(getCharactersUseCaseProvider),
    deleteCharacterUseCase: ref.watch(deleteCharacterUseCaseProvider),
  ),
);
