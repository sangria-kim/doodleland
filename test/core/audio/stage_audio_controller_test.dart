import 'dart:async';

import 'package:doodleland/core/audio/stage_audio_controller.dart';
import 'package:doodleland/core/settings/domain/play_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/fake_stage_audio.dart';

void main() {
  test('plays mapped background bgm and switches track', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    await controller.syncBackgroundId('forest');
    await controller.syncBackgroundId('sky');

    expect(
      bgmPlayer.playedAssets,
      equals([
        'audio/bgm/bgm_forest_happy_animal_friends.ogg',
        'audio/bgm/bgm_sky_puppy_playtime.ogg',
      ]),
    );
    expect(bgmPlayer.stopCount, equals(2));
  });

  test('does not replay same bgm while already playing', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    await controller.syncBackgroundId('ocean');
    await controller.syncBackgroundId('ocean');

    expect(
      bgmPlayer.playedAssets,
      equals(['audio/bgm/bgm_ocean_slow_flowing_ambient.ogg']),
    );
    expect(bgmPlayer.stopCount, equals(1));
  });

  test('stops bgm for non-mapped background id', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    await controller.syncBackgroundId('forest');
    await controller.syncBackgroundId('starry_night');

    expect(
      bgmPlayer.playedAssets,
      equals(['audio/bgm/bgm_forest_happy_animal_friends.ogg']),
    );
    expect(bgmPlayer.stopCount, equals(2));
  });

  test('stops bgm when route leaves stage flow', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    await controller.syncBackgroundId('forest');
    await controller.syncRoutePath('/capture');

    expect(bgmPlayer.stopCount, equals(2));
  });

  test('keeps bgm when route is stage background selector', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    await controller.syncBackgroundId('forest');
    await controller.syncRoutePath('/stage/background');

    expect(bgmPlayer.stopCount, equals(1));
  });

  test('coalesces the same pending background request', () async {
    final player = ControlledStageBgmPlayer()..stopGate = Completer<void>();
    final controller = StageAudioController(
      bgmPlayer: player,
      sfxPlayer: FakeStageSfxPlayer(),
      voicePlayer: FakeStageVoicePlayer(),
    );
    addTearDown(controller.dispose);
    final first = controller.syncBackgroundId('forest');
    final duplicate = controller.syncBackgroundId('forest');
    player.stopGate!.complete();
    await Future.wait([first, duplicate]);
    expect(player.stopCount, 1);
    expect(player.playedAssets, [
      'audio/bgm/bgm_forest_happy_animal_friends.ogg',
    ]);
  });

  test('serializes a newer background after a pending play', () async {
    final player = ControlledStageBgmPlayer()..playGate = Completer<void>();
    final controller = StageAudioController(
      bgmPlayer: player,
      sfxPlayer: FakeStageSfxPlayer(),
      voicePlayer: FakeStageVoicePlayer(),
    );
    addTearDown(controller.dispose);
    final started = player.playStarted.stream.first;
    final first = controller.syncBackgroundId('forest');
    await started;
    final second = controller.syncBackgroundId('sky');
    player.playGate!.complete();
    await Future.wait([first, second]);
    expect(player.playedAssets, [
      'audio/bgm/bgm_forest_happy_animal_friends.ogg',
      'audio/bgm/bgm_sky_puppy_playtime.ogg',
    ]);
    expect(player.currentAsset, 'audio/bgm/bgm_sky_puppy_playtime.ogg');
    expect(player.stopCount, 2);
  });

  for (final leaveStage in [false, true]) {
    test(
      'cancels pending play on ${leaveStage ? 'route exit' : 'silent background'} and permits reentry',
      () async {
        final player = ControlledStageBgmPlayer()..playGate = Completer<void>();
        final controller = StageAudioController(
          bgmPlayer: player,
          sfxPlayer: FakeStageSfxPlayer(),
          voicePlayer: FakeStageVoicePlayer(),
        );
        addTearDown(controller.dispose);
        final started = player.playStarted.stream.first;
        final playing = controller.syncBackgroundId('forest');
        await started;
        final stopping = leaveStage
            ? controller.syncRoutePath('/capture')
            : controller.syncBackgroundId('starry_night');
        player.playGate!.complete();
        await Future.wait([playing, stopping]);
        expect(player.currentAsset, isNull);
        if (leaveStage) await controller.syncRoutePath('/stage');
        await controller.syncBackgroundId('forest');
        expect(player.playedAssets.length, 2);
        expect(
          player.currentAsset,
          'audio/bgm/bgm_forest_happy_animal_friends.ogg',
        );
      },
    );
  }

  test('retries the same background after a failed play', () async {
    final player = ControlledStageBgmPlayer()..failNextPlay = true;
    final controller = StageAudioController(
      bgmPlayer: player,
      sfxPlayer: FakeStageSfxPlayer(),
      voicePlayer: FakeStageVoicePlayer(),
    );
    addTearDown(controller.dispose);
    await controller.syncBackgroundId('forest');
    expect(player.currentAsset, isNull);
    await controller.syncBackgroundId('forest');
    expect(player.playedAssets.length, 2);
    expect(
      player.currentAsset,
      'audio/bgm/bgm_forest_happy_animal_friends.ogg',
    );
  });

  test('dispose invalidates pending stop and ignores later calls', () async {
    final player = ControlledStageBgmPlayer()..stopGate = Completer<void>();
    final controller = StageAudioController(
      bgmPlayer: player,
      sfxPlayer: FakeStageSfxPlayer(),
      voicePlayer: FakeStageVoicePlayer(),
    );
    final pending = controller.syncBackgroundId('forest');
    // Let the queued operation enter stop before disposing.
    await Future<void>.value();
    final disposing = controller.dispose();
    player.stopGate!.complete();
    await Future.wait([pending, disposing]);
    await controller.syncBackgroundId('sky');
    expect(player.playedAssets, isEmpty);
    expect(player.disposeCount, 1);
  });

  test(
    'dispose waits for an in-flight play before releasing the player',
    () async {
      final player = ControlledStageBgmPlayer()..playGate = Completer<void>();
      final controller = StageAudioController(
        bgmPlayer: player,
        sfxPlayer: FakeStageSfxPlayer(),
        voicePlayer: FakeStageVoicePlayer(),
      );
      final started = player.playStarted.stream.first;
      final pending = controller.syncBackgroundId('forest');
      await started;
      final disposing = controller.dispose();
      expect(player.disposeCount, 0);
      player.playGate!.complete();
      await Future.wait([pending, disposing]);
      expect(player.currentAsset, isNull);
      expect(player.disposeCount, 1);
    },
  );

  test('plays spawn and remove sfx', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    await controller.playSpawnSfx();
    await controller.playRemoveSfx();

    expect(
      sfxPlayer.playedAssets,
      equals([
        'audio/sfx/sfx_spawn_pop.ogg',
        'audio/sfx/sfx_remove_swoosh.ogg',
      ]),
    );
  });

  test('plays alternating home entry voice on dedicated player', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    controller.setHomeRouteForEntryVoice(true);
    await controller.playHomeEntryVoice();
    await controller.playHomeEntryVoice();
    await controller.playHomeEntryVoice();

    expect(
      voicePlayer.playedAssets,
      equals([
        'audio/main/main_entry_voice_01.m4a',
        'audio/main/main_entry_voice_02.m4a',
        'audio/main/main_entry_voice_01.m4a',
      ]),
    );
    expect(sfxPlayer.playedAssets, isEmpty);
  });

  test('cancels pending home entry voice when leaving home route', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = ControlledStageVoicePlayer()
      ..stopGate = Completer<void>();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    controller.setHomeRouteForEntryVoice(true);
    final pendingVoicePlayback = controller.playHomeEntryVoice();
    controller.setHomeRouteForEntryVoice(false);
    voicePlayer.stopGate!.complete();
    await pendingVoicePlayback;

    expect(voicePlayer.playedAssets, isEmpty);
  });

  test('disposes home voice player with other audio players', () async {
    final bgmPlayer = FakeStageBgmPlayer();
    final sfxPlayer = FakeStageSfxPlayer();
    final voicePlayer = FakeStageVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );

    await controller.dispose();

    expect(bgmPlayer.disposeCount, equals(1));
    expect(sfxPlayer.disposeCount, equals(1));
    expect(voicePlayer.disposeCount, equals(1));
  });
  test(
    'logical voice and effects are independent on the shared SFX player',
    () async {
      final sfx = ControlledStageSfxPlayer();
      final voice = ControlledStageVoicePlayer();
      final controller = StageAudioController(
        bgmPlayer: FakeStageBgmPlayer(),
        sfxPlayer: sfx,
        voicePlayer: voice,
      );
      addTearDown(controller.dispose);
      controller.setHomeRouteForEntryVoice(true);
      await controller.applySettings(const PlaySettings(effectsEnabled: false));
      await controller.playSpawnSfx();
      await controller.playHomeCreateButtonSfx();
      await controller.playHomeEntryVoice();
      expect(sfx.currentAsset, contains('main_create_btn'));
      expect(voice.currentAsset, isNotNull);
      await controller.applySettings(const PlaySettings(voiceEnabled: false));
      expect(sfx.currentAsset, isNull);
      expect(voice.currentAsset, isNull);
      await controller.playHomePlayButtonSfx();
      await controller.playSpawnSfx();
      expect(sfx.currentAsset, contains('sfx_spawn'));
      await controller.applySettings(const PlaySettings());
      expect(sfx.currentAsset, contains('sfx_spawn'));
      expect(voice.currentAsset, isNull);
      await controller.playHomePlayButtonSfx();
      await controller.applySettings(const PlaySettings(effectsEnabled: false));
      expect(sfx.currentAsset, contains('main_play_btn'));
    },
  );

  test(
    'BGM remembers latest muted background and reevaluates the same id',
    () async {
      final bgm = ControlledStageBgmPlayer();
      final controller = StageAudioController(
        bgmPlayer: bgm,
        sfxPlayer: FakeStageSfxPlayer(),
        voicePlayer: FakeStageVoicePlayer(),
      );
      addTearDown(controller.dispose);
      await controller.syncRoutePath('/stage');
      await controller.syncBackgroundId('forest');
      await controller.applySettings(const PlaySettings(musicEnabled: false));
      expect(bgm.currentAsset, isNull);
      await controller.applySettings(const PlaySettings());
      expect(bgm.playedAssets.length, 2);
      await controller.applySettings(const PlaySettings(musicEnabled: false));
      await controller.syncBackgroundId('ocean');
      await controller.applySettings(const PlaySettings());
      expect(bgm.currentAsset, contains('ocean'));
      await controller.syncRoutePath('/');
      await controller.syncBackgroundId('sky');
      expect(bgm.currentAsset, isNull);
      await controller.syncRoutePath('/stage/background');
      expect(bgm.currentAsset, contains('sky'));
      await controller.syncBackgroundId('candy_land');
      expect(bgm.currentAsset, isNull);
    },
  );

  for (final beforePlay in [false, true]) {
    for (final voiceCue in [false, true]) {
      test(
        'OFF invalidates ${voiceCue ? 'button voice' : 'effects'} during delayed ${beforePlay ? 'stop' : 'play'} and ON does not replay',
        () async {
          final player = ControlledStageSfxPlayer();
          final gate = Completer<void>();
          if (beforePlay) {
            player.stopGate = gate;
          } else {
            player.playGate = gate;
          }
          final controller = StageAudioController(
            bgmPlayer: FakeStageBgmPlayer(),
            sfxPlayer: player,
            voicePlayer: FakeStageVoicePlayer(),
          );
          addTearDown(controller.dispose);
          final pending = voiceCue
              ? controller.playHomeCreateButtonSfx()
              : controller.playSpawnSfx();
          await Future<void>.delayed(Duration.zero);
          final off = controller.applySettings(
            voiceCue
                ? const PlaySettings(voiceEnabled: false)
                : const PlaySettings(effectsEnabled: false),
          );
          final on = controller.applySettings(const PlaySettings());
          gate.complete();
          await Future.wait([pending, off, on]);
          expect(player.currentAsset, isNull);
          expect(player.playedAssets.length, beforePlay ? 0 : 1);
          await controller.playRemoveSfx();
          expect(player.currentAsset, contains('remove'));
        },
      );
    }
  }

  for (final interruption in ['mute', 'background', 'route', 'dispose']) {
    test('late home voice play cannot survive $interruption', () async {
      final voice = ControlledStageVoicePlayer()..playGate = Completer<void>();
      final controller = StageAudioController(
        bgmPlayer: FakeStageBgmPlayer(),
        sfxPlayer: FakeStageSfxPlayer(),
        voicePlayer: voice,
      );
      addTearDown(controller.dispose);
      controller.setHomeRouteForEntryVoice(true);
      final pending = controller.playHomeEntryVoice();
      await Future<void>.delayed(Duration.zero);
      final cancel = switch (interruption) {
        'mute' => controller.applySettings(
          const PlaySettings(voiceEnabled: false),
        ),
        'background' => controller.setForeground(false),
        'route' => controller.syncRoutePath('/library'),
        _ => controller.dispose(),
      };
      voice.playGate!.complete();
      await Future.wait([pending, cancel]);
      expect(voice.currentAsset, isNull);
    });
  }

  test(
    'background invalidates delayed SFX and resume only restores current BGM',
    () async {
      final sfx = ControlledStageSfxPlayer()..playGate = Completer<void>();
      final bgm = ControlledStageBgmPlayer();
      final voice = ControlledStageVoicePlayer();
      final controller = StageAudioController(
        bgmPlayer: bgm,
        sfxPlayer: sfx,
        voicePlayer: voice,
      );
      addTearDown(controller.dispose);
      await controller.syncBackgroundId('forest');
      final cue = controller.playHomePlayButtonSfx();
      await Future<void>.delayed(Duration.zero);
      final background = controller.setForeground(false);
      await controller.setForeground(false);
      await controller.syncBackgroundId('sky');
      final mute = controller.applySettings(
        const PlaySettings(voiceEnabled: false),
      );
      sfx.playGate!.complete();
      await Future.wait([cue, background, mute]);
      expect(sfx.currentAsset, isNull);
      expect(bgm.currentAsset, isNull);
      await controller.setForeground(true);
      expect(bgm.currentAsset, contains('sky'));
      expect(sfx.playedAssets.length, 1);
      expect(voice.playedAssets, isEmpty);
    },
  );

  test(
    'SFX failure does not poison queue and dispose waits for pending play',
    () async {
      final player = ControlledStageSfxPlayer()..failNextPlay = true;
      final controller = StageAudioController(
        bgmPlayer: FakeStageBgmPlayer(),
        sfxPlayer: player,
        voicePlayer: FakeStageVoicePlayer(),
      );
      await controller.playSpawnSfx();
      await controller.playRemoveSfx();
      expect(player.currentAsset, contains('remove'));
      player.playGate = Completer<void>();
      final pending = controller.playHomePlayButtonSfx();
      await Future<void>.delayed(Duration.zero);
      final disposing = controller.dispose();
      expect(player.disposeCount, 0);
      player.playGate!.complete();
      await Future.wait([pending, disposing]);
      expect(player.currentAsset, isNull);
      expect(player.disposeCount, 1);
    },
  );

  test(
    'mute during delayed BGM play settles stopped then resumes latest route only',
    () async {
      final player = ControlledStageBgmPlayer()..playGate = Completer<void>();
      final controller = StageAudioController(
        bgmPlayer: player,
        sfxPlayer: FakeStageSfxPlayer(),
        voicePlayer: FakeStageVoicePlayer(),
      );
      addTearDown(controller.dispose);
      final started = player.playStarted.stream.first;
      final pending = controller.syncBackgroundId('forest');
      await started;
      final off = controller.applySettings(
        const PlaySettings(musicEnabled: false),
      );
      final background = controller.syncBackgroundId('sky');
      final on = controller.applySettings(const PlaySettings());
      final exit = controller.syncRoutePath('/');
      player.playGate!.complete();
      await Future.wait([pending, off, background, on, exit]);
      expect(player.currentAsset, isNull);
      expect(player.playedAssets.length, 1);
      await controller.syncRoutePath('/stage');
      expect(player.currentAsset, contains('sky'));
    },
  );
}
