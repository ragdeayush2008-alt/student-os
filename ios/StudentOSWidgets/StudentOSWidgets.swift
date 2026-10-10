// Tier-1 Student OS widgets (WidgetKit). One Widget per family; small /
// medium / large via supportedFamilies. See WIRING.md before expecting
// these to compile — the extension target is not yet in the Xcode project.

import WidgetKit
import SwiftUI

// MARK: - Exam Countdown

struct ExamCountdownWidget: Widget {
    let kind = "StudentOsExamCountdown"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            if let snap = entry.snapshot, let exam = snap.nextExam, !exam.id.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.title).font(.headline).foregroundColor(StudentOSWidgetConfig.ink).lineLimit(2)
                    Text(countdownLabel(days: exam.daysLeft, date: exam.dateLabel))
                        .font(.title2).bold().foregroundColor(StudentOSWidgetConfig.ink)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("exam?id=\(exam.id)"))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No upcoming exams").font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text("Tap to add your exam").font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("add-exam"))
            }
        }
        .configurationDisplayName("Next Exam")
        .description("Your next exam countdown from Student OS.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }

    private func countdownLabel(days: Int?, date: String) -> String {
        guard let days = days else { return date }
        switch days {
        case ..<0: return "Past due"
        case 0: return "Today"
        case 1: return "Tomorrow · \(date)"
        default: return "\(days) DAYS · \(date)"
        }
    }
}

// MARK: - Tasks

struct TasksWidget: Widget {
    let kind = "StudentOsTasks"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            if let tasks = entry.snapshot?.todayTasks {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tasks.remaining == 0 ? "You're all clear" : "\(tasks.remaining) task\(tasks.remaining == 1 ? "" : "s") left")
                        .font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text(tasks.topTitle.map { "Next: \($0) · ✓ \(tasks.completed) done" } ?? "✓ \(tasks.completed) done")
                        .font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("tasks"))
            } else {
                LoggedOutWidgetView()
            }
        }
        .configurationDisplayName("Today's Tasks")
        .description("Today's work from Student OS.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Plan

struct PlanWidget: Widget {
    let kind = "StudentOsPlan"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            if let plan = entry.snapshot?.todayPlan, !plan.items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(plan.items.prefix(3).enumerated()), id: \.offset) { _, item in
                        Text("\(item.time) \(item.title)")
                            .font(.caption).foregroundColor(StudentOSWidgetConfig.ink).lineLimit(1)
                    }
                    if let next = plan.nextTitle, !next.isEmpty {
                        Text("Next: \(next)").font(.caption2).foregroundColor(StudentOSWidgetConfig.sage).lineLimit(1)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("planning"))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No plan yet today").font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text("Tap to plan your day").font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("planning"))
            }
        }
        .configurationDisplayName("Daily Plan")
        .description("Your schedule from Student OS.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Focus (session + quick durations via links)

struct FocusWidget: Widget {
    let kind = "StudentOsFocus"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            VStack(alignment: .leading, spacing: 4) {
                if let focus = entry.snapshot?.focus, focus.hasActive {
                    Text(focus.title ?? "Focusing").font(.headline).foregroundColor(StudentOSWidgetConfig.ink).lineLimit(1)
                    Text(focus.remainingLabel ?? "").font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                } else {
                    Text("Ready to focus?").font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text("25 · 45 · custom in app").font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(StudentOSWidgetConfig.forest)
            .cornerRadius(StudentOSWidgetConfig.cornerRadius)
            .widgetURL(widgetURL("focus"))
        }
        .configurationDisplayName("Focus")
        .description("Your focus session from Student OS.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Assistant

struct AssistantWidget: Widget {
    let kind = "StudentOsAssistant"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            if let rec = entry.snapshot?.assistant, !rec.headline.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rec.headline).font(.headline).foregroundColor(StudentOSWidgetConfig.ink).lineLimit(2)
                    Text([rec.reason, rec.minutes.map { "\($0) min" } ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption).foregroundColor(StudentOSWidgetConfig.sage).lineLimit(2)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("assistant"))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What should I do now?").font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text("Open Student OS Assistant").font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("assistant"))
            }
        }
        .configurationDisplayName("Assistant")
        .description("Your next recommendation from Student OS.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Sleep

struct SleepWidget: Widget {
    let kind = "StudentOsSleep"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            if let sleep = entry.snapshot?.sleep {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sleep.bedtimeLabel) → \(sleep.wakeLabel)").font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text("\(sleep.durationLabel) planned").font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("sleep"))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set your sleep schedule").font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text("Tap to open sleep").font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("sleep"))
            }
        }
        .configurationDisplayName("Sleep")
        .description("Your planned sleep window from Student OS.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Study

struct StudyWidget: Widget {
    let kind = "StudentOsStudy"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            if let study = entry.snapshot?.todayStudy {
                let left = max(0, study.plannedMinutes - study.completedMinutes)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's study").font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    Text("\(study.plannedMinutes)m planned · \(study.completedMinutes)m done · \(left)m left")
                        .font(.caption).foregroundColor(StudentOSWidgetConfig.sage)
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("progress"))
            } else {
                LoggedOutWidgetView()
            }
        }
        .configurationDisplayName("Today's Study")
        .description("Study progress from Student OS.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Brief (Pro-gated)

struct BriefWidget: Widget {
    let kind = "StudentOsBrief"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StudentOSProvider()) { entry in
            if let snap = entry.snapshot, snap.lockedWidgetIds.contains("daily_brief") {
                LockedWidgetView(title: "Daily Brief")
            } else if let brief = entry.snapshot?.brief {
                VStack(alignment: .leading, spacing: 4) {
                    Text(brief.greeting).font(.headline).foregroundColor(StudentOSWidgetConfig.ink)
                    ForEach(Array(brief.lines.prefix(3).enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption).foregroundColor(StudentOSWidgetConfig.sage).lineLimit(1)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(StudentOSWidgetConfig.forest)
                .cornerRadius(StudentOSWidgetConfig.cornerRadius)
                .widgetURL(widgetURL("assistant"))
            } else {
                LoggedOutWidgetView()
            }
        }
        .configurationDisplayName("Daily Brief")
        .description("Your morning brief from Student OS.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Bundle

@main
struct StudentOSWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ExamCountdownWidget()
        TasksWidget()
        PlanWidget()
        FocusWidget()
        AssistantWidget()
        SleepWidget()
        StudyWidget()
        BriefWidget()
    }
}
