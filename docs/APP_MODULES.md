# Student OS — Application Modules

> This document defines the complete high-level modular structure for Student OS. It is a **blueprint** showing how a scalable, all-in-one student operating system will be organized into logical modules. **No modules are implemented yet.**

## Purpose & Strategy

Student OS is designed to eventually host **500+ features**. To keep this manageable, features are **not** listed as one flat, endless list. Instead, they are organized into a small set of high-level **domains**, each built from **modules**, each containing individual **features**.

Hierarchy used throughout this document:

```
Domain (top-level area)
  └── Module (logical unit of functionality)
        └── Feature (a single capability)
```

This grouping strategy:

- Keeps navigation simple by exposing only domains (and their top modules) to the user.
- Keeps code boundaries clean (one module per concern).
- Allows new features to be added by extending an existing module without global changes.
- Lets future features attach to the right home rather than being randomly scattered.

## Modular Navigation & Feature Grouping

### Navigation Strategy
- The app uses a small, stable set of **primary navigation destinations** derived from core domains (e.g., Home/Dashboard, Plan, Study, Prepare, Milestones, More).
- **Secondary navigation** (settings, profile, admin, utilities) lives within a "More" / overflow area and via contextual entry points.
- Domains present only their top relevant modules at each level to avoid overwhelming the user; deeper features are reached progressively.

### Feature Grouping Rules
1. Group features by **purpose**, not by exam or syllabus.
2. A feature belongs to exactly **one** module (single home) unless it is genuinely cross-cutting, in which case it lives in the shared/core layer.
3. Shared/utility capabilities (theming, notifications, settings) live in core modules, not duplicated per feature.

## Domain & Module Map

The following domains organize the future feature set. Each domain is composed of modules; each module notes representative future features.

### 1. Home & Dashboard (`home` domain)
The personalized landing area tying all other domains together.

- **Dashboard module** — today overview, quick actions, status summary.
- **Daily Summary module** — daily agenda, reminders, continuity/streaks.
- **At-a-Glance module** — cross-domain widgets (upcoming milestones, pending plan items).

### 2. Planning (`planning` domain)
Long-term and short-term academic planning.

- **Timeline module** — academic calendars, term/semester planning.
- **Planner module** — daily/weekly/monthly planning, scheduling.
- **Goal Planning module** — long-term goal definition and breakdown.
- **Task & Scheduling module** — to-dos, priorities, recurring tasks.

### 3. Study Management (`study` domain)
Organizing study content and workflow.

- **Materials module** — organizing notes, subjects, topics, documents.
- **Curriculum/Track module** — mapping to curricula and study paths (exam-agnostic).
- **Note-taking module** — structured notes and annotations.
- **Revision module** — spaced review, revision scheduling.

### 4. Productivity (`productivity` domain)
Focus and daily efficiency.

- **Focus module** — focus sessions, timers (e.g., Pomodoro), deep work blocks.
- **Habits module** — daily habit tracking and streaks.
- **Time Tracking module** — time allocation and reports.
- **Workflow module** — inbox, capture, prioritization helpers.

### 5. Preparation (`preparation` domain)
Structured preparation across different exams and paths.

- **Mock Test module** — practice tests and mock exams (exam-agnostic templates).
- **Question Bank module** — practice questions, categorized sets.
- **Study Plan module** — preparation roadmaps and coverage tracking.
- **Performance module** — weak areas, accuracy, score trends.

### 6. Milestones & Achievement (`milestones` domain)
Tracking and celebrating progress.

- **Milestones module** — defining and tracking key achievements.
- **Progress Tracking module** — visual progress toward goals.
- **Reflection module** — journals, reviews, retrospectives.

### 7. Exams (`exams` domain)
General examination support without locking into one exam.

- **Exam Profiles module** — configurable exam types and formats.
- **Syllabus module** — syllabus organization per chosen path.
- **Exam Preparation module** — preparation coordination across exam-based features.

### 8. Academic Tools (`academic_tools` domain)
Day-to-day study utilities.

- **Calculator & Formula module** — academic formula/calculator tools.
- **Reference module** — quick reference tables, conversions.
- **Research/Utility module** — citation, bibliography, helpers.

### 9. Resources (`resources` domain)
Curated and personal study resources.

- **Resource Library module** — personal and shared study resources.
- **Bookmarks module** — saved links, references, media.
- **Content Discovery module** — finding useful study content.

### 10. Focus & Well-being (`wellbeing` domain)
Supporting sustainable study.

- **Focus Tools module** — breaks, mindfulness, concentration aids.
- **Wellness module** — balance reminders, stress awareness.

### 11. Social & Community (`community` domain)
Collaboration and motivation (optional, opt-in).

- **Study Circles module** — study groups and collaborative spaces.
- **Community module** — discussion areas, peer support (moderated).
- **Achievement Sharing module** — sharing milestones (non-intrusive).

### 12. Rewards & Gamification (`rewards` domain)
Motivation through achievement recognition.

- **Rewards module** — earned badges, points, recognition.
- **Gamification module** — streaks, levels, achievements (student-facing).
- **Incentive module** — earned incentives (functional, non-paid).

### 13. Personalization (`personalization` domain)
Making the OS feel personal.

- **Profile module** — student identity and educational path.
- **Appearance module** — themes, layouts, personalization.
- **Preference module** — user preferences and defaults.

### 14. Utilities (`utilities` domain)
Cross-cutting helper tools.

- **System Utilities module** — calculators, converters, quick tools.
- **Backup/Data module** — data export, backup management.

### 15. Account & Settings (`account` domain)
Shared user/device management (see [USER_SYSTEM.md](./USER_SYSTEM.md)).

- **Account module** — sign-in, profile, account actions.
- **Settings module** — app settings, notifications, appearance, privacy.
- **Notifications module** — notification preferences and delivery.

### 16. Core (`core` domain)
Not user-facing; shared foundations mentioned here for completeness.

- **Design System** — theming, components, navigation shell.
- **Networking/Data** — API client, local cache, state management.
- **Auth** — authentication primitives.

## Cross-Cutting & Shared Modules

Several capabilities are shared rather than owned by one feature domain:

- **Notifications** — used by planning, milestones, exams, and admin announcements alike.
- **Design System** — all domains render through shared components.
- **Navigation Shell** — hosts all primary and secondary destinations.
- **Data Access** — domains read/write through shared data services (see [DATA_AND_SERVICES.md](./DATA_AND_SERVICES.md)).
- **Admin/Configuration** — feature flags and configuration surfaced to domains (see [ADMIN_SYSTEM.md](./ADMIN_SYSTEM.md)).

## Where Future Features Go

When a new feature is proposed, it is assigned to the domain/module that best matches its purpose. If no existing module fits, a new module is added **within an existing domain**; a new domain is created only when a genuinely new high-level area emerges. This keeps 500+ features navigable and maintainable.
