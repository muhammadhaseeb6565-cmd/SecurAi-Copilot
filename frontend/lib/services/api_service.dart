import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "https://0a643739-5090-4757-848c-da433c6d0b94-00-ezuj5w92pcze.pike.replit.dev";

  Stream<String> streamMessage(String message, String persona, String language) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/chat'));
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
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
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

  Stream<Map<String, dynamic>> streamMetrics() async* {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse('$baseUrl/metrics/stream'));
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
