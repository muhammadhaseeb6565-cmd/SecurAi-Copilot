import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'github_pr_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _systemMetrics;
  final _shodanController = TextEditingController();
  Map<String, dynamic>? _shodanResult;
  bool _isShodanLoading = false;
  bool _isDeepScanning = false;

  StreamSubscription? _metricsSub;
  Map<String, dynamic> _streamData = {
    "total_requests": 0,
    "auth_failures": 0,
    "shadow_apis_detected": 0,
    "anomaly_score": 0.0,
    "threats": 0
  };
  Timer? _healthTimer;
  List<FlSpot> _trafficSpots = [const FlSpot(0, 0)];
  double _graphX = 0;
  
  final List<Map<String, dynamic>> _liveAlerts = [];

  @override
  void initState() {
    super.initState();
    _fetchSystemMetrics();
    _healthTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchSystemMetrics());
    
    _metricsSub = _apiService.streamMetrics().listen((data) {
      if (mounted) {
        setState(() {
          _streamData = data;
          _graphX += 1;
          _trafficSpots.add(FlSpot(_graphX, (data["total_requests"] ?? 0) / 1000.0));
          if (_trafficSpots.length > 10) {
            _trafficSpots.removeAt(0);
          }
          _generateLiveAlerts(data);
        });
      }
    });
  }

  void _generateLiveAlerts(Map<String, dynamic> data) {
    final anomaly = data['anomaly_score'] ?? 0.0;
    final authFails = data['auth_failures'] ?? 0;
    final shadow = data['shadow_apis_detected'] ?? 0;

    String? type;
    String? message;
    Color? color;

    if (anomaly > 8.0) {
      type = 'CRITICAL';
      message = 'High anomaly score spike: $anomaly';
      color = Colors.redAccent;
    } else if (authFails > 60) {
      type = 'WARNING';
      message = 'Unusual auth failures: $authFails';
      color = Colors.orangeAccent;
    } else if (shadow > 3) {
      type = 'INFO';
      message = 'Unregistered API endpoints hit: $shadow';
      color = Colors.cyanAccent;
    }

    if (type != null && message != null && color != null) {
      // Prevent spamming the exact same message back to back
      if (_liveAlerts.isEmpty || _liveAlerts.first['message'] != message) {
        _liveAlerts.insert(0, {
          'type': type,
          'message': message,
          'color': color,
          'time': "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}"
        });
        if (_liveAlerts.length > 5) {
          _liveAlerts.removeLast();
        }
      }
    }
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    _metricsSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchSystemMetrics() async {
    final metrics = await ApiService.fetchSystemMetrics();
    if (metrics != null && mounted) {
      setState(() {
        _systemMetrics = metrics;
      });
    }
  }

  Future<void> _runShodanScan() async {
    final ip = _shodanController.text.trim();
    if (ip.isEmpty) return;

    setState(() {
      _isShodanLoading = true;
      _shodanResult = null;
    });

    // We use a hardcoded API key for the UI demo if the user hasn't set one in settings
    final result = await ApiService.shodanScan(ip, 'YOUR_SHODAN_API_KEY');
    
    setState(() {
      _isShodanLoading = false;
      _shodanResult = result ?? {'error': 'Failed to connect or invalid API key.'};
    });
  }

  void _runDeepScan() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
  }

  void _runBreachScan() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => DataBreachScreen()));
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.cyanAccent),
                  SizedBox(width: 8),
                  Text('Notification Center', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orangeAccent),
                title: const Text('Unusual Traffic Spike', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('API received 500+ requests in 1 min.'),
                trailing: const Text('2m ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              ListTile(
                leading: const Icon(Icons.error, color: Colors.redAccent),
                title: const Text('Failed SSH Logins', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Multiple failed auth attempts on Prod DB.'),
                trailing: const Text('15m ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              ListTile(
                leading: const Icon(Icons.security_update, color: Colors.greenAccent),
                title: const Text('Patch Deployed', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Self-healing patch v1.2 applied successfully.'),
                trailing: const Text('1h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Security Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications),
            ),
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_streamData["anomaly_score"] > 8.0)
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
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield, color: Theme.of(context).colorScheme.primary, size: 28),
                            const SizedBox(height: 8),
                            const Text('System Health', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              _systemMetrics != null 
                                ? '${_systemMetrics!['system_health'].toStringAsFixed(1)}%' 
                                : '...',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 28),
                            const SizedBox(height: 8),
                            const Text('Active Threats', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${_streamData["threats"]}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(context, "Requests", "${_streamData["total_requests"]}", Icons.sync_alt, Colors.blueAccent),
                    const SizedBox(width: 16),
                    _buildStatCard(context, "Auth Fails", "${_streamData["auth_failures"]}", Icons.gavel, Colors.purpleAccent),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLiveAlertsFeed(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildShodanSearch(),
                const SizedBox(height: 24),
                _buildTrafficGraph(),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAlertsFeed() {
    if (_liveAlerts.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Live Incident Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _liveAlerts.length,
          itemBuilder: (context, index) {
            final alert = _liveAlerts[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (alert['color'] as Color).withValues(alpha: 0.1),
                border: Border(left: BorderSide(color: alert['color'] as Color, width: 4)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    alert['type'] == 'CRITICAL' ? Icons.error : alert['type'] == 'WARNING' ? Icons.warning : Icons.info,
                    color: alert['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert['type'] as String, style: TextStyle(color: alert['color'] as Color, fontWeight: FontWeight.bold, fontSize: 10)),
                        Text(alert['message'] as String, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Text(alert['time'] as String, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _buildActionCard(Icons.code, 'GitHub PR Audit', Colors.purpleAccent, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const GithubPrScreen()));
              }),
              _isDeepScanning 
                ? const SizedBox(width: 140, child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
                : _buildActionCard(Icons.analytics, 'Run Deep Scan', Colors.cyanAccent, _runDeepScan),
              _buildActionCard(Icons.travel_explore, 'Breach Scan', Colors.orangeAccent, _runBreachScan),
              _buildActionCard(Icons.security, 'Lockdown System', Colors.redAccent, () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('System Lockdown triggered.')));
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficGraph() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Traffic Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_getDayLabel(value.toInt()), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _trafficSpots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShodanSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shodan Attack Surface Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _shodanController,
                        decoration: const InputDecoration(
                          hintText: 'Enter IP Address (e.g., 8.8.8.8)',
                          prefixIcon: Icon(Icons.radar, color: Colors.cyanAccent),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isShodanLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2))
                        : const Icon(Icons.search, color: Colors.cyanAccent),
                      onPressed: _isShodanLoading ? null : _runShodanScan,
                    ),
                  ],
                ),
                if (_shodanResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _shodanResult!.containsKey('error')
                        ? Text(_shodanResult!['error'], style: const TextStyle(color: Colors.redAccent))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Organization: ${_shodanResult!['org']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('OS: ${_shodanResult!['os']}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              const Text('Open Ports:', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                              Text('${_shodanResult!['ports']}', style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalThreatMap() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Global Threat Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(20.0, 0.0),
                  initialZoom: 1.2,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.securai',
                  ),
                  MarkerLayer(
                    markers: [
                      _buildThreatMarker(LatLng(39.9042, 116.4074), "Beijing, CN"),
                      _buildThreatMarker(LatLng(55.7558, 37.6173), "Moscow, RU"),
                      _buildThreatMarker(LatLng(38.9072, -77.0369), "Washington DC, US"),
                      _buildThreatMarker(LatLng(51.5074, -0.1278), "London, UK"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildThreatMarker(LatLng point, String location) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Active Threat from $location')));
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.redAccent.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent,
                boxShadow: [
                  BoxShadow(color: Colors.redAccent, blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDayLabel(int index) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index % 7];
  }
}
