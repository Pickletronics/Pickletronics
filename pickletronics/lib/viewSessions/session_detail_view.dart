import 'package:flutter/material.dart';
import 'session_parser.dart';

class SessionDetailsPage extends StatelessWidget {
  final Session session;
  final int displayedSessionNumber;

  const SessionDetailsPage({Key? key, required this.session, required this.displayedSessionNumber})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Session $displayedSessionNumber Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Session Number: ${displayedSessionNumber}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Total Impacts: ${session.impacts.length}", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text("Impact Data:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...session.impacts.asMap().entries.map((entry) {
              int index = entry.key + 1;
              Impact impact = entry.value;
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Impact #$index", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Max Rotation: ${impact.maxRotation}"),
                      Text("Impact Rotation: ${impact.impactRotation}"),
                      Text("Impact Strength: ${impact.impactStrength}"),
                      const SizedBox(height: 5),
                      Text("Impact Array: ${impact.impactArray.join(', ')}"),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
