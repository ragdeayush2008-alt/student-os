import 'package:flutter/foundation.dart';

enum SleepEntryType {
  night('Night sleep'),
  nap('Nap');

  const SleepEntryType(this.label);
  final String label;
}

enum SleepRecordSource {
  manual('Logged by you'),
  derived('Derived from schedule');

  const SleepRecordSource(this.label);
  final String label;
}

@immutable
class SleepRecord {
  const SleepRecord({
    required this.id,
    required this.bedtime,
    required this.wakeTime,
    this.type = SleepEntryType.night,
    this.quality,
    this.note = '',
    this.source = SleepRecordSource.manual,
    this.createdAt,
  });

  final String id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final SleepEntryType type;
  final int? quality;
  final String note;
  final SleepRecordSource source;
  final DateTime? createdAt;

  DateTime get date =>
      DateTime(bedtime.year, bedtime.month, bedtime.day);

  int get durationMinutes {
    final diff = wakeTime.difference(bedtime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  bool get isNightSleep => type == SleepEntryType.night;

  SleepRecord copyWith({
    DateTime? bedtime,
    DateTime? wakeTime,
    SleepEntryType? type,
    int? quality,
    String? note,
    SleepRecordSource? source,
    DateTime? createdAt,
    bool clearQuality = false,
  }) {
    return SleepRecord(
      id: id,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      type: type ?? this.type,
      quality: clearQuality ? null : (quality ?? this.quality),
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bedtime': bedtime.toIso8601String(),
    'wakeTime': wakeTime.toIso8601String(),
    'type': type.name,
    'quality': quality,
    'note': note,
    'source': source.name,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    final bedtime = json['bedtime'] != null
        ? DateTime.parse(json['bedtime'] as String)
        : DateTime.now();
    final wakeTime = json['wakeTime'] != null
        ? DateTime.parse(json['wakeTime'] as String)
        : bedtime;
    return SleepRecord(
      id: (json['id'] as String?) ?? 'sleep_${bedtime.microsecondsSinceEpoch}',
      bedtime: bedtime,
      wakeTime: wakeTime,
      type: SleepEntryType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SleepEntryType.night,
      ),
      quality: json['quality'] is int ? json['quality'] as int : null,
      note: (json['note'] as String?) ?? '',
      source: SleepRecordSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => SleepRecordSource.manual,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
