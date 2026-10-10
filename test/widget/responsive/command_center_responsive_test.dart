import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/core/widgets/student_os_bottom_nav.dart';
import 'package:student_os/core/widgets/student_os_button.dart';
import 'package:student_os/core/widgets/student_os_card.dart';
import 'package:student_os/core/widgets/student_os_menu.dart';
import 'package:student_os/core/widgets/student_os_section.dart';
import 'package:student_os/core/widgets/student_os_segmented_control.dart';
import 'package:student_os/core/widgets/student_os_status.dart';

Widget _wrap(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Future<void> _expectNoOverflow(
    WidgetTester tester, Widget child, Size size, String label) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_wrap(child, size: size));
  await tester.pump();
  expect(tester.takeException(), isNull, reason: label);
}

void main() {
  group('Command Center responsive validation', () {
    final sizes = {
      '320dp': const Size(320, 568),
      '360dp': const Size(360, 640),
      '390dp': const Size(390, 844),
      '412dp': const Size(412, 732),
      '430dp': const Size(430, 932),
      'tablet': const Size(768, 1024),
      'desktop': const Size(1280, 800),
    };

    for (final entry in sizes.entries) {
      testWidgets('bottom nav has no overflow at ${entry.key}',
          (tester) async {
        await _expectNoOverflow(
          tester,
          StudentOSBottomNavigation(
              selectedIndex: 0, onDestinationSelected: (_) {}),
          entry.value,
          entry.key,
        );
      });

      testWidgets('menu icon + header have no overflow at ${entry.key}',
          (tester) async {
        await _expectNoOverflow(
          tester,
          const StudentOSHeader(title: 'Home'),
          entry.value,
          entry.key,
        );
      });

      testWidgets('cards have no overflow at ${entry.key}', (tester) async {
        await _expectNoOverflow(
          tester,
          const Column(
            children: [
              StudentOSCard.standard(child: Text('Standard card content')),
              StudentOSCard.hero(child: Text('Hero card content')),
              StudentOSCard.compact(child: Text('Compact')),
            ],
          ),
          entry.value,
          entry.key,
        );
      });

      testWidgets('buttons + segmented have no overflow at ${entry.key}',
          (tester) async {
        await _expectNoOverflow(
          tester,
          Column(
            children: [
              StudentOSButton.primary(
                  label: 'Plan my time', onPressed: null),
              StudentOSSegmentedControl<String>(
                segments: const [
                  StudentOSSegment(value: 'plan', label: 'Plan'),
                  StudentOSSegment(value: 'study', label: 'Study'),
                ],
                selected: 'plan',
                onChanged: (_) {},
              ),
              const StudentOSStatusChip(label: 'On track'),
            ],
          ),
          entry.value,
          entry.key,
        );
      });
    }

    testWidgets('menu panel fits narrow 320dp width (tall viewport)', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          backgroundColor: const Color(0xFF315CF6),
          body: StudentOSMenu(
            selectedIndex: 0,
            onSelect: (_) {},
            onClose: () {},
            onProgress: () {},
            onAssistant: () {},
            onSettings: () {},
            onLogout: () {},
            itemAnimation: const AlwaysStoppedAnimation(1.0),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
