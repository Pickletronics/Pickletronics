import 'package:fl_chart/fl_chart.dart';
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
  // Calculate overall percentage as before
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
  double overallPercentage = totalImpacts > 0 ? (sweetSpotHits / totalImpacts * 100) : 0;
  int totalHits = allSessions.fold(0, (sum, session) => sum + session.impacts.length);
  int sweetHits = allSessions.fold(0, (prev, session) => prev + session.impacts.where((impact) => impact.isSweetSpot).length);
  int nonSweetHits = totalHits - sweetHits;

  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGoodHitCardWithBarChart(overallPercentage),
          const SizedBox(height: 12),
          _buildHighSpinShotsCard(),
          const SizedBox(height: 12),
          _buildStrongestShotCard(),
          const Divider(thickness: 2),
          const Text(
            "Total Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildTotalRow("Total Games Played", allSessions.length.toString()),
          _buildTotalRow("Total Minutes Played", "12m 34s"),    // TODO: parse for this value
          _buildTotalRow("Total Hits Recorded", totalHits.toString()),
          _buildTotalRow("Total Sweet Spot Hits Recorded", sweetHits.toString()),
          _buildTotalRow("Total Mishits Recorded", nonSweetHits.toString()),
        ],
      ),
    ),
  );
}

Widget _buildGoodHitCardWithBarChart(double overallPercentage) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section: Good Hit % info
          Row(
            children: [
              Image.asset("assets/bullseye_icon.png", width: 50, height: 50),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${overallPercentage.toStringAsFixed(0)}%",
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  const Text("Total Sweet Spot Hits",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom section: Bar Chart showing last 5 sessions
          _buildLastSessionsBarChartContent(),
        ],
      ),
    ),
  );
}

Widget _buildLastSessionsBarChartContent() {
  // Determine how many sessions to display (up to 5)
  final int count = allSessions.length >= 5 ? 5 : allSessions.length;
  // Sort sessions by timestamp (oldest first)
  List<Session> sortedSessions = List.from(allSessions)
    ..sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
  final List<Session> lastSessions =
      sortedSessions.sublist(sortedSessions.length - count);

  // Create a BarChartGroupData for each session
  List<BarChartGroupData> barGroups = [];
  for (int i = 0; i < lastSessions.length; i++) {
    final session = lastSessions[i];
    int total = session.impacts.length;
    int sweet = session.impacts.where((impact) => impact.isSweetSpot).length;
    double perc = total > 0 ? sweet / total * 100 : 0;
    barGroups.add(
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: perc,
            width: 16,
            color: Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  return SizedBox(
    height: 275,
    child: Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 12.0, right: 12.0, bottom: 12.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                "Most Recent Sessions",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text('S${value.toInt() + 1}');
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameSize: 40,
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(bottom: 1.0),
                child: const Text(
                  "Sweet Spot Hit Percentage (%)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                interval: 20,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text('${value.toInt()}%'),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
    ),
  );
}

  // Existing cards for High Spin Shots, Strongest Shot, and Totals Row...
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