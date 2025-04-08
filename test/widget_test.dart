// TODO: Refactor tests once main GUI implemented.

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cypress/app/common/loading.dart';
import 'package:cypress/view/client/client_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Note: this will require more complex logic: I believe we will need to call:
  /// TestWidgetsFlutterBinding.ensureInitialized() before running the test suite
  ///
  /// Additionally: if the application changes/animations need to run, we need to call
  /// await tester.pumpAndSettle()
  ///
  /// We can group tests in a suite if required.
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(ClientApplication(
        initializeController: initializeControllerWithSupabase()));

    // Add tests as necessary.
  });
}
