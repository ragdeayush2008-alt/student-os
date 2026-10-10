import 'package:flutter/foundation.dart';

/// Provider-neutral membership states.
enum MembershipStatus {
  free('Free'),
  active('Active'),
  cancelledPendingExpiry('Cancelling'),
  expired('Expired'),
  pending('Pending'),
  gracePeriod('Grace period'),
  unknown('Unknown');

  const MembershipStatus(this.label);
  final String label;
}

/// Billing provider behind a subscription. `none` until a real provider
/// verifies a purchase.
enum MembershipProvider {
  none('None'),
  googlePlay('Google Play'),
  appStore('App Store'),
  razorpay('Razorpay');

  const MembershipProvider(this.label);
  final String label;
}

/// What last established the stored state. Only `verified` reflects a real
/// provider purchase; `development` is the local debug preview.
enum VerificationSource {
  unverified('Unverified'),
  development('Development preview'),
  cached('Cached'),
  verified('Verified purchase');

  const VerificationSource(this.label);
  final String label;
}

/// Provider-neutral subscription record. Never claims verification until a
/// future provider confirms it.
@immutable
class PremiumSubscription {
  const PremiumSubscription({
    required this.userId,
    this.planId,
    this.status = MembershipStatus.free,
    this.provider = MembershipProvider.none,
    this.providerProductId,
    this.purchaseReference,
    this.startedAt,
    this.expiresAt,
    this.autoRenewing = false,
    this.lastVerifiedAt,
    this.verificationSource = VerificationSource.unverified,
  });

  final String userId;
  final String? planId;
  final MembershipStatus status;
  final MembershipProvider provider;
  final String? providerProductId;
  final String? purchaseReference;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool autoRenewing;
  final DateTime? lastVerifiedAt;
  final VerificationSource verificationSource;

  /// Active access: verified-or-development ACTIVE, grace period, or a
  /// cancelling plan that has not expired yet.
  bool get grantsProAccess {
    switch (status) {
      case MembershipStatus.active:
      case MembershipStatus.gracePeriod:
        return true;
      case MembershipStatus.cancelledPendingExpiry:
        final exp = expiresAt;
        if (exp == null) return true;
        return DateTime.now().isBefore(exp);
      case MembershipStatus.free:
      case MembershipStatus.expired:
      case MembershipStatus.pending:
      case MembershipStatus.unknown:
        return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'planId': planId,
        'status': status.name,
        'provider': provider.name,
        'providerProductId': providerProductId,
        'purchaseReference': purchaseReference,
        'startedAt': startedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'autoRenewing': autoRenewing,
        'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
        'verificationSource': verificationSource.name,
      };

  /// Tolerant: unknown/corrupt values degrade to a free, unverified state —
  /// never to spurious Pro access.
  factory PremiumSubscription.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v as String);
      } catch (_) {
        return null;
      }
    }

    MembershipStatus statusFrom(String? name) {
      for (final s in MembershipStatus.values) {
        if (s.name == name) return s;
      }
      return MembershipStatus.free;
    }

    MembershipProvider providerFrom(String? name) {
      for (final p in MembershipProvider.values) {
        if (p.name == name) return p;
      }
      return MembershipProvider.none;
    }

    VerificationSource sourceFrom(String? name) {
      for (final s in VerificationSource.values) {
        if (s.name == name) return s;
      }
      return VerificationSource.unverified;
    }

    return PremiumSubscription(
      userId: (json['userId'] as String?) ?? '',
      planId: json['planId'] as String?,
      status: statusFrom(json['status'] as String?),
      provider: providerFrom(json['provider'] as String?),
      providerProductId: json['providerProductId'] as String?,
      purchaseReference: json['purchaseReference'] as String?,
      startedAt: parseDate(json['startedAt']),
      expiresAt: parseDate(json['expiresAt']),
      autoRenewing: (json['autoRenewing'] as bool?) ?? false,
      lastVerifiedAt: parseDate(json['lastVerifiedAt']),
      verificationSource: sourceFrom(json['verificationSource'] as String?),
    );
  }
}
