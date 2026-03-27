import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/model/motion_preset.dart';
import '../domain/model/placed_character.dart';
import '../domain/place_character_usecase.dart';

@immutable
class StageState {
  const StageState({
    this.placedCharacters = const [],
    this.errorMessage,
  });

  final List<PlacedCharacter> placedCharacters;
  final String? errorMessage;

  bool get isFull => placedCharacters.length >= 10;

  StageState copyWith({
    List<PlacedCharacter>? placedCharacters,
    String? errorMessage,
  }) {
    return StageState(
      placedCharacters: placedCharacters ?? this.placedCharacters,
      errorMessage: errorMessage,
    );
  }
}

class StageViewModel extends StateNotifier<StageState> {
  StageViewModel({required PlaceCharacterUseCase placeCharacterUseCase})
      : _placeCharacterUseCase = placeCharacterUseCase,
        super(const StageState());

  final PlaceCharacterUseCase _placeCharacterUseCase;

  Future<bool> placeCharacter({
    required Character character,
    required MotionPreset motionPreset,
  }) async {
    if (state.isFull) {
      state = state.copyWith(errorMessage: '무대가 꽉 찼어요!');
      return false;
    }

    final nextZIndex = state.placedCharacters.isEmpty
        ? 0
        : state.placedCharacters.last.zIndex + 1;
    final placedCharacter = await _placeCharacterUseCase(
      character: character,
      motionPreset: motionPreset,
      zIndex: nextZIndex,
    );

    state = state.copyWith(
      placedCharacters: [...state.placedCharacters, placedCharacter],
      errorMessage: null,
    );
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final stageViewModelProvider =
    StateNotifierProvider<StageViewModel, StageState>(
  (ref) => StageViewModel(
    placeCharacterUseCase: ref.watch(placeCharacterUseCaseProvider),
  ),
);
