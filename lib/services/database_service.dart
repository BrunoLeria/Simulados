import 'dart:convert';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/attempt.dart';
import '../models/notebook.dart';
import '../models/question.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      join(directory.path, 'simulados.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE notebooks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            notebook_id INTEGER NOT NULL,
            external_id TEXT NOT NULL,
            banca TEXT NOT NULL,
            ano INTEGER NOT NULL,
            cargo TEXT NOT NULL,
            enunciado TEXT NOT NULL,
            alternativas TEXT NOT NULL,
            gabarito TEXT NOT NULL,
            justificativa TEXT NOT NULL,
            FOREIGN KEY(notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            notebook_id INTEGER NOT NULL,
            finished_at TEXT NOT NULL,
            correct INTEGER NOT NULL,
            total INTEGER NOT NULL,
            blank INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE attempt_answers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attempt_id INTEGER NOT NULL,
            question_id INTEGER NOT NULL,
            answer TEXT,
            FOREIGN KEY(attempt_id) REFERENCES attempts(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<Notebook>> getNotebooks() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT n.*, COUNT(q.id) AS question_count,
        latest.finished_at AS last_attempt_at,
        CASE WHEN latest.total > 0
          THEN (latest.correct * 100.0 / latest.total)
          ELSE 0
        END AS last_percentage
      FROM notebooks n
      LEFT JOIN questions q ON q.notebook_id = n.id
      LEFT JOIN attempts latest ON latest.id = (
        SELECT a.id FROM attempts a
        WHERE a.notebook_id = n.id
        ORDER BY a.finished_at DESC, a.id DESC
        LIMIT 1
      )
      GROUP BY n.id ORDER BY n.created_at DESC
    ''');
    return rows.map(Notebook.fromMap).toList();
  }

  Future<int> saveNotebook(String name, List<Question> questions) async {
    final db = await database;
    return db.transaction((txn) async {
      final notebookId = await txn.insert('notebooks', {
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (final question in questions) {
        await txn.insert('questions', {
          ...question.toMap(notebookId),
          'alternativas': jsonEncode(question.alternativas),
        });
      }
      return notebookId;
    });
  }

  Future<void> deleteNotebook(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('attempts', where: 'notebook_id = ?', whereArgs: [id]);
      await txn.delete('questions', where: 'notebook_id = ?', whereArgs: [id]);
      await txn.delete('notebooks', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Question>> getQuestions(int notebookId) async {
    final db = await database;
    final rows = await db
        .query('questions', where: 'notebook_id = ?', whereArgs: [notebookId]);
    return rows.map(Question.fromMap).toList();
  }

  Future<int> saveAttempt({
    required int notebookId,
    required List<Question> questions,
    required Map<int, String?> answers,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final correct =
          questions.where((q) => answers[q.id!] == q.gabarito).length;
      final blank = questions.where((q) => answers[q.id!] == null).length;
      final attemptId = await txn.insert('attempts', {
        'notebook_id': notebookId,
        'finished_at': DateTime.now().toIso8601String(),
        'correct': correct,
        'total': questions.length,
        'blank': blank,
      });
      for (final question in questions) {
        await txn.insert('attempt_answers', {
          'attempt_id': attemptId,
          'question_id': question.id,
          'answer': answers[question.id!],
        });
      }
      return attemptId;
    });
  }

  Future<List<Attempt>> getAttempts(int notebookId) async {
    final db = await database;
    final rows = await db.query('attempts',
        where: 'notebook_id = ?',
        whereArgs: [notebookId],
        orderBy: 'finished_at DESC');
    return rows.map(Attempt.fromMap).toList();
  }

  Future<Map<int, String?>> getAttemptAnswers(int attemptId) async {
    final db = await database;
    final rows = await db.query(
      'attempt_answers',
      columns: ['question_id', 'answer'],
      where: 'attempt_id = ?',
      whereArgs: [attemptId],
    );
    return {
      for (final row in rows)
        row['question_id'] as int: row['answer'] as String?,
    };
  }
}
