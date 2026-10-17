import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../ai/agent_duke_signal_memory.dart';

class DukeSignalHistoryStore {
  static const String _primaryKey = 'duke_signal_history_v1';
  static const String _backupKey = 'duke_signal_history_backup_v1';

  Future<bool> save(AgentDukeSignalMemory memory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(memory.exportState());
      final existing = prefs.getString(_primaryKey);
      if (existing != null && existing.isNotEmpty) {
        await prefs.setString(_backupKey, existing);
      }
      return await prefs.setString(_primaryKey, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<bool> restore(AgentDukeSignalMemory memory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final primary = prefs.getString(_primaryKey);
      if (_restoreEncoded(memory, primary)) return true;
      final backup = prefs.getString(_backupKey);
      return _restoreEncoded(memory, backup);
    } catch (_) {
      return false;
    }
  }

  bool _restoreEncoded(AgentDukeSignalMemory memory, String? encoded) {
    if (encoded == null || encoded.isEmpty) return false;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return false;
      return memory.restoreState(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return false;
    }
  }
}
