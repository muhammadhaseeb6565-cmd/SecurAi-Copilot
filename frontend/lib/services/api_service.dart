import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ?? "https://securai-copilot.onrender.com";
  }

  Future<String> get baseUrl async => await getBaseUrl();

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
      print('Error fetching real alerts: $response.statusCode');
      return [];
    } catch (e) {
      print('Error fetching real alerts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchSystemMetrics() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url/system-metrics'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching system metrics: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> shodanScan(String ip, String apiKey) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/shodan-scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ip': ip, 'api_key': apiKey}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error running shodan scan: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> githubPrReview(String repo, int prNumber, String pat) async {
    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/github-pr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'repo': repo, 'pr_number': prNumber, 'pat': pat}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error running github PR review: $e');
      return null;
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
