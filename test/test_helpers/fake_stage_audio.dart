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
