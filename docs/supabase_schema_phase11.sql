-- ====================================================================
-- STUDENT OS — PHASE 11 PRODUCTION SUPABASE SCHEMA & RLS POLICIES
-- ====================================================================
-- This schema establishes the relational tables, foreign keys, indexes,
-- triggers, and Row Level Security (RLS) policies for multi-device sync,
-- local-first mutations, and server-authoritative XP and entitlements.
-- ====================================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- --------------------------------------------------------------------
-- 1. STUDENT PROFILES
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT '',
    major TEXT NOT NULL DEFAULT '',
    university TEXT NOT NULL DEFAULT '',
    term_start TIMESTAMPTZ,
    term_end TIMESTAMPTZ,
    important_date TIMESTAMPTZ,
    important_date_label TEXT NOT NULL DEFAULT '',
    is_onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 2. SUBJECTS
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subjects (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL DEFAULT '',
    color_value BIGINT NOT NULL DEFAULT 4282479830, -- 0xFF2563EB default
    icon_name TEXT NOT NULL DEFAULT 'book',
    credits INTEGER NOT NULL DEFAULT 3,
    professor TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 3. EXAMS
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.exams (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subject_id TEXT REFERENCES public.subjects(id) ON DELETE SET NULL,
    subject_name TEXT NOT NULL DEFAULT '',
    exam_date TIMESTAMPTZ,
    location TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL DEFAULT 'midterm',
    status TEXT NOT NULL DEFAULT 'scheduled',
    weight_percentage DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    target_score DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    achieved_score DOUBLE PRECISION,
    syllabus_items JSONB NOT NULL DEFAULT '[]'::jsonb,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 4. TASKS
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tasks (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    priority TEXT NOT NULL DEFAULT 'medium',
    due_date TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'todo',
    subject_id TEXT REFERENCES public.subjects(id) ON DELETE SET NULL,
    exam_id TEXT REFERENCES public.exams(id) ON DELETE SET NULL,
    estimated_minutes INTEGER NOT NULL DEFAULT 25,
    actual_minutes INTEGER NOT NULL DEFAULT 0,
    subtasks JSONB NOT NULL DEFAULT '[]'::jsonb,
    recurrence_rule TEXT,
    is_inbox BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 5. STUDY SESSIONS
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.study_sessions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject TEXT NOT NULL DEFAULT 'General',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT TRUE,
    task_id TEXT REFERENCES public.tasks(id) ON DELETE SET NULL,
    notes TEXT NOT NULL DEFAULT '',
    rating INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 6. ACADEMIC RESOURCES
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.academic_resources (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL DEFAULT 'note',
    url TEXT,
    content TEXT,
    file_path TEXT,
    subject_id TEXT REFERENCES public.subjects(id) ON DELETE SET NULL,
    exam_id TEXT REFERENCES public.exams(id) ON DELETE SET NULL,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_accessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 7. USER GOALS & PREFERENCES
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    default_focus_minutes INTEGER NOT NULL DEFAULT 25,
    week_start_day TEXT NOT NULL DEFAULT 'monday',
    study_reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    study_reminder_hour INTEGER NOT NULL DEFAULT 18,
    study_reminder_minute INTEGER NOT NULL DEFAULT 0,
    planning_reminder_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    planning_reminder_hour INTEGER NOT NULL DEFAULT 8,
    planning_reminder_minute INTEGER NOT NULL DEFAULT 0,
    daily_study_target_minutes INTEGER NOT NULL DEFAULT 120,
    weekly_study_target_minutes INTEGER NOT NULL DEFAULT 600,
    weekly_task_target INTEGER NOT NULL DEFAULT 10,
    personal_goal TEXT NOT NULL DEFAULT '',
    active_theme_variant TEXT NOT NULL DEFAULT 'default',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 8. XP EVENTS (IMMUTABLE PROGRESSION LEDGER)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.xp_events (
    id TEXT PRIMARY KEY, -- Deterministic UUID / unique action key
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    amount INTEGER NOT NULL CHECK (amount > 0),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT NOT NULL DEFAULT '',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 9. REWARD TRANSACTIONS (IMMUTABLE AUDIT LOG)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reward_transactions (
    id TEXT PRIMARY KEY, -- UUID
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reward_id TEXT NOT NULL,
    reward_title TEXT NOT NULL,
    xp_spent INTEGER NOT NULL CHECK (xp_spent >= 0),
    redeemed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'completed',
    discount_applied DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- 10. STUDENT ENTITLEMENTS (SERVER-AUTHORITATIVE PRIVILEGES)
-- --------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.student_entitlements (
    id TEXT PRIMARY KEY, -- UUID
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reward_id TEXT NOT NULL,
    type TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'xp_reward',
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- --------------------------------------------------------------------
-- INDEXES FOR FAST SYNC AND USER-SCOPED QUERIES
-- --------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_subjects_user_id ON public.subjects(user_id);
CREATE INDEX IF NOT EXISTS idx_exams_user_id ON public.exams(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_updated_at ON public.tasks(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON public.study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_academic_resources_user_id ON public.academic_resources(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_events_user_id ON public.xp_events(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_reward_transactions_user_id ON public.reward_transactions(user_id, redeemed_at);
CREATE INDEX IF NOT EXISTS idx_student_entitlements_user_id ON public.student_entitlements(user_id, is_active);

-- --------------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
-- --------------------------------------------------------------------
-- Enable RLS on all public tables
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_entitlements ENABLE ROW LEVEL SECURITY;

-- 1. Student Profiles RLS
CREATE POLICY "Users can view their own profile"
    ON public.student_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can insert/update their own profile"
    ON public.student_profiles FOR ALL
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 2. Subjects RLS
CREATE POLICY "Users can access their own subjects"
    ON public.subjects FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 3. Exams RLS
CREATE POLICY "Users can access their own exams"
    ON public.exams FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4. Tasks RLS
CREATE POLICY "Users can access their own tasks"
    ON public.tasks FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 5. Study Sessions RLS
CREATE POLICY "Users can access their own study sessions"
    ON public.study_sessions FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 6. Academic Resources RLS
CREATE POLICY "Users can access their own resources"
    ON public.academic_resources FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 7. User Preferences RLS
CREATE POLICY "Users can access their own preferences"
    ON public.user_preferences FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 8. XP Events RLS (Append-only by user, select by user)
CREATE POLICY "Users can view their own XP events"
    ON public.xp_events FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can record valid XP events"
    ON public.xp_events FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 9. Reward Transactions RLS (Audit log: select + insert only)
CREATE POLICY "Users can view their own reward transactions"
    ON public.reward_transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own reward transactions"
    ON public.reward_transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 10. Student Entitlements RLS
CREATE POLICY "Users can view their own entitlements"
    ON public.student_entitlements FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own entitlements"
    ON public.student_entitlements FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
