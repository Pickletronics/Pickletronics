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
    if (!await file.exists()) {
      print("Log file does not exist.");
      return [];
    }

    String fileContent = await file.readAsString();
    print("Raw file content:\n$fileContent");  // Debug print

    List<Session> parsedSessions = parse(fileContent);
    print("Parsed sessions: ${parsedSessions.map((s) => s.toJson()).toList()}");

    if (parsedSessions.isEmpty) {
      print("No sessions were parsed.");
    } else {
      print("Parsed ${parsedSessions.length} sessions.");
    }

    await saveSessions(parsedSessions);
    return parsedSessions;
  }

List<Session> parse(String fileContent) {
  print("Parsing log file...");
  List<Session> sessions = [];
  Session? currentSession;
  List<double> currentImpactArray = [];
  double? impactStrength, impactRotation, maxRotation;
  int? sessionNumber;

  // Normalize file content by replacing newline variations with a single space
  fileContent = fileContent.replaceAll(RegExp(r'\n+'), ' ').trim();

  // Regex to detect a new session start
  RegExp sessionStartRegex = RegExp(r'(\d+)\s+New Impact Data');
  
  // Regex to extract impact values
  RegExp impactRegex = RegExp(
      r"Impact Array:\s*\[(.*?)\]\s*Impact Strength:\s*([\d.]+)\s*Impact Rotation:\s*([\d.]+)\s*Max Rotation:\s*([\d.]+)");

  // Regex to detect session end
  RegExp endOfSessionRegex = RegExp(r"End of file reached\.");

  // Regex to detect all sessions dumped
  RegExp allSessionsDumpedRegex = RegExp(r"Dumped all sessions\.");

  // Process the entire text
  int currentIndex = 0;
  while (currentIndex < fileContent.length) {
    // Detect new session
    Match? sessionMatch = sessionStartRegex.firstMatch(fileContent.substring(currentIndex));
    if (sessionMatch != null) {
      int newSessionNumber = int.parse(sessionMatch.group(1)!);
      print("Detected new session: $newSessionNumber");

      // If a previous session exists, save it before starting a new one
      if (currentSession != null && currentSession.impacts.isNotEmpty) {
        sessions.insert(0, currentSession);
      }

      // Start a new session
      sessionNumber = newSessionNumber;
      currentSession = Session(impacts: []);
      currentIndex += sessionMatch.end;
      continue;
    }

    // Detect impact data
    Match? impactMatch = impactRegex.firstMatch(fileContent.substring(currentIndex));
    if (impactMatch != null) {
      print("Impact data found.");

      // Extract impact array
      String impactArrayStr = impactMatch.group(1)!;
      List<double> impactArray = impactArrayStr.split(',').map((e) => double.parse(e.trim())).toList();

      // Extract individual impact parameters
      impactStrength = double.parse(impactMatch.group(2)!);
      impactRotation = double.parse(impactMatch.group(3)!);
      maxRotation = double.parse(impactMatch.group(4)!);

      // Add impact data to session
      currentSession?.impacts.insert(
        0,
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

    // Detect session end
    Match? endMatch = endOfSessionRegex.firstMatch(fileContent.substring(currentIndex));
    if (endMatch != null) {
      print("End of session detected.");

      if (currentSession != null) {
        sessions.insert(0, currentSession);
      }

      currentSession = null; // Reset session
      currentIndex += endMatch.end;
      continue;
    }

    // Detect all sessions dumped
    Match? dumpedMatch = allSessionsDumpedRegex.firstMatch(fileContent.substring(currentIndex));
    if (dumpedMatch != null) {
      print("No more sessions to process.");
      break;
    }

    currentIndex++; // Move forward if no match is found
  }

  // Add the last session if it exists and contains impacts
  if (currentSession != null && currentSession.impacts.isNotEmpty) {
    sessions.insert(0, currentSession);
  }

  print("Total sessions parsed: ${sessions.length}");
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
