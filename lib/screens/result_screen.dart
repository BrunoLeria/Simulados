import 'package:flutter/material.dart';

import '../models/question.dart';
import '../widgets/question_card.dart';

class ResultScreen extends StatelessWidget {
  final List<Question> questions;
  final Map<int, String?> answers;
  const ResultScreen(
      {super.key, required this.questions, required this.answers});

  String _message(double percentage) {
    if (percentage < 50) {
      return 'Revise a base com calma. Cada questão corrigida é um passo importante!';
    }
    if (percentage < 70) {
      return 'Você está evoluindo! Identifique os pontos fracos e continue praticando.';
    }
    if (percentage < 90) {
      return 'Parabéns pelo desempenho! Mantenha a consistência nos estudos.';
    }
    return 'Excelente resultado! Celebre a conquista e mantenha esse ritmo.';
  }

  @override
  Widget build(BuildContext context) {
    final correct = questions.where((q) => answers[q.id!] == q.gabarito).length;
    final blank = questions.where((q) => answers[q.id!] == null).length;
    final percentage =
        questions.isEmpty ? 0.0 : correct * 100 / questions.length;
    final byBanca = <String, List<int>>{};
    for (final q in questions) {
      final values = byBanca.putIfAbsent(q.banca, () => [0, 0]);
      values[1]++;
      if (answers[q.id!] == q.gabarito) values[0]++;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text('$correct/${questions.length}',
                    style: Theme.of(context).textTheme.displaySmall),
                Text('${percentage.toStringAsFixed(1)}% de acerto'),
                const SizedBox(height: 8),
                Text('$blank em branco'),
                const SizedBox(height: 16),
                Text(_message(percentage), textAlign: TextAlign.center),
              ]),
            ),
          ),
          if (byBanca.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Desempenho por banca',
                style: Theme.of(context).textTheme.titleLarge),
            ...byBanca.entries.map((entry) => ListTile(
                  title: Text(entry.key),
                  trailing: Text('${entry.value[0]}/${entry.value[1]}'),
                  subtitle: LinearProgressIndicator(
                      value: entry.value[0] / entry.value[1]),
                )),
          ],
          const SizedBox(height: 16),
          Text('Correção detalhada',
              style: Theme.of(context).textTheme.titleLarge),
          ...questions.asMap().entries.map((entry) {
            final q = entry.value;
            final userAnswer = answers[q.id!];
            final isCorrect = userAnswer == q.gabarito;
            final isWrong = userAnswer != null && !isCorrect;
            final colorScheme = Theme.of(context).colorScheme;
            final questionColor = isCorrect
                ? Colors.green
                : isWrong
                    ? colorScheme.error
                    : colorScheme.outline;
            final questionBackground = isCorrect
                ? Colors.green.withValues(alpha: .10)
                : isWrong
                    ? colorScheme.errorContainer.withValues(alpha: .45)
                    : null;
            return ExpansionTile(
              backgroundColor: questionBackground,
              collapsedBackgroundColor: questionBackground,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: questionColor, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              collapsedShape: RoundedRectangleBorder(
                side: BorderSide(color: questionColor, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                  'Questão ${entry.key + 1} — ${userAnswer ?? 'Em branco'}'),
              subtitle: Text('Gabarito: ${q.gabarito}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QuestionCard(
                          question: q,
                          selected: answers[q.id!],
                          onSelected: (_) {},
                          showCorrection: true,
                          userAnswer: answers[q.id!],
                        ),
                        const Divider(),
                        Text('Justificativa',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(q.justificativa),
                      ]),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
