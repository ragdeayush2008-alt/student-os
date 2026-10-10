import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/navigation/shell_destinations.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/widgets/student_os_menu.dart';
import 'package:student_os/core/widgets/student_os_menu_icon.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  final theme =
      brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();
  return MaterialApp(theme: theme, home: Scaffold(body: child));
}

/// Finds a [Semantics] widget carrying [label].
Finder findLabel(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.label == label),
    );

void main() {
  group('Bottom navigation — locked 5 destinations', () {
    test('order is Home, Plan & Study, SprintX, Tools Hub, Workspace', () {
      final titles = ShellDestinations.all.map((d) => d.title).toList();
      expect(titles,
          ['Home', 'Plan & Study', 'SprintX', 'Tools Hub', 'Workspace']);
      expect(ShellDestinations.all.length, 5);
    });

    testWidgets('all five destinations render with labels', (tester) async {
      var selected = 0;
      await tester.pumpWidget(_wrap(
        StudentOSBottomNavigation(
          selectedIndex: selected,
          onDestinationSelected: (i) => selected = i,
        ),
      ));
      for (final title in [
        'Home',
        'Plan & Study',
        'SprintX',
        'Tools Hub',
        'Workspace'
      ]) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('selected destination is marked selected', (tester) async {
      await tester.pumpWidget(_wrap(
        StudentOSBottomNavigation(
          selectedIndex: 2,
          onDestinationSelected: (_) {},
        ),
      ));
      final semantics = findLabel('SprintX tab');
      expect(semantics, findsOneWidget);
    });

    testWidgets('tapping destination calls back with index', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(_wrap(
        StudentOSBottomNavigation(
          selectedIndex: 0,
          onDestinationSelected: (i) => tapped = i,
        ),
      ));
      await tester.tap(find.text('SprintX'));
      expect(tapped, 2);
      await tester.tap(find.text('Workspace'));
      expect(tapped, 4);
    });

    testWidgets('route preservation: destinations keep routes', (tester) async {
      expect(ShellDestinations.home.route, '/home');
      expect(ShellDestinations.plan.route, '/plan');
      expect(ShellDestinations.focus.route, '/focus-center');
      expect(ShellDestinations.tools.route, '/tools');
      expect(ShellDestinations.workspace.route, '/more');
    });
  });

  group('StudentOSMenuIcon — official hamburger', () {
    testWidgets('renders with Open navigation label', (tester) async {
      await tester.pumpWidget(
          _wrap(const StudentOSMenuIcon(semanticLabel: 'Open navigation')));
      expect(findLabel('Open navigation'), findsOneWidget);
    });

    testWidgets('pressed state morphs toward close icon', (tester) async {
      await tester.pumpWidget(_wrap(const _MorphHarness()));
      expect(findLabel('Open navigation'), findsOneWidget);
      await tester.tap(find.byType(StudentOSMenuButton));
      await tester.pumpAndSettle();
      expect(findLabel('Close navigation'), findsOneWidget);
      // Both states paint without overflow.
      expect(tester.takeException(), isNull);
    });

    testWidgets('white variant renders on blue menu', (tester) async {
      await tester.pumpWidget(_wrap(
        const ColoredBox(
          color: Color(0xFF315CF6),
          child: StudentOSMenuIcon(color: Colors.white),
        ),
      ));
      expect(find.byType(StudentOSMenuIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StudentOSMenu — navigation layer', () {
    Future<void> pumpMenu(WidgetTester tester,
        {ValueChanged<int>? onSelect}) async {
      await tester.pumpWidget(_wrap(
        StudentOSMenu(
          selectedIndex: 0,
          onSelect: onSelect ?? (_) {},
          onClose: () {},
          onProgress: () {},
          onAssistant: () {},
          onSettings: () {},
          onLogout: () {},
          itemAnimation: const AlwaysStoppedAnimation(1.0),
          userGreeting: 'Good evening',
          userName: 'Test Student',
        ),
      ));
      await tester.pump();
    }

    testWidgets('shows primary destinations only (no engines)', (tester) async {
      await pumpMenu(tester);
      for (final label in [
        'Home',
        'Plan & Study',
        'SprintX',
        'Tools Hub',
        'Workspace'
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      for (final hidden in [
        'Revision Engine',
        'Planning Engine',
        'Autopilot',
        'Mastery Engine',
        'Conflict Engine',
      ]) {
        expect(find.text(hidden), findsNothing);
      }
    });

    testWidgets('secondary menu + logout below divider', (tester) async {
      await pumpMenu(tester);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Ask Student OS'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('close button has Close navigation label', (tester) async {
      await pumpMenu(tester);
      expect(findLabel('Close navigation'), findsOneWidget);
    });

    testWidgets('navigation from menu fires onSelect', (tester) async {
      var selected = -1;
      await pumpMenu(tester, onSelect: (i) => selected = i);
      await tester.tap(find.text('SprintX'));
      expect(selected, 2);
    });

    testWidgets('menu surface is solid Deep Forest (no glass)', (tester) async {
      await pumpMenu(tester);
      final menu =
          tester.widget<StudentOSMenu>(find.byType(StudentOSMenu));
      // Phase 1: the green family is the product identity, so the
      // hamburger/contextual menu surface is Deep Forest, not blue.
      expect(StudentOSMenu.menuSurface, const Color(0xFF123D35));
      expect(StudentOSMenu.menuBlue, StudentOSMenu.menuSurface);
      expect(StudentOSMenu.menuAccent, const Color(0xFF6F967F));
      expect(menu, isNotNull);
    });
  });
}

class _MorphHarness extends StatefulWidget {
  const _MorphHarness();

  @override
  State<_MorphHarness> createState() => _MorphHarnessState();
}

class _MorphHarnessState extends State<_MorphHarness> {
  bool closed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () => setState(() => closed = !closed),
        child: StudentOSMenuButton(
          onPressed: () => setState(() => closed = !closed),
          progress: closed ? 1 : 0,
          semanticLabel: closed ? 'Close navigation' : 'Open navigation',
        ),
      ),
    );
  }
}
