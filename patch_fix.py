import codecs
import re

with codecs.open('frontend/lib/services/api_service.dart', 'r', 'utf-8') as f:
    code = f.read()

secure_post_method = '''
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
'''

# Check if it was placed outside the class or just completely missing.
if 'static Future<http.Response> _securePost' not in code:
    code = code.replace('class ApiService {', 'class ApiService {\n' + secure_post_method)

with codecs.open('frontend/lib/services/api_service.dart', 'w', 'utf-8') as f:
    f.write(code)

