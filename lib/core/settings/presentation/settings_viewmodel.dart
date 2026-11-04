import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/file_settings_repository.dart';
import '../domain/play_settings.dart';
import '../domain/settings_repository.dart';

class SettingsState {
  const SettingsState({
    this.settings = const PlaySettings(),
    this.isSaving = false,
    this.saveError,
    this.restoreError,
  });

  final PlaySettings settings;
  final bool isSaving;
  final Object? saveError;
  final Object? restoreError;
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel(this._repository, SettingsLoadResult initial)
    : super(
        SettingsState(
          settings: initial.settings,
          restoreError: initial.restoreError,
        ),
      );

  final SettingsRepository _repository;
  int _revision = 0;
  Future<void>? _saving;

  void setMusicEnabled(bool value) =>
      _update(state.settings.copyWith(musicEnabled: value));
  void setEffectsEnabled(bool value) =>
      _update(state.settings.copyWith(effectsEnabled: value));
  void setVoiceEnabled(bool value) =>
      _update(state.settings.copyWith(voiceEnabled: value));
  void setReduceEffects(bool value) =>
      _update(state.settings.copyWith(reduceEffects: value));

  void _update(PlaySettings settings) {
    if (settings == state.settings) return;
    _revision++;
    state = SettingsState(
      settings: settings,
      isSaving: true,
      restoreError: state.restoreError,
    );
    _startSaving();
  }

  void retrySave() {
    _revision++;
    state = SettingsState(
      settings: state.settings,
      isSaving: true,
      restoreError: state.restoreError,
    );
    _startSaving();
  }

  // App-scoped, serialized snapshots: an older write can never overwrite a
  // newer snapshot or mark a newer unsaved selection as saved.
  void _startSaving() {
    _saving ??= _drain().whenComplete(() {
      _saving = null;
      if (mounted && state.isSaving) _startSaving();
    });
  }

  Future<void> _drain() async {
    while (mounted) {
      final revision = _revision;
      final snapshot = state.settings;
      Object? failure;
      try {
        await _repository.save(snapshot);
      } catch (error) {
        failure = error;
      }
      if (!mounted) return;
      if (revision != _revision) continue;
      state = SettingsState(
        settings: state.settings,
        saveError: failure,
        restoreError: failure == null ? null : state.restoreError,
      );
      return;
    }
  }

  Future<void> get pendingSave => _saving ?? Future<void>.value();
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => FileSettingsRepository(),
);
final initialSettingsProvider = Provider<SettingsLoadResult>(
  (ref) => const SettingsLoadResult(),
);
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>(
      (ref) => SettingsViewModel(
        ref.watch(settingsRepositoryProvider),
        ref.watch(initialSettingsProvider),
      ),
    );
