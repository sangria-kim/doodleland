import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/domain/play_settings.dart';
import '../settings/presentation/settings_viewmodel.dart';

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
    _initialization = _initialize().whenComplete(() => _initialization = null);
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
    'pororo_playground': 'audio/bgm/bgm_pororo.ogg',
  };

  final StageBgmPlayer _bgmPlayer;
  final StageSfxPlayer _sfxPlayer;
  final StageVoicePlayer _voicePlayer;
  int _homeCreateSfxIndex = 0;
  int _homePlaySfxIndex = 0;
  int _homeEntryVoiceIndex = 0;
  bool _isHomeRouteForEntryVoice = false;
  int _homeEntryVoiceRequestId = 0;

  static AudioContext get bgmAudioContext => _bgmAudioContext;
  static AudioContext get sfxAudioContext => _sfxAudioContext;
  static AudioContext get voiceAudioContext => _voiceAudioContext;

  int _bgmSyncRequestId = 0;
  String? _requestedBgmAsset;
  Future<void>? _bgmOperation;
  bool _disposed = false;
  Future<void>? _initialization;
  PlaySettings _settings = const PlaySettings();
  bool _foreground = true;
  String? _routePath;
  String? _backgroundId;
  Future<void>? _sfxOperation;
  Future<void>? _voiceOperation;
  int _effectsGeneration = 0;
  int _buttonVoiceGeneration = 0;
  bool? _activeSfxIsVoice;

  bool get _canPlay => !_disposed && _foreground;
  bool get _stageRoute =>
      _routePath == null ||
      _routePath == '/stage' ||
      _routePath!.startsWith('/stage/');
  bool get _canPlayBgm => _canPlay && _settings.musicEnabled && _stageRoute;

  Future<void> applySettings(PlaySettings settings) async {
    if (_disposed) return;
    final previous = _settings;
    _settings = settings;
    final operations = <Future<void>>[];
    if (previous.musicEnabled != settings.musicEnabled) {
      operations.add(_syncBgm());
    }
    if (previous.effectsEnabled && !settings.effectsEnabled) {
      operations.add(_cancelSfx(voice: false));
    }
    if (previous.voiceEnabled && !settings.voiceEnabled) {
      operations.add(_cancelSfx(voice: true));
      operations.add(_cancelHomeVoice());
    }
    await Future.wait(operations);
  }

  Future<void> setForeground(bool foreground) async {
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    // Invalidate all short sounds synchronously before any awaited operation.
    if (!foreground) {
      await Future.wait([_stopBgm(), _cancelSfx(), _cancelHomeVoice()]);
    } else {
      await _syncBgm();
    }
  }

  Future<void> _initialize() async {
    if (_disposed) {
      return;
    }
    try {
      await _bgmPlayer.setLooping();
      if (_disposed) return;
      await _bgmPlayer.setVolume(bgmVolume);
      if (_disposed) return;
      await _sfxPlayer.setVolume(sfxVolume);
      if (_disposed) return;
      await _voicePlayer.setVolume(voiceVolume);
    } catch (error, stackTrace) {
      debugPrint('[audio] initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> syncRoutePath(String path) async {
    if (_disposed) return;
    _routePath = _normalizeRoutePath(path);
    _isHomeRouteForEntryVoice = _routePath == '/';
    final operations = <Future<void>>[_syncBgm()];
    if (!_isHomeRouteForEntryVoice) operations.add(_cancelHomeVoice());
    await Future.wait(operations);
  }

  Future<void> syncBackgroundId(String backgroundId) async {
    if (_disposed) return;
    _backgroundId = backgroundId;
    await _syncBgm();
  }

  Future<void> _syncBgm() async {
    final targetAsset = _backgroundId == null
        ? null
        : _bgmAssetByBackgroundId[_backgroundId];
    if (!_canPlayBgm || targetAsset == null) {
      await _stopBgm();
      return;
    }
    if (_requestedBgmAsset == targetAsset) {
      final pending = _bgmOperation;
      if (pending != null) await pending;
      return;
    }
    _requestedBgmAsset = targetAsset;
    final requestId = ++_bgmSyncRequestId;
    await _queueBgmOperation(() async {
      if (!_canPlayBgm || _bgmSyncRequestId != requestId) return;
      try {
        await _bgmPlayer.stop();
        if (!_canPlayBgm || _bgmSyncRequestId != requestId) return;
        await _bgmPlayer.playAsset(targetAsset);
        // A later stop/play is serialized behind us; disposal also waits for
        // this call before releasing the player.
      } catch (error, stackTrace) {
        if (_bgmSyncRequestId == requestId) _requestedBgmAsset = null;
        debugPrint('[audio] bgm play failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
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
    await _playSfx(targetAsset, voice: true);
  }

  Future<void> playHomePlayButtonSfx() async {
    final index = _homePlaySfxIndex % 2;
    _homePlaySfxIndex += 1;
    final targetAsset = index == 0 ? _homePlaySfxAsset1 : _homePlaySfxAsset2;
    await _playSfx(targetAsset, voice: true);
  }

  Future<void> playHomeEntryVoice() async {
    if (!_canPlay || !_settings.voiceEnabled || !_isHomeRouteForEntryVoice) {
      return;
    }

    final index = _homeEntryVoiceIndex % 2;
    _homeEntryVoiceIndex += 1;
    final targetAsset = index == 0
        ? _homeEntryVoiceAsset1
        : _homeEntryVoiceAsset2;
    final requestId = ++_homeEntryVoiceRequestId;
    await _playHomeVoice(targetAsset, requestId);
  }

  void setHomeRouteForEntryVoice(bool isHomeRoute) {
    _isHomeRouteForEntryVoice = isHomeRoute;
    if (!isHomeRoute) {
      unawaited(_cancelHomeVoice());
    }
  }

  Future<void> stopHomeEntryVoice() async {
    await _cancelHomeVoice();
  }

  bool _sfxAllowed(bool voice, int generation) =>
      _canPlay &&
      (voice
          ? _settings.voiceEnabled && generation == _buttonVoiceGeneration
          : _settings.effectsEnabled && generation == _effectsGeneration);

  Future<void> _playSfx(String assetPath, {bool voice = false}) async {
    final generation = voice ? _buttonVoiceGeneration : _effectsGeneration;
    if (!_sfxAllowed(voice, generation)) return;
    await _queueSfxOperation(() async {
      if (!_sfxAllowed(voice, generation)) return;
      await _sfxPlayer.stop();
      _activeSfxIsVoice = null;
      if (!_sfxAllowed(voice, generation)) return;
      _activeSfxIsVoice = voice;
      await _sfxPlayer.playAsset(assetPath);
      if (!_sfxAllowed(voice, generation)) {
        await _sfxPlayer.stop();
        _activeSfxIsVoice = null;
      }
    });
  }

  Future<void> _cancelSfx({bool? voice}) {
    if (voice != false) _buttonVoiceGeneration++;
    if (voice != true) _effectsGeneration++;
    return _queueSfxOperation(() async {
      if (voice == null || _activeSfxIsVoice == voice) {
        await _sfxPlayer.stop();
        _activeSfxIsVoice = null;
      }
    });
  }

  Future<void> _queueSfxOperation(Future<void> Function() action) {
    final previous = _sfxOperation;
    late final Future<void> operation;
    operation =
        (() async {
          if (previous != null) await previous;
          try {
            await action();
          } catch (error) {
            debugPrint('[audio] sfx failed: $error');
          }
        })().whenComplete(() {
          if (identical(_sfxOperation, operation)) _sfxOperation = null;
        });
    _sfxOperation = operation;
    return operation;
  }

  bool _voiceAllowed(int requestId) =>
      _canPlay &&
      _settings.voiceEnabled &&
      _isHomeRouteForEntryVoice &&
      _homeEntryVoiceRequestId == requestId;

  Future<void> _playHomeVoice(String assetPath, int requestId) =>
      _queueVoiceOperation(() async {
        if (!_voiceAllowed(requestId)) return;
        await _voicePlayer.stop();
        if (!_voiceAllowed(requestId)) return;
        await _voicePlayer.playAsset(assetPath);
        if (!_voiceAllowed(requestId)) await _voicePlayer.stop();
      });

  Future<void> _cancelHomeVoice() {
    if (_disposed) return Future<void>.value();
    _homeEntryVoiceRequestId++;
    return _queueVoiceOperation(_voicePlayer.stop);
  }

  Future<void> _queueVoiceOperation(Future<void> Function() action) {
    final previous = _voiceOperation;
    late final Future<void> operation;
    operation =
        (() async {
          if (previous != null) await previous;
          try {
            await action();
          } catch (error) {
            debugPrint('[audio] voice failed: $error');
          }
        })().whenComplete(() {
          if (identical(_voiceOperation, operation)) _voiceOperation = null;
        });
    _voiceOperation = operation;
    return operation;
  }

  Future<void> _stopBgm() async {
    if (_disposed) {
      return;
    }
    _bgmSyncRequestId += 1;
    _requestedBgmAsset = null;
    // Serialize player calls so an old play cannot finish after a newer stop/play.
    await _queueBgmOperation(() async {
      if (_disposed) return;
      try {
        await _bgmPlayer.stop();
      } catch (error, stackTrace) {
        debugPrint('[audio] bgm stop failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  Future<void> _queueBgmOperation(Future<void> Function() action) {
    final previous = _bgmOperation;
    late final Future<void> operation;
    operation =
        (() async {
          if (previous != null) await previous;
          await action();
        })().whenComplete(() {
          if (identical(_bgmOperation, operation)) _bgmOperation = null;
        });
    _bgmOperation = operation;
    return operation;
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
    _bgmSyncRequestId += 1;
    _requestedBgmAsset = null;
    _effectsGeneration++;
    _buttonVoiceGeneration++;
    _homeEntryVoiceRequestId++;
    final initialization = _initialization;
    if (initialization != null) await initialization;
    for (final pending in [_bgmOperation, _sfxOperation, _voiceOperation]) {
      if (pending != null) await pending;
    }
    await Future.wait<void>([
      _bgmPlayer.dispose(),
      _sfxPlayer.dispose(),
      _voicePlayer.dispose(),
    ]);
  }
}

final stageAudioControllerProvider = Provider<StageAudioController>((ref) {
  final controller = StageAudioController();
  ref.listen(
    settingsViewModelProvider.select((state) => state.settings),
    (_, settings) {
      unawaited(controller.applySettings(settings));
    },
    fireImmediately: true,
  );
  ref.onDispose(() {
    unawaited(controller.dispose());
  });
  return controller;
});
