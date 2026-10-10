import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/widgets/student_os_button.dart';
import 'package:student_os/core/widgets/student_os_menu.dart';
import 'package:student_os/core/widgets/student_os_menu_icon.dart';
import 'package:student_os/core/widgets/student_os_segmented_control.dart';
import 'package:student_os/core/widgets/student_os_status.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));
}

/// Finds a [Semantics] widget carrying [label], independent of whether the
/// semantics tree is enabled in the test environment.
Finder findLabel(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.label == label),
    );

void main() {
  group('Command Center accessibility', () {
    testWidgets('hamburger has Open navigation label', (tester) async {
      await tester.pumpWidget(_wrap(
        StudentOSMenuButton(
            onPressed: () {}, semanticLabel: 'Open navigation'),
      ));
      expect(findLabel('Open navigation'), findsOneWidget);
    });

    testWidgets('menu close has Close navigation label', (tester) async {
      await tester.pumpWidget(_wrap(
        StudentOSMenu(
          selectedIndex: 0,
          onSelect: (_) {},
          onClose: () {},
          onProgress: () {},
          onAssistant: () {},
          onSettings: () {},
          onLogout: () {},
          itemAnimation: const AlwaysStoppedAnimation(1.0),
        ),
      ));
      expect(findLabel('Close navigation'), findsOneWidget);
    });

    testWidgets('bottom navigation has meaningful tab labels', (tester) async {
      await tester.pumpWidget(_wrap(
        StudentOSBottomNavigation(
            selectedIndex: 0, onDestinationSelected: (_) {}),
      ));
      for (final label in [
        'Home tab',
        'Plan & Study tab',
        'SprintX tab',
        'Tools Hub tab',
        'Workspace tab'
      ]) {
        expect(findLabel(label), findsOneWidget);
      }
    });

    testWidgets('buttons expose labels', (tester) async {
      await tester.pumpWidget(_wrap(
        Column(
          children: [
            StudentOSButton.primary(
                label: 'Plan my time',
                semanticLabel: 'Plan my time',
                onPressed: () {}),
            StudentOSButton.secondary(
                label: 'Cancel', semanticLabel: 'Cancel', onPressed: () {}),
          ],
        ),
      ));
      expect(findLabel('Plan my time'), findsWidgets);
      expect(findLabel('Cancel'), findsWidgets);
    });

    testWidgets('segmented control exposes selection', (tester) async {
      await tester.pumpWidget(_wrap(
        StudentOSSegmentedControl<String>(
          semanticLabel: 'Plan study selector',
          segments: const [
            StudentOSSegment(value: 'plan', label: 'Plan'),
            StudentOSSegment(value: 'study', label: 'Study'),
          ],
          selected: 'plan',
          onChanged: (_) {},
        ),
      ));
      expect(findLabel('Plan study selector'), findsOneWidget);
      expect(findLabel('Plan'), findsOneWidget);
    });

    testWidgets('menu items are buttons with labels', (tester) async {
      await tester.pumpWidget(_wrap(
        StudentOSMenu(
          selectedIndex: 1,
          onSelect: (_) {},
          onClose: () {},
          onProgress: () {},
          onAssistant: () {},
          onSettings: () {},
          onLogout: () {},
          itemAnimation: const AlwaysStoppedAnimation(1.0),
        ),
      ));
      expect(findLabel('Plan & Study navigation item'), findsOneWidget);
      expect(findLabel('Log out'), findsOneWidget);
    });

    testWidgets('status chip exposes label', (tester) async {
      await tester.pumpWidget(
          _wrap(const StudentOSStatusChip(label: 'On track')));
      expect(find.text('On track'), findsOneWidget);
    });
  });
}
