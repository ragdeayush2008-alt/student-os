import 'package:flutter/material.dart';

import '../../app/app_shell.dart';
import '../../core/services/student_service.dart';
import '../../core/services/supabase_service.dart';
import '../onboarding/presentation/onboarding_screen.dart';
import 'auth_scope.dart';
import 'auth_state.dart';
import 'presentation/forgot_password_screen.dart';
import 'presentation/sign_in_screen.dart';
import 'presentation/sign_up_screen.dart';
import 'presentation/update_password_screen.dart';
import 'presentation/verification_pending_screen.dart';
import 'presentation/welcome_screen.dart';
import 'widgets/auth_loading_screen.dart';

/// Root session gate that decides which top-level UI to show.
///
/// Decision tree:
/// ```
/// Supabase ready?
///   ├─ no  → AuthLoadingScreen (safe state, no private data shown)
///   └─ yes → auth.viewState
///              ├─ checking        → AuthLoadingScreen
///              ├─ unauthenticated → AuthExperience (welcome/signin/up)
///              └─ authenticated   → check onboarding
///                   ├─ incomplete → OnboardingScreen
///                   └─ complete  → StudentOsApp (full app)
/// ```
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    SupabaseService.instance.state.addListener(_onStateChanged);
    StudentService.instance.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SupabaseService.instance.state.removeListener(_onStateChanged);
    StudentService.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supaState = SupabaseService.instance.currentState;

    // ── Case A: Supabase initializing → safe loading state ──
    // Case B: Supabase ready / failed / not configured → follow auth state
    if (supaState == SupabaseInitState.initializing) {
      return const AuthLoadingScreen();
    }

    // ── Case B: Supabase ready → follow auth state ──
    final auth = AuthScope.of(context);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        return switch (auth.viewState) {
          AuthViewState.checking => const AuthLoadingScreen(),
          AuthViewState.unauthenticated => const _AuthExperience(),
          AuthViewState.authenticated => _authenticatedBranch(),
          AuthViewState.passwordRecovery => const UpdatePasswordScreen(),
          // Supabase unavailable/not configured: show auth experience
          // so user is not silently dropped into AppShell.
          AuthViewState.demoMode => const _AuthExperience(),
        };
      },
    );
  }

  Widget _authenticatedBranch() {
    // StudentService loads in the background after runApp(). While it loads,
    // isLoaded is false and the default profile has isOnboardingComplete=false,
    // which would incorrectly show onboarding. Show loading until profile is
    // ready.
    if (!StudentService.instance.isLoaded) {
      return const AuthLoadingScreen();
    }
    final profile = StudentService.instance.profile;
    if (!profile.isOnboardingComplete) {
      return const _OnboardingExperience();
    }
    return const AppShell();
  }
}

// ── Auth experience ───────────────────────────────────────────────

class _AuthExperience extends StatelessWidget {
  const _AuthExperience();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => switch (settings.name) {
            '/sign-in' => const SignInScreen(),
            '/sign-up' => const SignUpScreen(),
            '/forgot-password' => const ForgotPasswordScreen(),
            '/update-password' => const UpdatePasswordScreen(),
            '/verification-pending' => const VerificationPendingScreen(),
            _ => const WelcomeScreen(),
          },
        );
      },
      initialRoute: '/',
    );
  }
}

// ── Onboarding experience ─────────────────────────────────────────

class _OnboardingExperience extends StatelessWidget {
  const _OnboardingExperience();

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen();
  }
}
