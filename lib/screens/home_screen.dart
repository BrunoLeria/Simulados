import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/notebook.dart';
import '../providers/app_provider.dart';
import '../services/import_service.dart';
import '../widgets/empty_state.dart';
import 'history_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _import(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty || files.first.path == null || !context.mounted) return;
    try {
      final pickedFile = files.first;
      final file = File(pickedFile.path!);
      final parsed = ImportService().parse(await file.readAsString());
      if (parsed.questions.isEmpty) {
        throw Exception('nenhuma questão válida foi encontrada');
      }
      final name = pickedFile.name
          .replaceFirst(RegExp(r'\.json$', caseSensitive: false), '');
      final id = await provider.importNotebook(name, parsed.questions);
      if (!context.mounted) return;
      final details = parsed.discarded > 0
          ? '${parsed.questions.length} importadas; ${parsed.discarded} descartadas.\n${parsed.errors.join('\n')}'
          : '${parsed.questions.length} questões importadas.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(details)));
      if (id == null) throw Exception('falha ao salvar o caderno');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro na importação: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Simulados de concursos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _import(context),
        icon: const Icon(Icons.file_upload),
        label: const Text('Importar JSON'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.notebooks.isEmpty
              ? const EmptyState(
                  message:
                      'Nenhum caderno ainda.\nImporte um arquivo JSON para começar.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: provider.notebooks.map((notebook) {
                    final lastAttempt = notebook.lastAttemptAt;
                    final percentage = notebook.lastPercentage;
                    final isGreen = percentage != null && percentage > 90;
                    final needsReview = isGreen &&
                        lastAttempt != null &&
                        DateTime.now().difference(lastAttempt).inDays > 10;
                    final statusColor = needsReview
                        ? Colors.amber.shade700
                        : isGreen
                            ? Colors.green.shade700
                            : percentage == null
                                ? null
                                : Theme.of(context).colorScheme.error;
                    final statusBackground = needsReview
                        ? Colors.amber.withValues(alpha: .14)
                        : isGreen
                            ? Colors.green.withValues(alpha: .10)
                            : percentage == null
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .errorContainer
                                    .withValues(alpha: .45);
                    return Card(
                      color: statusBackground,
                      shape: statusColor == null
                          ? null
                          : RoundedRectangleBorder(
                              side: BorderSide(color: statusColor, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor,
                          child: Icon(Icons.menu_book,
                              color: statusColor == null
                                  ? null
                                  : Theme.of(context).colorScheme.surface),
                        ),
                        title: Text(notebook.name),
                        subtitle: Text(_subtitle(notebook)),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizSetupScreen(
                                  notebookId: notebook.id!,
                                  notebookName: notebook.name),
                            )),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'history') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HistoryScreen(
                                        notebookId: notebook.id!,
                                        notebookName: notebook.name),
                                  ));
                            } else if (value == 'delete') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Excluir caderno?'),
                                  content: const Text(
                                      'As tentativas deste caderno também serão removidas.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Excluir')),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await provider.deleteNotebook(notebook.id!);
                              }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'history', child: Text('Histórico')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  String _subtitle(Notebook notebook) {
    final lastAttempt = notebook.lastAttemptAt;
    final percentage = notebook.lastPercentage;
    if (lastAttempt == null || percentage == null) {
      return '${notebook.questionCount} questões • ainda não resolvido';
    }
    final date = DateFormat('dd/MM/yyyy HH:mm').format(lastAttempt);
    final review =
        percentage > 90 && DateTime.now().difference(lastAttempt).inDays > 10;
    return '${notebook.questionCount} questões • última nota: ${percentage.toStringAsFixed(1)}% em $date${review ? ' • revisar' : ''}';
  }
}
