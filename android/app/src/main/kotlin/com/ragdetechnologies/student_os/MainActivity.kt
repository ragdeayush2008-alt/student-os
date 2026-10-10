package com.ragdetechnologies.student_os

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ragdetechnologies.student_os/focus_guard"
    private var overlayView: View? = null
    private var floatingTimerView: View? = null
    private var floatingTimerText: TextView? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(true)
                }
                "hasUsageAccess" -> {
                    result.success(hasUsageAccess())
                }
                "openUsageAccessSettings" -> {
                    result.success(openUsageAccessSettings())
                }
                "hasOverlayPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "openOverlaySettings" -> {
                    result.success(openOverlaySettings())
                }
                "getForegroundApp" -> {
                    result.success(getForegroundApp())
                }
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                "bringAppToForeground" -> {
                    result.success(bringAppToForeground())
                }
                "showFloatingTimer" -> {
                    val elapsedTime = call.argument<String>("elapsedTime") ?: "00:00"
                    showFloatingTimer(elapsedTime)
                    result.success(true)
                }
                "updateFloatingTimer" -> {
                    val elapsedTime = call.argument<String>("elapsedTime") ?: "00:00"
                    updateFloatingTimer(elapsedTime)
                    result.success(true)
                }
                "hideFloatingTimer" -> {
                    hideFloatingTimer()
                    result.success(true)
                }
                "showFocusOverlay" -> {
                    val title = call.argument<String>("title") ?: "Focus Guard"
                    val objective = call.argument<String>("objective") ?: ""
                    val elapsedTime = call.argument<String>("elapsedTime") ?: ""
                    val remainingTime = call.argument<String>("remainingTime") ?: ""
                    val blockedAppName = call.argument<String>("blockedAppName") ?: "App"
                    val mode = call.argument<String>("mode") ?: "standard"
                    showFocusOverlay(title, objective, elapsedTime, remainingTime, blockedAppName, mode)
                    result.success(true)
                }
                "hideFocusOverlay" -> {
                    hideFocusOverlay()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ── Focus Background Music (bundled assets/audio: calm · ambient · energy) ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ragdetechnologies.student_os/focus_music"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val path = call.argument<String>("assetPath") ?: ""
                    result.success(playMusic(path))
                }
                "pause" -> {
                    result.success(pauseMusic())
                }
                "resume" -> {
                    result.success(resumeMusic())
                }
                "stop" -> {
                    result.success(stopMusic())
                }
                "dispose" -> {
                    result.success(disposeMusic())
                }
                "isPlaying" -> {
                    result.success(musicPlayer?.isPlaying == true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ── Prevent Screen Sleep (keep-awake via window flag while session runs) ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.ragdetechnologies.student_os/screen_sleep"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    result.success(setScreenSleep(true))
                }
                "disable" -> {
                    result.success(setScreenSleep(false))
                }
                "isEnabled" -> {
                    result.success(isScreenSleepEnabled())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    data = Uri.parse("package:$packageName")
                }
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                val fallback = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(fallback)
                true
            } catch (e2: Exception) {
                false
            }
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun openOverlaySettings(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                ).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                true
            } catch (e: Exception) {
                try {
                    val fallback = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(fallback)
                    true
                } catch (e2: Exception) {
                    false
                }
            }
        } else {
            true
        }
    }

    private fun getForegroundApp(): Map<String, Any?>? {
        if (!hasUsageAccess()) {
            return null
        }
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
        val endTime = System.currentTimeMillis()
        val beginTime = endTime - (1000 * 60)

        var fgPackage: String? = null
        var lastEventTime: Long = 0

        try {
            val usageEvents = usageStatsManager.queryEvents(beginTime, endTime)
            val event = UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                val eventType = event.eventType
                if (eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                    eventType == 1) {
                    if (event.timeStamp >= lastEventTime) {
                        fgPackage = event.packageName
                        lastEventTime = event.timeStamp
                    }
                }
            }
        } catch (e: Exception) {
            // fallback below
        }

        if (fgPackage == null) {
            try {
                val statsList = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    beginTime,
                    endTime
                )
                if (!statsList.isNullOrEmpty()) {
                    var mostRecent: UsageStats? = null
                    for (stats in statsList) {
                        if (mostRecent == null || stats.lastTimeUsed > mostRecent.lastTimeUsed) {
                            mostRecent = stats
                        }
                    }
                    if (mostRecent != null && mostRecent.lastTimeUsed > 0) {
                        fgPackage = mostRecent.packageName
                    }
                }
            } catch (e: Exception) {
                // ignore
            }
        }

        if (fgPackage == null) {
            return null
        }

        val isStudentOs = fgPackage == packageName
        val isLauncher = isLauncherPackage(fgPackage)
        val isSystemApp = isSystemPackage(fgPackage)
        val label = getPackageLabel(fgPackage)

        return mapOf(
            "packageName" to fgPackage,
            "label" to label,
            "isSystemApp" to isSystemApp,
            "isStudentOs" to isStudentOs,
            "isLauncher" to isLauncher
        )
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val appsList = mutableListOf<Map<String, Any?>>()
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(mainIntent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(mainIntent, 0)
        }

        val seenPackages = HashSet<String>()
        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            if (pkg == packageName || seenPackages.contains(pkg)) continue
            seenPackages.add(pkg)

            val label = info.loadLabel(pm).toString()
            val isSystem = (info.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            appsList.add(mapOf(
                "packageName" to pkg,
                "label" to label,
                "isSystemApp" to isSystem
            ))
        }

        return appsList.sortedBy { (it["label"] as? String)?.lowercase() ?: "" }
    }

    private fun bringAppToForeground(): Boolean {
        return try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun showFloatingTimer(elapsedTime: String) {
        if (!hasOverlayPermission()) {
            return
        }

        mainHandler.post {
            try {
                val windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return@post

                if (floatingTimerView != null) {
                    floatingTimerText?.text = "🛡 Student OS  $elapsedTime"
                    return@post
                }

                val layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    } else {
                        @Suppress("DEPRECATION")
                        WindowManager.LayoutParams.TYPE_PHONE
                    },
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.END
                    x = 32
                    y = 96
                }

                val pill = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    val pillBg = GradientDrawable().apply {
                        setColor(Color.parseColor("#E618181B"))
                        cornerRadius = 40f
                        setStroke(2, Color.parseColor("#40FFFFFF"))
                    }
                    background = pillBg
                    setPadding(28, 14, 28, 14)
                    setOnClickListener {
                        bringAppToForeground()
                    }
                }

                val textView = TextView(this).apply {
                    text = "🛡 Student OS  $elapsedTime"
                    setTextColor(Color.WHITE)
                    textSize = 13f
                    setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
                }
                floatingTimerText = textView
                pill.addView(textView)

                windowManager.addView(pill, layoutParams)
                floatingTimerView = pill
            } catch (e: Exception) {
                floatingTimerView = null
                floatingTimerText = null
            }
        }
    }

    private fun updateFloatingTimer(elapsedTime: String) {
        mainHandler.post {
            floatingTimerText?.text = "🛡 Student OS  $elapsedTime"
        }
    }

    private fun hideFloatingTimer() {
        mainHandler.post {
            try {
                if (floatingTimerView != null) {
                    val windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
                    windowManager?.removeView(floatingTimerView)
                    floatingTimerView = null
                    floatingTimerText = null
                }
            } catch (e: Exception) {
                floatingTimerView = null
                floatingTimerText = null
            }
        }
    }

    private fun showFocusOverlay(
        title: String,
        objective: String,
        elapsedTime: String,
        remainingTime: String,
        blockedAppName: String,
        mode: String
    ) {
        if (!hasOverlayPermission()) {
            bringAppToForeground()
            return
        }

        mainHandler.post {
            try {
                val windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return@post

                if (overlayView != null) {
                    try {
                        windowManager.removeView(overlayView)
                    } catch (e: Exception) {
                        // ignore
                    }
                    overlayView = null
                }

                val layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    } else {
                        @Suppress("DEPRECATION")
                        WindowManager.LayoutParams.TYPE_PHONE
                    },
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                            WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.CENTER
                }

                val root = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    setBackgroundColor(Color.parseColor("#F509090B"))
                    setPadding(48, 48, 48, 48)
                }

                val card = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER_HORIZONTAL
                    val cardBg = GradientDrawable().apply {
                        setColor(Color.parseColor("#18181B"))
                        cornerRadius = 28f
                        setStroke(2, Color.parseColor("#27272A"))
                    }
                    background = cardBg
                    setPadding(48, 48, 48, 48)
                }

                val badgeView = TextView(this).apply {
                    text = "🛡 STUDENT OS · FOCUS GUARD"
                    setTextColor(Color.parseColor("#A1A1AA"))
                    textSize = 11f
                    setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
                    gravity = Gravity.CENTER
                    setPadding(0, 0, 0, 14)
                }
                card.addView(badgeView)

                val titleView = TextView(this).apply {
                    text = "STAY IN FOCUS"
                    setTextColor(Color.WHITE)
                    textSize = 22f
                    setTypeface(Typeface.create("sans-serif", Typeface.BOLD))
                    gravity = Gravity.CENTER
                    setPadding(0, 0, 0, 8)
                }
                card.addView(titleView)

                val modeMessage = when (mode.lowercase()) {
                    "gentle" -> "Take a breath. Your session is still running."
                    "strict" -> "Focus mode is locked until your session ends."
                    else -> "Stay focused. This session isn't finished yet."
                }

                val descView = TextView(this).apply {
                    text = if (objective.isNotEmpty()) "$modeMessage\n$objective" else modeMessage
                    setTextColor(Color.parseColor("#D4D4D8"))
                    textSize = 14f
                    gravity = Gravity.CENTER
                    setPadding(0, 0, 0, 22)
                }
                card.addView(descView)

                if (elapsedTime.isNotEmpty() || remainingTime.isNotEmpty()) {
                    val timeStatsLayout = LinearLayout(this).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER
                        setPadding(0, 0, 0, 28)
                    }

                    if (elapsedTime.isNotEmpty()) {
                        val elapsedLayout = LinearLayout(this).apply {
                            orientation = LinearLayout.VERTICAL
                            gravity = Gravity.CENTER
                            setPadding(16, 0, 16, 0)
                        }
                        val elLabel = TextView(this).apply {
                            text = "ELAPSED"
                            setTextColor(Color.parseColor("#71717A"))
                            textSize = 11f
                            setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
                        }
                        val elVal = TextView(this).apply {
                            text = elapsedTime
                            setTextColor(Color.WHITE)
                            textSize = 20f
                            setTypeface(Typeface.create("sans-serif", Typeface.BOLD))
                        }
                        elapsedLayout.addView(elLabel)
                        elapsedLayout.addView(elVal)
                        timeStatsLayout.addView(elapsedLayout)
                    }

                    if (remainingTime.isNotEmpty()) {
                        val remLayout = LinearLayout(this).apply {
                            orientation = LinearLayout.VERTICAL
                            gravity = Gravity.CENTER
                            setPadding(16, 0, 16, 0)
                        }
                        val remLabel = TextView(this).apply {
                            text = "REMAINING"
                            setTextColor(Color.parseColor("#71717A"))
                            textSize = 11f
                            setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
                        }
                        val remVal = TextView(this).apply {
                            text = remainingTime
                            setTextColor(Color.WHITE)
                            textSize = 20f
                            setTypeface(Typeface.create("sans-serif", Typeface.BOLD))
                        }
                        remLayout.addView(remLabel)
                        remLayout.addView(remVal)
                        timeStatsLayout.addView(remLayout)
                    }

                    card.addView(timeStatsLayout)
                }

                val returnButton = Button(this).apply {
                    text = "Return to Focus"
                    setTextColor(Color.BLACK)
                    textSize = 15f
                    setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
                    val btnBg = GradientDrawable().apply {
                        setColor(Color.WHITE)
                        cornerRadius = 22f
                    }
                    background = btnBg
                    setPadding(36, 16, 36, 16)
                    setOnClickListener {
                        hideFocusOverlay()
                        bringAppToForeground()
                    }
                }
                card.addView(returnButton)

                root.addView(card)
                windowManager.addView(root, layoutParams)
                overlayView = root
            } catch (e: Exception) {
                bringAppToForeground()
            }
        }
    }

    private fun hideFocusOverlay() {
        mainHandler.post {
            try {
                if (overlayView != null) {
                    val windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
                    windowManager?.removeView(overlayView)
                    overlayView = null
                }
            } catch (e: Exception) {
                overlayView = null
            }
        }
    }

    private fun isLauncherPackage(pkg: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
            }
            val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            resolveInfo?.activityInfo?.packageName == pkg
        } catch (e: Exception) {
            false
        }
    }

    private fun isSystemPackage(pkg: String): Boolean {
        return try {
            val appInfo = packageManager.getApplicationInfo(pkg, 0)
            (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (e: Exception) {
            false
        }
    }

    private fun getPackageLabel(pkg: String): String? {
        return try {
            val appInfo = packageManager.getApplicationInfo(pkg, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            null
        }
    }

    // ── Focus Background Music helpers ────────────────────────────────────────
    private var musicPlayer: MediaPlayer? = null

    private fun playMusic(assetPath: String): Boolean {
        return try {
            musicPlayer?.release()
            musicPlayer = null
            val afd = if (assetPath.isNotEmpty()) assets.openFd(assetPath.removePrefix("assets/")) else null
                ?: return false
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            player.isLooping = true
            player.prepare()
            player.start()
            musicPlayer = player
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun pauseMusic(): Boolean {
        return try {
            val p = musicPlayer ?: return false
            if (p.isPlaying) p.pause()
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun resumeMusic(): Boolean {
        return try {
            val p = musicPlayer ?: return false
            p.start()
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun stopMusic(): Boolean {
        return try {
            val p = musicPlayer ?: return false
            if (p.isPlaying) p.stop()
            p.reset()
            p.release()
            musicPlayer = null
            true
        } catch (_: Exception) {
            musicPlayer = null
            false
        }
    }

    private fun disposeMusic(): Boolean {
        return try {
            musicPlayer?.release()
            musicPlayer = null
            true
        } catch (_: Exception) {
            musicPlayer = null
            false
        }
    }

    // ── Prevent Screen Sleep helpers ──────────────────────────────────────────
    private var screenSleepPrevented = false

    @Suppress("DEPRECATION")
    private fun setScreenSleep(prevent: Boolean): Boolean {
        return try {
            runOnUiThread {
                if (prevent) {
                    window?.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
            }
            screenSleepPrevented = prevent
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun isScreenSleepEnabled(): Boolean = screenSleepPrevented

    override fun onDestroy() {
        hideFloatingTimer()
        hideFocusOverlay()
        super.onDestroy()
    }
}
