import 'package:flutter/foundation.dart';

@immutable
class SleepSummary {
  const SleepSummary({
    required this.hasData,
    this.lastNightMinutes,
    this.lastNightBedtime,
    this.lastNightWake,
    this.averageNightMinutes,
    this.nightsLogged = 0,
    this.consistencyDays = 0,
  });

  final bool hasData;
  final int? lastNightMinutes;
  final DateTime? lastNightBedtime;
  final DateTime? lastNightWake;
  final int? averageNightMinutes;
  final int nightsLogged;
  final int consistencyDays;

  static const empty = SleepSummary(hasData: false);

  String get lastNightLabel {
    final minutes = lastNightMinutes;
    if (minutes == null) return 'No sleep logged';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String get averageLabel {
    final minutes = averageNightMinutes;
    if (minutes == null) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
