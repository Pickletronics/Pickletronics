import 'package:flutter/material.dart';
import 'session_parser.dart';

class SessionsTab extends StatefulWidget {
  const SessionsTab({super.key});

  @override
  _SessionsTabState createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  List<Session> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    List<Session> sessions = await SessionParser().loadSessions();
    setState(() {
      _sessions = sessions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Session $index'),
          subtitle: Text('${_sessions[index].impacts.length} impacts recorded'),
          onTap: () => _showSessionDetails(_sessions[index]),
        );
      },
    );
  }

  void _showSessionDetails(Session session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Session Details"),
          content: Text("Impacts: ${session.impacts.length}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }
}
