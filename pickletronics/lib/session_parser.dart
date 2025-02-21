import 'dart:convert';
import 'dart:io';

class ImpactData {
  List<double> impactArray;
  double impactStrength;
  double impactRotation;
  double maxRotation;

  ImpactData({
    required this.impactArray,
    required this.impactStrength,
    required this.impactRotation,
    required this.maxRotation,
  });

  Map<String, dynamic> toJson() => {
        "impactArray": impactArray,
        "impactStrength": impactStrength,
        "impactRotation": impactRotation,
        "maxRotation": maxRotation,
      };

  factory ImpactData.fromJson(Map<String, dynamic> json) => ImpactData(
        impactArray: List<double>.from(json["impactArray"]),
        impactStrength: json["impactStrength"],
        impactRotation: json["impactRotation"],
        maxRotation: json["maxRotation"],
      );
}

class Session {
  List<ImpactData> impacts = [];

  Session({required this.impacts});

  Map<String, dynamic> toJson() => {
        "impacts": impacts.map((e) => e.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        impacts: (json["impacts"] as List)
            .map((e) => ImpactData.fromJson(e))
            .toList(),
      );
}

class SessionParser {
  final String logFilePath = '/storage/emulated/0/Download/bluetooth_log.txt';
  final String sessionJsonPath =
      '/storage/emulated/0/Download/sessions.json'; // JSON storage

  Future<List<Session>> parseFile() async {
    final file = File(logFilePath);
    if (!await file.exists()) return [];

    String fileContent = await file.readAsString();
    List<Session> parsedSessions = parse(fileContent);

    // Save parsed sessions
    await saveSessions(parsedSessions);
    return parsedSessions;
  }

  List<Session> parse(String fileContent) {
    List<Session> sessions = [];
    Session? currentSession;
    List<double> currentImpactArray = [];
    double? impactStrength, impactRotation, maxRotation;

    for (String line in fileContent.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line == "End of file reached.") {
        if (currentSession != null) {
          sessions.insert(0, currentSession); // Newest session first
        }
        currentSession = Session(impacts: []);
        continue;
      }

      if (line == "Dumped all sessions.") break;

      if (line.startsWith("New Impact Data:")) {
        if (currentImpactArray.isNotEmpty &&
            impactStrength != null &&
            impactRotation != null &&
            maxRotation != null) {
          currentSession?.impacts.insert(
            0,
            ImpactData(
              impactArray: List.from(currentImpactArray),
              impactStrength: impactStrength!,
              impactRotation: impactRotation!,
              maxRotation: maxRotation!,
            ),
          );
        }
        currentImpactArray = [];
        impactStrength = impactRotation = maxRotation = null;
        continue;
      }

      if (line.startsWith("Impact Strength:")) {
        impactStrength = double.tryParse(line.split(":")[1].trim());
        continue;
      }

      if (line.startsWith("Impact Rotation:")) {
        impactRotation = double.tryParse(line.split(":")[1].trim());
        continue;
      }

      if (line.startsWith("Max Rotation:")) {
        maxRotation = double.tryParse(line.split(":")[1].trim());
        continue;
      }

      RegExp regex = RegExp(r'[-+]?\d*\.?\d+');
      Iterable<Match> matches = regex.allMatches(line);
      for (Match match in matches) {
        currentImpactArray.add(double.parse(match.group(0)!));
      }
    }

    if (currentSession != null && currentSession.impacts.isNotEmpty) {
      sessions.insert(0, currentSession); // Keep newest first
    }

    return sessions;
  }

  Future<void> saveSessions(List<Session> sessions) async {
    final file = File(sessionJsonPath);
    await file.writeAsString(jsonEncode(sessions));
  }

  Future<List<Session>> loadSessions() async {
    final file = File(sessionJsonPath);
    if (!await file.exists()) return [];

    String jsonString = await file.readAsString();
    List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((e) => Session.fromJson(e)).toList();
  }
}
