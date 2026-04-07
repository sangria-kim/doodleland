import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/scene_repository.dart';
import '../domain/model/motion_preset.dart';
import '../domain/model/placed_character.dart';
import '../domain/model/stage_background.dart';
import '../domain/place_character_usecase.dart';

@immutable
class StageState {
  const StageState({
    this.placedCharacters = const [],
    this.errorMessage,
    required this.selectedBackground,
  });

  final List<PlacedCharacter> placedCharacters;
  final String? errorMessage;
  final StageBackground selectedBackground;

  bool get isFull => placedCharacters.length >= 10;

  StageState copyWith({
    List<PlacedCharacter>? placedCharacters,
    String? errorMessage,
    StageBackground? selectedBackground,
  }) {
    return StageState(
      placedCharacters: placedCharacters ?? this.placedCharacters,
      errorMessage: errorMessage,
      selectedBackground: selectedBackground ?? this.selectedBackground,
    );
  }
}

class StageViewModel extends StateNotifier<StageState> {
  StageViewModel({
    required PlaceCharacterUseCase placeCharacterUseCase,
    required StageBackground initialBackground,
  }) : _placeCharacterUseCase = placeCharacterUseCase,
       super(StageState(selectedBackground: initialBackground));

  final PlaceCharacterUseCase _placeCharacterUseCase;

  Future<bool> placeCharacter({
    required Character character,
    required MotionPreset objectMotion,
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
      objectMotion: objectMotion,
      groundY: state.selectedBackground.groundY,
      zIndex: nextZIndex,
    );

    state = state.copyWith(
      placedCharacters: [...state.placedCharacters, placedCharacter],
      errorMessage: null,
    );
    return true;
  }

  bool updateCharacterPosition({
    required String instanceId,
    required Offset position,
  }) {
    final index = state.placedCharacters.indexWhere(
      (character) => character.instanceId == instanceId,
    );
    if (index == -1) {
      return false;
    }

    final clampedPosition = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );

    final placed = state.placedCharacters[index];
    if (placed.removalState == PlacedCharacterRemovalState.removing) {
      return false;
    }

    final updated = placed.copyWith(
      stageRuntime: placed.stageRuntime.copyWith(position: clampedPosition),
    );
    final nextCharacters = [...state.placedCharacters];
    nextCharacters[index] = updated;

    state = state.copyWith(
      placedCharacters: nextCharacters,
      errorMessage: null,
    );
    return true;
  }

  void bringCharacterToFront(String instanceId) {
    final index = state.placedCharacters.indexWhere(
      (character) => character.instanceId == instanceId,
    );
    if (index == -1) {
      return;
    }

    final maxZIndex = state.placedCharacters.fold<int>(
      0,
      (acc, item) => item.zIndex > acc ? item.zIndex : acc,
    );
    final placed = state.placedCharacters[index];
    if (placed.removalState == PlacedCharacterRemovalState.removing) {
      return;
    }

    final updated = placed.copyWith(zIndex: maxZIndex + 1);
    final nextCharacters = [...state.placedCharacters];
    nextCharacters[index] = updated;

    state = state.copyWith(
      placedCharacters: nextCharacters,
      errorMessage: null,
    );
  }

  bool removeCharacter(String instanceId) {
    final found = state.placedCharacters.any(
      (character) => character.instanceId == instanceId,
    );
    if (!found) {
      return false;
    }

    final remaining = state.placedCharacters
        .where((character) => character.instanceId != instanceId)
        .toList(growable: false);
    state = state.copyWith(placedCharacters: remaining, errorMessage: null);
    return true;
  }

  bool requestCharacterRemoval(String instanceId) {
    final index = state.placedCharacters.indexWhere(
      (character) => character.instanceId == instanceId,
    );
    if (index == -1) {
      return false;
    }

    final placed = state.placedCharacters[index];
    if (placed.removalState == PlacedCharacterRemovalState.removing) {
      return false;
    }

    final updated = placed.copyWith(
      removalState: PlacedCharacterRemovalState.removing,
      stageRuntime: placed.stageRuntime.copyWith(isPaused: true),
    );
    final nextCharacters = [...state.placedCharacters];
    nextCharacters[index] = updated;
    state = state.copyWith(
      placedCharacters: nextCharacters,
      errorMessage: null,
    );
    return true;
  }

  bool completeCharacterRemoval(String instanceId) {
    final found = state.placedCharacters.any(
      (character) => character.instanceId == instanceId,
    );
    if (!found) {
      return false;
    }

    final remaining = state.placedCharacters
        .where((character) => character.instanceId != instanceId)
        .toList(growable: false);
    state = state.copyWith(placedCharacters: remaining, errorMessage: null);
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void selectBackground(StageBackground background) {
    state = state.copyWith(selectedBackground: background);
  }
}

final stageViewModelProvider =
    StateNotifierProvider<StageViewModel, StageState>(
      (ref) => StageViewModel(
        placeCharacterUseCase: ref.watch(placeCharacterUseCaseProvider),
        initialBackground: ref.watch(sceneRepositoryProvider).defaultBackground,
      ),
    );
