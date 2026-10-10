import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/design/tokens/student_os_tokens.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/widgets/student_os_icon_glow.dart';
import 'package:student_os/core/widgets/student_os_menu_icon.dart';
import 'package:student_os/core/widgets/student_os_status.dart';
import 'package:student_os/features/auth/presentation/welcome_screen.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));
}

void main() {
  group('StudentOSGlow tokens', () {
    test('semantic tones map to the spec palette', () {
      // Phase 1: the primary glow tone is Forest, the product's identity.
      expect(
        StudentOSGlow.colorFor(StudentOSGlowTone.primary),
        const Color(0xFF285C4D),
      );
      expect(
        StudentOSGlow.colorFor(StudentOSGlowTone.secondary),
        const Color(0xFF7657F5),
      );
      expect(
        StudentOSGlow.colorFor(StudentOSGlowTone.success),
        const Color(0xFF16B88A),
      );
      expect(
        StudentOSGlow.colorFor(StudentOSGlowTone.warning),
        const Color(0xFFF5A524),
      );
      expect(
        StudentOSGlow.colorFor(StudentOSGlowTone.danger),
        const Color(0xFFEF5B63),
      );
    });

    test('opacity stays restrained across intensities', () {
      for (final i in StudentOSGlowIntensity.values) {
        final o = StudentOSGlow.opacityFor(i, false);
        expect(o, lessThanOrEqualTo(0.30), reason: '$i');
      }
      expect(StudentOSGlow.opacityFor(StudentOSGlowIntensity.none, false), 0.0);
      expect(
        StudentOSGlow.opacityFor(StudentOSGlowIntensity.minimal, false),
        lessThan(StudentOSGlow.opacityFor(StudentOSGlowIntensity.subtle, false)),
      );
      expect(
        StudentOSGlow.opacityFor(StudentOSGlowIntensity.subtle, false),
        lessThan(
          StudentOSGlow.opacityFor(StudentOSGlowIntensity.standard, false),
        ),
      );
    });

    test('radius tokens stay within the soft-glow budget', () {
      expect(StudentOSGlow.spreadFor(StudentOSGlowRadius.small), 4.0);
      expect(StudentOSGlow.spreadFor(StudentOSGlowRadius.medium), 6.0);
      expect(StudentOSGlow.spreadFor(StudentOSGlowRadius.hero), 8.0);
      expect(StudentOSGlow.blurFor(StudentOSGlowRadius.hero), 26.0);
    });

    test('disabled and none intensities produce no shadow', () {
      expect(
        StudentOSGlow.shadows(
          glowColor: StudentOSColors.primary,
          enabled: false,
        ),
        isEmpty,
      );
      expect(
        StudentOSGlow.shadows(
          glowColor: StudentOSColors.primary,
          intensity: StudentOSGlowIntensity.none,
        ),
        isEmpty,
      );
      expect(
        StudentOSGlow.shadows(glowColor: StudentOSColors.primary),
        hasLength(1),
      );
      // Single soft shadow, centered (ambient, not directional).
      final shadow = StudentOSGlow.shadows(
        glowColor: StudentOSColors.primary,
      ).single;
      expect(shadow.offset, Offset.zero);
      expect(shadow.blurRadius, greaterThan(shadow.spreadRadius));
    });
  });

  group('StudentOSIconGlow widget', () {
    testWidgets('renders child and passes through when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StudentOSIconGlow(
            glowColor: StudentOSColors.primary,
            enabled: false,
            child: Icon(Icons.bolt_rounded, size: 22),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      // Disabled glow adds no decorated wrapper: the glow widget returns
      // the child directly, so no Container exists in this minimal tree.
      expect(find.byType(Container), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('enabled glow wraps icon in a soft shadow container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StudentOSIconGlow(
            glowColor: StudentOSColors.primary,
            child: Icon(Icons.bolt_rounded, size: 22),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tone constructor resolves semantic color', (tester) async {
      await tester.pumpWidget(
        _wrap(
          StudentOSIconGlow.tone(
            tone: StudentOSGlowTone.success,
            intensity: StudentOSGlowIntensity.standard,
            radius: StudentOSGlowRadius.medium,
            child: Container(width: 44, height: 44, color: Colors.white),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ambient glow keeps emoji crisp', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StudentOSAmbientGlow.tone(
            tone: StudentOSGlowTone.primary,
            child: Text('🎯', style: TextStyle(fontSize: 32)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🎯'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('interactive glow holds active state without pulsing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const StudentOSInteractiveGlow(
            glowColor: StudentOSColors.primary,
            active: true,
            child: Icon(Icons.play_arrow_rounded, size: 22),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Glow integration — no clipping or overflow', () {
    testWidgets('bottom nav selected tab glows, bar stays clean', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            bottomNavigationBar: StudentOSBottomNavigation(
              selectedIndex: 2,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudentOSBottomNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menu icon clean at rest, subtle when morphed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudentOSMenuIcon(progress: 0),
              StudentOSMenuIcon(progress: 1),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state illustration glows softly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StudentOSEmptyState(
            title: 'Nothing here',
            message: 'Try again later.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('welcome fits 320dp and 430dp with glow', (tester) async {
      for (final width in [320.0, 430.0]) {
        tester.view.physicalSize = Size(width * 3, 800 * 3);
        tester.view.devicePixelRatio = 3.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: AuthScope(
              authService: AuthService.instance,
              child: const WelcomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Student OS'), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  });
}
