import 'dart:async';

import 'package:doodleland/core/audio/stage_audio_controller.dart';
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
    final voicePlayer = _DelayedStopVoicePlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
      voicePlayer: voicePlayer,
    );
    addTearDown(controller.dispose);

    controller.setHomeRouteForEntryVoice(true);
    final pendingVoicePlayback = controller.playHomeEntryVoice();
    controller.setHomeRouteForEntryVoice(false);
    voicePlayer.completePendingStop();
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
}

class _DelayedStopVoicePlayer extends FakeStageVoicePlayer {
  Completer<void>? _pendingStopCompleter;

  @override
  Future<void> stop() {
    final completer = Completer<void>();
    _pendingStopCompleter ??= completer;
    stopCount += 1;
    return completer.future;
  }

  void completePendingStop() {
    _pendingStopCompleter?.complete();
    _pendingStopCompleter = null;
  }
}
