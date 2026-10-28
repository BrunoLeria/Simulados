import 'dart:convert';

import '../models/question.dart';

class ImportResult {
  final List<Question> questions;
  final int discarded;
  final List<String> errors;

  const ImportResult(this.questions, this.discarded, this.errors);
}

class ImportService {
  static const _required = [
    'id',
    'banca',
    'ano',
    'cargo',
    'enunciado',
    'alternativas',
    'gabarito',
    'justificativa',
  ];

  ImportResult parse(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! List) {
      throw const FormatException(
          'O arquivo deve conter uma lista JSON de questões.');
    }
    final questions = <Question>[];
    final errors = <String>[];
    for (var i = 0; i < decoded.length; i++) {
      try {
        final item = decoded[i];
        if (item is! Map) throw Exception('o item não é um objeto');
        final map = Map<String, dynamic>.from(item);
        final missing =
            _required.where((key) => !map.containsKey(key)).toList();
        if (missing.isNotEmpty) {
          throw Exception('faltam as chaves: ${missing.join(', ')}');
        }
        if (map['alternativas'] is! Map) {
          throw Exception('alternativas deve ser um objeto');
        }
        final alternatives =
            Map<String, dynamic>.from(map['alternativas'] as Map);
        if (alternatives.length < 2) {
          throw Exception('a questão deve ter pelo menos 2 alternativas');
        }
        if (alternatives.keys.any((key) => key.trim().isEmpty)) {
          throw Exception('cada alternativa deve ter uma chave não vazia');
        }
        if (alternatives.values.any((value) => value is! String)) {
          throw Exception('cada alternativa deve ter um texto string');
        }
        final answer = map['gabarito'];
        if (answer is! String ||
            !alternatives.keys.any(
                (key) => key.toLowerCase() == answer.trim().toLowerCase())) {
          throw Exception(
              'gabarito deve corresponder a uma das chaves de alternativas');
        }
        if (map['id'] == null ||
            map['banca'] is! String ||
            (map['ano'] != null && map['ano'] is! num) ||
            (map['cargo'] != null && map['cargo'] is! String) ||
            map['enunciado'] is! String ||
            map['justificativa'] is! String) {
          throw Exception('um ou mais campos possuem tipo inválido');
        }
        questions.add(Question.fromJson(map));
      } catch (error) {
        errors.add('Questão ${i + 1}: $error');
      }
    }
    return ImportResult(questions, errors.length, errors);
  }
}
