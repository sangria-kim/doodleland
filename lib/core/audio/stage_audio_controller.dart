import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class StageBgmPlayer {
  Future<void> setLooping();

  Future<void> setVolume(double volume);

  Future<void> playAsset(String assetPath);

  Future<void> stop();

  Future<void> dispose();
}

abstract class StageSfxPlayer {
  Future<void> setVolume(double volume);

  Future<void> playAsset(String assetPath);

  Future<void> dispose();
}

class AudioplayersStageBgmPlayer implements StageBgmPlayer {
  AudioplayersStageBgmPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> setLooping() async {
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.play(
      AssetSource(assetPath),
      mode: PlayerMode.mediaPlayer,
      volume: StageAudioController.bgmVolume,
    );
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}

class AudioplayersStageSfxPlayer implements StageSfxPlayer {
  AudioplayersStageSfxPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.play(
      AssetSource(assetPath),
      mode: PlayerMode.lowLatency,
      volume: StageAudioController.sfxVolume,
    );
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}

class StageAudioController {
  StageAudioController({StageBgmPlayer? bgmPlayer, StageSfxPlayer? sfxPlayer})
    : _bgmPlayer = bgmPlayer ?? AudioplayersStageBgmPlayer(),
      _sfxPlayer = sfxPlayer ?? AudioplayersStageSfxPlayer() {
    unawaited(_initialize());
  }

  static const double bgmVolume = 0.5;
  static const double sfxVolume = 0.85;

  static const String _spawnSfxAsset = 'audio/sfx/sfx_spawn_pop.ogg';
  static const String _removeSfxAsset = 'audio/sfx/sfx_remove_swoosh.ogg';

  static const Map<String, String> _bgmAssetByBackgroundId = {
    'forest': 'audio/bgm/bgm_forest_happy_animal_friends.ogg',
    'ocean': 'audio/bgm/bgm_ocean_slow_flowing_ambient.ogg',
    'sky': 'audio/bgm/bgm_sky_puppy_playtime.ogg',
  };

  final StageBgmPlayer _bgmPlayer;
  final StageSfxPlayer _sfxPlayer;

  String? _currentBgmAsset;
  bool _isBgmPlaying = false;
  bool _disposed = false;

  Future<void> _initialize() async {
    if (_disposed) {
      return;
    }
    try {
      await _bgmPlayer.setLooping();
      await _bgmPlayer.setVolume(bgmVolume);
      await _sfxPlayer.setVolume(sfxVolume);
    } catch (error, stackTrace) {
      debugPrint('[audio] initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> syncRoutePath(String path) async {
    if (_disposed) {
      return;
    }

    final normalizedPath = _normalizeRoutePath(path);
    if (normalizedPath == '/stage' || normalizedPath.startsWith('/stage/')) {
      return;
    }

    await _stopBgm();
  }

  Future<void> syncBackgroundId(String backgroundId) async {
    if (_disposed) {
      return;
    }

    final targetAsset = _bgmAssetByBackgroundId[backgroundId];
    if (targetAsset == null) {
      await _stopBgm();
      return;
    }
    if (_isBgmPlaying && _currentBgmAsset == targetAsset) {
      return;
    }

    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.playAsset(targetAsset);
      _currentBgmAsset = targetAsset;
      _isBgmPlaying = true;
    } catch (error, stackTrace) {
      debugPrint('[audio] bgm play failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> playSpawnSfx() async {
    await _playSfx(_spawnSfxAsset);
  }

  Future<void> playRemoveSfx() async {
    await _playSfx(_removeSfxAsset);
  }

  Future<void> _playSfx(String assetPath) async {
    if (_disposed) {
      return;
    }
    try {
      await _sfxPlayer.playAsset(assetPath);
    } catch (error, stackTrace) {
      debugPrint('[audio] sfx play failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _stopBgm() async {
    if (_disposed || !_isBgmPlaying) {
      return;
    }

    try {
      await _bgmPlayer.stop();
    } catch (error, stackTrace) {
      debugPrint('[audio] bgm stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isBgmPlaying = false;
    }
  }

  String _normalizeRoutePath(String path) {
    if (path.isEmpty) {
      return '/';
    }
    final questionIndex = path.indexOf('?');
    if (questionIndex == -1) {
      return path;
    }
    return path.substring(0, questionIndex);
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await Future.wait<void>([_bgmPlayer.dispose(), _sfxPlayer.dispose()]);
  }
}

final stageAudioControllerProvider = Provider<StageAudioController>((ref) {
  final controller = StageAudioController();
  ref.onDispose(() {
    unawaited(controller.dispose());
  });
  return controller;
});
