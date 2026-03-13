import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:talekid/app.dart';

void main() {
  testWidgets('TaleKidApp renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TaleKidApp()),
    );

    // Verify the app builds successfully
    expect(find.byType(TaleKidApp), findsOneWidget);
  });
}
