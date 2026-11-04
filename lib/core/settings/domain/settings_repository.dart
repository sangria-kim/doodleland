import 'play_settings.dart';

class SettingsLoadResult {
  const SettingsLoadResult({
    this.settings = const PlaySettings(),
    this.restoreError,
  });

  final PlaySettings settings;
  final Object? restoreError;
}

abstract class SettingsRepository {
  Future<SettingsLoadResult> load();
  Future<void> save(PlaySettings settings);
}
