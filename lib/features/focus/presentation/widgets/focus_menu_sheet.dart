import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/assistant/assistant_launch_context.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../widgets/focus_palette.dart';
import '../../data/models/focus_mission.dart';
import '../screens/focus_history_screen.dart';
import '../screens/focus_insights_screen.dart';

class FocusMenuSheet extends StatefulWidget {
  const FocusMenuSheet({super.key, this.mode = FocusMode.focusGuard});

  final FocusMode mode;

  static Future<void> show(BuildContext context, {FocusMode mode = FocusMode.focusGuard}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FocusMenuSheet(mode: mode),
    );
  }

  @override
  State<FocusMenuSheet> createState() => _FocusMenuSheetState();
}

class _FocusMenuSheetState extends State<FocusMenuSheet> {
  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final isFocus = widget.mode == FocusMode.focusGuard;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: fp.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: fp.border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildSectionLabel('INSIGHTS & HISTORY', context),
              const SizedBox(height: 8),
              if (isFocus)
                _buildNavRow(
                  icon: Icons.insights_rounded,
                  label: 'Focus Analytics',
                  onTap: () => _open(context, const FocusInsightsScreen()),
                  context: context,
                ),
              if (isFocus) const SizedBox(height: 8),
              _buildNavRow(
                icon: Icons.history_rounded,
                label: 'Focus History',
                onTap: () => _open(context, const FocusHistoryScreen()),
                context: context,
              ),
              const SizedBox(height: 8),
              _buildNavRow(
                icon: Icons.auto_awesome_rounded,
                label: 'Ask Assistant',
                onTap: () {
                  Navigator.of(context).maybePop();
                  AppRouter.openAssistant(
                    context,
                    launchContext: const AssistantLaunchContext(
                      origin: AssistantOrigin.sprintx,
                    ),
                  );
                },
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final fp = FocusPalette.of(context);
    return Row(
      children: [
        Icon(Icons.tune_rounded, color: fp.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Focus Options',
          style: TextStyle(
            color: fp.text,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        AppPressable(
          onTap: () => Navigator.of(context).maybePop(),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: fp.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, BuildContext context) {
    final fp = FocusPalette.of(context);
    return Text(
      label,
      style: TextStyle(
        color: fp.textMuted,
        fontWeight: FontWeight.w800,
        fontSize: 10,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final fp = FocusPalette.of(context);
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: fp.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: fp.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: fp.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: fp.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: fp.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}
