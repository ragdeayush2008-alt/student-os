enum FocusGuardPermissionStatus {
  notReady,
  usageAccessRequired,
  overlayRequired,
  ready,
  unsupported,
}

enum FocusGuardMode {
  gentle,
  standard,
  strict,
}

extension FocusGuardModeExtension on FocusGuardMode {
  String get label {
    switch (this) {
      case FocusGuardMode.gentle:
        return 'Gentle';
      case FocusGuardMode.standard:
        return 'Standard';
      case FocusGuardMode.strict:
        return 'Strict';
    }
  }

  String get description {
    switch (this) {
      case FocusGuardMode.gentle:
        return 'Warns when opening blocked apps, allowing manual return.';
      case FocusGuardMode.standard:
        return 'Immediately presents Focus Guard to bring you back to study.';
      case FocusGuardMode.strict:
        return 'Stronger confirmation barrier to prevent impulse distractions.';
    }
  }
}

enum DetectedAppType {
  studentOs,
  launcher,
  system,
  userApp,
  unknown,
}

class DetectedApp {
  DetectedApp({
    required this.packageName,
    this.label,
    this.isSystemApp = false,
    this.isStudentOs = false,
    this.isLauncher = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String packageName;
  final String? label;
  final bool isSystemApp;
  final bool isStudentOs;
  final bool isLauncher;
  final DateTime timestamp;

  DetectedAppType get appType {
    if (isStudentOs) return DetectedAppType.studentOs;
    if (isLauncher) return DetectedAppType.launcher;
    if (isSystemApp) return DetectedAppType.system;
    if (packageName.isNotEmpty) return DetectedAppType.userApp;
    return DetectedAppType.unknown;
  }

  String get displayName => (label != null && label!.isNotEmpty) ? label! : packageName;

  factory DetectedApp.fromMap(Map<dynamic, dynamic> map) {
    return DetectedApp(
      packageName: map['packageName'] as String? ?? '',
      label: map['label'] as String?,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      isStudentOs: map['isStudentOs'] as bool? ?? false,
      isLauncher: map['isLauncher'] as bool? ?? false,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'packageName': packageName,
    'label': label,
    'isSystemApp': isSystemApp,
    'isStudentOs': isStudentOs,
    'isLauncher': isLauncher,
    'timestamp': timestamp.toIso8601String(),
    'appType': appType.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedApp &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}

class BlockedAppAttempt {
  BlockedAppAttempt({
    required this.id,
    required this.sessionId,
    required this.packageName,
    this.appLabel,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final String sessionId;
  final String packageName;
  final String? appLabel;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'packageName': packageName,
    'appLabel': appLabel,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BlockedAppAttempt.fromJson(Map<String, dynamic> json) => BlockedAppAttempt(
    id: json['id'] as String? ?? '',
    sessionId: json['sessionId'] as String? ?? '',
    packageName: json['packageName'] as String? ?? '',
    appLabel: json['appLabel'] as String?,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
  );
}

class FocusGuardConfig {
  const FocusGuardConfig({
    this.blockedPackages = const {},
    this.mode = FocusGuardMode.standard,
    this.enabled = true,
  });

  final Set<String> blockedPackages;
  final FocusGuardMode mode;
  final bool enabled;

  Map<String, dynamic> toJson() => {
    'blockedPackages': blockedPackages.toList(),
    'mode': mode.name,
    'enabled': enabled,
  };

  factory FocusGuardConfig.fromJson(Map<String, dynamic> json) {
    final list = json['blockedPackages'] as List<dynamic>? ?? [];
    final modeStr = json['mode'] as String? ?? 'standard';
    return FocusGuardConfig(
      blockedPackages: list.whereType<String>().toSet(),
      mode: FocusGuardMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => FocusGuardMode.standard,
      ),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  FocusGuardConfig copyWith({
    Set<String>? blockedPackages,
    FocusGuardMode? mode,
    bool? enabled,
  }) {
    return FocusGuardConfig(
      blockedPackages: blockedPackages ?? this.blockedPackages,
      mode: mode ?? this.mode,
      enabled: enabled ?? this.enabled,
    );
  }
}
