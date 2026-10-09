import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tn_landmate/features/live_portal/live_government_portal_screen.dart';

void main() {
  testWidgets('LiveGovernmentPortalScreen widget smoke test renders title and assistant', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LiveGovernmentPortalScreen(
            title: 'Test Live Portal',
            initialUrl: 'https://eservices.tn.gov.in',
            districtName: 'Chennai',
            talukName: 'Ambattur',
            surveyNumber: '104',
            subdivisionNumber: '2B',
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify title is displayed
    expect(find.text('Test Live Portal'), findsAtLeastNWidgets(1));
    // Verify Assistant banner is present
    expect(find.textContaining('Live Search Assistant'), findsOneWidget);
  });
}
