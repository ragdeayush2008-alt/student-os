import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import 'models/guide_models.dart';

/// Maps guide destinations onto existing navigation. Reuses [AppRouter]
/// helpers exclusively — no new routes, no stack surgery.
abstract final class GuideNavigator {
  static void open(BuildContext context, GuideDestination destination) {
    switch (destination) {
      case GuideDestination.home:
        AppRouter.openHome(context);
        break;
      case GuideDestination.plan:
        AppRouter.openPlan(context);
        break;
      case GuideDestination.tasks:
        AppRouter.openTasks(context);
        break;
      case GuideDestination.exams:
        AppRouter.openExams(context);
        break;
      case GuideDestination.focusCenter:
        AppRouter.openFocusCenter(context);
        break;
      case GuideDestination.sleep:
        AppRouter.openSleepSchedule(context);
        break;
      case GuideDestination.assistant:
        AppRouter.openAssistantCommandCenter(context);
        break;
      case GuideDestination.rewards:
        AppRouter.openRewards(context);
        break;
      case GuideDestination.progress:
        AppRouter.openProgress(context);
        break;
      case GuideDestination.toolsHub:
        AppRouter.openTools(context);
        break;
      case GuideDestination.learnCenter:
        AppRouter.openLearnCenter(context);
        break;
    }
  }
}
