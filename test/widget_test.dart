// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:doodleland/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoodlelandApp());

    // Verify that the new home screen is rendered.
    expect(find.text('그림놀이터'), findsOneWidget);
    expect(find.text('그림 만들기'), findsOneWidget);
    expect(find.text('놀이 시작'), findsOneWidget);
  });
}
