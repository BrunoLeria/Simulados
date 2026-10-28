import 'package:flutter/material.dart';

import '../models/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool showCorrection;
  final String? userAnswer;

  const QuestionCard({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelected,
    this.showCorrection = false,
    this.userAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final entries = question.alternativas.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.enunciado,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (entries.length == 2)
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: constraints.maxWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildOption(context, entries[0])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOption(context, entries[1])),
                ],
              ),
            ),
          )
        else
          RadioGroup<String>(
            groupValue: selected,
            onChanged: showCorrection
                ? (_) {}
                : (value) {
                    if (value != null) onSelected(value);
                  },
            child: Column(
              children:
                  entries.map((entry) => _buildOption(context, entry)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, MapEntry<String, String> entry) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = entry.key == selected;
    final isCorrect = entry.key == question.gabarito;
    final isWrong = showCorrection && entry.key == userAnswer && !isCorrect;
    final backgroundColor = showCorrection && isCorrect
        ? Colors.green.withValues(alpha: .18)
        : isWrong
            ? colors.errorContainer
            : isSelected
                ? colors.primaryContainer
                : null;

    if (question.alternativas.length == 2) {
      return FilledButton(
        onPressed: showCorrection ? null : () => onSelected(entry.key),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: isWrong ? colors.onErrorContainer : null,
          padding: const EdgeInsets.all(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: Center(
            child: Text(entry.value, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Card(
      color: backgroundColor,
      child: RadioListTile<String>(
        value: entry.key,
        enabled: !showCorrection,
        title: Text(entry.value),
      ),
    );
  }
}
