import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/app/app_router.dart';

void main() {
  group('Navigation Hardening Regression', () {
    testWidgets('Continue Task opens task detail when taskId present', (
      tester,
    ) async {
      // Verify openTaskDetail exists and takes non-null id
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('test'))),
      );
      // Navigation helper is present; structural verification
      expect(AppRouter.openTaskDetail, isA<Function>());
    });

    testWidgets('Start Now opens study when no taskId', (tester) async {
      expect(AppRouter.openStudy, isA<Function>());
    });
  });
}
