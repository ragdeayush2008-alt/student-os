import 'package:flutter/material.dart';

import '../auth/auth_isolation.dart';
import '../services/storage_service.dart';
import '../../features/auth/auth_service.dart';
import '../../features/guides/guide_assistant_bridge.dart';
import '../../features/guides/guide_registry.dart';
import '../../features/planning/controllers/planning_block_controller.dart';
import '../../features/tasks/task_controller.dart';
import 'assistant_launch_context.dart';
import 'assistant_message.dart';
import 'assistant_planning_engine.dart';
import 'daily_assistant_controller.dart';
import 'student_assistant_action.dart';
import 'student_assistant_context.dart';
import 'student_assistant_engine.dart';
import 'student_assistant_intent.dart';
import 'student_assistant_parser.dart';
import 'student_assistant_result.dart';

class StudentAssistantController extends ChangeNotifier {
  StudentAssistantController._();

  static final StudentAssistantController instance =
      StudentAssistantController._();

  static const _conversationKey = 'assistant_conversation';

  /// Cap: only recent history is kept (storage + rendering stay cheap).
  static const _maxMessages = 30;

  final StudentAssistantEngine _engine = const StudentAssistantEngine();

  String _currentInput = '';
  bool _isLoading = false;
  StudentAssistantResult? _lastResult;
  StudentAssistantAction? _pendingConfirmationAction;
  AssistantConversationContext _conversation =
      AssistantConversationContext.empty;
  List<AssistantMessage> _messages = [];

  /// P2 staged proposal (plan sessions / moves / creations). Set whenever a
  /// preview result carries one; applied only on Confirm, cleared on
  /// Cancel, new questions, or logout. Never persisted (session state).
  AssistantDayPlan? _pendingProposal;
  bool _disposed = false;

  String get currentInput => _currentInput;
  bool get isLoading => _isLoading;
  StudentAssistantResult? get lastResult => _lastResult;
  AssistantConversationContext get conversation => _conversation;
  StudentAssistantAction? get pendingConfirmationAction =>
      _pendingConfirmationAction;
  bool get isAwaitingConfirmation => _pendingConfirmationAction != null;

  /// Persisted visible history (capped). Ephemeral follow-up resolution
  /// still lives in [conversation].
  List<AssistantMessage> get messages => List.unmodifiable(_messages);

  /// Recent user prompts (most recent first, max 5, deduplicated) for the
  /// question catalog's "Recent" section. Derived from persisted history —
  /// no duplicate storage.
  List<String> get recentPrompts {
    final out = <String>[];
    for (final m in _messages.reversed) {
      if (m.role != AssistantMessageRole.user) continue;
      final text = m.text.trim();
      if (text.isEmpty || out.contains(text)) continue;
      out.add(text);
      if (out.length >= 5) break;
    }
    return out;
  }

  AssistantDayPlan? get pendingProposal => _pendingProposal;
  bool get hasPendingProposal =>
      _pendingProposal != null && !_pendingProposal!.isEmpty;

  /// Guide launch requested by an explicit "teach me" query. The UI layer
  /// (sheet / command center) consumes this post-frame and starts the guide
  /// with a real BuildContext. Null when none is pending.
  String? _pendingGuideId;
  String? get pendingGuideId => _pendingGuideId;

  /// Returns and clears the pending guide launch, if any.
  String? consumePendingGuide() {
    final id = _pendingGuideId;
    _pendingGuideId = null;
    return id;
  }

  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _currentInput = '';
    _isLoading = false;
    _lastResult = null;
    _pendingConfirmationAction = null;
    _pendingProposal = null;
    _launchContext = AssistantLaunchContext.global;
    _conversation = AssistantConversationContext.empty;
    _messages = [];
    if (!_disposed) notifyListeners();
  }

  /// Transient launch context for the canonical Assistant (which feature
  /// opened it). In-memory only — cleared on logout, never persisted.
  AssistantLaunchContext _launchContext = AssistantLaunchContext.global;
  AssistantLaunchContext get launchContext => _launchContext;

  /// Called by entry points before presenting the Assistant UI.
  void setLaunchContext(AssistantLaunchContext context) {
    _launchContext = context;
    if (!_disposed) notifyListeners();
  }

  /// Loads persisted conversation history for the current user.
  /// Missing/corrupt entries degrade to an empty history, never a crash.
  Future<void> loadConversation() async {
    final uid = _userId;
    if (uid == null) {
      _messages = [];
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final list = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _conversationKey,
      );
      _messages = list
              ?.map((j) {
                try {
                  return AssistantMessage.fromJson(j);
                } catch (_) {
                  return null;
                }
              })
              .whereType<AssistantMessage>()
              .toList() ??
          [];
      if (_messages.length > _maxMessages) {
        _messages = _messages.sublist(_messages.length - _maxMessages);
      }
    } catch (_) {
      _messages = [];
    }
    if (!_disposed) notifyListeners();
  }

  /// User-initiated clear: wipes memory AND stored history.
  Future<void> clearConversation() async {
    _messages = [];
    _conversation = AssistantConversationContext.empty;
    _lastResult = null;
    _pendingConfirmationAction = null;
    _pendingProposal = null;
    final uid = _userId;
    if (uid != null) {
      try {
        await StorageService.instance.remove(
          userId: uid,
          key: _conversationKey,
        );
      } catch (_) {}
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _persistConversation() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final capped = _messages.length > _maxMessages
          ? _messages.sublist(_messages.length - _maxMessages)
          : _messages;
      await StorageService.instance.saveJsonList(
        userId: uid,
        key: _conversationKey,
        list: capped.map((m) => m.toJson()).toList(),
      );
    } catch (_) {
      // Best-effort; in-memory history is unaffected.
    }
  }

  /// Processes user query through the assistant engine.
  ///
  /// The controller owns ephemeral conversation memory (Phase 4 §18): a bare
  /// duration or an ordinal reference ("the first one") is resolved against the
  /// previous turn before a fresh parse.
  Future<StudentAssistantResult> ask(String query) async {
    _currentInput = query.trim();
    _isLoading = true;
    _pendingConfirmationAction = null;
    // Interactive-guide interception: explicit "teach me" phrasing launches
    // a real guide instead of an engine answer. Anything else flows through.
    final guideId = GuideAssistantBridge.matchGuideId(_currentInput);
    if (guideId != null && GuideRegistry.byId(guideId) != null) {
      try {
        final title =
            GuideAssistantBridge.matchGuideTitle(_currentInput) ??
                'Student OS';
        _pendingGuideId = guideId;
        final result = StudentAssistantResult(
          success: true,
          intent: StudentAssistantIntent(
            rawText: _currentInput,
            intentType: AssistantIntentType.unknown,
          ),
          title: 'Opening guide: $title',
          message: GuideAssistantBridge.launchMessage(title),
          cardKind: AssistantCardKind.neutral,
        );
        _lastResult = result;
        _pendingProposal = null;
        _messages = [
          ..._messages,
          AssistantMessage(
            role: AssistantMessageRole.user,
            text: _currentInput,
            timestamp: DateTime.now(),
          ),
          AssistantMessage(
            role: AssistantMessageRole.assistant,
            text: result.message,
            timestamp: DateTime.now(),
            title: result.title,
            cardKind: result.cardKind.name,
          ),
        ];
        if (_messages.length > _maxMessages) {
          _messages = _messages.sublist(_messages.length - _maxMessages);
        }
        _persistConversation();
        return result;
      } finally {
        _isLoading = false;
        if (!_disposed) notifyListeners();
      }
    }
    // Follow-up resolution reads the staged proposal; it is replaced or
    // cleared below once the new result lands.
    final activeProposal = _pendingProposal;
    if (!_disposed) notifyListeners();

    try {
      final snapshot = AssistantContextSnapshot.capture();
      final explicit = _resolveFollowUp(_currentInput, snapshot);

      final result = _engine.process(
        _currentInput,
        context: snapshot,
        explicitIntent: explicit,
        proposal: activeProposal,
      );
      _lastResult = result;
      if (result.proposal != null) {
        _pendingProposal = result.proposal;
      } else if (result.clarificationRequired &&
          result.intent.intentType == AssistantIntentType.refinePlan &&
          activeProposal != null) {
        // "Which plan item?" keeps the staged proposal alive so the
        // answer can still resolve against it.
        _pendingProposal = activeProposal;
      } else {
        _pendingProposal = null;
      }
      // P3 daily loop transitions ride on intent types, never on content.
      if (result.intent.intentType == AssistantIntentType.morningBriefing &&
          result.proposal != null) {
        await DailyAssistantController.instance.markPrepared();
      }
      if (result.intent.intentType == AssistantIntentType.eveningReview) {
        await DailyAssistantController.instance.markReviewed();
      }
      // Stage the Apply confirmation whenever a proposal is previewed,
      // whether Apply is the primary or a secondary action.
      if (result.requiresConfirmation && result.primaryAction != null) {
        _pendingConfirmationAction = result.primaryAction;
      } else if (hasPendingProposal) {
        final apply = result.secondaryActions
            .where((a) => a.type == AssistantActionType.applyPlan)
            .firstOrNull;
        if (apply != null) _pendingConfirmationAction = apply;
      }
      _messages = [
        ..._messages,
        AssistantMessage(
          role: AssistantMessageRole.user,
          text: _currentInput,
          timestamp: DateTime.now(),
        ),
        AssistantMessage(
          role: AssistantMessageRole.assistant,
          text: result.message,
          timestamp: DateTime.now(),
          title: result.title,
          cardKind: result.cardKind.name,
        ),
      ];
      if (_messages.length > _maxMessages) {
        _messages = _messages.sublist(_messages.length - _maxMessages);
      }
      _persistConversation();
      _conversation = _conversation.nextTurn(
        query: _currentInput,
        steps: result.steps,
      );

      // Keep the original intent available when the Assistant asked for a
      // clarification, so a follow-up such as a bare "45 minutes" can be
      // resolved against it on the next turn (§18). Proposal refinements
      // always keep theirs so exact item titles resolve next turn.
      if (result.clarificationRequired &&
          (explicit == null ||
              result.intent.intentType == AssistantIntentType.refinePlan)) {
        _conversation = _conversation.withPendingDuration(result.intent);
      }

      return result;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Resolves a follow-up turn into a concrete intent, or null to parse fresh.
  StudentAssistantIntent? _resolveFollowUp(
    String query,
    AssistantContextSnapshot snapshot,
  ) {
    final lowered = query.toLowerCase().trim();
    if (lowered.isEmpty) return null;

    // 0. Proposal refinement ("remove X", "make Y first") resolves against
    // the staged proposal without repeating the original request.
    if (_pendingProposal != null && !_pendingProposal!.isEmpty) {
      final refined = _resolveProposalEdit(lowered, query);
      if (refined != null) return refined;

      // 0d. Answering a "which plan item?" clarification with an exact
      // item title completes the pending refinement.
      final pending = _conversation.pendingIntent;
      if (pending != null &&
          pending.intentType == AssistantIntentType.refinePlan) {
        final proposal = _pendingProposal!;
        final titles = [
          ...proposal.sessions.map((s) => s.title),
          ...proposal.moves.map((m) => m.taskTitle),
          ...proposal.creations.map((c) => c.title),
        ];
        for (var i = 0; i < titles.length; i++) {
          if (titles[i].toLowerCase() == lowered) {
            return pending.copyWith(
              rawText: query,
              refineIndex: i,
            );
          }
        }
      }
    }

    // 0b. Sleep duration follow-up: pending wake-time question + a bare
    // "7am" carries the held duration forward.
    final pending = _conversation.pendingIntent;
    if (pending != null &&
        pending.intentType == AssistantIntentType.updateSleepSchedule &&
        pending.durationMinutes != null &&
        pending.durationMinutes! > 0) {
      final wake = _parseBareClock(lowered);
      if (wake != null) {
        return pending.copyWith(rawText: query, wakeMinutes: wake);
      }
    }

    // 0c. Missing task title: a free-text reply names the task, unless the
    // reply itself is a recognizable command.
    if (_lastResult?.clarificationRequired == true &&
        _lastResult?.intent.intentType == AssistantIntentType.createTask &&
        (_lastResult?.intent.taskName ?? '').isEmpty &&
        !_looksLikeCommand(lowered)) {
      return _lastResult!.intent.copyWith(
        rawText: query,
        taskName: query.trim(),
      );
    }

    // 0d. Pending exam-date question answered with a bare date.
    final pendingForDate = _conversation.pendingIntent;
    if (pendingForDate != null &&
        pendingForDate.intentType == AssistantIntentType.updateExamDate &&
        pendingForDate.examId != null) {
      final day = DeterministicStudentIntentParser.parseDayDate(
        lowered,
        DateTime.now(),
      );
      if (day != null) {
        return pendingForDate.copyWith(
          rawText: query,
          targetDate: day,
        );
      }
    }

    // 1. A bare duration answers a pending question ("…45 minutes").
    if (pending != null) {
      final minutes = _parseBareDuration(lowered);
      if (minutes != null && minutes > 0) {
        return pending.copyWith(
          rawText: query,
          durationMinutes: minutes,
          availableMinutes: pending.availableMinutes ?? minutes,
        );
      }
    }

    // 2. An ordinal selects a row from the previous structured card.
    final index = _parseOrdinal(lowered);
    if (index != null &&
        index >= 0 &&
        index < _conversation.lastSteps.length) {
      return _intentForStep(_conversation.lastSteps[index], query, snapshot);
    }

    return null;
  }

  /// Proposal edits ("remove X", "make Y first") resolve item titles
  /// against the staged proposal. Returns null when the query is not a
  /// proposal edit, so normal parsing proceeds.
  StudentAssistantIntent? _resolveProposalEdit(
    String lowered,
    String query,
  ) {
    final proposal = _pendingProposal;
    if (proposal == null) return null;

    String? op;
    var remainder = '';
    for (final verb in ['remove ', 'drop ']) {
      if (lowered.startsWith(verb)) {
        op = 'remove';
        remainder = lowered.substring(verb.length).trim();
        break;
      }
    }
    if (op == null) {
      final firstMatch =
          RegExp(r'^(make|move)\s+(.+?)\s+first$').firstMatch(lowered) ??
              RegExp(r'^(.+?)\s+first$').firstMatch(lowered);
      if (firstMatch != null) {
        final candidate = firstMatch.groupCount == 2
            ? firstMatch.group(2)!
            : firstMatch.group(1)!;
        // "X first" alone is too ambiguous outside proposals with X.
        op = 'moveFirst';
        remainder = candidate.trim();
      }
    }
    if (op == null || remainder.isEmpty) return null;

    final titles = [
      ...proposal.sessions.map((s) => s.title),
      ...proposal.moves.map((m) => m.taskTitle),
      ...proposal.creations.map((c) => c.title),
    ];
    final hits = <int>[];
    for (var i = 0; i < titles.length; i++) {
      final title = titles[i].toLowerCase();
      if (title.contains(remainder) || remainder.contains(title)) {
        hits.add(i);
      }
    }
    // Verb is clear but the item isn't: let the engine clarify with the
    // real item titles instead of dropping to an unknown dead end.
    if (hits.length != 1) {
      return StudentAssistantIntent(
        rawText: query,
        intentType: AssistantIntentType.refinePlan,
        refineOp: op,
        refineIndex: -1,
      );
    }
    return StudentAssistantIntent(
      rawText: query,
      intentType: AssistantIntentType.refinePlan,
      refineOp: op,
      refineIndex: hits.single,
    );
  }

  /// Bare clock ("7am", "11:30pm") → minutes-since-midnight, else null.
  static int? _parseBareClock(String lowered) {
    final marked =
        RegExp(r'^(\d{3,4}|\d{1,2})\s*(am|pm)$').firstMatch(lowered);
    if (marked != null) {
      final digits = marked.group(1)!;
      final int h;
      var min = 0;
      if (digits.length > 2) {
        h = int.parse(digits.substring(0, digits.length - 2));
        min = int.parse(digits.substring(digits.length - 2));
      } else {
        h = int.parse(digits);
      }
      if (min > 59) return null;
      final marker = marked.group(2)!;
      if (h < 1 || h > 12) return null;
      final hour24 = marker == 'am'
          ? (h == 12 ? 0 : h)
          : (h == 12 ? 12 : h + 12);
      return hour24 * 60 + min;
    }
    final dotted =
        RegExp(r'^(\d{1,2})\.(\d{2})\s*(am|pm)?$').firstMatch(lowered);
    if (dotted != null) {
      final h = int.parse(dotted.group(1)!);
      final min = int.parse(dotted.group(2)!);
      if (min > 59 || h > 23) return null;
      return h * 60 + min;
    }
    return null;
  }

  /// Heuristic: does this look like a fresh command rather than a free-text
  /// slot value (e.g. a task title)?
  static bool _looksLikeCommand(String lowered) {
    const starters = [
      'create',
      'add',
      'make',
      'move',
      'set',
      'plan',
      'show',
      'what',
      'how',
      'when',
      'start',
      'stop',
      'delete',
      'remove',
      'fix',
      'complete',
      'finish',
      'break',
      'give',
      'help',
      'open',
    ];
    for (final s in starters) {
      if (lowered == s || lowered.startsWith('$s ')) return true;
    }
    return false;
  }

  /// Prefill text for the proposal Edit affordance (the original request,
  /// editable and resendable).
  String draftTextForEdit() => _conversation.lastQuery ?? _currentInput;

  StudentAssistantIntent? _intentForStep(    AssistantResultStep step,
    String query,
    AssistantContextSnapshot snapshot,
  ) {
    if (step.topicId != null) {
      return StudentAssistantIntent(
        rawText: query,
        intentType: AssistantIntentType.scheduleTopic,
        subjectId: step.subjectId,
        chapterId: step.chapterId,
        topicId: step.topicId,
        topicName: step.label,
      );
    }
    if (step.taskId != null) {
      return StudentAssistantIntent(
        rawText: query,
        intentType: AssistantIntentType.startTask,
        taskId: step.taskId,
        taskName: step.label,
        durationMinutes: step.minutes,
      );
    }
    if (step.subjectId != null) {
      return StudentAssistantIntent(
        rawText: query,
        intentType: AssistantIntentType.focusSubject,
        subjectId: step.subjectId,
        durationMinutes: step.minutes,
      );
    }
    return null;
  }

  static int? _parseOrdinal(String lowered) {
    final compact = lowered.replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    switch (compact) {
      case 'first':
      case 'first one':
      case 'the first':
      case 'the first one':
      case '1':
      case '1st':
      case 'one':
      case 'number 1':
        return 0;
      case 'second':
      case 'second one':
      case 'the second':
      case 'the second one':
      case '2':
      case '2nd':
      case 'two':
      case 'number 2':
        return 1;
      case 'third':
      case 'third one':
      case 'the third':
      case 'the third one':
      case '3':
      case '3rd':
      case 'three':
      case 'number 3':
        return 2;
    }
    return null;
  }

  static int? _parseBareDuration(String lowered) {
    final compact = lowered.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').trim();
    if (compact.isEmpty) return null;

    if (RegExp(r'\b(half an hour)\b').hasMatch(compact)) return 30;
    if (RegExp(r'\b(an hour|one hour)\b').hasMatch(compact)) return 60;

    final hourMatch =
        RegExp(r'(\d+)\s*(hours|hour|hrs|hr|h)\b').firstMatch(compact);
    if (hourMatch != null) {
      final h = int.tryParse(hourMatch.group(1)!);
      if (h != null && h > 0) return h * 60;
    }

    final minMatch =
        RegExp(r'(\d+)\s*(minutes|minute|mins|min|m)\b').firstMatch(compact);
    if (minMatch != null) {
      final m = int.tryParse(minMatch.group(1)!);
      if (m != null && m > 0) return m;
    }

    final bare = RegExp(r'^(\d{1,3})$').firstMatch(compact);
    if (bare != null) {
      final m = int.tryParse(bare.group(1)!);
      if (m != null && m > 0) return m;
    }
    return null;
  }

  /// Selects one of the clarification choices and immediately processes it.
  Future<StudentAssistantResult> selectClarificationChoice(String choice) async {
    return ask(choice);
  }

  /// Confirms and executes the pending mutating action.
  ///
  /// Proposal confirmations ([AssistantActionType.applyPlan] with a staged
  /// [_pendingProposal]) execute through the existing controllers item by
  /// item and report success / partial / failure honestly. Everything else
  /// delegates to the engine as before.
  Future<void> confirmAction(BuildContext context) async {
    final action = _pendingConfirmationAction;
    if (action == null) return;

    _pendingConfirmationAction = null;
    if (!_disposed) notifyListeners();

    final proposal = _pendingProposal;
    if (action.type == AssistantActionType.applyPlan && proposal != null) {
      _pendingProposal = null;
      await DailyAssistantController.instance.logAction(
        'Applied ${_describeProposal(proposal)}',
      );
      await DailyAssistantController.instance.noteApplied(
        sessions: proposal.sessions.length,
        moves: proposal.moves.length,
        creations: proposal.creations.length,
      );
      await _applyProposal(proposal);
      return;
    }
    _pendingProposal = null;
    await DailyAssistantController.instance.logAction(
      'Confirmed ${action.label}',
    );
    if (!context.mounted) return;
    await _engine.executeAction(context, action);
  }

  static String _describeProposal(AssistantDayPlan proposal) {
    final parts = <String>[];
    if (proposal.sessions.isNotEmpty) {
      parts.add(
        '${proposal.sessions.length} session${proposal.sessions.length == 1 ? '' : 's'}',
      );
    }
    if (proposal.moves.isNotEmpty) {
      parts.add(
        '${proposal.moves.length} move${proposal.moves.length == 1 ? '' : 's'}',
      );
    }
    if (proposal.creations.isNotEmpty) {
      parts.add(
        '${proposal.creations.length} task${proposal.creations.length == 1 ? '' : 's'}',
      );
    }
    return parts.isEmpty ? 'empty plan' : 'plan (${parts.join(', ')})';
  }

  /// Applies a staged proposal through existing controllers. Never deletes;
  /// sessions become planning blocks, moves shift due dates, creations
  /// become tasks. Reports success / partial / failed honestly.
  Future<void> _applyProposal(AssistantDayPlan proposal) async {
    var okSessions = 0;
    final failedSessions = <String>[];
    var okMoves = 0;
    final failedMoves = <String>[];
    var okCreations = 0;
    final failedCreations = <String>[];

    final starts = proposal.laidOutStarts();
    for (var i = 0; i < proposal.sessions.length; i++) {
      final s = proposal.sessions[i];
      try {
        final start = i < starts.length ? starts[i] : DateTime.now();
        await PlanningBlockController.instance.scheduleBlock(
          s.taskId,
          start,
          start.add(Duration(minutes: s.minutes)),
          subjectId: s.subjectId,
          topicId: s.topicId,
          examId: s.examId,
          customTitle: s.taskId == null &&
                  s.subjectId == null &&
                  s.topicId == null &&
                  s.examId == null
              ? s.title
              : null,
        );
        okSessions++;
      } catch (_) {
        failedSessions.add(s.title);
      }
    }

    for (final m in proposal.moves) {
      try {
        final task = TaskController.instance.tasks
            .where((t) => t.id == m.taskId)
            .firstOrNull;
        if (task == null) {
          failedMoves.add('${m.taskTitle} (no longer exists)');
          continue;
        }
        await TaskController.instance.updateTask(
          task.copyWith(dueDate: m.toDate),
        );
        okMoves++;
      } catch (_) {
        failedMoves.add(m.taskTitle);
      }
    }

    for (final c in proposal.creations) {
      try {
        await TaskController.instance.createTask(
          title: c.title,
          dueDate: c.dueDate,
          subjectId: c.subjectId,
          priority: c.priority,
          estimatedMinutes: c.estimatedMinutes,
        );
        okCreations++;
      } catch (_) {
        failedCreations.add(c.title);
      }
    }

    final total = proposal.sessions.length +
        proposal.moves.length +
        proposal.creations.length;
    final done = okSessions + okMoves + okCreations;
    final failed = [
      ...failedSessions,
      ...failedMoves,
      ...failedCreations,
    ];

    final parts = <String>[];
    if (okSessions > 0) {
      parts.add('$okSessions session${okSessions == 1 ? '' : 's'} planned');
    }
    if (okMoves > 0) {
      parts.add('$okMoves task${okMoves == 1 ? '' : 's'} moved');
    }
    if (okCreations > 0) {
      parts.add('$okCreations task${okCreations == 1 ? '' : 's'} created');
    }
    final StudentAssistantResult outcome;
    if (done == 0) {
      outcome = const StudentAssistantResult(
        success: false,
        intent: StudentAssistantIntent(
          rawText: '',
          intentType: AssistantIntentType.planTime,
        ),
        title: 'Couldn\'t Apply Changes',
        message: 'No changes were made. Nothing was deleted.',
        cardKind: AssistantCardKind.error,
      );
    } else if (failed.isEmpty) {
      outcome = StudentAssistantResult(
        success: true,
        intent: const StudentAssistantIntent(
          rawText: '',
          intentType: AssistantIntentType.planTime,
        ),
        title: 'Done',
        message: 'Applied: ${parts.join(', ')}.',
        cardKind: AssistantCardKind.success,
      );
    } else {
      outcome = StudentAssistantResult(
        success: true,
        intent: const StudentAssistantIntent(
          rawText: '',
          intentType: AssistantIntentType.planTime,
        ),
        title: 'Partially Applied',
        message:
            '$done of $total applied (${parts.join(', ')}). Skipped: ${failed.take(3).join('; ')}.',
        cardKind: AssistantCardKind.confirmation,
      );
    }

    _lastResult = outcome;
    _messages = [
      ..._messages,
      AssistantMessage(
        role: AssistantMessageRole.assistant,
        text: outcome.message,
        timestamp: DateTime.now(),
        title: outcome.title,
        cardKind: outcome.cardKind.name,
      ),
    ];
    if (_messages.length > _maxMessages) {
      _messages = _messages.sublist(_messages.length - _maxMessages);
    }
    _persistConversation();
    if (!_disposed) notifyListeners();
  }

  /// Cancels the pending confirmation action.
  void cancelConfirmation() {
    _pendingConfirmationAction = null;
    _pendingProposal = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
