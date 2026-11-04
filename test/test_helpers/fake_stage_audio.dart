import 'dart:async';

import 'package:doodleland/core/audio/stage_audio_controller.dart';

class FakeStageBgmPlayer implements StageBgmPlayer {
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

class FakeStageSfxPlayer implements StageSfxPlayer {
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
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}

class FakeStageVoicePlayer implements StageVoicePlayer {
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
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}

// Tests explicitly release a player call to exercise ordering without timers.
class ControlledStageBgmPlayer extends FakeStageBgmPlayer {
  Completer<void>? stopGate;
  Completer<void>? playGate;
  final playStarted = StreamController<String>.broadcast(sync: true);
  bool failNextPlay = false;
  String? currentAsset;

  @override
  Future<void> stop() async {
    stopCount += 1;
    await stopGate?.future;
    currentAsset = null;
  }

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
    playStarted.add(assetPath);
    await playGate?.future;
    if (failNextPlay) {
      failNextPlay = false;
      throw StateError('controlled play failure');
    }
    currentAsset = assetPath;
  }

  @override
  Future<void> dispose() async {
    currentAsset = null;
    await playStarted.close();
    await super.dispose();
  }
}

class ControlledStageSfxPlayer extends FakeStageSfxPlayer {
  Completer<void>? stopGate;
  Completer<void>? playGate;
  bool failNextPlay = false;
  String? currentAsset;
  @override
  Future<void> stop() async {
    stopCount++;
    await stopGate?.future;
    currentAsset = null;
  }

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
    await playGate?.future;
    if (failNextPlay) {
      failNextPlay = false;
      throw StateError('play failed');
    }
    currentAsset = assetPath;
  }

  @override
  Future<void> dispose() async {
    currentAsset = null;
    await super.dispose();
  }
}

class ControlledStageVoicePlayer extends FakeStageVoicePlayer {
  Completer<void>? stopGate;
  Completer<void>? playGate;
  String? currentAsset;
  @override
  Future<void> stop() async {
    stopCount++;
    await stopGate?.future;
    currentAsset = null;
  }

  @override
  Future<void> playAsset(String assetPath) async {
    playedAssets.add(assetPath);
    await playGate?.future;
    currentAsset = assetPath;
  }

  @override
  Future<void> dispose() async {
    currentAsset = null;
    await super.dispose();
  }
}
