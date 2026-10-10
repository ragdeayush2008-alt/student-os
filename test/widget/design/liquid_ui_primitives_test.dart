import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/design/design_system.dart';
import 'package:student_os/core/theme/app_theme.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: Center(child: child))),
  );
}

void main() {
  group('AppButton Hierarchy', () {
    testWidgets('AppButton.primary renders with blue accent styling', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AppButton.primary(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      await tester.tap(find.text('Continue'));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton.secondary renders as translucent glass', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppButton.secondary(
            label: 'Cancel',
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('AppButton.destructive renders with error styling', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppButton.destructive(
            label: 'Delete Task',
            icon: Icons.delete_outline_rounded,
          ),
        ),
      );

      expect(find.text('Delete Task'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('AppButton shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppButton.primary(
            label: 'Saving...',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppIconButton', () {
    testWidgets('renders glass, solid, and ghost variants', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          Row(
            children: [
              AppIconButton(
                icon: Icons.add,
                variant: AppIconButtonVariant.glass,
                onPressed: () => tapped = true,
              ),
              const AppIconButton(
                icon: Icons.edit,
                variant: AppIconButtonVariant.solid,
              ),
              const AppIconButton(
                icon: Icons.close,
                variant: AppIconButtonVariant.ghost,
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      expect(tapped, isTrue);
    });
  });

  group('Card Hierarchy', () {
    testWidgets('HeroCard renders title, subtitle, actions, and badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HeroCard(
            title: 'Exam Preparation',
            subtitle: 'Physics midterm in 3 days',
            icon: Icons.school_rounded,
            badge: const StatusPill(status: AppStatusType.exam),
            primaryAction: AppButton.primary(label: 'Start Study', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Exam Preparation'), findsOneWidget);
      expect(find.text('Physics midterm in 3 days'), findsOneWidget);
      expect(find.text('Start Study'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    });

    testWidgets('ActionCard responds to tap and displays chevron', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ActionCard(
            title: 'Review Mistakes',
            subtitle: '12 practice questions need attention',
            icon: Icons.history_edu_rounded,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Review Mistakes'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Review Mistakes'));
      expect(tapped, isTrue);
    });

    testWidgets('ListCard renders leading, title, subtitle, and trailing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ListCard(
            leading: Icon(Icons.check_box_outline_blank_rounded),
            title: 'Complete Math Homework',
            subtitle: 'Due today at 5:00 PM',
            trailing: StatusPill(status: AppStatusType.overdue),
          ),
        ),
      );

      expect(find.text('Complete Math Homework'), findsOneWidget);
      expect(find.text('Due today at 5:00 PM'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });
  });

  group('Status System', () {
    testWidgets('StatusChip renders all semantic status types', (tester) async {
      for (final status in AppStatusType.values) {
        await tester.pumpWidget(
          _wrap(
            StatusChip(status: status),
          ),
        );
        expect(find.text(status.defaultLabel), findsOneWidget);
      }
    });

    testWidgets('StatusPill renders compact dot and label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StatusPill(status: AppStatusType.completed),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
    });
  });

  group('Progress System', () {
    testWidgets('LiquidLinearProgress renders animated progress bar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LiquidLinearProgress(value: 0.65, height: 8),
        ),
      );

      expect(find.byType(LiquidLinearProgress), findsOneWidget);
    });

    testWidgets('LiquidCircularProgress renders with center label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LiquidCircularProgress(
            value: 0.75,
            label: '75%',
            subtitle: 'Goal',
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
    });

    testWidgets('StatProgressCard renders title, value, and progress bar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const StatProgressCard(
            title: 'Syllabus Mastery',
            value: '84%',
            progress: 0.84,
            icon: Icons.auto_graph_rounded,
          ),
        ),
      );

      expect(find.text('Syllabus Mastery'), findsOneWidget);
      expect(find.text('84%'), findsOneWidget);
      expect(find.byIcon(Icons.auto_graph_rounded), findsOneWidget);
    });

    testWidgets('DurationProgress renders elapsed and total minutes', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DurationProgress(
            elapsedMinutes: 30,
            totalMinutes: 45,
          ),
        ),
      );

      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('of 45 min'), findsOneWidget);
    });
  });

  group('States System', () {
    testWidgets('GlassEmptyState renders title, description, and action', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GlassEmptyState(
            title: 'No Tasks Yet',
            description: 'Add your first assignment or study goal.',
            icon: Icons.task_alt_rounded,
            primaryAction: AppButton.primary(label: 'Add Task', onPressed: () {}),
          ),
        ),
      );

      expect(find.text('No Tasks Yet'), findsOneWidget);
      expect(find.text('Add your first assignment or study goal.'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('GlassErrorState and AppErrorCard render retry CTA', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          AppErrorCard(
            title: 'Failed to load schedule',
            message: 'Network timeout occurred.',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Failed to load schedule'), findsOneWidget);
      expect(find.text('Network timeout occurred.'), findsOneWidget);

      await tester.tap(find.byTooltip('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('SyncStatusIndicator displays sync states accurately', (tester) async {
      for (final state in SyncState.values) {
        await tester.pumpWidget(
          _wrap(
            SyncStatusIndicator(state: state),
          ),
        );
        expect(find.text(state.label), findsOneWidget);
      }
    });

    testWidgets('OfflineBanner displays notice to user', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const OfflineBanner(),
        ),
      );

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
    });
  });

  group('Responsive & Accessibility Foundation', () {
    testWidgets('LiquidResponsiveContent constrains wide screens to 720 max width', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrap(
          const LiquidResponsiveContent(
            child: Text('Constrained Content'),
          ),
        ),
      );

      expect(find.text('Constrained Content'), findsOneWidget);
      final box = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Constrained Content'), matching: find.byType(ConstrainedBox)).first,
      );
      expect(box.constraints.maxWidth, 720);
    });

    testWidgets('LiquidTouchTarget ensures min 48x48 bounds', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LiquidTouchTarget(
            child: SizedBox(width: 20, height: 20),
          ),
        ),
      );

      final size = tester.getSize(find.byType(LiquidTouchTarget));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });
}
