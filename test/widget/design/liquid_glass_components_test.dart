import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/design/background/ambient_background.dart';
import 'package:student_os/core/design/components/inputs/liquid_glass_input.dart';
import 'package:student_os/core/design/components/selection/liquid_glass_segmented_control.dart';
import 'package:student_os/core/design/glass/glass.dart';
import 'package:student_os/core/theme/app_theme.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('AmbientBackground', () {
    testWidgets('renders all ambient variants cleanly in light and dark modes', (tester) async {
      for (final variant in AmbientVariant.values) {
        await tester.pumpWidget(
          _wrap(
            AmbientBackground(
              variant: variant,
              child: Text('Variant ${variant.name}'),
            ),
            brightness: Brightness.dark,
          ),
        );
        expect(find.text('Variant ${variant.name}'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            AmbientBackground(
              variant: variant,
              child: Text('Variant Light ${variant.name}'),
            ),
            brightness: Brightness.light,
          ),
        );
        expect(find.text('Variant Light ${variant.name}'), findsOneWidget);
      }
    });

    testWidgets('darkStage forces dark environment in light mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AmbientBackground(
            variant: AmbientVariant.authentication,
            darkStage: true,
            child: Text('Dark Stage Content'),
          ),
          brightness: Brightness.light,
        ),
      );

      expect(find.text('Dark Stage Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('GlassSurface', () {
    testWidgets('renders child content across all 4 hierarchy levels', (tester) async {
      for (final level in GlassLevel.values) {
        await tester.pumpWidget(
          _wrap(
            GlassSurface(
              level: level,
              child: Text('Level ${level.name}'),
            ),
          ),
        );
        expect(find.text('Level ${level.name}'), findsOneWidget);
      }
    });

    testWidgets('renders all hierarchy levels in light mode too', (tester) async {
      for (final level in GlassLevel.values) {
        await tester.pumpWidget(
          _wrap(
            GlassSurface(
              level: level,
              child: Text('Light Level ${level.name}'),
            ),
            brightness: Brightness.light,
          ),
        );
        expect(find.text('Light Level ${level.name}'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('base level is blurless; frosted levels apply backdropped blur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassSurface(
            level: GlassLevel.base,
            child: Text('Base Surface'),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);

      await tester.pumpWidget(
        _wrap(
          const GlassSurface(
            level: GlassLevel.standard,
            child: Text('Standard Surface'),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('handles onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          GlassSurface(
            onTap: () => tapped = true,
            child: const Text('Tap Me'),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, isTrue);
    });

    testWidgets('renders specular highlight by default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassSurface(
            level: GlassLevel.standard,
            child: Text('Specular Test'),
          ),
        ),
      );

      expect(find.text('Specular Test'), findsOneWidget);
    });
  });

  group('LiquidGlassInput', () {
    testWidgets('renders label, hint, prefix icon and accepts user typing', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          LiquidGlassInput(
            label: 'Email Address',
            hint: 'student@university.edu',
            prefixIcon: Icons.email_outlined,
            controller: ctrl,
          ),
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('student@university.edu'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'alex@mit.edu');
      expect(ctrl.text, 'alex@mit.edu');
    });

    testWidgets('toggles obscure text for password fields', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LiquidGlassInput(
            label: 'Password',
            obscureText: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('displays error message when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LiquidGlassInput(
            label: 'Email',
            errorText: 'Invalid email address',
          ),
        ),
      );

      expect(find.text('Invalid email address'), findsOneWidget);
    });
  });

  group('LiquidGlassSegmentedControl', () {
    testWidgets('switches selected segment and fires callback', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return LiquidGlassSegmentedControl<int>(
                items: const {0: 'Daily', 1: 'Weekly', 2: 'Monthly'},
                selected: selected,
                onChanged: (val) => setState(() => selected = val),
              );
            },
          ),
        ),
      );

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      await tester.tap(find.text('Weekly'));
      await tester.pump();
      expect(selected, 1);
    });
  });

  group('GlassCard', () {
    testWidgets('renders content with padding and radius in dark mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassCard(
            child: Text('Glass Card Content'),
          ),
          brightness: Brightness.dark,
        ),
      );

      expect(find.text('Glass Card Content'), findsOneWidget);
    });

    testWidgets('renders in light mode without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassCard(
            child: Text('Light Glass Card'),
          ),
          brightness: Brightness.light,
        ),
      );

      expect(find.text('Light Glass Card'), findsOneWidget);
    });
  });

  group('GlassPanel', () {
    testWidgets('renders panel with title, subtitle, and trailing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassPanel(
            title: 'Study Stats',
            subtitle: 'Today overview',
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14),
            child: Text('Panel Body'),
          ),
        ),
      );

      expect(find.text('Study Stats'), findsOneWidget);
      expect(find.text('Today overview'), findsOneWidget);
      expect(find.text('Panel Body'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });
  });

  group('GlassContainer', () {
    testWidgets('respects width and height constraints', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassContainer(
            width: 200,
            height: 100,
            child: Text('Constrained'),
          ),
        ),
      );

      expect(find.text('Constrained'), findsOneWidget);
      final size = tester.getSize(find.byType(GlassContainer));
      expect(size.width, 200);
      expect(size.height, 100);
    });
  });

  group('GlassButton', () {
    testWidgets('renders normal button and calls onPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          GlassButton(
            label: 'Start Focus',
            icon: Icons.play_arrow_rounded,
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Start Focus'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.text('Start Focus'));
      expect(pressed, isTrue);
    });

    testWidgets('shows loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassButton(
            label: 'Saving',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled button does not trigger callback', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      );

      final button = tester.widget<Semantics>(
        find.ancestor(of: find.text('Disabled'), matching: find.byType(Semantics)).first,
      );
      expect(button.properties.enabled, isFalse);
    });
  });

  group('GlassChip & GlassPill', () {
    testWidgets('renders status label and icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassChip(
            label: 'Revision',
            icon: Icons.repeat_rounded,
            isSelected: true,
          ),
        ),
      );

      expect(find.text('Revision'), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    });

    testWidgets('GlassPill responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          GlassPill(
            label: 'Active',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Active'));
      expect(tapped, isTrue);
    });
  });

  group('GlassNavigationSurface', () {
    testWidgets('renders navigation content inside glass surface', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassNavigationSurface(
            height: 60,
            child: Text('Nav Content'),
          ),
        ),
      );

      expect(find.text('Nav Content'), findsOneWidget);
    });
  });

  group('GlassSheet & GlassDialog', () {
    testWidgets('GlassSheet renders with title, drag handle, and body', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GlassSheet(
            title: 'Sheet Title',
            subtitle: 'Sheet Subtitle',
            child: Text('Sheet Body Content'),
          ),
        ),
      );

      expect(find.text('Sheet Title'), findsOneWidget);
      expect(find.text('Sheet Subtitle'), findsOneWidget);
      expect(find.text('Sheet Body Content'), findsOneWidget);
    });

    testWidgets('GlassDialog renders with icon, title, content, and actions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GlassDialog(
            icon: Icons.star_rounded,
            title: 'Reward Unlocked',
            content: const Text('You reached Level 5!'),
            actions: [
              TextButton(onPressed: () {}, child: const Text('Awesome')),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Reward Unlocked'), findsOneWidget);
      expect(find.text('You reached Level 5!'), findsOneWidget);
      expect(find.text('Awesome'), findsOneWidget);
    });
  });
}
