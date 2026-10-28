import 'dart:convert';

class Question {
  final int? id;
  final String externalId;
  final String banca;
  final int ano;
  final String cargo;
  final String enunciado;
  final Map<String, String> alternativas;
  final String gabarito;
  final String justificativa;

  const Question({
    this.id,
    required this.externalId,
    required this.banca,
    required this.ano,
    required this.cargo,
    required this.enunciado,
    required this.alternativas,
    required this.gabarito,
    required this.justificativa,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawAlternatives = json['alternativas'] as Map;
    final alternatives = rawAlternatives.map(
      (key, value) => MapEntry(
        key.toString(),
        _removeAlternativePrefix(value.toString()),
      ),
    );
    final answer = json['gabarito'] as String;
    final gabarito = alternatives.keys.firstWhere(
      (key) => key.toLowerCase() == answer.trim().toLowerCase(),
    );
    return Question(
      externalId: json['id'].toString(),
      banca: json['banca'] as String,
      ano: (json['ano'] as num?)?.toInt() ?? DateTime.now().year,
      cargo: (json['cargo'] as String?) ?? 'NDA',
      enunciado: json['enunciado'] as String,
      alternativas: alternatives,
      gabarito: gabarito,
      justificativa: json['justificativa'] as String,
    );
  }

  static String _removeAlternativePrefix(String text) {
    return text.replaceFirst(
      RegExp(r'^\s*[A-Ea-e]\s*[\)\.\-:]\s*'),
      '',
    );
  }

  Map<String, dynamic> toMap(int notebookId) => {
        'notebook_id': notebookId,
        'external_id': externalId,
        'banca': banca,
        'ano': ano,
        'cargo': cargo,
        'enunciado': enunciado,
        'alternativas': alternativas,
        'gabarito': gabarito,
        'justificativa': justificativa,
      };

  factory Question.fromMap(Map<String, dynamic> map) {
    final alternatives = Map<String, dynamic>.from(
      jsonDecode(map['alternativas'] as String) as Map,
    );
    return Question(
      id: map['id'] as int?,
      externalId: map['external_id'] as String,
      banca: map['banca'] as String,
      ano: map['ano'] as int,
      cargo: map['cargo'] as String,
      enunciado: map['enunciado'] as String,
      alternativas: alternatives.map(
        (key, value) =>
            MapEntry(key, _removeAlternativePrefix(value as String)),
      ),
      gabarito: map['gabarito'] as String,
      justificativa: map['justificativa'] as String,
    );
  }
}
