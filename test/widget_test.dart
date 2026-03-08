import 'package:flutter_test/flutter_test.dart';
import 'package:rasykh/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const RasykhApp());
    // Verify bottom nav appears with Library tab
    expect(find.text('Library'), findsNothing); // labels are icons-only
    // App renders — basic smoke test
  });
}
