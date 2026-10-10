// Shared WidgetKit plumbing: config, timeline provider, theme, entries.

import WidgetKit
import SwiftUI

enum StudentOSWidgetConfig {
    static let appGroupId = "group.com.ragdetechnologies.studentos.widgets"
    static let snapshotKey = "student_os_widget_snapshot"

    // Deep emerald brand surfaces (match Android + app theme family).
    static let forest = Color(red: 0x12 / 255.0, green: 0x3D / 255.0, blue: 0x35 / 255.0)
    static let sage = Color(red: 0xA9 / 255.0, green: 0xC1 / 255.0, blue: 0xAE / 255.0)
    static let ink = Color.white
    static let cornerRadius: CGFloat = 20
}

struct StudentOSEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct StudentOSProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudentOSEntry {
        StudentOSEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudentOSEntry) -> Void) {
        completion(StudentOSEntry(date: Date(), snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudentOSEntry>) -> Void) {
        let entry = StudentOSEntry(date: Date(), snapshot: WidgetSnapshot.load())
        // WidgetKit decides refresh cadence; re-read the snapshot on the
        // next timeline pass. The app pushes fresh data on every meaningful
        // change, so timelines stay honest without polling here.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

func widgetURL(_ path: String) -> URL? {
    URL(string: "studentos://widget/\(path)")
}

/// Locked (Pro-gated) placeholder. The app re-checks entitlement on tap.
struct LockedWidgetView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(StudentOSWidgetConfig.ink)
            Text("PRO · Tap to explore")
                .font(.caption)
                .foregroundColor(StudentOSWidgetConfig.sage)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(StudentOSWidgetConfig.forest)
        .cornerRadius(StudentOSWidgetConfig.cornerRadius)
        .widgetURL(widgetURL("premium?feature=premium.assistant.proactive"))
    }
}

struct LoggedOutWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Student OS")
                .font(.headline)
                .foregroundColor(StudentOSWidgetConfig.ink)
            Text("Sign in to view your day")
                .font(.caption)
                .foregroundColor(StudentOSWidgetConfig.sage)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(StudentOSWidgetConfig.forest)
        .cornerRadius(StudentOSWidgetConfig.cornerRadius)
        .widgetURL(widgetURL("home"))
    }
}
