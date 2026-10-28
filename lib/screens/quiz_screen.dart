import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/app_provider.dart';
import '../widgets/question_card.dart';
import 'result_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  final int notebookId;
  final String notebookName;
  const QuizSetupScreen(
      {super.key, required this.notebookId, required this.notebookName});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  bool shuffle = false;
  bool starting = false;

  Future<void> _start() async {
    setState(() => starting = true);
    try {
      final questions = await context
          .read<AppProvider>()
          .questions(widget.notebookId, shuffle: shuffle);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                QuizScreen(notebookId: widget.notebookId, questions: questions),
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
      setState(() => starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.notebookName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.assignment, size: 64),
              const SizedBox(height: 16),
              Text('Pronto para começar?',
                  style: Theme.of(context).textTheme.headlineSmall),
              SwitchListTile(
                title: const Text('Embaralhar questões'),
                value: shuffle,
                onChanged: (value) => setState(() => shuffle = value),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: starting ? null : _start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar simulado'),
              ),
            ]),
          ),
        ),
      );
}

class QuizScreen extends StatefulWidget {
  final int notebookId;
  final List<Question> questions;
  const QuizScreen(
      {super.key, required this.notebookId, required this.questions});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  var index = 0;
  final answers = <int, String?>{};
  final ScrollController _questionScrollController = ScrollController();

  @override
  void dispose() {
    _questionScrollController.dispose();
    super.dispose();
  }

  void _goToQuestion(int questionIndex) {
    setState(() => index = questionIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_questionScrollController.hasClients) {
        _questionScrollController.jumpTo(0);
      }
    });
  }

  Future<void> _finish() async {
    final blank = widget.questions.where((q) => answers[q.id!] == null).length;
    if (blank > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Há questões em branco'),
          content: Text(
              '$blank questão(ões) não respondida(s). Finalizar mesmo assim?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Finalizar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await context.read<AppProvider>().database.saveAttempt(
            notebookId: widget.notebookId,
            questions: widget.questions,
            answers: answers,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResultScreen(questions: widget.questions, answers: answers),
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao finalizar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[index];
    return Scaffold(
      appBar: AppBar(
        title: Text('Questão ${index + 1}/${widget.questions.length}'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Navegar entre questões',
            icon: const Icon(Icons.grid_view),
            onSelected: _goToQuestion,
            itemBuilder: (_) => [
              for (var i = 0; i < widget.questions.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Text(
                    'Questão ${i + 1}${answers[widget.questions[i].id!] == null ? ' • em branco' : ' • respondida'}',
                  ),
                ),
            ],
          ),
          TextButton(onPressed: _finish, child: const Text('Finalizar')),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (index + 1) / widget.questions.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
                '${question.banca} • ${question.ano} • ${question.cargo}',
                style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _questionScrollController,
              padding: const EdgeInsets.all(16),
              child: QuestionCard(
                question: question,
                selected: answers[question.id!],
                onSelected: (value) =>
                    setState(() => answers[question.id!] = value),
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: index == 0 ? null : () => _goToQuestion(index - 1),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
                FilledButton.icon(
                  onPressed: index == widget.questions.length - 1
                      ? _finish
                      : () => _goToQuestion(index + 1),
                  icon: Icon(index == widget.questions.length - 1
                      ? Icons.check
                      : Icons.arrow_forward),
                  label: Text(index == widget.questions.length - 1
                      ? 'Finalizar'
                      : 'Próxima'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
