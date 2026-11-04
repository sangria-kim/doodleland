import 'package:doodleland/app.dart';
import 'package:doodleland/core/audio/stage_audio_controller.dart';
import 'package:doodleland/core/settings/domain/play_settings.dart';
import 'package:doodleland/core/settings/domain/settings_repository.dart';
import 'package:doodleland/core/settings/presentation/settings_viewmodel.dart';
import 'package:doodleland/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers/fake_stage_audio.dart';

class _Repository implements SettingsRepository {
  @override
  Future<SettingsLoadResult> load() async => const SettingsLoadResult();
  @override
  Future<void> save(PlaySettings settings) async {}
}

void main() {
  testWidgets(
    'restored quiet settings apply before first home frame; dialog is not a home entry',
    (tester) async {
      final bgm = ControlledStageBgmPlayer();
      final sfx = ControlledStageSfxPlayer();
      final voice = ControlledStageVoicePlayer();
      final audio = StageAudioController(
        bgmPlayer: bgm,
        sfxPlayer: sfx,
        voicePlayer: voice,
      );
      final container = ProviderContainer(
        overrides: [
          stageAudioControllerProvider.overrideWithValue(audio),
          settingsRepositoryProvider.overrideWithValue(_Repository()),
          initialSettingsProvider.overrideWithValue(
            const SettingsLoadResult(
              settings: PlaySettings(
                musicEnabled: false,
                effectsEnabled: false,
                voiceEnabled: false,
                reduceEffects: true,
              ),
            ),
          ),
        ],
      );
      AppRouter.router.go('/');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DoodlelandApp(),
        ),
      );
      await tester.pump();
      expect(bgm.playedAssets, isEmpty);
      expect(sfx.playedAssets, isEmpty);
      expect(voice.playedAssets, isEmpty);
      for (final key in [
        'home-bg-foreground',
        'home-bg-cars',
        'home-bg-title',
      ]) {
        final opacity = tester.widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(Key(key)),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(opacity.opacity, 1);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('부모 설정').hitTestable());
      await tester.pumpAndSettle();
      container.read(settingsViewModelProvider.notifier).setVoiceEnabled(true);
      await tester.pump();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(voice.playedAssets, isEmpty);
      AppRouter.router.push('/stage');
      await tester.pumpAndSettle();
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(voice.playedAssets.length, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await audio.dispose();
      container.dispose();
    },
  );

  testWidgets(
    'app lifecycle stops all channels and resumes only latest permitted stage BGM',
    (tester) async {
      final bgm = ControlledStageBgmPlayer();
      final sfx = ControlledStageSfxPlayer();
      final voice = ControlledStageVoicePlayer();
      final audio = StageAudioController(
        bgmPlayer: bgm,
        sfxPlayer: sfx,
        voicePlayer: voice,
      );
      final container = ProviderContainer(
        overrides: [
          stageAudioControllerProvider.overrideWithValue(audio),
          settingsRepositoryProvider.overrideWithValue(_Repository()),
        ],
      );
      AppRouter.router.go('/');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DoodlelandApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(voice.currentAsset, isNotNull);
      await audio.playHomeCreateButtonSfx();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(voice.currentAsset, isNull);
      expect(sfx.currentAsset, isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      AppRouter.router.go('/stage');
      await tester.pumpAndSettle();
      container.read(settingsViewModelProvider.notifier).setMusicEnabled(false);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(bgm.currentAsset, isNull);
      container.read(settingsViewModelProvider.notifier).setMusicEnabled(true);
      await tester.pump();
      expect(bgm.currentAsset, contains('forest'));
      expect(voice.playedAssets.length, 1);
      expect(sfx.playedAssets.length, 1);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('부모 설정').hitTestable());
      await tester.pumpAndSettle();
      expect(bgm.currentAsset, contains('forest'));
      await tester.tap(find.widgetWithText(SwitchListTile, '배경 음악'));
      await tester.pumpAndSettle();
      expect(bgm.currentAsset, isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('0/10'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await audio.dispose();
      container.dispose();
      AppRouter.router.go('/');
    },
  );
}
