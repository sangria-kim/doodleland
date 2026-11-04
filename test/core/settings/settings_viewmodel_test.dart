import 'dart:async';

import 'package:doodleland/core/settings/domain/play_settings.dart';
import 'package:doodleland/core/settings/domain/settings_repository.dart';
import 'package:doodleland/core/settings/presentation/settings_viewmodel.dart';
import 'package:doodleland/main.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements SettingsRepository {
  final writes = <PlaySettings>[];
  final gates = <Completer<void>>[];
  PlaySettings saved = const PlaySettings();
  Completer<SettingsLoadResult>? loadGate;
  @override
  Future<SettingsLoadResult> load() =>
      loadGate?.future ?? Future.value(SettingsLoadResult(settings: saved));
  @override
  Future<void> save(PlaySettings settings) async {
    writes.add(settings);
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    saved = settings;
  }
}

void main() {
  test('bootstrap does not launch UI before delayed restoration', () async {
    final repository = _Repository()
      ..loadGate = Completer<SettingsLoadResult>();
    SettingsLoadResult? launched;
    final boot = bootstrapSettings(
      repository: repository,
      launch: (_, initial) => launched = initial,
    );
    await Future<void>.value();
    expect(launched, isNull);
    const initial = SettingsLoadResult(
      settings: PlaySettings(
        musicEnabled: false,
        effectsEnabled: false,
        voiceEnabled: false,
        reduceEffects: true,
      ),
    );
    repository.loadGate!.complete(initial);
    await boot;
    expect(launched, same(initial));
  });

  test(
    'serializes rapid choices; old success cannot mark latest saved',
    () async {
      final repository = _Repository();
      final model = SettingsViewModel(repository, const SettingsLoadResult());
      addTearDown(model.dispose);
      model.setMusicEnabled(false);
      model.setVoiceEnabled(false);
      model.setReduceEffects(true);
      expect(repository.writes.length, 1);
      expect(model.state.settings.voiceEnabled, isFalse);
      repository.gates.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(model.state.isSaving, isTrue);
      expect(repository.writes.length, 2);
      expect(repository.writes.last, model.state.settings);
      repository.gates.last.complete();
      await model.pendingSave;
      expect(model.state.isSaving, isFalse);
      final restored = SettingsViewModel(repository, await repository.load());
      expect(restored.state.settings, model.state.settings);
      restored.dispose();
    },
  );

  for (final retryByToggle in [false, true]) {
    test(
      'failed save keeps runtime choices and retries latest (${retryByToggle ? 'toggle' : 'button'})',
      () async {
        final repository = _Repository();
        final model = SettingsViewModel(
          repository,
          SettingsLoadResult(restoreError: StateError('read')),
        );
        addTearDown(model.dispose);
        model.setEffectsEnabled(false);
        repository.gates.first.completeError(StateError('disk full'));
        await model.pendingSave;
        expect(model.state.settings.effectsEnabled, isFalse);
        expect(model.state.saveError, isNotNull);
        if (retryByToggle) {
          model.setVoiceEnabled(false);
        } else {
          model.retrySave();
        }
        expect(repository.writes.last, model.state.settings);
        repository.gates.last.complete();
        await model.pendingSave;
        expect(model.state.saveError, isNull);
        expect(model.state.restoreError, isNull);
      },
    );
  }

  test(
    'obsolete failure drains the latest snapshot instead of restoring old state',
    () async {
      final repository = _Repository();
      final model = SettingsViewModel(repository, const SettingsLoadResult());
      addTearDown(model.dispose);
      model.setMusicEnabled(false);
      model.setMusicEnabled(true);
      model.setVoiceEnabled(false);
      repository.gates.first.completeError(StateError('old failure'));
      await Future<void>.delayed(Duration.zero);
      expect(model.state.isSaving, isTrue);
      expect(model.state.saveError, isNull);
      repository.gates.last.complete();
      await model.pendingSave;
      expect(repository.saved, const PlaySettings(voiceEnabled: false));
    },
  );
}
