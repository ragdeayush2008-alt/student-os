# WIRING the StudentOSWidgets extension (iOS) — NOT YET DONE

The Swift sources in this directory (`WidgetSnapshot.swift`,
`WidgetShared.swift`, `StudentOSWidgets.swift`) are complete for the Tier 1
family but are **not part of any Xcode target**, so they neither compile nor
ship today. This is deliberate: adding an app extension requires an Apple
Developer Team, an App Group capability, and project changes that cannot be
verified in this environment.

## To wire the extension (requires a Mac with Xcode + paid team)

1. Xcode → Runner.xcodeproj → + Target → Widget Extension.
   - Product name: `StudentOSWidgets`
   - Bundle id: `com.ragdetechnologies.studentOs.StudentOSWidgets`
   - Deployment target: ≥ 16.0 (matches app floor of 15.0+ safely)
   - Swift, SwiftUI + WidgetKit (Xcode links both automatically).
2. Add the three `.swift` files in this directory to the new target's
   *Compile Sources* (remove them from nowhere else — they are in no
   target today).
3. Capabilities (both Runner + extension targets):
   - App Groups → `group.com.ragdetechnologies.studentos.widgets`
     (must match `WidgetDataService.iosAppGroupId` in Dart).
4. The extension's `*.entitlements` must include the same App Group.
5. The `studentos://` URL scheme is already registered in
   `ios/Runner/Info.plist` (`CFBundleURLTypes`), so `widgetURL(...)` taps
   open the app; `WidgetLinkHandler` (Dart) routes them with auth,
   user-isolation, and entitlement checks.
6. Build the `StudentOSWidgets` scheme, then run on a device/simulator:
   long-press home screen → + → Student OS → add each widget.

## Shared-storage contract (both platforms)

- Group defaults key: `student_os_widget_snapshot` (JSON string).
- Written by Dart `WidgetDataService`; read-only for native code.
- Logout writes the logged-out empty snapshot; native renders the
  signed-out state and never shows prior-user data.

## Why Android shipped first

Android widgets need no paid team, no new signing, and no Xcode target —
receivers + layouts compile into the existing APK (verified by build).
iOS flips to implemented the moment the target above exists; no Dart or
snapshot changes are needed.
