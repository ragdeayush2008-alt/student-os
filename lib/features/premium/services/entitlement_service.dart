import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_isolation.dart';
import '../../../core/services/feature_gate.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/auth_service.dart';
import '../../rewards/entitlement_manager.dart';
import '../../rewards/premium_entitlement.dart';
import '../models/premium_catalog.dart';
import '../models/premium_subscription.dart';

/// Central Premium entitlement authority (Student OS membership foundation).
///
/// Decision order for every feature check:
/// 1. Development override (debug builds only — local preview, never a
///    purchase, never verified).
/// 2. Stored subscription state (future verified purchases; cached states
///    degrade safely; stale states never grant).
/// 3. Legacy access: active trial or XP-reward feature unlock (existing
///    behavior preserved for themes/features).
/// 4. Otherwise locked.
///
/// All UI gates route through [hasFeatureAccess]/[requireAccess] — never
/// through scattered `if premium` checks.
class EntitlementService extends ChangeNotifier {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  static const _subscriptionKey = 'premium_subscription';
  static const _devOverrideKey = 'premium_dev_override';

  PremiumSubscription? _subscription;
  bool _devOverride = false;
  bool _loaded = false;
  bool _disposed = false;

  bool get isLoaded => _loaded;

  /// True only in debug/development builds. The bypass UI and setter both
  /// honor this, so release builds cannot enable it by any path.
  static bool get isDevelopmentBypassAvailable => kDebugMode;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  MembershipStatus get status {
    if (_devOverride) return MembershipStatus.active;
    final sub = _subscription;
    if (sub == null) return MembershipStatus.free;
    return sub.status;
  }

  bool get isPro {
    if (_devOverride) return true;
    final sub = _subscription;
    if (sub != null && sub.grantsProAccess) return true;
    return _legacyProAccess;
  }

  bool get isFree => !isPro;

  /// Whether Pro access currently comes from the development preview
  /// (never presented as a purchase anywhere in the UI).
  bool get isDevelopmentPreview =>
      _devOverride && !(_subscription?.grantsProAccess ?? false);

  /// Legacy access preserved: active trial or XP-reward feature state.
  /// Guarded so a failing legacy system degrades to free, never to Pro.
  bool get _legacyProAccess {
    try {
      if (PremiumEntitlement.instance.isPremiumActive) return true;
    } catch (_) {}
    return false;
  }

  /// Central gate. COMING_SOON/UNAVAILABLE catalog features never open,
  /// even for Pro — they have no destination yet.
  bool hasFeatureAccess(String featureId) {
    final feature = PremiumCatalog.byId(featureId);
    if (feature == null) return false;
    if (feature.status != PremiumFeatureStatus.active) return false;
    if (_devOverride) return true;
    final sub = _subscription;
    if (sub != null && sub.grantsProAccess) return true;
    if (_legacyFeatureAccess(featureId)) return true;
    return false;
  }

  /// Legacy per-feature unlocks (trial-active or XP-reward entitlement).
  bool _legacyFeatureAccess(String featureId) {
    try {
      if (PremiumEntitlement.instance.isPremiumActive) return true;
    } catch (_) {}
    try {
      if (EntitlementManager.instance.isFeatureUnlocked(featureId)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Where current Pro access comes from (for honest UI labels).
  FeatureAccessSource accessSource(String featureId) {
    if (_devOverride) return FeatureAccessSource.premiumSubscription;
    final sub = _subscription;
    if (sub != null && sub.grantsProAccess) {
      return FeatureAccessSource.premiumSubscription;
    }
    if (_legacyFeatureAccess(featureId)) {
      return FeatureAccessSource.rewardEntitlement;
    }
    return FeatureAccessSource.baseline;
  }

  void clearData() {
    _subscription = null;
    _devOverride = false;
    _loaded = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      _subscription = null;
      _devOverride = false;
      _loaded = true;
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final subJson = await StorageService.instance.loadJson(
        userId: uid,
        key: _subscriptionKey,
      );
      _subscription = subJson == null
          ? null
          : PremiumSubscription.fromJson(subJson);
      final devRaw = await StorageService.instance.loadBool(
        userId: uid,
        key: _devOverrideKey,
      );
      // Stored dev state only ever applies in debug builds.
      _devOverride = isDevelopmentBypassAvailable && devRaw;
    } catch (_) {
      _subscription = null;
      _devOverride = false;
    } finally {
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      if (_subscription == null) {
        await StorageService.instance.remove(
          userId: uid,
          key: _subscriptionKey,
        );
      } else {
        await StorageService.instance.saveJson(
          userId: uid,
          key: _subscriptionKey,
          json: _subscription!.toJson(),
        );
      }
      await StorageService.instance.saveBool(
        userId: uid,
        key: _devOverrideKey,
        value: _devOverride,
      );
    } catch (_) {}
  }

  /// Temporary development-only Pro preview. Returns false (no-op) outside
  /// debug builds. Never a purchase, never verified, never counted.
  Future<bool> setDevOverride(bool enabled) async {
    if (!isDevelopmentBypassAvailable) return false;
    _devOverride = enabled;
    await _save();
    if (!_disposed) notifyListeners();
    return true;
  }

  /// Records a future verified subscription (provider integration point).
  /// Until a provider calls this with verified data, production stays free.
  Future<void> applyVerifiedSubscription(PremiumSubscription sub) async {
    _subscription = sub;
    await _save();
    if (!_disposed) notifyListeners();
  }

  /// Clears stored subscription state (logout hygiene / expiry handling).
  Future<void> clearSubscription() async {
    _subscription = null;
    await _save();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
