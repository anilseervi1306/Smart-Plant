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
    return Scaffold(
      appBar: AppBar(title: const Text('My Smart Plant')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('readings')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading data'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No data available'));
          
          final data = docs.first.data() as Map<String, dynamic>;
          final moisture = data['soil_moisture'] ?? 0.0;
          final temp = data['temperature'] ?? 0.0;
          final prediction = data['prediction'] ?? 'Unknown';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(moisture),
                const SizedBox(height: 20),
                _buildSensorGrid(moisture, temp, data),
                const SizedBox(height: 20),
                const Text("Soil Moisture History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Expanded(child: HistoryChart()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(double moisture) {
    String message = "I am Feeling Great!";
    Color color = Colors.green;
    if (moisture < 20) {
      message = "I am Thirsty!";
      color = Colors.orange;
    } else if (moisture > 80) {
      message = "Too much water!";
      color = Colors.blue;
    }
    
    return Card(
      color: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.spa, size: 60, color: color),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(double moisture, double temp, Map<String, dynamic> data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _sensorCard("Moisture", "${moisture.toStringAsFixed(1)}%", Icons.water_drop, Colors.blue),
        _sensorCard("Temp", "${temp.toStringAsFixed(1)}°C", Icons.thermostat, Colors.red),
        _sensorCard("Light", "${data['light_intensity'] ?? 0} lx", Icons.sunny, Colors.orange),
        _sensorCard("Humidity", "${data['humidity'] ?? 0}%", Icons.cloud, Colors.grey),
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
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
           spots.add(FlSpot(i.toDouble(), (data['soil_moisture'] as num).toDouble()));
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
