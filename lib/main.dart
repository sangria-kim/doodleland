import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/settings/data/file_settings_repository.dart';
import 'core/settings/domain/settings_repository.dart';
import 'core/settings/presentation/settings_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await bootstrapSettings(
    repository: FileSettingsRepository(),
    launch: (repository, initial) => runApp(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          initialSettingsProvider.overrideWithValue(initial),
        ],
        child: const DoodlelandApp(),
      ),
    ),
  );
}

// The launch boundary is injectable so tests verify that no UI/audio can start
// until restoration has completed, using the same path as main.
Future<void> bootstrapSettings({
  required SettingsRepository repository,
  required void Function(SettingsRepository, SettingsLoadResult) launch,
}) async {
  final initial = await repository.load();
  launch(repository, initial);
}
