import 'package:flutter_test/flutter_test.dart';
import 'package:masarifi/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MasarifiApp());
    await tester.pumpAndSettle();
    expect(find.text('مصاريفي'), findsOneWidget);
  });
}
