import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<String> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? "https://securai-copilot.onrender.com";
  }

  Stream<String> streamMessage(String message, String persona, String language) async* {
    final client = http.Client();
    try {
      final url = await baseUrl;
      final request = http.Request('POST', Uri.parse('$url/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({"message": message, "persona": persona, "language": language});

      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        yield "Server Error: ${response.statusCode}";
        return;
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        yield chunk;
      }
    } catch (e) {
      yield "Failed to connect to backend API: $e";
    } finally {
      client.close();
    }
  }

  Future<String> generateReport(String alertDetails) async {
    return _postRequest('/generate-report', alertDetails, 'report');
  }

  Future<String> generateCodePatch(String alertDetails) async {
    return _postRequest('/generate-patch', alertDetails, 'patch');
  }

  Future<String> _postRequest(String endpoint, String alertDetails, String key) async {
    try {
      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"alert_details": alertDetails}),
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded[key] ?? "Error processing request.";
      } else {
        return "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Failed to connect to backend API: $e";
    }
  }

  Future<List<Map<String, dynamic>>> fetchRealAlerts() async {
    final url = await baseUrl;
    try {
      final response = await http.get(Uri.parse('$url/run-scan'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> alertsData = data['alerts'] ?? [];
        return alertsData.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [
        {"title": "Server Error", "severity": "High", "time": "Just now", "details": "Failed to run scan. HTTP ${response.statusCode}"}
      ];
    } catch (e) {
      return [
        {"title": "Connection Error", "severity": "High", "time": "Just now", "details": "Could not connect to backend server: $e"}
      ];
    }
  }

  Stream<Map<String, dynamic>> streamMetrics() async* {
    final client = http.Client();
    try {
      final url = await baseUrl;
      final request = http.Request('GET', Uri.parse('$url/metrics/stream'));
      final response = await client.send(request);
      
      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (chunk.startsWith('data: ')) {
            final jsonStr = chunk.substring(6);
            yield jsonDecode(jsonStr);
          }
        }
      }
    } catch (e) {
      // Stream failed
    } finally {
      client.close();
    }
  }
}
