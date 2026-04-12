import 'package:doodleland/feature/stage/domain/model/stage_background.dart';
import 'package:doodleland/feature/stage/presentation/background_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('background select screen shows all default backgrounds', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BackgroundSelectScreen())),
    );

    for (final background in defaultStageBackgrounds) {
      await tester.scrollUntilVisible(find.byKey(ValueKey(background.id)), 250);
      await tester.pumpAndSettle();
      expect(find.textContaining(background.name), findsOneWidget);
      expect(
        find.byKey(ValueKey('background-tile-${background.id}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('tap on background returns selected value', (
    WidgetTester tester,
  ) async {
    StageBackground? selectedBackground;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackgroundSelectScreen(
            onBackgroundSelected: (background) =>
                selectedBackground = background,
          ),
        ),
      ),
    );

    final target = defaultStageBackgrounds.first;
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('background-tile-${target.id}')),
      250,
    );
    await tester.tap(find.byKey(ValueKey('background-tile-${target.id}')));
    await tester.pumpAndSettle();

    expect(selectedBackground, isNotNull);
    expect(selectedBackground?.id, equals(target.id));
    expect(selectedBackground?.groundY, equals(target.groundY));
  });

  testWidgets('pororo playground is listed and selectable', (
    WidgetTester tester,
  ) async {
    StageBackground? selectedBackground;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BackgroundSelectScreen(
            onBackgroundSelected: (background) =>
                selectedBackground = background,
          ),
        ),
      ),
    );

    const pororoId = 'pororo_playground';
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('background-tile-$pororoId')),
      250,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('background-tile-$pororoId')));
    await tester.pumpAndSettle();

    expect(selectedBackground?.id, equals(pororoId));
    expect(selectedBackground?.name, equals('뽀로로 놀이터'));
    expect(
      selectedBackground?.assetPath,
      equals('assets/backgrounds/bg_pororo.jpg'),
    );
  });
}
