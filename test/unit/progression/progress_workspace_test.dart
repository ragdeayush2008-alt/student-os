import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/progression/progress_workspace_screen.dart';

void main() {
  testWidgets('ProgressWorkspace renders with real controllers', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProgressWorkspaceScreen()));
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
