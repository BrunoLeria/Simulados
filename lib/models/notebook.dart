class Notebook {
  final int? id;
  final String name;
  final DateTime createdAt;
  final int questionCount;
  final DateTime? lastAttemptAt;
  final double? lastPercentage;

  const Notebook({
    this.id,
    required this.name,
    required this.createdAt,
    required this.questionCount,
    this.lastAttemptAt,
    this.lastPercentage,
  });

  factory Notebook.fromMap(Map<String, dynamic> map) => Notebook(
        id: map['id'] as int?,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        questionCount: (map['question_count'] as num?)?.toInt() ?? 0,
        lastAttemptAt: map['last_attempt_at'] == null
            ? null
            : DateTime.parse(map['last_attempt_at'] as String),
        lastPercentage: map['last_percentage'] == null
            ? null
            : (map['last_percentage'] as num).toDouble(),
      );
}
