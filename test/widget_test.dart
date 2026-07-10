import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:handwriting_to_text/presentation/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen shows its first step', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Capture your handwriting'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
