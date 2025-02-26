import 'package:flutter/material.dart';
import 'session_parser.dart';
import 'session_detail_view.dart';

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
      _sessions = sessions.reversed.toList(); // Reverse order: newest first
    });
  }

  // Refresh sessions when coming back to the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSessions(); // Reload sessions every time UI is shown
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
                int displayedSessionNumber = _sessions.length - index;
                
                return ListTile(
                  title: Text("Session $displayedSessionNumber"),
                  subtitle: Text("Impacts: ${_sessions[index].impacts.length}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionDetailsPage(
                          session: _sessions[index], 
                          displayedSessionNumber: displayedSessionNumber,  // ✅ Pass correct session number
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
