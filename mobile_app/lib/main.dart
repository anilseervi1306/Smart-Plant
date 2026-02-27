import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NOTE: User must add google-services.json (Android) / GoogleService-Info.plist (iOS)
  await Firebase.initializeApp();
  runApp(const SmartPlantApp());
}

class SmartPlantApp extends StatelessWidget {
  const SmartPlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant That Talks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('readings')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        int carePoints = 0;
        int healthScore = 100;
        double moisture = 0.0;
        double temp = 0.0;
        Map<String, dynamic> data = {};

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          moisture = (data['soil_moisture'] as num?)?.toDouble() ?? 0.0;
          temp = (data['temperature'] as num?)?.toDouble() ?? 0.0;
          healthScore = (data['health_score'] as num?)?.toInt() ?? 100;
          carePoints = (data['care_points'] as num?)?.toInt() ?? 0;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Smart Plant'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '$carePoints',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: snapshot.hasError
              ? const Center(child: Text('Error loading data'))
              : (!snapshot.hasData)
              ? const Center(child: CircularProgressIndicator())
              : (snapshot.data!.docs.isEmpty)
              ? const Center(child: Text('No data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAvatarCard(healthScore),
                      const SizedBox(height: 20),
                      _buildSensorGrid(moisture, temp, data),
                      const SizedBox(height: 20),
                      const Text(
                        "Soil Moisture History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Expanded(child: HistoryChart()),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAvatarCard(int healthScore) {
    String emoji = "🌿😊";
    String statusText = "I'm Feeling Great!";
    Color color = Colors.green;

    if (healthScore < 50) {
      emoji = "🥀🥵";
      statusText = "I need help!";
      color = Colors.red;
    } else if (healthScore < 80) {
      emoji = "🪴😐";
      statusText = "I'm doing okay.";
      color = Colors.orange;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 10),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  "Health Score: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: healthScore / 100,
                    backgroundColor: Colors.grey[300],
                    color: color,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "$healthScore/100",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(
    double moisture,
    double temp,
    Map<String, dynamic> data,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _sensorCard(
          "Moisture",
          "${moisture.toStringAsFixed(1)}%",
          Icons.water_drop,
          Colors.blue,
        ),
        _sensorCard(
          "Temp",
          "${temp.toStringAsFixed(1)}°C",
          Icons.thermostat,
          Colors.red,
        ),
        _sensorCard(
          "Light",
          "${data['light_intensity'] ?? 0} lx",
          Icons.sunny,
          Colors.orange,
        ),
        _sensorCard(
          "Humidity",
          "${data['humidity'] ?? 0}%",
          Icons.cloud,
          Colors.grey,
        ),
      ],
    );
  }

  Widget _sensorCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('readings')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        List<FlSpot> spots = [];

        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          // Simple index based x-axis for now
          spots.add(
            FlSpot(i.toDouble(), (data['soil_moisture'] as num).toDouble()),
          );
        }

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots.reversed.toList(),
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }
}
