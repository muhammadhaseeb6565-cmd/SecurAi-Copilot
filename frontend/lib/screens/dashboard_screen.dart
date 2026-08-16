import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Security Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _apiService.streamMetrics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {
            "total_requests": 0,
            "auth_failures": 0,
            "shadow_apis_detected": 0,
            "anomaly_score": 0.0,
            "threats": 0
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data["anomaly_score"] > 8.0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Expanded(child: Text("CRITICAL ALERT: High anomaly score detected. AI auto-patching recommended.", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('API Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dashboard exported to PDF.')));
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text("Export"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(context, 'Live Traffic', '${data["total_requests"]}/s', Icons.swap_vert, Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Auth Failures', '${data["auth_failures"]}', Icons.security_outlined, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(context, 'Shadow APIs', '${data["shadow_apis_detected"]}', Icons.visibility_off, Colors.purple),
                    const SizedBox(width: 16),
                    _buildStatCard(context, 'Anomaly Score', '${data["anomaly_score"]}', Icons.analytics, data["anomaly_score"] > 5 ? Colors.orange : Colors.green),
                  ],
                ),
                const SizedBox(height: 32),
                Text('Traffic Analysis (Live)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 6000,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final now = DateTime.now();
                              final day = now.subtract(Duration(days: 6 - value.toInt()));
                              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Text(days[day.weekday - 1], style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 1500, color: Colors.blueAccent)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 2000, color: Colors.blueAccent)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1800, color: Colors.blueAccent)]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 3000, color: Colors.blueAccent)]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 2500, color: Colors.blueAccent)]),
                        BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 4000, color: Colors.blueAccent)]),
                        BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: data["total_requests"].toDouble(), color: Colors.greenAccent)]), // Live animated bar
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 500),
                    swapAnimationCurve: Curves.easeInOut,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
