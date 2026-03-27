import 'package:doodleland/feature/stage/presentation/stage_viewmodel.dart';
import 'package:doodleland/feature/stage/domain/model/stage_background.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('selected background is initialized and can be changed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(stageViewModelProvider).selectedBackground;
    expect(initial.id, equals(defaultStageBackgrounds.first.id));
    expect(initial.groundY, equals(defaultStageBackgrounds.first.groundY));

    final target = defaultStageBackgrounds[3];
    container.read(stageViewModelProvider.notifier).selectBackground(target);
    final updated = container.read(stageViewModelProvider).selectedBackground;

    expect(updated.id, equals(target.id));
    expect(updated.name, equals(target.name));
  });
}
