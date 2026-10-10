import 'package:meta/meta.dart';

/// Status of a redemption transaction.
enum RedemptionStatus {
  pending('Pending'),
  completed('Completed'),
  failed('Failed'),
  refunded('Refunded');

  const RedemptionStatus(this.label);
  final String label;
}

/// A single XP redemption transaction.
///
/// Records when a student spends XP to redeem a reward. This is part of the
/// append-only audit trail ensuring XP accounting is transparent and verifiable.
@immutable
class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.rewardId,
    required this.xpSpent,
    required this.timestamp,
    required this.status,
    this.rewardTitle,
    this.failureReason,
  });

  /// Unique transaction ID (deterministic to prevent duplicate redemptions).
  final String id;

  /// ID of the reward that was redeemed.
  final String rewardId;

  /// Amount of XP spent (always positive).
  final int xpSpent;

  /// When the transaction occurred.
  final DateTime timestamp;

  /// Current status of the transaction.
  final RedemptionStatus status;

  /// Human-readable reward title for transaction history.
  final String? rewardTitle;

  /// Reason for failure (if status is failed).
  final String? failureReason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'rewardId': rewardId,
    'xpSpent': xpSpent,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    if (rewardTitle != null) 'rewardTitle': rewardTitle,
    if (failureReason != null) 'failureReason': failureReason,
  };

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      xpSpent: json['xpSpent'] as int? ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: RedemptionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RedemptionStatus.completed,
      ),
      rewardTitle: json['rewardTitle'] as String?,
      failureReason: json['failureReason'] as String?,
    );
  }

  RewardTransaction copyWith({
    String? id,
    String? rewardId,
    int? xpSpent,
    DateTime? timestamp,
    RedemptionStatus? status,
    String? rewardTitle,
    String? failureReason,
  }) {
    return RewardTransaction(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      xpSpent: xpSpent ?? this.xpSpent,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      rewardTitle: rewardTitle ?? this.rewardTitle,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
