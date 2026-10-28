import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attempt.dart';
import '../providers/app_provider.dart';
import 'quiz_screen.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  final int notebookId;
  final String notebookName;
  const HistoryScreen(
      {super.key, required this.notebookId, required this.notebookName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histórico — $notebookName')),
      body: FutureBuilder<List<Attempt>>(
        future: context.read<AppProvider>().attempts(notebookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar histórico: ${snapshot.error}'));
          }
          final attempts = snapshot.data!;
          if (attempts.isEmpty) {
            return const Center(child: Text('Nenhuma tentativa realizada.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            itemBuilder: (_, index) {
              final attempt = attempts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                      child: Text('${attempt.percentage.round()}%')),
                  title: Text('${attempt.correct}/${attempt.total} acertos'),
                  subtitle: Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(attempt.finishedAt)} • ${attempt.blank} em branco'),
                  onTap: () async {
                    try {
                      final provider = context.read<AppProvider>();
                      final questions = await provider.questions(notebookId);
                      final answers =
                          await provider.database.getAttemptAnswers(attempt.id);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            questions: questions,
                            answers: answers,
                          ),
                        ),
                      );
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Não foi possível carregar o gabarito: $error'),
                          ),
                        );
                      }
                    }
                  },
                  trailing: IconButton(
                    tooltip: 'Refazer caderno',
                    icon: const Icon(Icons.replay),
                    onPressed: () async {
                      final questions = await context
                          .read<AppProvider>()
                          .questions(notebookId);
                      if (context.mounted) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                  notebookId: notebookId, questions: questions),
                            ));
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
