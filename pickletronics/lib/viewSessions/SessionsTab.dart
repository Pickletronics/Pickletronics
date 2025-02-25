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
    _sessions = sessions.reversed.toList();  // Reverse order: newest first
  });
  print("Loaded ${_sessions.length} sessions in reversed order.");
}

// Refresh sessions when coming back to the screen
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadSessions();  // Reload sessions every time UI is shown
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sessions")),
      body: _sessions.isEmpty
          ? Center(child: Text("No sessions recorded."))
          : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                // Reverse session numbering so Session 1 is the newest
                int displayedSessionNumber = _sessions.length - index;
                
                return ListTile(
                  title: Text("Session $displayedSessionNumber"),
                  subtitle: Text("Impacts: ${_sessions[index].impacts.length}"),
                  onTap: () {
                    _showSessionDetails(_sessions[index]);
                  },
                );
              },
            ),
    );
  }

  void _showSessionDetails(Session session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Session Details"),
          content: Text("Session Data: ${session.toJson()}"),
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
