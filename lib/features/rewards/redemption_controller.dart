import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/student_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/theme/theme_variants.dart';
import '../../data/models/entitlement.dart';
import '../../data/models/reward.dart';
import '../../data/models/reward_transaction.dart';
import '../auth/auth_service.dart';
import '../notifications/notification_controller.dart';
import '../progression/progression_controller.dart';
import 'premium_entitlement.dart';
import 'reward_catalog.dart';
import 'theme_manager.dart';

/// Result of a redemption attempt.
class RedemptionResult {
  const RedemptionResult({
    required this.success,
    this.transaction,
    this.entitlement,
    this.errorMessage,
  });

  final bool success;
  final RewardTransaction? transaction;
  final StudentEntitlement? entitlement;
  final String? errorMessage;

  factory RedemptionResult.success({
    required RewardTransaction transaction,
    required StudentEntitlement entitlement,
  }) {
    return RedemptionResult(
      success: true,
      transaction: transaction,
      entitlement: entitlement,
    );
  }

  factory RedemptionResult.failure(String errorMessage) {
    return RedemptionResult(success: false, errorMessage: errorMessage);
  }
}

/// Central controller for reward redemption, ownership, inventory, and equipment in Rewards Marketplace 2.0.
class RedemptionController extends ChangeNotifier {
  RedemptionController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _transactions.clear();
    _entitlements.clear();
    _transactionIds.clear();
    _ownedRewardIds.clear();
    _equippedSlots.clear();
    _favoriteIds.clear();
    _loaded = false;
    notifyListeners();
  }

  static final RedemptionController instance = RedemptionController._();

  static const _transactionsKey = 'reward_transactions';
  static const _entitlementsKey = 'reward_entitlements';
  static const _equippedSlotsKey = 'reward_equipped_slots';
  static const _favoritesKey = 'reward_favorites';
  static final _uuid = const Uuid();

  List<RewardTransaction> _transactions = [];
  List<StudentEntitlement> _entitlements = [];
  final Set<String> _transactionIds = {};
  final Set<String> _ownedRewardIds = {};
  final Map<String, String> _equippedSlots = {};
  final Set<String> _favoriteIds = {};
  bool _loaded = false;
  bool _disposed = false;

  /// All redemption transactions (newest first).
  List<RewardTransaction> get transactions =>
      List.unmodifiable(_transactions.reversed);

  /// All entitlements (active first).
  List<StudentEntitlement> get entitlements => List.unmodifiable(
    _entitlements..sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return b.grantedAt.compareTo(a.grantedAt);
    }),
  );

  /// Active entitlements only.
  List<StudentEntitlement> get activeEntitlements =>
      _entitlements.where((e) => e.isActive).toList();

  /// Set of all owned reward IDs.
  Set<String> get ownedRewardIds => Set.unmodifiable(_ownedRewardIds);

  /// All owned reward instances (inventory).
  List<Reward> get inventory {
    final list = <Reward>[];
    for (final id in _ownedRewardIds) {
      final r = RewardCatalog.instance.findById(id);
      if (r != null) list.add(r);
    }
    return List.unmodifiable(list);
  }

  /// Map of currently equipped items by slot ('theme', 'badge', 'profileFrame', 'focusStyle').
  Map<String, String> get equippedSlots => Map.unmodifiable(_equippedSlots);

  /// Favorited reward IDs.
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  /// Whether data has been loaded from storage.
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown.
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Loading / Persistence ───────────────────────────────────────────

  Future<void> load() async {
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    final uid = _userId;
    if (uid == null) return;

    final transactionsList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _transactionsKey,
    );

    final entitlementsList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _entitlementsKey,
    );

    final equippedMap = await StorageService.instance.loadJson(
      userId: uid,
      key: _equippedSlotsKey,
    );

    final favoritesList = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _favoritesKey,
    );

    _transactions = [];
    _transactionIds.clear();
    _ownedRewardIds.clear();
    _equippedSlots.clear();
    _favoriteIds.clear();

    if (transactionsList != null) {
      for (final item in transactionsList) {
        try {
          final tx = RewardTransaction.fromJson(item);
          if (_transactionIds.add(tx.id)) {
            _transactions.add(tx);
            if (tx.status == RedemptionStatus.completed) {
              _ownedRewardIds.add(tx.rewardId);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[RedemptionController] Error parsing transaction: $e');
          }
        }
      }
      _transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    _entitlements = [];
    if (entitlementsList != null) {
      for (final item in entitlementsList) {
        try {
          _entitlements.add(StudentEntitlement.fromJson(item));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[RedemptionController] Error parsing entitlement: $e');
          }
        }
      }
    }

    if (equippedMap != null) {
      for (final entry in equippedMap.entries) {
        _equippedSlots[entry.key] = entry.value.toString();
      }
    }

    if (favoritesList != null) {
      for (final item in favoritesList) {
        if (item['id'] != null) {
          _favoriteIds.add(item['id'].toString());
        }
      }
    }

    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> _saveTransactions() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _transactionsKey,
      list: _transactions.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> _saveEntitlements() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _entitlementsKey,
      list: _entitlements.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _saveEquippedSlots() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _equippedSlotsKey,
      json: _equippedSlots,
    );
  }

  Future<void> _saveFavorites() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _favoritesKey,
      list: _favoriteIds.map((id) => {'id': id}).toList(),
    );
  }

  // ─── Redemption Engine ───────────────────────────────────────────────

  /// Attempts to redeem a reward.
  Future<RedemptionResult> redeemReward(String rewardId) async {
    // 1. Find the reward
    final reward = RewardCatalog.instance.findById(rewardId);
    if (reward == null) {
      return RedemptionResult.failure('Reward not found');
    }

    // 2. Check availability
    if (!reward.isRedeemable) {
      return RedemptionResult.failure('This reward is not available yet');
    }

    // 3. Check ownership (one-time rewards)
    if (reward.isOneTime && _ownedRewardIds.contains(rewardId)) {
      return RedemptionResult.failure('You already own this reward');
    }

    // 4. Check level requirement
    final progression = ProgressionController.instance;
    final currentLevel = progression.currentLevel.level;
    if (currentLevel < reward.minimumLevel) {
      return RedemptionResult.failure('Requires Level ${reward.minimumLevel}');
    }

    // 4b. Check streak requirement if any
    if (reward.requiredStreak != null && reward.requiredStreak! > 0) {
      final currentStreak = StreakService.instance.currentStreak;
      if (currentStreak < reward.requiredStreak!) {
        return RedemptionResult.failure(
          'Requires ${reward.requiredStreak!}-day streak (current: $currentStreak)',
        );
      }
    }

    // 5. Check spendable XP
    final spendableXp = progression.spendableXp;
    if (spendableXp < reward.xpCost) {
      return RedemptionResult.failure(
        'Not enough XP (need ${reward.xpCost}, have $spendableXp)',
      );
    }

    // 6. Create deterministic transaction ID
    final now = DateTime.now();
    final txId = _createTransactionId(rewardId, now);

    // 7. Check for duplicate transaction
    if (_transactionIds.contains(txId)) {
      return RedemptionResult.failure('Duplicate redemption attempt');
    }

    // 8. Create transaction record
    final transaction = RewardTransaction(
      id: txId,
      rewardId: rewardId,
      xpSpent: reward.xpCost,
      timestamp: now,
      status: RedemptionStatus.completed,
      rewardTitle: reward.title,
    );

    // 9. Deduct XP (atomic operation)
    final spendSuccess = await progression.spendXp(reward.xpCost);
    if (!spendSuccess) {
      return RedemptionResult.failure('Failed to spend XP');
    }

    // 10. Grant entitlement
    final entitlement = _createEntitlement(reward, now);

    // 10b. If this is a trial or premium activation, trigger activation
    if (entitlement.type == EntitlementType.discount ||
        entitlement.type == EntitlementType.premium) {
      final trialDays = (reward.metadata?['trialDays'] as num?)?.toInt() ?? 7;
      if (reward.id == 'discount_premium_trial') {
        await PremiumEntitlement.instance.activateTrial(
          durationDays: trialDays,
        );
      }
    }

    // 11. Persist everything
    try {
      _transactionIds.add(txId);
      _transactions.add(transaction);
      _ownedRewardIds.add(rewardId);
      _entitlements.add(entitlement);

      await _saveTransactions();
      await _saveEntitlements();

      // Automatically equip cosmetics if slot is empty
      if (reward.isEquippable) {
        final slot = reward.equipmentSlot;
        if (!_equippedSlots.containsKey(slot)) {
          await equipReward(reward);
        }
      }

      // Queue transaction and entitlement for cloud sync
      await SyncQueue.instance.enqueue(
        table: 'reward_transactions',
        recordId: transaction.id,
        type: SyncOperationType.upsert,
        payload: transaction.toJson(),
      );

      await SyncQueue.instance.enqueue(
        table: 'student_entitlements',
        recordId: entitlement.id,
        type: SyncOperationType.upsert,
        payload: entitlement.toJson(),
      );

      SyncEngine.instance.synchronize();

      if (!_disposed) notifyListeners();

      NotificationController.instance.onRewardUnlocked(reward.id, reward.title);

      return RedemptionResult.success(
        transaction: transaction,
        entitlement: entitlement,
      );
    } catch (e) {
      await progression.refundXp(reward.xpCost);

      if (kDebugMode) {
        debugPrint('[RedemptionController] Redemption failed: $e');
      }

      return RedemptionResult.failure('Failed to save redemption');
    }
  }

  String _createTransactionId(String rewardId, DateTime timestamp) {
    final ts = timestamp.millisecondsSinceEpoch;
    return 'reward_tx_${rewardId}_$ts';
  }

  StudentEntitlement _createEntitlement(Reward reward, DateTime now) {
    final entitlementType = _mapRewardTypeToEntitlement(reward.type);

    return StudentEntitlement(
      id: _uuid.v4(),
      rewardId: reward.id,
      type: entitlementType,
      grantedAt: now,
      status: EntitlementStatus.active,
      expiresAt: reward.expiresAt,
      metadata: reward.metadata,
    );
  }

  EntitlementType _mapRewardTypeToEntitlement(String rewardType) {
    return switch (rewardType) {
      'theme' => EntitlementType.theme,
      'badge' => EntitlementType.badge,
      'frame' => EntitlementType.badge,
      'feature' => EntitlementType.feature,
      'academic' => EntitlementType.feature,
      'discount' => EntitlementType.discount,
      _ => EntitlementType.badge,
    };
  }

  // ─── Equipment & Favorites ───────────────────────────────────────────

  /// Equips an owned cosmetic reward to its appropriate slot.
  Future<bool> equipReward(Reward reward) async {
    if (!ownsReward(reward.id)) return false;

    final slot = reward.equipmentSlot;
    _equippedSlots[slot] = reward.id;

    // 1. Theme slot
    if (reward.type == 'theme') {
      final themeId = reward.metadata?['themeId'] as String?;
      if (themeId != null) {
        final variant = ThemeVariantId.fromId(themeId);
        await ThemeManager.instance.setThemeVariant(variant);
      }
    }

    // 2. Badge slot (reflected in Profile hero)
    if (reward.type == 'badge') {
      await StudentService.instance.updateImportantDate(
        StudentService.instance.profile.importantDate,
        'primary_badge:${reward.id}',
      );
    }

    await _saveEquippedSlots();
    if (!_disposed) notifyListeners();
    return true;
  }

  /// Unequips a cosmetic item from a slot.
  Future<void> unequipSlot(String slot) async {
    final currentRewardId = _equippedSlots.remove(slot);
    if (currentRewardId == null) return;

    if (slot == 'theme') {
      await ThemeManager.instance.setThemeVariant(ThemeVariantId.defaultTheme);
    } else if (slot == 'badge') {
      final profile = StudentService.instance.profile;
      if (profile.importantDateLabel.startsWith('primary_badge:')) {
        await StudentService.instance.updateImportantDate(
          profile.importantDate,
          '',
        );
      }
    }

    await _saveEquippedSlots();
    if (!_disposed) notifyListeners();
  }

  /// Checks if a reward is currently equipped.
  bool isEquipped(String rewardId) {
    if (_equippedSlots.containsValue(rewardId)) return true;

    final reward = RewardCatalog.instance.findById(rewardId);
    if (reward != null && reward.type == 'theme') {
      final themeId = reward.metadata?['themeId'] as String?;
      if (themeId != null &&
          ThemeManager.instance.activeVariant.id == themeId) {
        return true;
      }
    }
    return false;
  }

  /// Toggles a reward as favorite.
  Future<void> toggleFavorite(String rewardId) async {
    if (_favoriteIds.contains(rewardId)) {
      _favoriteIds.remove(rewardId);
    } else {
      _favoriteIds.add(rewardId);
    }
    await _saveFavorites();
    if (!_disposed) notifyListeners();
  }

  /// Checks if a reward is favorited.
  bool isFavorite(String rewardId) => _favoriteIds.contains(rewardId);

  // ─── Query Helpers ───────────────────────────────────────────────────

  /// Checks if the student owns a reward.
  bool ownsReward(String rewardId) => _ownedRewardIds.contains(rewardId);

  /// Gets the entitlement for a reward (if owned).
  StudentEntitlement? getEntitlement(String rewardId) {
    try {
      return _entitlements.firstWhere((e) => e.rewardId == rewardId);
    } catch (_) {
      return null;
    }
  }

  /// Gets the transaction for a reward (if redeemed).
  RewardTransaction? getTransaction(String rewardId) {
    try {
      return _transactions.firstWhere((t) => t.rewardId == rewardId);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a reward is eligible for redemption.
  bool isEligible(Reward reward) {
    if (!reward.isRedeemable) return false;
    if (reward.isOneTime && ownsReward(reward.id)) return false;

    final progression = ProgressionController.instance;
    final currentLevel = progression.currentLevel.level;
    final spendableXp = progression.spendableXp;

    if (reward.requiredStreak != null && reward.requiredStreak! > 0) {
      if (StreakService.instance.currentStreak < reward.requiredStreak!) {
        return false;
      }
    }

    return currentLevel >= reward.minimumLevel && spendableXp >= reward.xpCost;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
