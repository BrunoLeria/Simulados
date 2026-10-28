import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/attempt.dart';
import '../models/notebook.dart';
import '../models/question.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService database = DatabaseService();
  List<Notebook> notebooks = [];
  bool loading = false;
  String? error;

  Future<void> loadNotebooks() async {
    loading = true;
    notifyListeners();
    try {
      notebooks = await database.getNotebooks();
      error = null;
    } catch (e) {
      error = 'Não foi possível carregar os cadernos: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<int?> importNotebook(String name, List<Question> questions) async {
    try {
      final id = await database.saveNotebook(name, questions);
      await loadNotebooks();
      return id;
    } catch (e) {
      error = 'Não foi possível salvar o caderno: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteNotebook(int id) async {
    try {
      await database.deleteNotebook(id);
      await loadNotebooks();
      return true;
    } catch (e) {
      error = 'Não foi possível excluir o caderno: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<Question>> questions(int id, {bool shuffle = false}) async {
    final result = await database.getQuestions(id);
    if (shuffle) result.shuffle(Random());
    return result;
  }

  Future<List<Attempt>> attempts(int id) => database.getAttempts(id);
}
