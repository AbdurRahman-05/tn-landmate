import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tn_landmate/main.dart';

void main() {
  testWidgets('App smoke test: loads ProviderScope and initial shell navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TnLandMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main screen renders
    expect(find.byType(TnLandMateApp), findsOneWidget);
  });
}
