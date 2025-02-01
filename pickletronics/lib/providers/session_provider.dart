// lib/providers/session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_notifier.dart';
import '../models/session.dart';

final sessionProvider =
StateNotifierProvider<SessionNotifier, List<Session>>((ref) {
  return SessionNotifier();
});