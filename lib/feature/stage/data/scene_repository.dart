import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/model/stage_background.dart';

class SceneRepository {
  const SceneRepository();

  StageBackground get defaultBackground => defaultStageBackgrounds.first;
}

final sceneRepositoryProvider = Provider<SceneRepository>(
  (ref) => const SceneRepository(),
);
