// lib/models/session.dart
class Session {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<String> logs;

  Session({
    required this.id,
    required this.startTime,
    this.endTime,
    List<String>? logs,
  }) : logs = logs ?? [];

  void addLog(String log) {
    logs.add(log);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'logs': logs,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null
        ? DateTime.parse(json['endTime'])
        : null,
    logs: List<String>.from(json['logs'] ?? []),
  );

  @override
  String toString() {
    return 'Session(id: $id, start: $startTime, end: $endTime, logs: $logs)';
  }
}
