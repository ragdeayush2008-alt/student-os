import 'models/guide_models.dart';

/// Initial high-quality set of real guides. Every guide targets functionality
/// that exists; expectations are verified against live controllers.
///
/// Anchor ids reference [GuideTargetAnchor]s registered in the real screens.
/// Steps without anchors show a coach card only and still verify their
/// controller-backed expectations.
abstract final class GuidesCatalog {
  static List<GuideDefinition> get all => const [
        // ── FIRST-TIME TOUR (≈60s) ────────────────────────────────
        GuideDefinition(
          id: 'quick_tour',
          title: 'Student OS in 60 seconds',
          description:
              'Home decides, Plan organizes, SprintX executes, Assistant helps, Sleep protects, Progress shows momentum.',
          category: GuideCategory.startHere,
          estimatedSeconds: 60,
          steps: [
            GuideStep(
              id: 'tour_home',
              title: 'Your command center',
              message:
                  'This is Home. Student OS shows what matters today — your next move, today\u2019s plan, and tonight\u2019s sleep.',
              destination: GuideDestination.home,
              targetAnchorId: 'home.hero',
            ),
            GuideStep(
              id: 'tour_plan',
              title: 'Plan organizes the work',
              message:
                  'Plan turns subjects and tasks into a day timeline. Tap Add to create your first task later.',
              destination: GuideDestination.plan,
              targetAnchorId: 'plan.addTask',
            ),
            GuideStep(
              id: 'tour_sprintx',
              title: 'SprintX executes the work',
              message:
                  'SprintX is where work happens: Focus, Timer, or Stopwatch. Pick a mode to begin.',
              destination: GuideDestination.focusCenter,
              targetAnchorId: 'sprintx.modeControl',
            ),
            GuideStep(
              id: 'tour_assistant',
              title: 'Ask Student OS for help',
              message:
                  'The Assistant can plan your day, fix your schedule, and explain any feature. Type below any time.',
              destination: GuideDestination.assistant,
              targetAnchorId: 'assistant.input',
            ),
            GuideStep(
              id: 'tour_sleep',
              title: 'Protect rest',
              message:
                  'Sleep is a planning constraint, not a medical dashboard. Set a bedtime once and planning respects it.',
              destination: GuideDestination.sleep,
              targetAnchorId: 'sleep.save',
            ),
            GuideStep(
              id: 'tour_progress',
              title: 'See your momentum',
              message:
                  'Progress and Rewards turn consistency into XP, levels, and unlocks. That\u2019s the tour — explore freely!',
              destination: GuideDestination.progress,
            ),
          ],
        ),

        // ── START HERE ───────────────────────────────────────────
        GuideDefinition(
          id: 'basics',
          title: 'Student OS Basics',
          description:
              'Your first day: the mental model behind Home, Plan, SprintX, Assistant, Sleep, and Progress.',
          category: GuideCategory.startHere,
          estimatedSeconds: 90,
          steps: [
            GuideStep(
              id: 'basics_home',
              title: 'Home decides',
              message:
                  'Home answers one question: what matters right now? Your hero card always shows the next best move.',
              destination: GuideDestination.home,
              targetAnchorId: 'home.hero',
            ),
            GuideStep(
              id: 'basics_assistant',
              title: 'Assistant helps',
              message:
                  'Stuck anywhere? Open the Assistant and ask — it can act, not just answer. Try a quick action tile.',
              destination: GuideDestination.assistant,
              targetAnchorId: 'assistant.quickActions',
            ),
            GuideStep(
              id: 'basics_learn',
              title: 'Learn by doing',
              message:
                  'Revisit any guide any time from Learn Student OS in Settings. Completed guides can be replayed.',
              destination: GuideDestination.learnCenter,
            ),
          ],
        ),
        GuideDefinition(
          id: 'home',
          title: 'Understanding your Home',
          description: 'Read your hero card, today\u2019s plan, and sleep at a glance.',
          category: GuideCategory.startHere,
          estimatedSeconds: 45,
          steps: [
            GuideStep(
              id: 'home_hero',
              title: 'Next best move',
              message:
                  'This hero card is computed from your tasks, exams, and plan. Tap Start Now to act on it.',
              destination: GuideDestination.home,
              targetAnchorId: 'home.hero',
            ),
          ],
        ),

        // ── PLAN & STUDY ─────────────────────────────────────────
        GuideDefinition(
          id: 'planning',
          title: 'How to use Planning',
          description: 'Turn tasks into a real day timeline.',
          category: GuideCategory.planStudy,
          estimatedSeconds: 75,
          steps: [
            GuideStep(
              id: 'planning_add',
              title: 'Add to your day',
              message:
                  'Tap Add to put a real task on today\u2019s timeline. Go ahead — create one now.',
              destination: GuideDestination.plan,
              targetAnchorId: 'plan.addTask',
              expectation: GuideExpectationKind.planningBlockCreated,
            ),
            GuideStep(
              id: 'planning_done',
              title: 'Timeline updated',
              message:
                  'Done — your timeline now includes that work. Planning stays in sync with Tasks automatically.',
              destination: GuideDestination.plan,
              navigateOnEnter: false,
            ),
          ],
        ),
        GuideDefinition(
          id: 'tasks',
          title: 'How to use Tasks',
          description: 'Capture work, then let planning and focus pick it up.',
          category: GuideCategory.planStudy,
          estimatedSeconds: 60,
          steps: [
            GuideStep(
              id: 'tasks_add',
              title: 'Create a real task',
              message:
                  'Tap the add control and create a real task. The guide advances when it exists.',
              destination: GuideDestination.tasks,
              targetAnchorId: 'tasks.add',
              expectation: GuideExpectationKind.taskCreated,
            ),
            GuideStep(
              id: 'tasks_done',
              title: 'Task captured',
              message:
                  'Captured. Tasks flow into Planning timelines and Focus sessions automatically.',
              destination: GuideDestination.tasks,
              navigateOnEnter: false,
            ),
          ],
        ),
        GuideDefinition(
          id: 'add_exam',
          title: 'How to add an Exam',
          description:
              'Create an exam deadline and let Student OS organize preparation.',
          category: GuideCategory.planStudy,
          estimatedSeconds: 60,
          steps: [
            GuideStep(
              id: 'exam_add',
              title: 'Add your exam',
              message:
                  'Tap add and create a real exam: name, date, and subject. The countdown starts immediately.',
              destination: GuideDestination.exams,
              targetAnchorId: 'exams.add',
              expectation: GuideExpectationKind.examCreated,
            ),
            GuideStep(
              id: 'exam_done',
              title: 'Countdown live',
              message:
                  'Your exam now drives countdowns, pressure readings, and exam-plan suggestions.',
              destination: GuideDestination.exams,
              navigateOnEnter: false,
            ),
          ],
        ),
        GuideDefinition(
          id: 'exam_planning',
          title: 'How to build an Exam Plan',
          description:
              'Structure preparation across the days your exam date allows.',
          category: GuideCategory.planStudy,
          difficulty: GuideDifficulty.intermediate,
          estimatedSeconds: 90,
          unlockAfter: ['add_exam'],
          steps: [
            GuideStep(
              id: 'examplan_exam',
              title: 'Start from the deadline',
              message:
                  'Exam planning works backward from your exam date. Open your nearest exam first.',
              destination: GuideDestination.exams,
              targetAnchorId: 'exams.add',
            ),
            GuideStep(
              id: 'examplan_plan',
              title: 'Shape the days',
              message:
                  'In Planning, preparation becomes day blocks across the days you have left. Add one now to feel it.',
              destination: GuideDestination.plan,
              targetAnchorId: 'plan.addTask',
              expectation: GuideExpectationKind.planningBlockCreated,
            ),
          ],
        ),
        GuideDefinition(
          id: 'revision',
          title: 'How to use Revision',
          description: 'Keep memory fresh with a due-queue, not a list.',
          category: GuideCategory.planStudy,
          estimatedSeconds: 60,
          unlockAfter: ['planning'],
          steps: [
            GuideStep(
              id: 'revision_tour',
              title: 'Your memory queue',
              message:
                  'Revision surfaces what is due, overdue, and stable. Work the queue top-down.',
              destination: GuideDestination.plan,
            ),
          ],
        ),

        // ── FOCUS ────────────────────────────────────────────────
        GuideDefinition(
          id: 'sprintx',
          title: 'How to use SprintX',
          description: 'Turn planned work into focused sessions.',
          category: GuideCategory.focus,
          estimatedSeconds: 45,
          steps: [
            GuideStep(
              id: 'sprintx_modes',
              title: 'Three modes',
              message:
                  'Focus guards your attention, Timer counts down, Stopwatch counts up. Choose one to begin.',
              destination: GuideDestination.focusCenter,
              targetAnchorId: 'sprintx.modeControl',
            ),
          ],
        ),
        GuideDefinition(
          id: 'focus',
          title: 'How to use Focus',
          description: 'Guarded attention with a mission and a duration.',
          category: GuideCategory.focus,
          estimatedSeconds: 60,
          unlockAfter: ['sprintx'],
          steps: [
            GuideStep(
              id: 'focus_start',
              title: 'Start a real session',
              message:
                  'Start any real focus session now. The guide advances the moment it runs — end it whenever you like.',
              destination: GuideDestination.focusCenter,
              expectation: GuideExpectationKind.focusSessionStarted,
            ),
            GuideStep(
              id: 'focus_done',
              title: 'Session running',
              message:
                  'That\u2019s a live session. End it from the session screen whenever you\u2019re ready — nothing is wasted.',
              destination: GuideDestination.focusCenter,
              navigateOnEnter: false,
            ),
          ],
        ),
        GuideDefinition(
          id: 'custom_focus',
          title: 'How to use Custom Focus',
          description: 'Any duration you need, not just presets.',
          category: GuideCategory.focus,
          difficulty: GuideDifficulty.intermediate,
          estimatedSeconds: 75,
          unlockAfter: ['sprintx'],
          steps: [
            GuideStep(
              id: 'custom_duration',
              title: 'Pick your minutes',
              message:
                  'Open the Timer, choose a preset or Custom, and set the minutes that fit your energy.',
              destination: GuideDestination.focusCenter,
              targetAnchorId: 'sprintx.durationPicker',
            ),
            GuideStep(
              id: 'custom_start',
              title: 'Start the timer',
              message:
                  'Press Start Timer to run a real session with your duration. End it any time.',
              destination: GuideDestination.focusCenter,
              targetAnchorId: 'sprintx.startTimer',
              navigateOnEnter: false,
              expectation: GuideExpectationKind.focusSessionStarted,
            ),
          ],
        ),
        GuideDefinition(
          id: 'deep_focus',
          title: 'How to use Deep Focus',
          description: 'Your first guarded deep session, verified live.',
          category: GuideCategory.focus,
          difficulty: GuideDifficulty.advanced,
          estimatedSeconds: 90,
          unlockAfter: ['sprintx', 'focus'],
          steps: [
            GuideStep(
              id: 'deep_modes',
              title: 'Deep Focus lives here',
              message:
                  'Deep Focus is the guarded mode of SprintX: a mission, a duration, and protection from distractions.',
              destination: GuideDestination.focusCenter,
              targetAnchorId: 'sprintx.modeControl',
            ),
            GuideStep(
              id: 'deep_duration',
              title: 'Choose how long',
              message:
                  'Choose how long you want to focus. Pick a duration that feels honest — 25 minutes is a fine start.',
              destination: GuideDestination.focusCenter,
              targetAnchorId: 'sprintx.durationPicker',
              navigateOnEnter: false,
            ),
            GuideStep(
              id: 'deep_start',
              title: 'Start for real',
              message:
                  'Press the actual start control. The guide verifies your live session — no long commitment needed.',
              destination: GuideDestination.focusCenter,
              targetAnchorId: 'sprintx.startTimer',
              navigateOnEnter: false,
              expectation: GuideExpectationKind.focusSessionStarted,
            ),
            GuideStep(
              id: 'deep_during',
              title: 'During the session',
              message:
                  'While it runs, SprintX guards your screen and tracks the time. End it whenever you like — you\u2019ve learned the interaction.',
              destination: GuideDestination.focusCenter,
              navigateOnEnter: false,
            ),
          ],
        ),

        // ── STUDENT LIFE ─────────────────────────────────────────
        GuideDefinition(
          id: 'sleep',
          title: 'How to use Sleep',
          description: 'Set a bedtime once; planning respects it forever.',
          category: GuideCategory.studentLife,
          estimatedSeconds: 60,
          steps: [
            GuideStep(
              id: 'sleep_bedtime',
              title: 'Planned bedtime',
              message:
                  'Sleep is a schedule, not a medical report. Set the bedtime you actually want.',
              destination: GuideDestination.sleep,
              targetAnchorId: 'sleep.bedtime',
            ),
            GuideStep(
              id: 'sleep_wake',
              title: 'Wake time',
              message:
                  'Now the wake time. The window between them is your protected rest.',
              destination: GuideDestination.sleep,
              targetAnchorId: 'sleep.wake',
              navigateOnEnter: false,
            ),
            GuideStep(
              id: 'sleep_save',
              title: 'Save it for real',
              message:
                  'Press Save Schedule. Planning immediately treats this window as a constraint.',
              destination: GuideDestination.sleep,
              targetAnchorId: 'sleep.save',
              navigateOnEnter: false,
              expectation: GuideExpectationKind.sleepScheduleSaved,
            ),
          ],
        ),
        GuideDefinition(
          id: 'progress',
          title: 'How to use Progress',
          description: 'Read momentum: streaks, XP, and what moved.',
          category: GuideCategory.studentLife,
          estimatedSeconds: 45,
          steps: [
            GuideStep(
              id: 'progress_tour',
              title: 'Your momentum',
              message:
                  'Progress turns finished work into streaks and insight. Check it weekly, not hourly.',
              destination: GuideDestination.progress,
            ),
          ],
        ),
        GuideDefinition(
          id: 'rewards',
          title: 'How Rewards work',
          description: 'XP, levels, and unlocks for consistency.',
          category: GuideCategory.studentLife,
          estimatedSeconds: 60,
          unlockAfter: ['progress'],
          steps: [
            GuideStep(
              id: 'rewards_tour',
              title: 'Earn by showing up',
              message:
                  'Finishing work earns XP. Levels unlock cosmetics and themes — never pay-to-win mechanics.',
              destination: GuideDestination.rewards,
            ),
          ],
        ),

        // ── TOOLS ──────────────────────────────────────────────
        GuideDefinition(
          id: 'tools',
          title: 'How to use Tools Hub',
          description: 'Quick utilities: notes, calculator, checklist, habits.',
          category: GuideCategory.tools,
          estimatedSeconds: 60,
          steps: [
            GuideStep(
              id: 'tools_assistant',
              title: 'Ask from anywhere',
              message:
                  'The Assistant lives here too. Ask it to plan, triage, or explain — same brain, same context.',
              destination: GuideDestination.toolsHub,
              targetAnchorId: 'tools.assistant',
            ),
            GuideStep(
              id: 'tools_primary',
              title: 'Everyday utilities',
              message:
                  'Notes, calculator, wellness, checklist, habits, and the distraction inbox — tap any tile to open the real tool.',
              destination: GuideDestination.toolsHub,
              targetAnchorId: 'tools.primary',
              navigateOnEnter: false,
            ),
          ],
        ),

        // ── ASSISTANT ────────────────────────────────────────────
        GuideDefinition(
          id: 'assistant',
          title: 'How to use Student OS Assistant',
          description: 'Ask, preview, confirm — the Assistant acts.',
          category: GuideCategory.assistant,
          estimatedSeconds: 60,
          steps: [
            GuideStep(
              id: 'assistant_ask',
              title: 'Ask anything',
              message:
                  'Type below any time. Try “Plan my day” — the Assistant previews a real plan before applying it.',
              destination: GuideDestination.assistant,
              targetAnchorId: 'assistant.input',
            ),
            GuideStep(
              id: 'assistant_actions',
              title: 'One-tap actions',
              message:
                  'These tiles trigger real flows: planning, study picks, urgency triage, sleep setup. Tap one to feel it.',
              destination: GuideDestination.assistant,
              targetAnchorId: 'assistant.quickActions',
              navigateOnEnter: false,
            ),
          ],
        ),
      ];
}
