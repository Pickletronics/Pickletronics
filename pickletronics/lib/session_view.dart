// lib/sessions_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/session_provider.dart';

class SessionsView extends ConsumerWidget {
  const SessionsView({Key? key}) : super(key: key);

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
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('Session ID: ${session.id}'),
            subtitle: Text('Lines: ${session.logs.length}\n'
                'Started: ${session.startTime}\n'
                'Ended: ${session.endTime ?? "N/A"}'),
            isThreeLine: true,
            onTap: () {
            },
          ),
        );
      },
    );
  }
}