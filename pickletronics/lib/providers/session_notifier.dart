import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';

class SessionNotifier extends StateNotifier<List<Session>> {
  SessionNotifier() : super([]);

  Session? _currentSession;

  void processIncomingLine(String rawLine) {
    final line = rawLine.replaceAll('\r', '').trim();

    if (line.isEmpty) {
      return;
    }

    if (line == "End of file reached.") {
      if (_currentSession != null) {
        _finalizeAndSaveSession(_currentSession!);
        _currentSession = null;
      }
      return;
    }

    if (RegExp(r'^\d+$').hasMatch(line)) {
      if (_currentSession != null) {
        _finalizeAndSaveSession(_currentSession!);
      }
      _startNewSession(line);
      return;
    }

    if (line.contains(',')) {
      if (_currentSession == null) {
        String sessionNum = state.length.toString();
        _startNewSession(sessionNum);
      }
      _currentSession!.addLog(line);
    }

    if (line == "Dumped all sessions.") {
      if (_currentSession != null) {
        _finalizeAndSaveSession(_currentSession!);
        _currentSession = null;
      }
    }
  }

  void _startNewSession(String sessionNumber) {
    _currentSession = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionName: sessionNumber,
      startTime: DateTime.now(),
      logs: [sessionNumber],
    );
  }

  void _finalizeAndSaveSession(Session session) {
    try {
      session.endTime = DateTime.now();

      final dataLines = session.logs.where((log) =>
      log.contains(',') &&
          !RegExp(r'^\d+$').hasMatch(log)
      ).toList();

      if (dataLines.isNotEmpty) {
        state = [...state, session];
      }
    } catch (e, st) {
      // Error handling can be added here if needed
    }
  }

  void resetAll() {
    _currentSession = null;
    state = [];
  }
}