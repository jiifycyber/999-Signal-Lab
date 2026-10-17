import 'dart:convert';

import 'package:http/http.dart' as http;

class DukePlannedAction {
  final String name;
  final Map<String, dynamic> arguments;

  const DukePlannedAction({
    required this.name,
    this.arguments = const {},
  });

  factory DukePlannedAction.fromJson(
    Map<String, dynamic> json,
  ) {
    return DukePlannedAction(
      name: (json['name'] ?? '').toString(),
      arguments: json['arguments'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['arguments'] as Map,
            )
          : const {},
    );
  }
}

class DukeReasoningPlan {
  final String reply;
  final List<DukePlannedAction> actions;

  const DukeReasoningPlan({
    required this.reply,
    required this.actions,
  });
}

class AgentDukeReasoningGateway {
  static const String endpoint = String.fromEnvironment(
    'DUKE_AI_URL',
    defaultValue: '',
  );

  bool get enabled => endpoint.trim().isNotEmpty;

  Future<DukeReasoningPlan?> plan({
    required String userMessage,
    required String page,
    required String symbol,
    required String timeframe,
    required List<String> availableActions,
    required List<Map<String, String>> conversation,
  }) async {
    if (!enabled) return null;

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'agent': 'Agent Duke the Boss',
            'mode': 'trading_application_operator',
            'message': userMessage,
            'context': {
              'page': page,
              'symbol': symbol,
              'timeframe': timeframe,
            },
            'available_actions': availableActions,
            'conversation': conversation,
            'instructions': [
              'Understand natural conversational requests.',
              'Use application tools when an action is needed.',
              'Create multi-step plans when necessary.',
              'Never invent an application action.',
              'Explain trading analysis with uncertainty.',
              'Do not claim guaranteed profit or accuracy.',
              'Never execute broker orders unless a separately authorized execution tool exists.',
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) return null;

    final map = Map<String, dynamic>.from(decoded);

    final rawActions = map['actions'];

    final actions = rawActions is List
        ? rawActions
            .whereType<Map>()
            .map(
              (item) => DukePlannedAction.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where(
              (action) => action.name.trim().isNotEmpty,
            )
            .toList()
        : <DukePlannedAction>[];

    return DukeReasoningPlan(
      reply: (map['reply'] ?? '').toString(),
      actions: actions,
    );
  }
}
