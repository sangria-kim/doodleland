import 'package:doodleland/core/settings/domain/play_settings.dart';
import 'package:doodleland/core/settings/domain/settings_repository.dart';
import 'package:doodleland/core/settings/presentation/settings_viewmodel.dart';
import 'package:doodleland/feature/settings/presentation/parent_settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements SettingsRepository {
  bool fail = false;
  PlaySettings? saved;
  @override
  Future<SettingsLoadResult> load() async => const SettingsLoadResult();
  @override
  Future<void> save(PlaySettings settings) async {
    if (fail) throw StateError('disk full');
    saved = settings;
  }
}

void main() {
  testWidgets(
    'four switches remain reachable at 640x360 with large text; back closes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showParentSettings(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsNWidgets(4));
      for (final label in ['배경 음악', '효과음', '안내 음성', '효과 줄이기']) {
        final tile = find.widgetWithText(SwitchListTile, label);
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(
        repository.saved,
        const PlaySettings(
          musicEnabled: false,
          effectsEnabled: false,
          voiceEnabled: false,
          reduceEffects: true,
        ),
      );
      await tester.ensureVisible(find.text('닫기'));
      expect(find.text('닫기').hitTestable(), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ParentSettingsDialog), findsNothing);
    },
  );

  testWidgets(
    'save error survives closing and reopening; retry saves runtime snapshot',
    (tester) async {
      final repository = _Repository()..fail = true;
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showParentSettings(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, '배경 음악'));
      await tester.pumpAndSettle();
      expect(
        container.read(settingsViewModelProvider).settings.musicEnabled,
        isFalse,
      );
      expect(find.text('지금은 적용됐지만 다음 실행을 위해 저장하지 못했어요.'), findsOneWidget);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('다시 저장'), findsOneWidget);
      repository.fail = false;
      await tester.ensureVisible(find.text('다시 저장'));
      await tester.tap(find.text('다시 저장'));
      await tester.pumpAndSettle();
      expect(repository.saved!.musicEnabled, isFalse);
      expect(find.text('다시 저장'), findsNothing);
    },
  );
}
