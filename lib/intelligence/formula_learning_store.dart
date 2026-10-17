import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'advanced_combined_formula_engine.dart';

class FormulaLearningStore {
  static const String _primaryKey =
      'stage56_advanced_formula_learning_state_v1';
  static const String _backupKey =
      'stage56_advanced_formula_learning_state_backup_v1';
  static const String _knownGoodKey = 'stage59_advanced_formula_known_good_v1';

  Future<bool> save(AdvancedCombinedFormulaEngine engine) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(engine.exportLearningState());

      final existing = prefs.getString(_primaryKey);
      if (existing != null && existing.isNotEmpty) {
        await prefs.setString(_backupKey, existing);
      }

      return await prefs.setString(_primaryKey, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<bool> restore(AdvancedCombinedFormulaEngine engine) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final primary = prefs.getString(_primaryKey);
      if (_restoreEncoded(engine, primary)) {
        return true;
      }

      final backup = prefs.getString(_backupKey);
      if (_restoreEncoded(engine, backup)) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  bool _restoreEncoded(
    AdvancedCombinedFormulaEngine engine,
    String? encoded,
  ) {
    if (encoded == null || encoded.isEmpty) {
      return false;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return false;
      }

      return engine.restoreLearningState(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_primaryKey) || prefs.containsKey(_backupKey);
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveKnownGood(AdvancedCombinedFormulaEngine engine) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(engine.exportLearningState());
      return await prefs.setString(_knownGoodKey, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreKnownGood(AdvancedCombinedFormulaEngine engine) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_knownGoodKey);
      return _restoreEncoded(engine, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasKnownGood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_knownGoodKey);
    } catch (_) {
      return false;
    }
  }
}
