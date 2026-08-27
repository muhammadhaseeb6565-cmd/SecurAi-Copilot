import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ThreatLogsScreen extends StatefulWidget {
  const ThreatLogsScreen({super.key});

  @override
  State<ThreatLogsScreen> createState() => _ThreatLogsScreenState();
}

class _ThreatLogsScreenState extends State<ThreatLogsScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await _supabase
          .from('threat_logs')
          .select()
          .order('timestamp', ascending: false)
          .limit(100);
      setState(() {
        _logs = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Threat Logs'),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading threats:\n$_error\n\nNote: Did you create the "threat_logs" table in Supabase?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchLogs,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No threats detected yet.\nYour app is secure.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.greenAccent, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final ip = log['ip_address'] ?? 'Unknown IP';
                        final attackType = log['attack_type'] ?? 'Unknown Attack';
                        final rawDate = log['timestamp'] as String?;
                        
                        String dateStr = 'Unknown Time';
                        if (rawDate != null) {
                          try {
                            final parsed = DateTime.parse(rawDate).toLocal();
                            dateStr = DateFormat('MMM dd, yyyy - hh:mm:ss a').format(parsed);
                          } catch (_) {}
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.redAccent, width: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            title: Text(
                              attackType,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'IP: $ip\nTime: $dateStr',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
