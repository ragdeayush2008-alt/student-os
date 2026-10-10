import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/assistant/presentation/assistant_command_center_screen.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';

/// Tools Hub shows ONE unified Student OS Assistant resolving to the
/// canonical Command Center (same controller/conversation/actions).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('exactly one Assistant entry opens the unified Assistant', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        routes: AppRouter.routes(),
        home: const ToolsHubScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student OS Assistant'), findsOneWidget);
    expect(find.text('Ask Student OS'), findsNothing);
    expect(find.text('Assistant Command Centre'), findsNothing);
    expect(find.text('Assistant Command Center'), findsNothing);

    await tester.ensureVisible(find.text('Student OS Assistant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Student OS Assistant'));
    await tester.pumpAndSettle();

    expect(find.byType(AssistantCommandCenterScreen), findsOneWidget);
  });
}
