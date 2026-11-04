import 'package:flutter/foundation.dart';

@immutable
class PlaySettings {
  const PlaySettings({
    this.musicEnabled = true,
    this.effectsEnabled = true,
    this.voiceEnabled = true,
    this.reduceEffects = false,
  });

  final bool musicEnabled;
  final bool effectsEnabled;
  final bool voiceEnabled;
  final bool reduceEffects;

  PlaySettings copyWith({
    bool? musicEnabled,
    bool? effectsEnabled,
    bool? voiceEnabled,
    bool? reduceEffects,
  }) => PlaySettings(
    musicEnabled: musicEnabled ?? this.musicEnabled,
    effectsEnabled: effectsEnabled ?? this.effectsEnabled,
    voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    reduceEffects: reduceEffects ?? this.reduceEffects,
  );

  factory PlaySettings.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1) {
      throw const FormatException('Unknown settings schema');
    }
    bool value(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    return PlaySettings(
      musicEnabled: value('musicEnabled', true),
      effectsEnabled: value('effectsEnabled', true),
      voiceEnabled: value('voiceEnabled', true),
      reduceEffects: value('reduceEffects', false),
    );
  }

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'musicEnabled': musicEnabled,
    'effectsEnabled': effectsEnabled,
    'voiceEnabled': voiceEnabled,
    'reduceEffects': reduceEffects,
  };

  @override
  bool operator ==(Object other) =>
      other is PlaySettings &&
      musicEnabled == other.musicEnabled &&
      effectsEnabled == other.effectsEnabled &&
      voiceEnabled == other.voiceEnabled &&
      reduceEffects == other.reduceEffects;

  @override
  int get hashCode =>
      Object.hash(musicEnabled, effectsEnabled, voiceEnabled, reduceEffects);
}
