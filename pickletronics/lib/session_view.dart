import 'dart:io';
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
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _processFile();
  }

  /// Reads the actual file contents from `bluetooth_log.txt` and parses them
  /// into [Session] and [Impact] objects via SessionParser.
  Future<void> _processFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final file = File('/storage/emulated/0/Download/bluetooth_log.txt');
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Log file not found in Downloads folder.';
        });
        return;
      }

      // Read the entire file as a single String, then split by lines.
      final fileContent = await file.readAsString();
      final lines = fileContent.split('\n');

      // Process each line with the SessionParser
      for (final line in lines) {
        sessionParser.processIncomingLine(line.trim());
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error reading/parsing file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = sessionParser.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : sessions.isEmpty
          ? const Center(child: Text('No sessions found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, sessionIndex) {
          final session = sessions[sessionIndex];
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
                // You can customize the date/time formatting as needed:
                'Recorded on ${session.startTime} • '
                    '${session.impacts.length} impacts',
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
