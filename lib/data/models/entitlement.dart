import 'package:meta/meta.dart';

/// Type of entitlement granted through rewards.
enum EntitlementType {
  theme('Theme'),
  badge('Badge'),
  feature('Feature Access'),
  premium('Premium Access'),
  discount('Discount');

  const EntitlementType(this.label);
  final String label;
}

/// Status of an entitlement.
enum EntitlementStatus {
  active('Active'),
  expired('Expired'),
  revoked('Revoked');

  const EntitlementStatus(this.label);
  final String label;
}

/// A granted entitlement from reward redemption.
///
/// Entitlements represent what the student has unlocked through XP redemption.
/// They persist across app restarts and track active/expired state.
@immutable
class StudentEntitlement {
  const StudentEntitlement({
    required this.id,
    required this.rewardId,
    required this.type,
    required this.grantedAt,
    required this.status,
    this.expiresAt,
    this.activatedAt,
    this.metadata,
  });

  /// Unique entitlement ID.
  final String id;

  /// ID of the reward that granted this entitlement.
  final String rewardId;

  /// Type of entitlement.
  final EntitlementType type;

  /// When the entitlement was granted.
  final DateTime grantedAt;

  /// Current status.
  final EntitlementStatus status;

  /// Optional expiration (null = permanent).
  final DateTime? expiresAt;

  /// When the student first activated/used this entitlement.
  final DateTime? activatedAt;

  /// Additional data for the entitlement (theme ID, feature flag, etc.).
  final Map<String, dynamic>? metadata;

  /// Whether this entitlement is currently active and usable.
  bool get isActive {
    if (status != EntitlementStatus.active) return false;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rewardId': rewardId,
    'type': type.name,
    'grantedAt': grantedAt.toIso8601String(),
    'status': status.name,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (activatedAt != null) 'activatedAt': activatedAt!.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };

  factory StudentEntitlement.fromJson(Map<String, dynamic> json) {
    return StudentEntitlement(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      type: EntitlementType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EntitlementType.theme,
      ),
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      status: EntitlementStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EntitlementStatus.active,
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  StudentEntitlement copyWith({
    String? id,
    String? rewardId,
    EntitlementType? type,
    DateTime? grantedAt,
    EntitlementStatus? status,
    DateTime? expiresAt,
    DateTime? activatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return StudentEntitlement(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      type: type ?? this.type,
      grantedAt: grantedAt ?? this.grantedAt,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      activatedAt: activatedAt ?? this.activatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEntitlement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
