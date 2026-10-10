import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:student_os/features/auth/presentation/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen renders without demo user', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Student OS'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
