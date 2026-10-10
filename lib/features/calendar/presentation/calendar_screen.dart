import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_week_utils.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../exams/exam_controller.dart';
import '../../planning/controllers/planning_block_controller.dart';
import '../../tasks/task_controller.dart';
import '../academic_schedule_controller.dart';
import 'widgets/add_edit_event_sheet.dart';
import 'widgets/day_schedule_view.dart';
import 'widgets/month_schedule_view.dart';
import 'widgets/week_schedule_view.dart';

/// Available view modes for the Academic Calendar.
enum CalendarViewMode {
  week('Week', Icons.calendar_view_week_rounded),
  day('Day', Icons.view_agenda_rounded),
  month('Month', Icons.calendar_month_rounded);

  const CalendarViewMode(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Calendar & Academic Schedule 2.0 workspace.
///
/// Unifies fixed commitments, exams, task deadlines, and planning blocks
/// into the student's unified academic time layer.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.initialDate,
    this.initialMode = CalendarViewMode.week,
  });

  final DateTime? initialDate;
  final CalendarViewMode initialMode;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarViewMode _viewMode;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialMode;
    _selectedDay = AppWeekUtils.dateOnly(widget.initialDate ?? DateTime.now());

    AcademicScheduleController.instance.addListener(_onDataChanged);
    ExamController.instance.addListener(_onDataChanged);
    TaskController.instance.addListener(_onDataChanged);
    PlanningBlockController.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AcademicScheduleController.instance.removeListener(_onDataChanged);
    ExamController.instance.removeListener(_onDataChanged);
    TaskController.instance.removeListener(_onDataChanged);
    PlanningBlockController.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _openAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditEventSheet(
        initialDate: _selectedDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Academic Schedule',
      actions: [
        // Today Jump Button
        TextButton.icon(
          icon: const Icon(Icons.today_rounded, size: 18),
          label: const Text('Today'),
          onPressed: () {
            setState(() {
              _selectedDay = AppWeekUtils.dateOnly(DateTime.now());
            });
          },
        ),
        // Add Commitment Button
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add Commitment',
          onPressed: _openAddEventSheet,
        ),
      ],
      body: Column(
        children: [
          // View Mode Selector Segmented Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<CalendarViewMode>(
                segments: CalendarViewMode.values.map((mode) {
                  return ButtonSegment<CalendarViewMode>(
                    value: mode,
                    label: Text(mode.label),
                    icon: Icon(mode.icon, size: 16),
                  );
                }).toList(),
                selected: {_viewMode},
                onSelectionChanged: (newSelection) {
                  setState(() => _viewMode = newSelection.first);
                },
              ),
            ),
          ),

          // Main View Content
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_viewMode) {
      case CalendarViewMode.week:
        return WeekScheduleView(
          selectedDay: _selectedDay,
          onDaySelected: (day) {
            setState(() => _selectedDay = AppWeekUtils.dateOnly(day));
          },
          onAddEventPressed: _openAddEventSheet,
        );
      case CalendarViewMode.day:
        return DayScheduleView(
          selectedDay: _selectedDay,
          onDaySelected: (day) {
            setState(() => _selectedDay = AppWeekUtils.dateOnly(day));
          },
          onAddEventPressed: _openAddEventSheet,
        );
      case CalendarViewMode.month:
        return MonthScheduleView(
          selectedDay: _selectedDay,
          onDaySelected: (day) {
            setState(() => _selectedDay = AppWeekUtils.dateOnly(day));
          },
          onSwitchToDayView: () {
            setState(() => _viewMode = CalendarViewMode.day);
          },
        );
    }
  }
}
