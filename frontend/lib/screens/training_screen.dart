import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../services/api_service.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _topicController = TextEditingController();
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool _isLoading = false;
  bool _hasStarted = false;

  Future<void> _generateQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasStarted = true;
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _answered = false;
    });

    try {
      final questions = await ApiService().generateQuiz(topic);
      setState(() {
        _questions = questions;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate quiz: $e')));
      setState(() {
        _hasStarted = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitAnswer(int selectedIndex) {
    if (_answered) return;

    final currentQ = _questions[_currentQuestionIndex];
    final isCorrect = selectedIndex == currentQ['correct_index'];

    setState(() {
      _answered = true;
      if (isCorrect) _score += 100;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect
              ? 'Correct! +100 Points'
              : 'Incorrect. ${currentQ['explanation'] ?? ""}',
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
      });
    } else {
      // Quiz finished
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Quiz completed! Score: $_score')));
      setState(() {
        _hasStarted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DevSecOps Training",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !_hasStarted
            ? _buildSetupView()
            : _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              )
            : _buildQuizView(),
      ),
    );
  }

  Widget _buildSetupView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.school, size: 80, color: Colors.cyanAccent),
        const SizedBox(height: 24),
        Text(
          "DevSecOps Academy",
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Enter a topic (e.g. 'Kubernetes Security', 'OWASP Top 10', 'IAM Roles') and our AI will generate a custom quiz for you.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _topicController,
          decoration: const InputDecoration(
            hintText: 'Enter topic to learn...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => _generateQuiz(),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _generateQuiz,
          child: const Text('Start Quiz'),
        ),
      ],
    );
  }

  Widget _buildQuizView() {
    if (_questions.isEmpty) return const SizedBox();
    final currentQ = _questions[_currentQuestionIndex];
    final options = currentQ['options'] as List<dynamic>;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${_currentQuestionIndex + 1} / ${_questions.length}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  "Score: $_score",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            currentQ['question'] ?? "",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (currentQ['code_snippet'] != null &&
              currentQ['code_snippet'].toString().trim().isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Markdown(
                data: currentQ['code_snippet'],
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet(
                  code: TextStyle(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          ...List.generate(options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildAnswerButton(
                options[index].toString(),
                index,
                currentQ['correct_index'],
              ),
            );
          }),

          if (_answered) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(
                _currentQuestionIndex < _questions.length - 1
                    ? "Next Question"
                    : "Finish Quiz",
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String text, int index, int correctIndex) {
    final isCorrect = index == correctIndex;
    Color? bgColor;
    if (_answered) {
      if (isCorrect) {
        bgColor = Colors.green.withValues(alpha: 0.2);
      } else {
        bgColor = Colors.red.withValues(alpha: 0.1);
      }
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        backgroundColor: bgColor,
        side: BorderSide(
          color: (_answered && isCorrect)
              ? Colors.green
              : Theme.of(context).dividerColor,
        ),
      ),
      onPressed: () => _submitAnswer(index),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
