import os
import re

api_service = r"F:\The Arzens Intership Tasks\SecurAI Copilot\frontend\lib\services\api_service.dart"
with open(api_service, "r", encoding="utf-8") as f:
    content = f.read()

quiz_method_old = """      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to generate quiz");
      }"""

quiz_method_new = """      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        return decoded as List<dynamic>;
      } else {
        throw Exception("Failed to generate quiz: ${response.statusCode}");
      }"""

content = content.replace(quiz_method_old, quiz_method_new)

with open(api_service, "w", encoding="utf-8") as f:
    f.write(content)

print("Updated API service generateQuiz error handling")
