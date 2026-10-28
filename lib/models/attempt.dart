class Attempt {
  final int id;
  final int notebookId;
  final DateTime finishedAt;
  final int correct;
  final int total;
  final int blank;

  const Attempt({
    required this.id,
    required this.notebookId,
    required this.finishedAt,
    required this.correct,
    required this.total,
    required this.blank,
  });

  double get percentage => total == 0 ? 0 : correct * 100 / total;

  factory Attempt.fromMap(Map<String, dynamic> map) => Attempt(
        id: map['id'] as int,
        notebookId: map['notebook_id'] as int,
        finishedAt: DateTime.parse(map['finished_at'] as String),
        correct: map['correct'] as int,
        total: map['total'] as int,
        blank: map['blank'] as int,
      );
}
