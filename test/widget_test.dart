import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodleland/app.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DoodlelandApp()));

    expect(find.byKey(const Key('home-bg-base')), findsOneWidget);
    expect(find.byKey(const Key('home-bg-foreground')), findsOneWidget);
    expect(find.byKey(const Key('home-bg-cars')), findsOneWidget);
    expect(find.byKey(const Key('home-bg-title')), findsOneWidget);
    expect(find.text('그림 만들기'), findsOneWidget);
    expect(find.text('놀이 시작'), findsOneWidget);
  });
}
