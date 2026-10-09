import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tn_landmate/features/land_search/land_search_screen.dart';

void main() {
  testWidgets('LandSearchScreen renders hierarchy fields and live extraction button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LandSearchScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title / Hierarchy header
    expect(find.text('வருவாய் படிநிலை விவரங்கள்'), findsOneWidget);

    // Verify Survey & Subdivision TextFields
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify 3 Administrative Dropdowns (District, Taluk, Village)
    expect(find.byType(DropdownButton<int>), findsNWidgets(3));

    // Verify Live Government Portal Extraction Button via Icons.bolt
    expect(find.byIcon(Icons.bolt), findsOneWidget);

    // Verify Search Records OutlinedButton
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
