import 'package:doodleland/core/audio/stage_audio_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plays mapped background bgm and switches track', () async {
    final bgmPlayer = _FakeStageBgmPlayer();
    final sfxPlayer = _FakeStageSfxPlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
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
    final bgmPlayer = _FakeStageBgmPlayer();
    final sfxPlayer = _FakeStageSfxPlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
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
    final bgmPlayer = _FakeStageBgmPlayer();
    final sfxPlayer = _FakeStageSfxPlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
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
    final bgmPlayer = _FakeStageBgmPlayer();
    final sfxPlayer = _FakeStageSfxPlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
    );
    addTearDown(controller.dispose);

    await controller.syncBackgroundId('forest');
    await controller.syncRoutePath('/capture');

    expect(bgmPlayer.stopCount, equals(2));
  });

  test('keeps bgm when route is stage background selector', () async {
    final bgmPlayer = _FakeStageBgmPlayer();
    final sfxPlayer = _FakeStageSfxPlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
    );
    addTearDown(controller.dispose);

    await controller.syncBackgroundId('forest');
    await controller.syncRoutePath('/stage/background');

    expect(bgmPlayer.stopCount, equals(1));
  });

  test('plays spawn and remove sfx', () async {
    final bgmPlayer = _FakeStageBgmPlayer();
    final sfxPlayer = _FakeStageSfxPlayer();
    final controller = StageAudioController(
      bgmPlayer: bgmPlayer,
      sfxPlayer: sfxPlayer,
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
}

class _FakeStageBgmPlayer implements StageBgmPlayer {
  int setLoopingCount = 0;
  int stopCount = 0;
  int disposeCount = 0;
  double? volume;
  final List<String> playedAssets = [];

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> setLooping() async {
    setLoopingCount += 1;
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}

class _FakeStageSfxPlayer implements StageSfxPlayer {
  int disposeCount = 0;
  double? volume;
  final List<String> playedAssets = [];

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> stop() async {}
}
