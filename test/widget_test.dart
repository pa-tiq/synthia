import 'package:flutter_test/flutter_test.dart';
import 'package:synthia/app.dart';

void main() {
  testWidgets('App title is shown in AppBar', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const SynthiaApp());

    // Verify that the AppBar contains the app name
    expect(find.text('Synthia'), findsOneWidget);
  });

  testWidgets('File selection button is present', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const SynthiaApp());

    // Find the button with text
    expect(find.text('Choose File to Summarize'), findsOneWidget);
  });

  testWidgets('Feature cards are displayed', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const SynthiaApp());

    // Check for feature descriptions
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
  });

  // Add more tests as needed
}
