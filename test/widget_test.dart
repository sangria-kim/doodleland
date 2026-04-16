import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodleland/app.dart';
import 'package:doodleland/core/audio/stage_audio_controller.dart';

import 'test_helpers/fake_stage_audio.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    final controller = StageAudioController(
      bgmPlayer: FakeStageBgmPlayer(),
      sfxPlayer: FakeStageSfxPlayer(),
      voicePlayer: FakeStageVoicePlayer(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stageAudioControllerProvider.overrideWith((ref) => controller),
        ],
        child: const DoodlelandApp(),
      ),
    );

    expect(find.byKey(const Key('home-bg-base')), findsOneWidget);
    expect(find.byKey(const Key('home-bg-foreground')), findsOneWidget);
    expect(find.byKey(const Key('home-bg-cars')), findsOneWidget);
    expect(find.byKey(const Key('home-bg-title')), findsOneWidget);
    expect(find.text('그림 만들기'), findsOneWidget);
    expect(find.text('놀이 시작'), findsOneWidget);
    expect(find.text('내 그림'), findsOneWidget);
  });
}
