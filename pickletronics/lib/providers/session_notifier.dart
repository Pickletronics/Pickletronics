// lib/providers/session_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';

class SessionNotifier extends StateNotifier<List<Session>> {
  SessionNotifier() : super([]);

  Session? _currentSession;
  String? _currentSessionName;

  void processIncomingLine(String line) {
    if (line.startsWith('session') && line.endsWith('.txt')) {
      if (_currentSession != null) {
        _finalizeCurrentSession();
      }
      _startNewSession(line);
      return;
    }

    if (line == 'end-of-file') {
      _currentSession?.addLog(line);
      _finalizeCurrentSession();
      return;
    }

    if (_currentSession != null) {
      _currentSession!.addLog(line);
    }
  }

  void _startNewSession(String sessionLine) {
    _currentSessionName = sessionLine;
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentSession = Session(
      id: sessionId,
      startTime: DateTime.now(),
      logs: [],
    );
    _currentSession!.addLog('Starting $sessionLine');
  }

  void _finalizeCurrentSession() {
    if (_currentSession == null) return;

    final finishedSession = _currentSession!;
    finishedSession.endTime = DateTime.now();

    if (finishedSession.logs.isNotEmpty &&
        finishedSession.logs.last == 'end-of-file') {
      state = [...state, finishedSession];
      print('Session "${_currentSessionName ?? ""}" completed with ${finishedSession.logs.length} lines.');
    } else {
      print('Discarding session "${_currentSessionName ?? ""}" due to missing termination marker.');
    }

    _currentSession = null;
    _currentSessionName = null;
  }

  void resetAll() {
    _currentSession = null;
    _currentSessionName = null;
    state = [];
  }
}
