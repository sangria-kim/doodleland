import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/model/stage_background.dart';

class SceneRepository {
  const SceneRepository();

  List<StageBackground> get availableBackgrounds => defaultStageBackgrounds;

  StageBackground get defaultBackground => defaultStageBackgrounds.first;

  StageBackground? findById(String id) {
    return defaultStageBackgrounds
        .cast<StageBackground?>()
        .firstWhere(
          (background) => background?.id == id,
          orElse: () => null,
        );
  }
}

final sceneRepositoryProvider = Provider<SceneRepository>(
  (ref) => const SceneRepository(),
);
