# Student OS — Leaderboard Backend & RLS Specification

This document details the Supabase database schema, views, triggers, and Row-Level Security (RLS) policies required for the Leaderboard ecosystem.

> **Backend Environment Notice:**
> In the local Flutter application environment, leaderboard data is operated in offline-first mode using authoritative local XP ledgers and local-storage caching. The SQL below represents the required backend migration to enable multi-device remote leaderboard aggregation on Supabase.

---

## 1. Schema Design

### `leaderboard_entries` (Public Aggregates Table)

```sql
-- Create table for public leaderboard entries (aggregates only, no private data)
CREATE TABLE IF NOT EXISTS public.leaderboard_entries (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT 'Student',
    total_xp INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
    week_xp INTEGER NOT NULL DEFAULT 0 CHECK (week_xp >= 0),
    month_xp INTEGER NOT NULL DEFAULT 0 CHECK (month_xp >= 0),
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    streak INTEGER NOT NULL DEFAULT 0 CHECK (streak >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance indexes for period-specific ranking queries
CREATE INDEX IF NOT EXISTS idx_leaderboard_week_xp_desc 
ON public.leaderboard_entries (week_xp DESC, updated_at ASC);

CREATE INDEX IF NOT EXISTS idx_leaderboard_month_xp_desc 
ON public.leaderboard_entries (month_xp DESC, updated_at ASC);

CREATE INDEX IF NOT EXISTS idx_leaderboard_total_xp_desc 
ON public.leaderboard_entries (total_xp DESC, updated_at ASC);
```

---

## 2. Row-Level Security (RLS) Policies

```sql
-- Enable Row-Level Security
ALTER TABLE public.leaderboard_entries ENABLE ROW LEVEL SECURITY;

-- 1. Anyone authenticated can READ public leaderboard entries
CREATE POLICY "Allow authenticated users to read leaderboard"
ON public.leaderboard_entries
FOR SELECT
TO authenticated
USING (true);

-- 2. Users can only INSERT/UPDATE their OWN leaderboard record
CREATE POLICY "Users can insert their own leaderboard record"
ON public.leaderboard_entries
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own leaderboard record"
ON public.leaderboard_entries
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 3. Prohibit deletion of entries except by account deletion cascade
CREATE POLICY "Users can delete their own leaderboard record"
ON public.leaderboard_entries
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
```

---

## 3. Server-Side Aggregate Trigger (Immutable Ledger Derivation)

To prevent clients from directly tampering with XP amounts, the server calculates XP aggregates directly from verified rows in `xp_events`:

```sql
CREATE OR REPLACE FUNCTION public.handle_xp_event_added()
RETURNS TRIGGER AS $$
DECLARE
    v_week_start TIMESTAMPTZ := date_trunc('week', NOW());
    v_month_start TIMESTAMPTZ := date_trunc('month', NOW());
    v_total_xp INTEGER;
    v_week_xp INTEGER;
    v_month_xp INTEGER;
    v_level INTEGER;
BEGIN
    -- Calculate lifetime XP
    SELECT COALESCE(SUM(amount), 0) INTO v_total_xp
    FROM public.xp_events
    WHERE user_id = NEW.user_id;

    -- Calculate current week XP (since Monday 00:00:00)
    SELECT COALESCE(SUM(amount), 0) INTO v_week_xp
    FROM public.xp_events
    WHERE user_id = NEW.user_id AND timestamp >= v_week_start;

    -- Calculate current month XP (since 1st of month 00:00:00)
    SELECT COALESCE(SUM(amount), 0) INTO v_month_xp
    FROM public.xp_events
    WHERE user_id = NEW.user_id AND timestamp >= v_month_start;

    -- Calculate level (LevelCurve logic)
    v_level := FLOOR(1 + SQRT(v_total_xp / 100.0));

    -- Upsert public aggregate
    INSERT INTO public.leaderboard_entries (
        user_id,
        display_name,
        total_xp,
        week_xp,
        month_xp,
        level,
        updated_at
    )
    VALUES (
        NEW.user_id,
        COALESCE((SELECT display_name FROM public.student_profiles WHERE id = NEW.user_id), 'Student'),
        v_total_xp,
        v_week_xp,
        v_month_xp,
        v_level,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE
    SET 
        total_xp = EXCLUDED.total_xp,
        week_xp = EXCLUDED.week_xp,
        month_xp = EXCLUDED.month_xp,
        level = EXCLUDED.level,
        updated_at = EXCLUDED.updated_at;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_xp_event_inserted
AFTER INSERT ON public.xp_events
FOR EACH ROW
EXECUTE FUNCTION public.handle_xp_event_added();
```

---

## 4. Privacy Invariants

The `leaderboard_entries` table strictly excludes:
- Email addresses and phone numbers
- Authentication tokens, passwords, and secrets
- Academic notes, files, and study resources
- Private tasks, subtasks, and exam deadlines
- Personal goals and reflections
