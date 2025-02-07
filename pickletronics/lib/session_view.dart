import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/session_provider.dart';

class SessionsView extends ConsumerWidget {
  const SessionsView({Key? key}) : super(key: key);

  List<String> getSessionData(List<String> logs) {
    return logs.where((log) =>
    log.contains(',') &&
        !RegExp(r'^\d+$').hasMatch(log) &&
        log != 'End of file reached.' &&
        log != 'Dumped all sessions.'
    ).toList();
  }

  String getSessionNumber(List<String> logs) {
    String? sessionNum = logs.firstWhere(
            (log) => RegExp(r'^\d+$').hasMatch(log),
        orElse: () => '-1'
    );
    return 'Session $sessionNum';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionProvider);

    if (sessions.isEmpty) {
      return const Center(child: Text('No sessions received yet.'));
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final dataLines = getSessionData(session.logs);

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(getSessionNumber(session.logs)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...dataLines.map((line) {
                      final values = line.split(',');
                      if (values.length >= 3) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'X: ${values[0]}, Y: ${values[1]}, Z: ${values[2]}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        );
                      }
                      return Text(line);
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}