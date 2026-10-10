import 'package:flutter/material.dart';

import '../planning/planning_screen.dart';

/// Legacy alias for Plan & Study tab with STUDY mode active.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlanningScreen(initialTab: PlanStudyTab.study);
  }
}
