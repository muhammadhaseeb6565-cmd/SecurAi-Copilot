import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static Future<http.Response> _securePost(Uri url, {Map<String, String>? headers, Object? body}) async {
    headers ??= {};
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    headers['X-Request-Time'] = timestamp;
    headers['X-SecurAI-Client'] = 'mobile-app-verified-v1';
    
    if (body != null) {
      final bodyStr = body.toString();
      final secret = utf8.encode('NuclearGradeSecurAISignature2026');
      final message = utf8.encode(timestamp + bodyStr);
      final hmacSha256 = Hmac(sha256, secret);
      final signature = hmacSha256.convert(message).toString();
      headers['X-Payload-Signature'] = signature;
    }
    
    return await http.post(url, headers: headers, body: body);
  }


  // [SECURITY LAYER] HONEYPOT CANARY TOKEN
  // This looks like a highly privileged API key to anyone reverse-engineering or decompiling the APK/IPA.
  // In reality, it is radioactive. Any request received by the backend using this token results in an instant, permanent IP ban.
  static const String _fallbackAdminToken = 'Bearer sk-live-7x9qM32PjL5vRk9bN2mZ1xQ4';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ??
        "https://securai-copilot.onrender.com";
  }

  static Future<String> getAiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ai_model') ?? "openai/gpt-oss-20b";
  }

  Future<String> get baseUrl async => await getBaseUrl();

  Stream<String> streamMessage(
    String message,
    String persona,
    String language, {
    String? imageBase64,
  }) async* {
    final client = http.Client();
    try {
      final url = await baseUrl;
      final model = await getAiModel();
      final request = http.Request('POST', Uri.parse('$url/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['X-SecurAI-Client'] = 'mobile-app-verified-v1';
    request.headers['X-Request-Time'] = DateTime.now().millisecondsSinceEpoch.toString();
      final bodyMap = {
        "message": message,
        "persona": persona,
        "language": language,
        "model": model,
      };
      if (imageBase64 != null) {
        bodyMap["image_base64"] = imageBase64;
      }
      final bodyStr = jsonEncode(bodyMap);
      request.body = bodyStr;
      
      final timestamp = request.headers['X-Request-Time']!;
      final secret = utf8.encode('NuclearGradeSecurAISignature2026');
      final msg = utf8.encode(timestamp + bodyStr);
      final hmacSha256 = Hmac(sha256, secret);
      final signature = hmacSha256.convert(msg).toString();
      request.headers['X-Payload-Signature'] = signature;

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

  Future<Map<String, dynamic>> sendMessage(
    String message,
    String persona,
    String endpoint,
  ) async {
    try {
      final url = await baseUrl;
      final response = await _securePost(
        Uri.parse("$url/$endpoint"),
        headers: {
          'Content-Type': 'application/json',
          'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({
          "message": message,
          "persona": persona,
          "language": "en",
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to connect: $e");
    }
  }

  Future<List<dynamic>> generateQuiz(String topic) async {
    try {
      final url = await baseUrl;
      final response = await _securePost(
        Uri.parse("$url/generate-quiz"),
        headers: {
          'Content-Type': 'application/json',
          'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({"topic": topic}),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        return decoded as List<dynamic>;
      } else {
        throw Exception("Failed to generate quiz: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<String> generateReport(String alertDetails) async {
    return _postRequest('/generate-report', alertDetails, 'report');
  }

  Future<String> generateCodePatch(String alertDetails) async {
    return _postRequest('/generate-patch', alertDetails, 'patch');
  }

  static Future<Map<String, dynamic>?> githubAutoFix(
    String repo,
    int prNumber,
    String pat,
    String fixCode,
  ) async {
    try {
      final url = await getBaseUrl();
      final response = await _securePost(
        Uri.parse('$url/github-auto-fix'),
        headers: {
          'Content-Type': 'application/json',
          'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({
          'repo': repo,
          'pr_number': prNumber,
          'pat': pat,
          'fix_code': fixCode,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error running github auto fix: $e');
      return null;
    }
  }

  Future<String> _postRequest(
    String endpoint,
    String alertDetails,
    String key,
  ) async {
    try {
      final url = await baseUrl;
      final model = await getAiModel();
      final response = await _securePost(
        Uri.parse('$url$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({"alert_details": alertDetails, "model": model}),
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

  Future<List<Map<String, dynamic>>> fetchRealAlerts(String targetUrl) async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse('$url/url-scan'),
            headers: {
              'Content-Type': 'application/json',
              'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
            },
            body: jsonEncode({"url": targetUrl}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final alerts = data['alerts'] as List;
        return alerts.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching real alerts: $e');
    }
    return [
      {
        "title": "Scanner Error",
        "severity": "High",
        "time": "Just now",
        "details":
            "Could not execute scan on the specified URL. Please check the backend connection.",
      },
    ];
  }

  Future<Map<String, dynamic>> breachScan(String email) async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse('$url/breach-scan'),
            headers: {
              'Content-Type': 'application/json',
              'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
            },
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching breach scan: $e');
    }
    return {"found": false, "breaches": []};
  }

  static Future<Map<String, dynamic>?> fetchSystemMetrics() async {
    try {
      final url = await getBaseUrl();
      final response = await http.get(
        Uri.parse('$url/system-metrics'),
        headers: {'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching system metrics: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> shodanScan(
    String ip,
    String apiKey,
  ) async {
    try {
      final url = await getBaseUrl();
      final response = await _securePost(
        Uri.parse('$url/shodan-scan'),
        headers: {
          'Content-Type': 'application/json',
          'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({'ip': ip, 'api_key': apiKey}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error running shodan scan: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> githubPrReview(
    String repo,
    int prNumber,
    String pat,
  ) async {
    try {
      final url = await getBaseUrl();
      final response = await _securePost(
        Uri.parse('$url/github-pr'),
        headers: {
          'Content-Type': 'application/json',
          'X-SecurAI-Client': 'mobile-app-verified-v1',
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({'repo': repo, 'pr_number': prNumber, 'pat': pat}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error running github PR review: $e');
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
        await for (final chunk
            in response.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
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
