# Student OS — User System

> This document defines everything related to student accounts, onboarding, profiles, preferences, settings, personalization, privacy, notifications, appearance, data management, account actions and the user lifecycle. It is a **blueprint only** — **nothing here is implemented.**

## Overview

The user system is the foundation of the student experience. It handles who a student is, how they get started, how they customize the OS, and how they manage their account and data over time.

## Accounts & Authentication

### Account Model
- Each student has a single account tied to an authentication identity.
- Account identity is provided by the auth backend (email, and social/OAuth where available) — see [DATA_AND_SERVICES.md](./DATA_AND_SERVICES.md). The app never stores raw passwords.

### Authentication Methods (future)
- Email/password registration and login.
- Social / OAuth sign-in where free-tier supported.
- Session persistence across app launches.

### Roles
- **Student** — the primary role of the platform.
- **Admin** — platform administrator (see [ADMIN_SYSTEM.md](./ADMIN_SYSTEM.md)).
- Role is separate from profile and is not user-editable.

## Onboarding

### Purpose
Guide a new student from account creation to their first valuable action quickly and without friction.

### Onboarding Steps (future)
1. **Welcome** — introduce Student OS and its value.
2. **Identity basics** — name, educational path context.
3. **Path selection** — choose the general study context (school, national/international exam, vocational, self-directed) — exam-agnostic; nothing is locked in.
4. **Preference capture** — language, appearance, notification defaults.
5. **First setup** — create a first goal, plan item, or milestone so the student sees value immediately.

### Principles
- Keep onboarding short and skippable.
- Default to sensible values so students can proceed without answering everything.
- Never require exam-specific lock-in.

## Profiles

### Student Profile (future)
- Basic identity: display name, avatar, optional profile details.
- Educational path context (adjustable at any time — not permanent).
- Optional bio/goals shown only where the student chooses.

### Profile Scoping
- Profile data is controlled by the student.
- Sharing (e.g., within community features) is always opt-in and reversible.

## Preferences & Personalization

### Preferences (future)
- Educational path and area of focus.
- Language and region settings.
- Home/locked defaults (which modules show first).
- Notification preferences (see below).

### Personalization (future)
- Personalized dashboard layout and ordering.
- Adaptive suggestions based on the student's own data (no third-party tracking).
- Balanced so personalization never locks a student into one path.

## App Settings

The settings area organizes all account and device configuration:

### Notification Preferences (future)
- Per-channel toggles (milestones, planning reminders, admin announcements, community).
- Quiet hours / schedules.
- Delivery method (in-app push/local; free-tier backend notification where available).

### Appearance Settings (future)
- Theme (light/dark/system).
- Accent color and customizations.
- Density and layout preferences.

### Privacy Controls (future)
- Data visibility and sharing toggles.
- Control over anonymized/summary analytics contribution (default off).
- Community sharing controls.

### Data Management (future)
- View / export own data (portability).
- Backup / restore options.
- Clear local cache.
- Delete account / data removal.

## Account Actions & Lifecycle

### Account Lifecycle States
1. **Anonymous / not signed in** — read-only or limited use (where sensible).
2. **Registered** — standard active student account.
3. **Active** — normal usage, syncing with backend.
4. **Deactivated / suspended** — admin-driven (see [ADMIN_SYSTEM.md](./ADMIN_SYSTEM.md)).
5. **Deleted / deprovisioned** — account and data removal per privacy commitments.

### Account Actions (future)
- Update profile and preferences.
- Change password (backend-managed).
- Sign out / sign in on multiple devices.
- Export data.
- Permanently delete account with confirmation.

### Lifecycle Rules
- Students always own their data and can request deletion.
- Lifecycle transitions are logged for audit (see [ADMIN_SYSTEM.md](./ADMIN_SYSTEM.md)).
- Account state drives what capabilities are available.

## Non-Goals (for now)
- No paid accounts, tiers, or premium personalization.
- No third-party behavioral tracking or ad-based profiling.
- No implementation here — see the implementation phases in [ROADMAP.md](./ROADMAP.md).
