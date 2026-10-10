package com.ragdetechnologies.student_os

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONObject

/**
 * Student OS home-screen widgets (Tier 1).
 *
 * Pure projection: every provider reads ONE JSON snapshot written by the
 * Flutter WidgetDataService ("HomeWidgetPreferences" →
 * "student_os_widget_snapshot") and renders it with RemoteViews. No
 * business logic, no network, no secrets live here.
 *
 * Taps deep-link back into the app (`studentos://widget/...`) through the
 * home_widget launch mechanism, so Flutter routes them with auth,
 * user-isolation, and entitlement checks applied.
 */
abstract class StudentOsWidgetProvider : AppWidgetProvider() {
    abstract val layoutRes: Int

    /** Bind a valid, logged-in snapshot. */
    abstract fun bind(
        context: Context,
        views: RemoteViews,
        snap: JSONObject,
        widgetId: Int,
    )

    /** Deep link for a valid snapshot (may depend on its content). */
    abstract fun tapUri(snap: JSONObject): String

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            render(context, appWidgetManager, widgetId)
        }
    }

    fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, layoutRes)
        val snap = readSnapshot(context)
        if (snap == null || snap.optBoolean("loggedOut", false) ||
            snap.optString("userId", "").isEmpty()
        ) {
            bindLoggedOut(context, views, widgetId)
        } else {
            try {
                bind(context, views, snap, widgetId)
                setTap(context, views, R.id.widget_root, tapUri(snap), widgetId)
            } catch (_: Exception) {
                bindLoggedOut(context, views, widgetId)
            }
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun bindLoggedOut(context: Context, views: RemoteViews, widgetId: Int) {
        setText(views, R.id.widget_title, "Student OS")
        setText(views, R.id.widget_subtitle, "Sign in to view your day")
        setTap(context, views, R.id.widget_root, "studentos://widget/home", widgetId)
    }

    protected fun readSnapshot(context: Context): JSONObject? {
        return try {
            val prefs = context.getSharedPreferences(
                "HomeWidgetPreferences", Context.MODE_PRIVATE,
            )
            val raw = prefs.getString("student_os_widget_snapshot", null)
                ?: return null
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    protected fun setTap(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        uri: String,
        widgetId: Int,
    ) {
        try {
            val pending = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(uri),
            )
            views.setOnClickPendingIntent(viewId, pending)
        } catch (_: Exception) {
        }
    }

    protected fun setText(views: RemoteViews, viewId: Int, text: String?) {
        try {
            views.setTextViewText(viewId, text ?: "")
        } catch (_: Exception) {
        }
    }

    protected fun optStr(obj: JSONObject?, key: String): String =
        try {
            obj?.optString(key, "") ?: ""
        } catch (_: Exception) {
            ""
        }

    protected fun isLocked(snap: JSONObject, widgetId: String): Boolean {
        return try {
            val arr = snap.optJSONArray("lockedWidgetIds") ?: return false
            (0 until arr.length()).any { arr.optString(it) == widgetId }
        } catch (_: Exception) {
            false
        }
    }
}

// ─── Tier 1 providers ────────────────────────────────────────────────

class StudentOsExamCountdownWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_exam_countdown

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        val exam = snap.optJSONObject("nextExam")
        if (exam == null || exam.optString("id", "").isEmpty()) {
            setText(views, R.id.widget_title, "No upcoming exams")
            setText(views, R.id.widget_subtitle, "Tap to add your exam")
            setTap(context, views, R.id.widget_root, "studentos://widget/add-exam", widgetId)
            return
        }
        setText(views, R.id.widget_title, exam.optString("title", "Exam"))
        val days = if (exam.isNull("daysLeft")) null else exam.optInt("daysLeft", -1)
        setText(
            views, R.id.widget_subtitle,
            when (days) {
                null -> optStr(exam, "dateLabel")
                0 -> "Today"
                1 -> "Tomorrow · ${optStr(exam, "dateLabel")}"
                else -> "$days DAYS · ${optStr(exam, "dateLabel")}"
            },
        )
    }

    override fun tapUri(snap: JSONObject): String {
        val id = snap.optJSONObject("nextExam")?.optString("id", "")
        return if (id.isNullOrEmpty()) {
            "studentos://widget/exam"
        } else {
            "studentos://widget/exam?id=$id"
        }
    }
}

class StudentOsTasksWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_tasks

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        val tasks = snap.optJSONObject("todayTasks")
        if (tasks == null) {
            setText(views, R.id.widget_title, "You're all clear")
            setText(views, R.id.widget_subtitle, "No tasks today")
            return
        }
        val remaining = tasks.optInt("remaining", 0)
        val done = tasks.optInt("completed", 0)
        setText(
            views, R.id.widget_title,
            if (remaining == 0) "You're all clear" else "$remaining task${if (remaining == 1) "" else "s"} left",
        )
        val top = tasks.optString("topTitle", "")
        setText(
            views, R.id.widget_subtitle,
            if (top.isNotEmpty() && remaining > 0) "Next: $top · ✓ $done done" else "✓ $done done",
        )
    }

    override fun tapUri(snap: JSONObject) = "studentos://widget/tasks"
}

class StudentOsPlanWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_plan

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        val plan = snap.optJSONObject("todayPlan")
        val items = plan?.optJSONArray("items")
        if (items == null || items.length() == 0) {
            setText(views, R.id.widget_title, "No plan yet today")
            setText(views, R.id.widget_subtitle, "Tap to plan your day")
            setTap(context, views, R.id.widget_root, "studentos://widget/planning", widgetId)
            return
        }
        val lines = (0 until minOf(items.length(), 3)).joinToString("\n") { i ->
            val item = items.optJSONObject(i)
            "${item.optString("time", "")} ${item.optString("title", "")}".trim()
        }
        setText(views, R.id.widget_title, lines.ifEmpty { "Today's plan" })
        val next = plan.optString("nextTitle", "")
        setText(
            views, R.id.widget_subtitle,
            if (next.isNotEmpty()) "Next: $next" else "",
        )
    }

    override fun tapUri(snap: JSONObject) = "studentos://widget/planning"
}

class StudentOsFocusWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_focus

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        val focus = snap.optJSONObject("focus")
        val active = focus?.optBoolean("hasActive", false) == true
        if (active) {
            setText(views, R.id.widget_title, focus.optString("title", "Focusing"))
            setText(views, R.id.widget_subtitle, focus.optString("remainingLabel", ""))
        } else {
            setText(views, R.id.widget_title, "Ready to focus?")
            setText(views, R.id.widget_subtitle, "Tap a duration to start")
        }
        // Quick durations always available; CUSTOM opens the app flow.
        setTap(context, views, R.id.widget_focus_15, "studentos://widget/custom-focus?minutes=15", widgetId)
        setTap(context, views, R.id.widget_focus_25, "studentos://widget/custom-focus?minutes=25", widgetId)
        setTap(context, views, R.id.widget_focus_45, "studentos://widget/custom-focus?minutes=45", widgetId)
    }

    override fun tapUri(snap: JSONObject): String {
        val active =
            snap.optJSONObject("focus")?.optBoolean("hasActive", false) == true
        return if (active) "studentos://widget/focus" else "studentos://widget/custom-focus"
    }
}

class StudentOsAssistantWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_assistant

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        val assistant = snap.optJSONObject("assistant")
        if (assistant == null || assistant.optString("headline", "").isEmpty()) {
            setText(views, R.id.widget_title, "What should I do now?")
            setText(views, R.id.widget_subtitle, "Open Student OS Assistant")
            return
        }
        setText(views, R.id.widget_title, assistant.optString("headline", ""))
        val reason = assistant.optString("reason", "")
        val minutes = if (assistant.isNull("minutes")) "" else " · ${assistant.optInt("minutes", 0)} min"
        setText(views, R.id.widget_subtitle, "$reason$minutes".trim())
    }

    override fun tapUri(snap: JSONObject) = "studentos://widget/assistant"
}

class StudentOsSleepWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_sleep

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        val sleep = snap.optJSONObject("sleep")
        if (sleep == null) {
            setText(views, R.id.widget_title, "Set your sleep schedule")
            setText(views, R.id.widget_subtitle, "Tap to open sleep")
            return
        }
        setText(
            views, R.id.widget_title,
            "${sleep.optString("bedtimeLabel", "")} → ${sleep.optString("wakeLabel", "")}",
        )
        setText(
            views, R.id.widget_subtitle,
            "${sleep.optString("durationLabel", "")} planned",
        )
    }

    override fun tapUri(snap: JSONObject) = "studentos://widget/sleep"
}

class StudentOsStudyWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_study

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        val study = snap.optJSONObject("todayStudy")
        if (study == null) {
            setText(views, R.id.widget_title, "No study yet today")
            setText(views, R.id.widget_subtitle, "Tap to view progress")
            return
        }
        val planned = study.optInt("plannedMinutes", 0)
        val done = study.optInt("completedMinutes", 0)
        val left = (planned - done).coerceAtLeast(0)
        setText(views, R.id.widget_title, "Today's study")
        setText(
            views, R.id.widget_subtitle,
            "${planned}m planned · ${done}m done · ${left}m left",
        )
    }

    override fun tapUri(snap: JSONObject) = "studentos://widget/progress"
}

class StudentOsBriefWidget : StudentOsWidgetProvider() {
    override val layoutRes = R.layout.widget_brief

    override fun bind(context: Context, views: RemoteViews, snap: JSONObject, widgetId: Int) {
        // Pro-locked briefs render locked (snapshot carries the lock list).
        if (isLocked(snap, "daily_brief")) {
            setText(views, R.id.widget_title, "Daily Brief · PRO")
            setText(views, R.id.widget_subtitle, "Tap to explore Student OS Pro")
            setTap(context, views, R.id.widget_root, "studentos://widget/premium?feature=premium.assistant.proactive", widgetId)
            return
        }
        val brief = snap.optJSONObject("brief")
        if (brief == null) {
            setText(views, R.id.widget_title, "Open Student OS Assistant")
            setText(views, R.id.widget_subtitle, "Your day, organized with you")
            return
        }
        setText(views, R.id.widget_title, brief.optString("greeting", "Today"))
        val lines = brief.optJSONArray("lines")
        val text = if (lines == null) "" else (0 until minOf(lines.length(), 3)).joinToString("\n") {
            lines.optString(it, "")
        }
        setText(views, R.id.widget_subtitle, text)
    }

    override fun tapUri(snap: JSONObject): String {
        return if (isLocked(snap, "daily_brief")) {
            "studentos://widget/premium?feature=premium.assistant.proactive"
        } else {
            "studentos://widget/assistant"
        }
    }
}
