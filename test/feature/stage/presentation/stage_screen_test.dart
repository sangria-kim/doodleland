import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:doodleland/core/audio/stage_audio_controller.dart';
import 'package:doodleland/core/database/app_database.dart';
import 'package:doodleland/core/settings/domain/play_settings.dart';
import 'package:doodleland/core/settings/domain/settings_repository.dart';
import 'package:doodleland/core/settings/presentation/settings_viewmodel.dart';
import 'package:doodleland/feature/stage/domain/model/motion_preset.dart';
import 'package:doodleland/feature/stage/presentation/stage_screen.dart';
import 'package:doodleland/feature/stage/presentation/stage_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_helpers/fake_stage_audio.dart';

class _Repository implements SettingsRepository {
  @override
  Future<SettingsLoadResult> load() async => const SettingsLoadResult();
  @override
  Future<void> save(PlaySettings settings) async {}
}

void main() {
  late ProviderContainer container;
  late StageAudioController audio;
  late Completer<ImageInfo> imageReady;
  const imagePath = '/tmp/doodleland-settings-widget-character.png';
  final characterImage = find.byWidgetPredicate(
    (widget) => widget is Image && widget.image is FileImage,
  );
  final confetti = find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_ConfettiPainter',
  );

  Future<void> mount(WidgetTester tester, {bool reduced = false}) async {
    audio = StageAudioController(
      bgmPlayer: FakeStageBgmPlayer(),
      sfxPlayer: FakeStageSfxPlayer(),
      voicePlayer: FakeStageVoicePlayer(),
    );
    container = ProviderContainer(
      overrides: [
        stageAudioControllerProvider.overrideWithValue(audio),
        settingsRepositoryProvider.overrideWithValue(_Repository()),
        initialSettingsProvider.overrideWithValue(
          SettingsLoadResult(settings: PlaySettings(reduceEffects: reduced)),
        ),
      ],
    );
    imageReady = Completer<ImageInfo>();
    PaintingBinding.instance.imageCache.putIfAbsent(
      FileImage(File(imagePath)),
      () => OneFrameImageStreamCompleter(imageReady.future),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: StageScreen()),
      ),
    );
  }

  Future<void> place(WidgetTester tester) async {
    await container
        .read(stageViewModelProvider.notifier)
        .placeCharacter(
          character: Character(
            id: 1,
            name: 'test',
            originalImagePath: imagePath,
            transparentImagePath: imagePath,
            thumbnailPath: imagePath,
            width: 32,
            height: 32,
            createdAt: DateTime(2026),
          ),
          objectMotion: MotionPreset.floating,
        );
    await tester.pump();
  }

  Future<void> releaseImage(WidgetTester tester) async {
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 32, 32), Paint()..color = Colors.blue);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(32, 32);
    picture.dispose();
    imageReady.complete(ImageInfo(image: image));
    await tester.pump();
    await tester.pump();
  }

  double opacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(of: characterImage, matching: find.byType(Opacity)).first,
      )
      .opacity;

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await audio.dispose();
    container.dispose();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'reduced placement waits for image then displays normally and keeps motion, tap, drag and removal',
    (tester) async {
      await mount(tester, reduced: true);
      await place(tester);
      expect(confetti, findsNothing);
      await releaseImage(tester);
      expect(opacity(tester), 1);
      final before = tester.getCenter(characterImage);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getCenter(characterImage), isNot(before));
      final gestureFinder = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onPanStart != null,
      );
      await tester.tap(gestureFinder);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 200));
      final start = tester
          .getRect(characterImage)
          .intersect(tester.getRect(find.byType(StageScreen)))
          .center;
      final drag = await tester.startGesture(start);
      await drag.moveBy(const Offset(60, -50));
      await tester.pump();
      final held = tester.getCenter(characterImage);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getCenter(characterImage).dx, closeTo(held.dx, 0.1));
      await drag.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getCenter(characterImage).dx, isNot(closeTo(held.dx, 0.1)));
      await tester.longPressAt(
        tester
            .getRect(characterImage)
            .intersect(tester.getRect(find.byType(StageScreen)))
            .center,
      );
      await tester.pump();
      final placed = container
          .read(stageViewModelProvider)
          .placedCharacters
          .single;
      expect(placed.stageRuntime.isPaused, isTrue);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      expect(container.read(stageViewModelProvider).placedCharacters, isEmpty);
      await cleanup(tester);
    },
  );

  testWidgets(
    'reduce before image readiness consumes pending decorations even if toggled back',
    (tester) async {
      await mount(tester);
      await place(tester);
      expect(confetti, findsOneWidget);
      container.read(settingsViewModelProvider.notifier).setReduceEffects(true);
      await tester.pump();
      expect(confetti, findsNothing);
      container
          .read(settingsViewModelProvider.notifier)
          .setReduceEffects(false);
      await tester.pump();
      expect(confetti, findsNothing);
      await releaseImage(tester);
      expect(opacity(tester), 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(tester), 1);
      await cleanup(tester);
    },
  );

  testWidgets(
    'reduce during entrance finishes once; consumed effects never revive',
    (tester) async {
      await mount(tester);
      await place(tester);
      await releaseImage(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(tester), lessThan(1));
      expect(confetti, findsOneWidget);
      container.read(settingsViewModelProvider.notifier).setReduceEffects(true);
      await tester.pump();
      await tester.pump();
      expect(opacity(tester), 1);
      expect(confetti, findsNothing);
      container
          .read(settingsViewModelProvider.notifier)
          .setReduceEffects(false);
      await tester.pump();
      expect(opacity(tester), 1);
      expect(confetti, findsNothing);
      final position = tester.getCenter(characterImage);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getCenter(characterImage), isNot(position));
      await cleanup(tester);
    },
  );

  testWidgets(
    'removing wins when reduction changes during entrance; pending image dispose is safe',
    (tester) async {
      await mount(tester);
      await place(tester);
      final id = container
          .read(stageViewModelProvider)
          .placedCharacters
          .single
          .instanceId;
      container
          .read(stageViewModelProvider.notifier)
          .requestCharacterRemoval(id);
      container.read(settingsViewModelProvider.notifier).setReduceEffects(true);
      await tester.pump();
      await releaseImage(tester);
      expect(
        container
            .read(stageViewModelProvider)
            .placedCharacters
            .single
            .stageRuntime
            .isPaused,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      expect(container.read(stageViewModelProvider).placedCharacters, isEmpty);
      await place(tester);
      await cleanup(tester);
    },
  );
}
