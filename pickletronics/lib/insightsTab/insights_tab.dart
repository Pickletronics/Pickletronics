import 'package:flutter/material.dart';
import 'package:pickletronics/viewSessions/session_parser.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  _InsightsTabState createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  List<Session> allSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    List<Session> sessions = await SessionParser().loadSessions();
    setState(() {
      allSessions = sessions;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Compute total impacts and sweet spot hits from all sessions
    int totalImpacts = 0;
    int sweetSpotHits = 0;
    for (final session in allSessions) {
      for (final impact in session.impacts) {
        totalImpacts++;
        if (impact.isSweetSpot) {
          sweetSpotHits++;
        }
      }
    }
    double percentage = totalImpacts > 0 ? (sweetSpotHits / totalImpacts * 100) : 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGoodHitCard(percentage),
          const SizedBox(height: 12),
          _buildHighSpinShotsCard(),
          const SizedBox(height: 12),
          _buildStrongestShotCard(),
          const Spacer(),
          const Divider(thickness: 2),
          const Text(
            "Total Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildTotalRow("Total Hits", "143"),
          _buildTotalRow("Total Time", "12m 34s"),
          _buildTotalRow("Calories Burned", "97 kcal"),
        ],
      ),
    );
  }

  // Good Hit % card
  Widget _buildGoodHitCard(double percentage) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Image.asset("assets/bullseye_icon.png", width: 50, height: 50),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${percentage.toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                const Text("Good Hit %",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // High Spin Shots card
  Widget _buildHighSpinShotsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("High Spin Shots",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("27", style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  // Strongest Shot card
  Widget _buildStrongestShotCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Strongest Shot",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Backhand Drive – 62mph", style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }

  // Totals row widget
  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}