import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  int _score = 0;
  bool _answered = false;

  final String _vulnerableCode = """
```python
@app.route('/api/user')
def get_user():
    user_id = request.args.get('id')
    # Vulnerable database query
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    return cursor.fetchone()
```
  """;

  void _submitAnswer(bool isCorrect) {
    if (_answered) return;
    setState(() {
      _answered = true;
      if (isCorrect) _score += 100;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Correct! +100 Points' : 'Incorrect. That is a SQL Injection vulnerability.'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DevSecOps Training", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Scenario 1 / 10", style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(24)),
                  child: Text("Score: $_score", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 24),
            Text("Identify the vulnerability in the following Python API endpoint:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Markdown(
                data: _vulnerableCode,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
                  code: TextStyle(backgroundColor: Theme.of(context).colorScheme.surface, fontFamily: 'monospace'),
                  codeblockDecoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAnswerButton("A) Broken Object Level Authorization (BOLA)", false),
            const SizedBox(height: 8),
            _buildAnswerButton("B) Server-Side Request Forgery (SSRF)", false),
            const SizedBox(height: 8),
            _buildAnswerButton("C) SQL Injection (SQLi)", true),
            const SizedBox(height: 8),
            _buildAnswerButton("D) Cross-Site Scripting (XSS)", false),
            
            if (_answered) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() => _answered = false);
                  // In a real app, load next scenario
                },
                child: const Text("Next Scenario"),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String text, bool isCorrect) {
    Color? bgColor;
    if (_answered) {
      bgColor = isCorrect ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1);
    }
    
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        backgroundColor: bgColor,
        side: BorderSide(color: _answered && isCorrect ? Colors.green : Theme.of(context).dividerColor),
      ),
      onPressed: () => _submitAnswer(isCorrect),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}
