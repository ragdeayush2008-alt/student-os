# Student OS — Backend & Cloud Architecture (Phase 11)

## Overview

Student OS operates on an **Offline-First, Cloud-Synchronized** architecture. The application is completely functional without internet access, storing data in user-scoped local storage (`StorageService`), while continuously and idempotently synchronizing state with **Supabase** via the `SyncEngine` and `SyncQueue`.

```
                    STUDENT OS
                         │
             ┌───────────┴───────────┐
             ↓                       ↓
       LOCAL STORAGE             SUPABASE
        (Fast Reads)            (Cloud Sync)
             │                       │
             └───────────┬───────────┘
                         ↓
                    SYNC ENGINE
                         ↓
          SERVER-AUTHORITATIVE PROGRESSION
           (XP Ledger, Rewards, Entitlements)
```

---

## 1. Authentication & User Identity

- **Google / Email Auth**: Handled by Supabase Auth (`AuthService`).
- **Stable Identity**: All data records are bound to the authenticated `user.id` (UUID).
- **Demo / Offline Fallback**: In unauthenticated or offline demo mode, storage defaults safely to the `'demo'` namespace.
- **Account Isolation**: Switching accounts clears memory state and isolates local storage keys using `uos_${userId}_${key}` prefixes.

---

## 2. Data Ownership & Row Level Security (RLS)

All Supabase tables have **Row Level Security (RLS)** strictly enabled:
- **`student_profiles`**: `auth.uid() = id`
- **`subjects`**, **`exams`**, **`tasks`**, **`study_sessions`**, **`academic_resources`**, **`user_preferences`**: `auth.uid() = user_id`
- **`xp_events`**: Append-only by owner, select by owner.
- **`reward_transactions`**: Append-only audit log by owner.
- **`student_entitlements`**: Server-authoritative privilege checks by owner.

Service-role keys are **never** bundled into the client app; all requests use the publishable Anon key guarded by RLS.

---

## 3. Local-First Mutations & Sync Queue

- **Mutations**: Write immediately to local memory and `StorageService`.
- **Offline Queue**: Every mutating operation creates a `SyncMutation` in `SyncQueue`.
- **Sync Flush**: `SyncEngine.synchronize()` drains pending mutations to Supabase with automatic retry policies and error logging.
- **Conflict Strategy**: Last-write-wins based on monotonic timestamps (`updatedAt` / `createdAt`).

---

## 4. Server-Authoritative Progression & Entitlements

- **Immutable XP Ledger**: XP is an immutable ledger of discrete `XpEvent` entries identified by deterministic IDs (`XpEngine`).
- **Anti-Gaming Deduplication**: Duplicate event IDs are ignored, preventing repeated XP awards on sync or restart.
- **Atomic Redemptions**: `RedemptionController` validates requirements, deducts XP, creates transaction audits, and issues entitlements atomically with automatic rollback if persistence fails.
