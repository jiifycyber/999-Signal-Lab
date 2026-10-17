import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'stage53_outcome_tracker.dart';

class FormulaOutcomeHistoryStore {
  static const String _primaryKey = 'stage57_formula_outcome_history_v1';
  static const String _backupKey = 'stage57_formula_outcome_history_backup_v1';

  Future<bool> save(Stage53OutcomeTracker tracker) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(tracker.exportState());
      final existing = prefs.getString(_primaryKey);
      if (existing != null && existing.isNotEmpty) {
        await prefs.setString(_backupKey, existing);
      }
      return await prefs.setString(_primaryKey, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<bool> restore(Stage53OutcomeTracker tracker) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final primary = prefs.getString(_primaryKey);
      if (_restoreEncoded(tracker, primary)) {
        return true;
      }
      final backup = prefs.getString(_backupKey);
      if (_restoreEncoded(tracker, backup)) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  bool _restoreEncoded(
    Stage53OutcomeTracker tracker,
    String? encoded,
  ) {
    if (encoded == null || encoded.isEmpty) return false;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return false;
      return tracker.restoreState(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return false;
    }
  }
}
