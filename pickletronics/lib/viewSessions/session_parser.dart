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
  final String sessionCounterPath = '/storage/emulated/0/Download/session_counter.json'; // Stores last session number
  final String sessionJsonPath =
      '/storage/emulated/0/Download/sessions.json'; // JSON storage

  Future<int> getLastSessionNumber() async {
  final file = File(sessionCounterPath);
  if (await file.exists()) {
    String content = await file.readAsString();
    return int.tryParse(content) ?? 0;
  }
  return 0;
}

  Future<List<Session>> parseFile() async {
    final file = File(logFilePath);
    if (!await file.exists()) {
      print("Log file does not exist.");
      return [];
    }

    String fileContent = await file.readAsString();
    print("Raw file content:\n$fileContent");

    int lastSessionNumber = await getLastSessionNumber();
    List<Session> parsedSessions = parse(fileContent, lastSessionNumber);
    print("Parsed sessions: ${parsedSessions.map((s) => s.toJson()).toList()}");

    if (parsedSessions.isEmpty) {
      print("No sessions were parsed.");
    } else {
      print("Parsed ${parsedSessions.length} sessions.");
      lastSessionNumber += parsedSessions.length;
      await saveLastSessionNumber(lastSessionNumber);
      await saveSessions(parsedSessions);
    }

    return parsedSessions;
  }


List<Session> parse(String fileContent, int startingSessionNumber) {
  print("Parsing log file...");
  List<Session> sessions = [];
  Session? currentSession;
  List<ImpactData> currentImpacts = [];
  int sessionNumber = startingSessionNumber;

  fileContent = fileContent.replaceAll(RegExp(r'\n+'), ' ').trim();

  RegExp sessionStartRegex = RegExp(r'(\d+)\s+New Impact Data');
  RegExp impactRegex = RegExp(
      r"Impact Array:\s*\[(.*?)\]\s*Impact Strength:\s*([\d.]+)\s*Impact Rotation:\s*([\d.]+)\s*Max Rotation:\s*([\d.]+)");
  RegExp endOfSessionRegex = RegExp(r"End of file reached\.");
  RegExp allSessionsDumpedRegex = RegExp(r"Dumped all sessions\.");

  int currentIndex = 0;
  while (currentIndex < fileContent.length) {
    Match? sessionMatch = sessionStartRegex.firstMatch(fileContent.substring(currentIndex));
    if (sessionMatch != null) {
      print("Detected new session: ${sessionMatch.group(1)!}, Assigning Global Session $sessionNumber");

      if (currentSession != null && currentImpacts.isNotEmpty) {
        currentSession.impacts.addAll(currentImpacts);
        sessions.add(currentSession);
        sessionNumber++;
      }

      currentSession = Session(impacts: []);
      currentImpacts = [];

      currentIndex += sessionMatch.end;
      continue;
    }

    Match? impactMatch = impactRegex.firstMatch(fileContent.substring(currentIndex));
    if (impactMatch != null) {
      print("Impact data found for session $sessionNumber");

      String impactArrayStr = impactMatch.group(1) ?? "";
      List<double> impactArray = impactArrayStr.isNotEmpty
          ? impactArrayStr.split(',').map((e) => double.tryParse(e.trim()) ?? 0.0).toList()
          : [];

      double impactStrength = double.tryParse(impactMatch.group(2) ?? "0.0") ?? 0.0;
      double impactRotation = double.tryParse(impactMatch.group(3) ?? "0.0") ?? 0.0;
      double maxRotation = double.tryParse(impactMatch.group(4) ?? "0.0") ?? 0.0;

      currentImpacts.add(
        ImpactData(
          impactArray: impactArray,
          impactStrength: impactStrength,
          impactRotation: impactRotation,
          maxRotation: maxRotation,
        ),
      );

      currentIndex += impactMatch.end;
      continue;
    }

    Match? endMatch = endOfSessionRegex.firstMatch(fileContent.substring(currentIndex));
    if (endMatch != null) {
      print("End of session detected for session $sessionNumber.");

      if (currentSession != null) {
        currentSession.impacts.addAll(currentImpacts);
        sessions.add(currentSession);
        sessionNumber++;
      }

      currentSession = null;
      currentImpacts = [];

      currentIndex += endMatch.end;
      continue;
    }

    Match? dumpedMatch = allSessionsDumpedRegex.firstMatch(fileContent.substring(currentIndex));
    if (dumpedMatch != null) {
      print("No more sessions to process.");
      break;
    }

    currentIndex++;
  }

  if (currentSession != null && currentImpacts.isNotEmpty) {
    currentSession.impacts.addAll(currentImpacts);
    sessions.add(currentSession);
  }

  print("Total sessions parsed: ${sessions.length}");
  return sessions;
}

Future<void> saveLastSessionNumber(int lastSession) async {
  final file = File(sessionCounterPath);
  await file.writeAsString(lastSession.toString());
}


 Future<void> saveSessions(List<Session> newSessions) async {
  final file = File(sessionJsonPath);
  List<Session> existingSessions = [];

  if (await file.exists()) {
    String jsonString = await file.readAsString();
    List<dynamic> jsonData = jsonDecode(jsonString);
    existingSessions = jsonData.map((e) => Session.fromJson(e)).toList();
  }

  // Append new sessions
  existingSessions.addAll(newSessions);

  // Save the updated session list
  await file.writeAsString(jsonEncode(existingSessions));

  print("Saved ${newSessions.length} new sessions. Total: ${existingSessions.length}");
}


  Future<List<Session>> loadSessions() async {
    final file = File(sessionJsonPath);
    if (!await file.exists()) return [];

    String jsonString = await file.readAsString();
    List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((e) => Session.fromJson(e)).toList();
  }
}
