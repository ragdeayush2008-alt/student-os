import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import 'entitlement_service.dart';

/// Central feature-gate flow (UI → EntitlementService → feature | paywall).
///
/// Returns true when the feature may open, false after redirecting a Free
/// user straight to the Premium purchase page with feature context. Only
/// ACTIVE catalog features gate; anything else stays free.
abstract final class PremiumGate {
  static bool check(BuildContext context, String featureId) {
    if (EntitlementService.instance.hasFeatureAccess(featureId)) {
      return true;
    }
    AppRouter.openPremiumPage(context, sourceFeatureId: featureId);
    return false;
  }
}
