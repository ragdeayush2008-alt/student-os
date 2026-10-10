# Phase 5 — Foundational Student Experience

## What Phase 5 Implements

Transforms Student OS from an authenticated shell into a genuinely useful foundational student workspace with real data, onboarding, and task management.

### Student Profile & Academic Context
- Foundational `StudentProfile` model with display name, education level, institution, course, year, goals, and academic focus.
- `EducationLevel`, `StudentGoal`, `AcademicFocus` enums for structured academic context.
- Profile displayed in Profile screen with real data.
- Profile editable via onboarding restart.

### Onboarding
- Premium 5-step guided onboarding: Welcome → Studies → Goals → Focus → Ready.
- Animated progress dots, step transitions, back/skip navigation.
- Premium selectable cards for goals and focus areas (not generic checkboxes).
- Important date picker for upcoming milestones.
- Summary step before completion.
- Persists after each step; restores if app closes.
- Shows for authenticated users with incomplete onboarding.

### Task Management
- Real `StudentTask` model with title, description, priority, due date, scheduled date, category, status.
- 4 priority levels: Low, Medium, High, Critical — visually distinct.
- Task statuses: Active, Completed.
- Premium bottom sheet for creation and editing.
- Swipe-to-delete with confirmation dialog.
- Task grouping: Overdue → Today → Upcoming → Later → Completed.
- Empty state with CTA.
- Completion tracking, streak calculation.

### Personalized Home Dashboard
- Greeting uses real student name from profile.
- Daily overview driven by actual task data (completed/total, progress).
- Today's priorities showing overdue and today's tasks.
- Upcoming section showing next few tasks.
- Momentum section with real completion count and streak.
- Quick actions linked to real screens (tasks, plan, study, progress).

### Persistence
- Local persistence via `shared_preferences` (JSON serialization).
- User-scoped storage: different accounts do not share data on same device.
- `StorageService` singleton handles all local persistence.
- Graceful fallback when persistence fails.

### Supabase / Cloud Persistence
- Optional cloud sync for profile and tasks when authenticated and Supabase configured.
- Cloud failures are silent — local data remains authoritative.
- SQL setup documented separately (tables may not exist yet).
- App fully functional without Supabase database tables.

## Data Models

### StudentProfile
```
id, displayName, email, educationLevel, institution, course,
currentYear, goals[], academicFocus, importantDate,
importantDateLabel, onboardingState, createdAt, updatedAt
```

### StudentTask
```
id, title, description, priority, status, dueDate, scheduledDate,
category, createdAt, completedAt, sortOrder
```

## Architecture

### Services
- `StorageService` — local persistence via shared_preferences.
- `StudentService` — profile management, onboarding state, user scoping.
- `TaskController` — task CRUD, filtering, streak calculation.

### State Management
- ChangeNotifier + InheritedNotifier (consistent with existing patterns).
- No new state-management frameworks added.

## What Is NOT Implemented
- Full calendar system
- Complex timetable engine
- AI features
- Flashcards / Pomodoro
- Social/community features
- Rewards economy
- Notifications infrastructure
- Edge Functions
- Storage uploads
- Complex repository abstraction

## Supabase Setup (Optional Cloud Sync)

If cloud persistence is desired, create these tables in your Supabase project:

```sql
-- Student profiles
CREATE TABLE student_profiles (
  id TEXT PRIMARY KEY,
  display_name TEXT DEFAULT '',
  email TEXT DEFAULT '',
  education_level TEXT,
  institution TEXT DEFAULT '',
  course TEXT DEFAULT '',
  current_year TEXT DEFAULT '',
  goals JSONB DEFAULT '[]',
  academic_focus TEXT,
  important_date TIMESTAMPTZ,
  important_date_label TEXT DEFAULT '',
  onboarding_state TEXT DEFAULT 'incomplete',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES auth.users(id),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'active',
  due_date TIMESTAMPTZ,
  scheduled_date TIMESTAMPTZ,
  category TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  sort_order INTEGER DEFAULT 0
);

-- Enable RLS
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own profile"
  ON student_profiles FOR ALL
  USING (auth.uid() = id);

CREATE POLICY "Users can manage their own tasks"
  ON tasks FOR ALL
  USING (auth.uid() = user_id);
```

The app works fully without these tables — local persistence handles everything.
