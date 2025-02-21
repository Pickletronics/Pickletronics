import 'package:flutter/material.dart';
import 'session_parser.dart'; // Contains SessionParser and ImpactBuilder
import '/models/impact_graph.dart';

class SessionsView extends StatefulWidget {
  const SessionsView({Key? key}) : super(key: key);
  @override
  _SessionsViewState createState() => _SessionsViewState();
}

class _SessionsViewState extends State<SessionsView> {
  final SessionParser sessionParser = SessionParser();

  // Simulated file processing. Replace with your actual file reading logic.
  Future<void> _processFile() async {
    final List<String> lines = await Future.delayed(
      const Duration(seconds: 1),
          () => [
        "0",
        "New Impact Data:",
        "Acceleration Magnitude Array:",
        "[7.1,7.2,7.3]",
        "Impact Strength:",
        "0.5",
        "Impact Rotation:",
        "1.0",
        "Max Rotation:",
        "1.5",
        "Dumped all sessions."
      ],
    );
    for (final line in lines) {
      sessionParser.processIncomingLine(line);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _processFile();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = sessionParser.sessions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
      ),
      body: sessions.isEmpty
          ? const Center(child: Text('No sessions found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, sessionIndex) {
          final session = sessionParser.sessions[sessionIndex];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Session ${session.sessionName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Recorded on ${session.startTime} • ${session.impacts.length} impacts',
                style: const TextStyle(fontSize: 14),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Impact Analysis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (int i = 0; i < session.impacts.length; i++) ...[
                        SizedBox(
                          height: 400,
                          child: ImpactGraph(
                            data: session.impacts[i].accelerationMagnitudes,
                            title: 'Impact ${i + 1}',
                            color: i.isEven ? Colors.blue : Colors.purple,
                            impactStrength: session.impacts[i].impactStrength,
                            impactRotation: session.impacts[i].impactRotation,
                            isSweetSpot: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
