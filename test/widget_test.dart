// Basic smoke test: app builds and renders the shell + initial route.

import 'package:flutter_test/flutter_test.dart';

import 'package:sc3_frontend/app.dart';

void main() {
  testWidgets('App renders Items page with NavigationRail shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.text('Tambah Item'), findsOneWidget);
  });
}
