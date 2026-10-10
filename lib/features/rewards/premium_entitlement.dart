import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../auth/auth_service.dart';
import 'entitlement_manager.dart';

import 'package:flutter/foundation.dart';

/// Status of a student's premium membership or trial.
enum PremiumStatus {
  /// Regular free tier student.
  free('Free'),

  /// Active temporary trial period.
  activeTrial('Trial Active'),

  /// Paid premium membership (future proofing).
  subscribed('Subscribed'),

  /// Trial has ended.
  trialExpired('Trial Expired');

  const PremiumStatus(this.label);
  final String label;
}

/// Manages Student OS Premium access, trials, and discount computations.
///
/// Designed as a future-proof foundation without mock/fake payments or simulated billing.
/// Handles local trial activation, date expiration, and dynamic tier discounting.
class PremiumEntitlement extends ChangeNotifier {
  PremiumEntitlement._();

  static final PremiumEntitlement instance = PremiumEntitlement._();

  static const _trialActivationKey = 'premium_trial_activation_date';
  static const _trialDurationDaysKey = 'premium_trial_duration_days';

  DateTime? _trialActivatedAt;
  int _trialDurationDays = 7;
  bool _loaded = false;
  bool _disposed = false;

  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  /// When the current trial was activated (null if never activated).
  DateTime? get trialActivatedAt => _trialActivatedAt;

  /// Expiration timestamp of the current trial (null if no trial).
  DateTime? get trialExpiresAt {
    if (_trialActivatedAt == null) return null;
    return _trialActivatedAt!.add(Duration(days: _trialDurationDays));
  }

  /// Days remaining in the active trial (0 if expired or not active).
  int get trialDaysRemaining {
    final expires = trialExpiresAt;
    if (expires == null) return 0;
    final diff = expires.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inDays + (diff.inHours % 24 > 0 ? 1 : 0);
  }

  /// Whether the student currently has active Premium access (trial or entitlement).
  bool get isPremiumActive {
    if (_isTrialValid()) return true;
    return EntitlementManager.instance.hasActivePremium;
  }

  /// Detailed status descriptor for UI components.
  PremiumStatus get status {
    if (_isTrialValid()) return PremiumStatus.activeTrial;
    if (EntitlementManager.instance.hasActivePremium) {
      return PremiumStatus.subscribed;
    }
    if (_trialActivatedAt != null && !_isTrialValid()) {
      return PremiumStatus.trialExpired;
    }
    return PremiumStatus.free;
  }

  bool _isTrialValid() {
    final expires = trialExpiresAt;
    if (expires == null) return false;
    return DateTime.now().isBefore(expires);
  }

  // ─── Persistence & Loading ──────────────────────────────────────────

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    final uid = _userId;
    if (uid == null) return;
    final rawDate = await StorageService.instance.loadString(
      userId: uid,
      key: _trialActivationKey,
    );
    final rawDays = await StorageService.instance.loadInt(
      userId: uid,
      key: _trialDurationDaysKey,
    );

    if (rawDate != null) {
      _trialActivatedAt = DateTime.tryParse(rawDate);
    } else {
      _trialActivatedAt = null;
    }

    if (rawDays != null && rawDays > 0) {
      _trialDurationDays = rawDays;
    }

    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  /// Activates a premium trial for a specific duration in days.
  Future<bool> activateTrial({int durationDays = 7}) async {
    // Only allow activating if trial has not been activated yet or is expired
    final now = DateTime.now();
    _trialActivatedAt = now;
    _trialDurationDays = durationDays;

    final uid = _userId;
    if (uid == null) return true;
    await StorageService.instance.saveString(
      userId: uid,
      key: _trialActivationKey,
      value: now.toIso8601String(),
    );
    await StorageService.instance.saveInt(
      userId: uid,
      key: _trialDurationDaysKey,
      value: durationDays,
    );

    if (!_disposed) notifyListeners();
    return true;
  }

  /// Computes the effective student discount percentage combining level progression
  /// and any redeemed discount entitlements (capped at 50% total discount).
  double computeDiscount({required int level}) {
    // Progression-based baseline discount
    double baseDiscount = 0.0;
    if (level >= 50) {
      baseDiscount = 0.20;
    } else if (level >= 20) {
      baseDiscount = 0.15;
    } else if (level >= 10) {
      baseDiscount = 0.10;
    } else if (level >= 5) {
      baseDiscount = 0.05;
    }

    // Redeemed coupon/entitlement discount
    final redeemedDiscount =
        EntitlementManager.instance.premiumDiscountPercent / 100.0;

    // Combined capped discount
    final combined = baseDiscount + redeemedDiscount;
    return combined.clamp(0.0, 0.50);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
