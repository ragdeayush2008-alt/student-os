// StudentOSWidgets — WidgetKit extension sources (Tier 1).
//
// STATUS: source-complete, Xcode target NOT yet wired (see WIRING.md).
// These files are intentionally outside the Runner target so they cannot
// break existing iOS builds. Wire them per WIRING.md when an Apple
// Developer Team + App Group become available, then flip the per-report
// iOS verification items from BLOCKED to executed.
//
// Architecture mirrors Android: read ONE JSON snapshot from the shared
// App Group ("group.com.ragdetechnologies.studentos.widgets",
// key "student_os_widget_snapshot"), render, deep-link back
// (`studentos://widget/...`). No business logic, no secrets.

import WidgetKit
import SwiftUI

// MARK: - Snapshot model (tolerant decode, mirrors widget_snapshot.dart)

struct WidgetSnapshot: Decodable {
    var userId: String = ""
    var generatedAt: String = ""
    var loggedOut: Bool = false
    var nextExam: ExamData?
    var upcomingExams: [ExamData] = []
    var examPrep: ExamPrepData?
    var todayStudy: StudyData?
    var subjectProgress: SubjectProgressData?
    var nextAction: ActionData?
    var todayTasks: TasksData?
    var todayPlan: PlanData?
    var backlog: BacklogData?
    var focus: FocusData?
    var focusStats: FocusStatsData?
    var focusStreakDays: Int?
    var assistant: AssistantData?
    var sleep: SleepData?
    var dayBalance: DayBalanceData?
    var brief: BriefData?
    var lockedWidgetIds: [String] = []

    enum CodingKeys: String, CodingKey {
        case userId, generatedAt, loggedOut, nextExam, upcomingExams,
             examPrep, todayStudy, subjectProgress, nextAction, todayTasks,
             todayPlan, backlog, focus, focusStats, focusStreakDays,
             assistant, sleep, dayBalance, brief, lockedWidgetIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = (try? c.decodeIfPresent(String.self, forKey: .userId)) ?? ""
        generatedAt = (try? c.decodeIfPresent(String.self, forKey: .generatedAt)) ?? ""
        loggedOut = (try? c.decodeIfPresent(Bool.self, forKey: .loggedOut)) ?? false
        nextExam = try? c.decodeIfPresent(ExamData.self, forKey: .nextExam)
        upcomingExams = (try? c.decodeIfPresent([ExamData].self, forKey: .upcomingExams)) ?? []
        examPrep = try? c.decodeIfPresent(ExamPrepData.self, forKey: .examPrep)
        todayStudy = try? c.decodeIfPresent(StudyData.self, forKey: .todayStudy)
        subjectProgress = try? c.decodeIfPresent(SubjectProgressData.self, forKey: .subjectProgress)
        nextAction = try? c.decodeIfPresent(ActionData.self, forKey: .nextAction)
        todayTasks = try? c.decodeIfPresent(TasksData.self, forKey: .todayTasks)
        todayPlan = try? c.decodeIfPresent(PlanData.self, forKey: .todayPlan)
        backlog = try? c.decodeIfPresent(BacklogData.self, forKey: .backlog)
        focus = try? c.decodeIfPresent(FocusData.self, forKey: .focus)
        focusStats = try? c.decodeIfPresent(FocusStatsData.self, forKey: .focusStats)
        focusStreakDays = try? c.decodeIfPresent(Int.self, forKey: .focusStreakDays)
        assistant = try? c.decodeIfPresent(AssistantData.self, forKey: .assistant)
        sleep = try? c.decodeIfPresent(SleepData.self, forKey: .sleep)
        dayBalance = try? c.decodeIfPresent(DayBalanceData.self, forKey: .dayBalance)
        brief = try? c.decodeIfPresent(BriefData.self, forKey: .brief)
        lockedWidgetIds = (try? c.decodeIfPresent([String].self, forKey: .lockedWidgetIds)) ?? []
    }

    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: StudentOSWidgetConfig.appGroupId),
              let raw = defaults.string(forKey: StudentOSWidgetConfig.snapshotKey),
              let data = raw.data(using: .utf8),
              let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              !snap.loggedOut,
              !snap.userId.isEmpty else {
            return nil
        }
        return snap
    }
}

struct ExamData: Decodable {
    var id: String = ""
    var title: String = ""
    var subject: String = ""
    var dateLabel: String = ""
    var daysLeft: Int?
    var windowDays: Int?
}

struct ExamPrepData: Decodable {
    var examId: String = ""
    var title: String = ""
    var daysLeft: Int?
    var targetTitle: String?
    var targetMinutes: Int?
}

struct StudyData: Decodable {
    var plannedMinutes: Int = 0
    var completedMinutes: Int = 0
}

struct SubjectProgressData: Decodable {
    var subjectId: String = ""
    var subjectName: String = ""
    var studyPercent: Int?
    var revisionDone: Int?
    var revisionTotal: Int?
}

struct ActionData: Decodable {
    var title: String = ""
    var subtitle: String = ""
    var minutes: Int?
    var reason: String = ""
    var taskId: String?
    var kind: String = "task"
}

struct TasksData: Decodable {
    var remaining: Int = 0
    var completed: Int = 0
    var topTitle: String?
    var topPriority: String?
}

struct PlanItemData: Decodable {
    var time: String = ""
    var title: String = ""
    var minutes: Int?
}

struct PlanData: Decodable {
    var items: [PlanItemData] = []
    var nextTitle: String?
    var nextMinutes: Int?
}

struct BacklogData: Decodable {
    var unfinished: Int = 0
    var overdue: Int = 0
    var topTitle: String?
}

struct FocusData: Decodable {
    var hasActive: Bool = false
    var title: String?
    var remainingLabel: String?
    var mode: String?
}

struct FocusStatsData: Decodable {
    var todayMinutes: Int = 0
    var sessionsToday: Int = 0
    var weekMinutes: Int = 0
}

struct AssistantData: Decodable {
    var headline: String = ""
    var reason: String = ""
    var minutes: Int?
}

struct SleepData: Decodable {
    var bedtimeLabel: String = ""
    var wakeLabel: String = ""
    var durationLabel: String = ""
}

struct DayBalanceData: Decodable {
    var studyMinutes: Int = 0
    var focusMinutes: Int = 0
    var tasksRemaining: Int = 0
    var sleepLabel: String?
}

struct BriefData: Decodable {
    var greeting: String = ""
    var lines: [String] = []
}
