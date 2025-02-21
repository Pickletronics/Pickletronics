import '/models/session.dart';
import '/models/impact.dart';

enum ImpactParseField { none, accelerationArray, impactStrength, impactRotation, maxRotation }

class SessionParser {
  List<Session> sessions = [];
  Session? _currentSession;
  ImpactBuilder? _currentImpact;
  ImpactParseField _expectedField = ImpactParseField.none;

  void processIncomingLine(String rawLine) {
    final line = rawLine.replaceAll('\r', '').trim();
    if (line.isEmpty) return;

    // End markers.
    if (line == "End of file reached." || line == "Dumped all sessions.") {
      if (_currentImpact != null && _currentImpact!.isComplete) {
        _currentSession?.impacts.add(_currentImpact!.build());
        _currentImpact = null;
        _expectedField = ImpactParseField.none;
      }
      if (_currentSession != null) {
        _currentSession!.endTime = DateTime.now();
        if (_currentSession!.impacts.isNotEmpty) {
          sessions.add(_currentSession!);
        }
        _currentSession = null;
      }
      return;
    }

    // New session marker (line with only digits)
    if (RegExp(r'^\d+$').hasMatch(line)) {
      if (_currentImpact != null && _currentImpact!.isComplete) {
        _currentSession?.impacts.add(_currentImpact!.build());
        _currentImpact = null;
        _expectedField = ImpactParseField.none;
      }
      if (_currentSession != null) {
        _currentSession!.endTime = DateTime.now();
        if (_currentSession!.impacts.isNotEmpty) {
          sessions.add(_currentSession!);
        }
      }
      _currentSession = Session(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionName: line,
        startTime: DateTime.now(),
        logs: [line],
        impacts: [],
      );
      return;
    }

    // Impact markers.
    if (line == "New Impact Data:") {
      if (_currentImpact != null && _currentImpact!.isComplete) {
        _currentSession?.impacts.add(_currentImpact!.build());
      }
      _currentImpact = ImpactBuilder();
      _expectedField = ImpactParseField.none;
      return;
    }
    if (line == "Acceleration Magnitude Array:") {
      _currentImpact ??= ImpactBuilder();
      _expectedField = ImpactParseField.accelerationArray;
      return;
    }
    if (line == "Impact Strength:") {
      _currentImpact ??= ImpactBuilder();
      _expectedField = ImpactParseField.impactStrength;
      return;
    }
    if (line == "Impact Rotation:") {
      _currentImpact ??= ImpactBuilder();
      _expectedField = ImpactParseField.impactRotation;
      return;
    }
    if (line == "Max Rotation:") {
      _currentImpact ??= ImpactBuilder();
      _expectedField = ImpactParseField.maxRotation;
      return;
    }

    // Process field values.
    if (_expectedField == ImpactParseField.accelerationArray) {
      final trimmed = line.replaceAll(RegExp(r'[\[\]]'), '');
      final parts = trimmed.split(',');
      List<double> acceleration = [];
      for (var part in parts) {
        part = part.trim();
        if (part.isNotEmpty) {
          double? value = double.tryParse(part);
          if (value != null) acceleration.add(value);
        }
      }
      _currentImpact?.acceleration = acceleration;
      _expectedField = ImpactParseField.none;
      return;
    }
    if (_expectedField == ImpactParseField.impactStrength) {
      double? strength = double.tryParse(line);
      if (strength != null) _currentImpact?.strength = strength;
      _expectedField = ImpactParseField.none;
      return;
    }
    if (_expectedField == ImpactParseField.impactRotation) {
      double? rotation = double.tryParse(line);
      if (rotation != null) _currentImpact?.rotation = rotation;
      _expectedField = ImpactParseField.none;
      return;
    }
    if (_expectedField == ImpactParseField.maxRotation) {
      double? maxRotation = double.tryParse(line);
      if (maxRotation != null) _currentImpact?.maxRotation = maxRotation;
      _expectedField = ImpactParseField.none;
      return;
    }
    _currentSession?.logs.add(line);
  }
}

class ImpactBuilder {
  List<double>? acceleration;
  double? strength;
  double? rotation;
  double? maxRotation;

  bool get isComplete =>
      acceleration != null && strength != null && rotation != null && maxRotation != null;

  Impact build() {
    if (!isComplete) throw Exception("Incomplete impact data");
    return Impact(
      accelerationMagnitudes: acceleration!,
      impactStrength: strength!,
      impactRotation: rotation!,
      maxRotation: maxRotation!,
    );
  }
}
