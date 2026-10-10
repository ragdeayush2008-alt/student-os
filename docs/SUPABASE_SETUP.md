# Student OS — Supabase Setup

## Why Supabase

Student OS uses Supabase as its primary free-tier backend. It provides:

- **PostgreSQL** database (relational persistence for student data).
- **Auth** (email, social, passwordless) for future authentication.
- **Storage** for user-uploaded content.
- **Realtime** for sync and collaborative/community features.
- **Edge Functions** for server-side logic, when needed.

Supabase aligns with the project's commitment to **free/open-source** services (see [PROJECT_VISION.md](./PROJECT_VISION.md) and [DATA_AND_SERVICES.md](./DATA_AND_SERVICES.md)).

## What Phase 4A Does

Establishes the **connection foundation** only:

- A compile-time configuration layer (`lib/core/config/app_config.dart`).
- A thin bootstrap service (`lib/core/services/supabase_service.dart`).
- Clear lifecycle states (`notConfigured`, `initializing`, `ready`, `failed`).
- A single, safe accessor for the Supabase client that is only non-null when ready.
- Graceful local/demo fallback when Supabase is **not** configured.

## What Phase 4A Intentionally Does NOT Do

- **No** authentication UI.
- **No** onboarding UI.
- **No** database tables (created from Flutter or otherwise).
- **No** Supabase Edge Functions.
- **No** repositories (auth/profile/rewards/admin) — those belong to later phases.
- **No** hardcoded credentials, and **no** requirement to enter credentials at runtime.

## How to Configure

Credentials are supplied at **build/run time** via Dart compile-time environment
variables. They are read in `lib/core/config/app_config.dart`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

They are never committed or hardcoded.

## Running with Supabase (placeholders)

Use your real URL and **anon (publishable)** key in place of the placeholders:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

### Running without credentials (local / demo mode)

Just run without the defines — the app launches normally in local/demo mode:

```bash
flutter run
```

## Security Rules

- **Never commit secrets** to the repository.
- **Never hardcode** the Supabase URL or anon key in source code.
- **Never use the `service_role` key** in the Flutter client — it is secret and
  grants full database access. The Flutter app must use only the **anon key**.
- The Supabase team: the anon key is a publishable key by design, but it should
  still be guarded by **Row Level Security (RLS)** so users can only access their
  own data. RLS is configured on the backend, *not* in the Flutter app.

## Initialization States

| State | Meaning |
|-------|---------|
| `notConfigured` | Credentials absent — app runs in local/demo mode. |
| `initializing` | Credentials present; initialization in progress. |
| `ready` | Initialized; `SupabaseService.instance.client` is available. |
| `failed` | Credentials present but initialization failed; app stays usable. |

The current state is observable via `SupabaseService.instance.state` (a
`ValueListenable`). Future features should obtain the client only when the state
is `ready`:

```dart
final client = SupabaseService.instance.client; // null unless ready
```

## Behavior When Supabase Is Not Configured

- The app starts immediately with **no white flash** and **no blocked UI**.
- Existing mock/demo functionality continues to work.
- Supabase state remains `notConfigured`.
- No crash.

## Future Phases Using This Foundation

- **Phase 4B** — authentication flow (sign-up, sign-in, session).
- **Phase 5** — foundational student experience with cloud sync.
- **Profile/preferences** — synced across devices.
- **Notifications, rewards, admin** and other student data.

## Files

- `lib/core/config/app_config.dart` — compile-time config + detection.
- `lib/core/services/supabase_service.dart` — init service, state, client accessor.
- `test/supabase_connection_test.dart` — deterministic configuration tests.
