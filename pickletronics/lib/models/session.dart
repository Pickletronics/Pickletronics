import 'impact.dart';

class Session {
  final String id;
  final String sessionName;
  final DateTime startTime;
  DateTime? endTime;
  final List<String> logs;
  final List<Impact> impacts;

  Session({
    required this.id,
    required this.sessionName,
    required this.startTime,
    this.endTime,
    List<String>? logs,
    List<Impact>? impacts,
  })  : logs = logs ?? [],
        impacts = impacts ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionName': sessionName,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'logs': logs,
    'impacts': impacts.map((impact) => impact.toJson()).toList(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    sessionName: json['sessionName'] ?? '',
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    logs: List<String>.from(json['logs'] ?? []),
    impacts: (json['impacts'] as List<dynamic>?)
        ?.map((impactJson) => Impact.fromJson(impactJson as Map<String, dynamic>))
        .toList() ??
        [],
  );

  @override
  String toString() {
    return 'Session(id: $id, name: $sessionName, start: $startTime, end: $endTime, logs: $logs, impacts: $impacts)';
  }
}
