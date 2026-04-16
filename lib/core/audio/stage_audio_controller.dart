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

  Future<void> stop();

  Future<void> dispose();
}

abstract class StageVoicePlayer {
  Future<void> setVolume(double volume);

  Future<void> playAsset(String assetPath);

  Future<void> stop();

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
      ctx: StageAudioController.bgmAudioContext,
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
      mode: PlayerMode.mediaPlayer,
      volume: StageAudioController.sfxVolume,
      ctx: StageAudioController.sfxAudioContext,
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

class AudioplayersStageVoicePlayer implements StageVoicePlayer {
  AudioplayersStageVoicePlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.play(
      AssetSource(assetPath),
      mode: PlayerMode.mediaPlayer,
      volume: StageAudioController.voiceVolume,
      ctx: StageAudioController.voiceAudioContext,
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

class StageAudioController {
  StageAudioController({
    StageBgmPlayer? bgmPlayer,
    StageSfxPlayer? sfxPlayer,
    StageVoicePlayer? voicePlayer,
  }) : _bgmPlayer = bgmPlayer ?? AudioplayersStageBgmPlayer(),
       _sfxPlayer = sfxPlayer ?? AudioplayersStageSfxPlayer(),
       _voicePlayer = voicePlayer ?? AudioplayersStageVoicePlayer() {
    unawaited(_initialize());
  }

  static const double bgmVolume = 0.5;
  static const double sfxVolume = 0.85;
  static const double voiceVolume = 1.0;

  static const String _spawnSfxAsset = 'audio/sfx/sfx_spawn_pop.ogg';
  static const String _removeSfxAsset = 'audio/sfx/sfx_remove_swoosh.ogg';
  static const String _homeCreateSfxAsset1 =
      'audio/main/main_create_btn_01.m4a';
  static const String _homeCreateSfxAsset2 =
      'audio/main/main_create_btn_02.m4a';
  static const String _homePlaySfxAsset1 = 'audio/main/main_play_btn_01.m4a';
  static const String _homePlaySfxAsset2 = 'audio/main/main_play_btn_02.m4a';
  static const String _homeEntryVoiceAsset1 =
      'audio/main/main_entry_voice_01.m4a';
  static const String _homeEntryVoiceAsset2 =
      'audio/main/main_entry_voice_02.m4a';
  static final AudioContext _bgmAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.gain,
    route: AudioContextConfigRoute.system,
  ).build();
  static final AudioContext _sfxAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    route: AudioContextConfigRoute.system,
  ).build();
  static final AudioContext _voiceAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    route: AudioContextConfigRoute.system,
  ).build();

  static const Map<String, String> _bgmAssetByBackgroundId = {
    'forest': 'audio/bgm/bgm_forest_happy_animal_friends.ogg',
    'ocean': 'audio/bgm/bgm_ocean_slow_flowing_ambient.ogg',
    'sky': 'audio/bgm/bgm_sky_puppy_playtime.ogg',
  };

  final StageBgmPlayer _bgmPlayer;
  final StageSfxPlayer _sfxPlayer;
  final StageVoicePlayer _voicePlayer;
  int _homeCreateSfxIndex = 0;
  int _homePlaySfxIndex = 0;
  int _homeEntryVoiceIndex = 0;

  static AudioContext get bgmAudioContext => _bgmAudioContext;
  static AudioContext get sfxAudioContext => _sfxAudioContext;
  static AudioContext get voiceAudioContext => _voiceAudioContext;

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
      await _voicePlayer.setVolume(voiceVolume);
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

  Future<void> playHomeCreateButtonSfx() async {
    final index = _homeCreateSfxIndex % 2;
    _homeCreateSfxIndex += 1;
    final targetAsset = index == 0
        ? _homeCreateSfxAsset1
        : _homeCreateSfxAsset2;
    await _playSfx(targetAsset);
  }

  Future<void> playHomePlayButtonSfx() async {
    final index = _homePlaySfxIndex % 2;
    _homePlaySfxIndex += 1;
    final targetAsset = index == 0 ? _homePlaySfxAsset1 : _homePlaySfxAsset2;
    await _playSfx(targetAsset);
  }

  Future<void> playHomeEntryVoice() async {
    final index = _homeEntryVoiceIndex % 2;
    _homeEntryVoiceIndex += 1;
    final targetAsset = index == 0
        ? _homeEntryVoiceAsset1
        : _homeEntryVoiceAsset2;
    await _playVoice(targetAsset);
  }

  Future<void> _playSfx(String assetPath) async {
    if (_disposed) {
      return;
    }
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.playAsset(assetPath);
    } catch (error, stackTrace) {
      debugPrint('[audio] sfx play failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _playVoice(String assetPath) async {
    if (_disposed) {
      return;
    }
    try {
      await _voicePlayer.stop();
      await _voicePlayer.playAsset(assetPath);
    } catch (error, stackTrace) {
      debugPrint('[audio] voice play failed: $error');
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
    await Future.wait<void>([
      _bgmPlayer.dispose(),
      _sfxPlayer.dispose(),
      _voicePlayer.dispose(),
    ]);
  }
}

final stageAudioControllerProvider = Provider<StageAudioController>((ref) {
  final controller = StageAudioController();
  ref.onDispose(() {
    unawaited(controller.dispose());
  });
  return controller;
});
