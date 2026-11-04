import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/play_settings.dart';
import '../domain/settings_repository.dart';

class FileSettingsRepository implements SettingsRepository {
  FileSettingsRepository({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;
  static const fileName = 'play_settings.json';

  @override
  Future<SettingsLoadResult> load() async {
    try {
      final file = File('${(await _directory()).path}/$fileName');
      if (!await file.exists()) return const SettingsLoadResult();
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Settings must be an object');
      }
      return SettingsLoadResult(settings: PlaySettings.fromJson(json));
    } catch (error) {
      return SettingsLoadResult(restoreError: error);
    }
  }

  @override
  Future<void> save(PlaySettings settings) async {
    File? temporary;
    try {
      final directory = await _directory();
      await directory.create(recursive: true);
      final target = File('${directory.path}/$fileName');
      temporary = File('${target.path}.tmp');
      await temporary.writeAsString(jsonEncode(settings.toJson()), flush: true);
      // Same-directory rename replaces the previous snapshot atomically on our
      // Android/iOS filesystems; never delete the valid target before replacing.
      await temporary.rename(target.path);
    } catch (_) {
      try {
        if (temporary != null && await temporary.exists()) {
          await temporary.delete();
        }
      } catch (_) {
        // Preserve the original write error for the UI.
      }
      rethrow;
    }
  }
}
