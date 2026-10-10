class DistractionCapture {
  DistractionCapture({
    required this.id,
    required this.thought,
    required this.capturedAt,
    this.sessionId,
    this.category = 'Other',
    this.resolved = false,
  });

  final String id;
  final String thought;
  final DateTime capturedAt;
  final String? sessionId;
  final String category;
  bool resolved;

  static const categories = [
    'Social',
    'Entertainment',
    'Games',
    'Shopping',
    'News',
    'Email',
    'Messages',
    'Other',
  ];

  String get categoryLabel {
    switch (category) {
      case 'Social':
        return 'Social';
      case 'Entertainment':
        return 'Entertainment';
      case 'Games':
        return 'Games';
      case 'Shopping':
        return 'Shopping';
      case 'News':
        return 'News';
      case 'Email':
        return 'Email';
      case 'Messages':
        return 'Messages';
      default:
        return 'Other';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'thought': thought,
    'capturedAt': capturedAt.toIso8601String(),
    'sessionId': sessionId,
    'category': category,
    'resolved': resolved,
  };

  factory DistractionCapture.fromJson(Map<String, dynamic> json) =>
      DistractionCapture(
        id: json['id'] as String,
        thought: json['thought'] as String? ?? '',
        capturedAt: json['capturedAt'] != null
            ? DateTime.parse(json['capturedAt'] as String)
            : DateTime.now(),
        sessionId: json['sessionId'] as String?,
        category: json['category'] as String? ?? 'Other',
        resolved: json['resolved'] as bool? ?? false,
      );
}

class FocusCheckpoint {
  FocusCheckpoint({
    required this.id,
    required this.sessionId,
    required this.elapsed,
    required this.timestamp,
    this.assessment = 'onTrack',
    this.note = '',
  });

  final String id;
  final String sessionId;
  final Duration elapsed;
  final DateTime timestamp;
  String assessment;
  String note;

  static const assessments = ['onTrack', 'needMoreTime', 'finishedEarly'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'elapsed': elapsed.inSeconds,
    'timestamp': timestamp.toIso8601String(),
    'assessment': assessment,
    'note': note,
  };

  factory FocusCheckpoint.fromJson(Map<String, dynamic> json) =>
      FocusCheckpoint(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        elapsed: Duration(seconds: (json['elapsed'] as int?) ?? 0),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        assessment: json['assessment'] as String? ?? 'onTrack',
        note: json['note'] as String? ?? '',
      );
}

class FocusInsight {
  FocusInsight({
    required this.id,
    required this.text,
    this.type = 'insight',
    this.data = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String text;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FocusInsight.fromJson(Map<String, dynamic> json) => FocusInsight(
    id: json['id'] as String,
    text: json['text'] as String? ?? '',
    type: json['type'] as String? ?? 'insight',
    data: Map<String, dynamic>.from(json['data'] ?? {}),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
  );
}
