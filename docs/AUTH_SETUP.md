# Student OS — Authentication Setup (Phase 4B)

## What Phase 4B Implements

A complete authentication foundation built on Supabase Auth:

- **Auth state management** — session-aware `AuthService` with clear view states.
- **Session restoration** — persists and restores Supabase sessions across app restarts.
- **Auth-aware routing** — `AuthGate` root widget routes between demo, auth, and app.
- **Premium Welcome screen** — animated visual identity landing for unauthenticated users.
- **Sign In** — email/password with real Supabase `signInWithPassword`.
- **Sign Up** — email/password with real Supabase `signUp`, handles email confirmation.
- **Forgot Password** — email field, calls Supabase `resetPasswordForEmail`.
- **Email Verification Pending** — premium screen shown when email confirmation is required.
- **Sign Out** — real Supabase `signOut` with confirmation dialog in Profile screen.
- **Error handling** — user-friendly, non-technical error messages.
- **Demo/local mode** — full app works when Supabase is unconfigured; no auth required.

## Required Supabase Auth Configuration

For authentication to work, your Supabase project must have:

1. **Email/Password provider** enabled (default in most Supabase projects).
2. The email/password sign-in provider turned on in the Supabase dashboard under
   *Authentication → Providers → Email*.

### Email Confirmation

Supabase projects may have email confirmation enabled or disabled:

- **Disabled (default for new projects):** Users are authenticated immediately
  after sign-up (a session is returned).
- **Enabled:** Users receive a verification email. The app shows the
  *Verification Pending* screen. The user verifies externally and then signs in.

The app handles both cases automatically — no code change is needed.

## How to Configure

Credentials are provided at build time via Dart compile-time env vars (see
[SUPABASE_SETUP.md](./SUPABASE_SETUP.md)):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## How Local / Demo Mode Behaves

When `SUPABASE_URL` and `SUPABASE_ANON_KEY` are **not** provided:

- Supabase marks itself as not configured.
- `AuthGate` detects this and shows the Student OS app shell directly.
- No authentication screens are shown.
- Existing demo/mock data continues to work.
- The Profile screen shows "Demo Student".
- No crash, no blank screen, no blocking.

## Session Restoration Behavior

When Supabase is configured and the app restarts:

1. `SupabaseService` initializes (fast if already cached).
2. `AuthService` calls `getSession()` to check for a persisted session.
3. If a session exists, the user is authenticated and sees the app shell.
4. If no session, the user sees the authentication experience.
5. The user should **not** need to sign in every time when Supabase has a valid
   persisted session.

Supabase's `supabase_flutter` package handles session persistence natively.
Student OS does **not** manually store or manage tokens.

## Sign Out Behavior

- Sign Out is available in the Profile screen when Supabase is configured and
  the user is authenticated.
- A confirmation dialog is shown before signing out.
- After sign out, the `AuthGate` automatically routes back to the
  authentication experience.
- In demo mode, the Sign Out action is not shown.

## Password Reset Behavior

- The Forgot Password screen sends a reset email via Supabase.
- The user completes the reset through the Supabase-configured redirect flow
  (web/deep-link).
- Full in-app reset completion is **not** implemented in Phase 4B — this is
  deferred to a later phase where deep-link / redirect handling can be
  properly established.

## Security Considerations

- Passwords are never stored, logged, or transmitted by Student OS directly.
- All authentication goes through Supabase Auth over HTTPS.
- The Supabase anon key is a publishable key, never a secret service role key.
- Row Level Security (RLS) on the Supabase backend ensures users can only
  access their own data — this is a backend configuration, not a Flutter concern.
- Auth errors are mapped to user-friendly messages; raw Supabase exceptions are
  never shown to users.
- Tokens are never logged or printed in any environment.

## What Is Intentionally Deferred to Future Phases

- Onboarding flow (Profile setup, educational path selection).
- OAuth providers (Google, Apple Sign In).
- Phone authentication.
- Profile database tables and user data persistence.
- Row Level Security policies.
- In-app deep-link / redirect password-reset completion.
- Admin authentication.
- Rewards, notifications, community features.

## Files

- `lib/features/auth/auth_state.dart` — auth view-state and session enums, error mapping.
- `lib/features/auth/auth_service.dart` — auth operations, session listening, error classification.
- `lib/features/auth/auth_scope.dart` — InheritedNotifier for widget tree access.
- `lib/features/auth/auth_gate.dart` — root decision widget (demo/auth/app routing).
- `lib/features/auth/presentation/welcome_screen.dart` — premium landing screen.
- `lib/features/auth/presentation/sign_in_screen.dart` — sign in form.
- `lib/features/auth/presentation/sign_up_screen.dart` — sign up form.
- `lib/features/auth/presentation/forgot_password_screen.dart` — password reset request.
- `lib/features/auth/presentation/verification_pending_screen.dart` — email verification prompt.
- `lib/features/auth/widgets/auth_shell.dart` — auth screen wrapper with gradient.
- `lib/features/auth/widgets/auth_text_field.dart` — premium themed text field.
- `lib/features/auth/widgets/auth_loading_screen.dart` — loading state during session check.
- `test/auth_test.dart` — deterministic validation and error mapping tests.
