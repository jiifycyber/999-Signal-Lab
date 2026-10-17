import 'dart:async';

import 'package:flutter/material.dart';

import 'agent_duke_reasoning_gateway.dart';

import 'agent_duke_voice_controller.dart';

typedef DukeAppAction = FutureOr<String> Function(
  Map<String, dynamic> arguments,
);

class DukeConversationMessage {
  final String role;
  final String text;
  final DateTime createdAt;

  const DukeConversationMessage({
    required this.role,
    required this.text,
    required this.createdAt,
  });
}

class _DukeActionBinding {
  final Object owner;
  final DukeAppAction action;

  const _DukeActionBinding({
    required this.owner,
    required this.action,
  });
}

class AgentDukeGlobalController extends ChangeNotifier {
  AgentDukeGlobalController._();

  static final AgentDukeGlobalController instance =
      AgentDukeGlobalController._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final Map<String, List<_DukeActionBinding>> _actions = {};

  final AgentDukeReasoningGateway reasoning = AgentDukeReasoningGateway();

  final AgentDukeVoiceController voice = AgentDukeVoiceController();

  bool voiceInitialized = false;

  final List<DukeConversationMessage> conversation =
      <DukeConversationMessage>[];

  String page = 'AI SCANNER';
  String symbol = 'EURUSD';
  String timeframe = 'M1';

  String lastResponse =
      'Agent Duke the Boss is online and connected to the application.';

  bool busy = false;
  bool autonomousMode = false;

  Future<void> initializeVoice() async {
    if (voiceInitialized) return;

    await voice.initialize();

    voiceInitialized = true;

    await voice.startListening(
      (spokenCommand) async {
        final command = spokenCommand.trim();

        if (command.isEmpty) {
          return;
        }

        final response = await submit(command);

        if (voice.voiceRepliesEnabled && response.trim().isNotEmpty) {
          await voice.speak(response);
        }
      },
    );

    await voice.stopListening();

    await voice.startWakeMode(
      () async {
        notifyListeners();
      },
    );

    notifyListeners();
  }

  Future<void> toggleVoice() async {
    await initializeVoice();

    if (voice.state == DukeVoiceState.listening) {
      await voice.stopListening();
      notifyListeners();
      return;
    }

    await voice.startListening((spokenCommand) async {
      final command = spokenCommand.trim();

      if (command.isEmpty) return;

      final response = await submit(command);

      if (voice.voiceRepliesEnabled && response.trim().isNotEmpty) {
        await voice.speak(response);
      }

      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> stopVoice() async {
    await voice.stopListening();
    notifyListeners();
  }

  Set<String> get availableActions => Set.unmodifiable(_actions.keys);

  void updateContext({
    String? page,
    String? symbol,
    String? timeframe,
  }) {
    if (page != null && page.trim().isNotEmpty) {
      this.page = page.trim();
    }

    if (symbol != null && symbol.trim().isNotEmpty) {
      this.symbol = symbol.trim().toUpperCase();
    }

    if (timeframe != null && timeframe.trim().isNotEmpty) {
      this.timeframe = timeframe.trim().toUpperCase();
    }

    notifyListeners();
  }

  void registerAction({
    required Object owner,
    required String name,
    required DukeAppAction action,
  }) {
    final key = _normalizeAction(name);

    final list = _actions.putIfAbsent(
      key,
      () => <_DukeActionBinding>[],
    );

    list.removeWhere((entry) => identical(entry.owner, owner));

    list.add(
      _DukeActionBinding(
        owner: owner,
        action: action,
      ),
    );
  }

  void registerActions({
    required Object owner,
    required Map<String, DukeAppAction> actions,
  }) {
    for (final entry in actions.entries) {
      registerAction(
        owner: owner,
        name: entry.key,
        action: entry.value,
      );
    }
  }

  void unregisterOwner(Object owner) {
    final empty = <String>[];

    for (final entry in _actions.entries) {
      entry.value.removeWhere(
        (binding) => identical(binding.owner, owner),
      );

      if (entry.value.isEmpty) {
        empty.add(entry.key);
      }
    }

    for (final key in empty) {
      _actions.remove(key);
    }
  }

  Future<String> execute(
    String name, {
    Map<String, dynamic> arguments = const {},
  }) async {
    final key = _normalizeAction(name);
    final bindings = _actions[key];

    if (bindings == null || bindings.isEmpty) {
      return _answer(
        'I cannot execute "$name" from the current application state yet.',
      );
    }

    busy = true;
    notifyListeners();

    try {
      // Most recently registered screen wins.
      final result = await bindings.last.action(arguments);
      return _answer(result);
    } catch (error) {
      return _answer(
        'I could not complete "$name": $error',
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> _runDukeFastCommand(String rawText) async {
    final text = rawText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    if (text.isEmpty) {
      return null;
    }

    Future<String?> runFirst(
      List<String> actionNames, [
      Map<String, dynamic> args = const {},
    ]) async {
      for (final action in actionNames) {
        if (availableActions.contains(action)) {
          return execute(action, arguments: args);
        }
      }

      return null;
    }

    if (text.contains('take me home') ||
        text.contains('home screen') ||
        text.contains('main screen') ||
        text.contains('main scanner') ||
        text.contains('back to scanner') ||
        text.contains('open scanner') ||
        text == 'scanner') {
      return runFirst([
        'open_scanner',
        'navigate_back',
      ]);
    }

    if (text.contains('go back') ||
        text.contains('take me back') ||
        text == 'back') {
      return runFirst([
        'navigate_back',
        'open_scanner',
      ]);
    }

    if (text.contains('advanced chart') ||
        text.contains('trading studio') ||
        text.contains('open chart')) {
      return runFirst([
        'open_advanced_chart',
      ]);
    }

    if (text.contains('open analytics') ||
        text.contains('show analytics') ||
        text == 'analytics') {
      return runFirst([
        'open_analytics',
      ]);
    }

    if (text.contains('open tools') ||
        text.contains('show tools') ||
        text == 'tools') {
      return runFirst([
        'open_tools',
      ]);
    }

    if (text.contains('open markets') ||
        text.contains('show markets') ||
        text == 'markets') {
      return runFirst([
        'open_markets',
      ]);
    }

    if (text.contains('open tracker') ||
        text.contains('trade tracker') ||
        text == 'tracker') {
      return runFirst([
        'open_tracker',
      ]);
    }

    if (text.contains('analytics')) {
      return runFirst([
        'open_analytics',
      ]);
    }

    if (text.contains('tools')) {
      return runFirst([
        'open_tools',
      ]);
    }

    if (text.contains('markets')) {
      return runFirst([
        'open_markets',
      ]);
    }

    if (text.contains('tracker')) {
      return runFirst([
        'open_tracker',
      ]);
    }

    if (text.contains('alerts')) {
      return runFirst([
        'open_alerts',
      ]);
    }

    if (text.contains('scan all') || text.contains('scan every')) {
      return runFirst([
        'scan_all',
      ]);
    }

    if (text.contains('deep scan')) {
      return runFirst([
        'deep_scan',
      ]);
    }

    if (text.contains('indicator')) {
      return runFirst([
        'open_indicators',
      ]);
    }

    if (text.contains('drawing tool') || text.contains('drawing tools')) {
      return runFirst([
        'open_drawings',
      ]);
    }

    if (text.contains('support') && text.contains('resistance')) {
      return runFirst([
        'support_resistance',
      ]);
    }

    if (text.contains('fibonacci') || text.contains(' fib ')) {
      return runFirst([
        'fibonacci',
      ]);
    }

    if (text.contains('pattern')) {
      return runFirst([
        'pattern_scanner',
      ]);
    }

    if (text.contains('liquidity')) {
      return runFirst([
        'liquidity_analysis',
        'breakout_detector',
      ]);
    }

    if (text.contains('breakout')) {
      return runFirst([
        'breakout_detector',
      ]);
    }

    if (text.contains('backtest')) {
      return runFirst([
        'backtester',
      ]);
    }

    if (text.contains('strategy lab') || text.contains('strategy builder')) {
      return runFirst([
        'strategy_lab',
      ]);
    }

    if (text.contains('replay')) {
      return runFirst([
        'open_replay',
      ]);
    }

    if (text.contains('zoom in')) {
      return runFirst([
        'chart_zoom_in',
      ]);
    }

    if (text.contains('zoom out')) {
      return runFirst([
        'chart_zoom_out',
      ]);
    }

    if (text.contains('reset zoom') || text.contains('auto scale')) {
      return runFirst([
        'chart_zoom_reset',
      ]);
    }

    return null;
  }

  Future<String> submit(String rawText) async {
    final fastResult = await _runDukeFastCommand(rawText);

    if (fastResult != null) {
      lastResponse = fastResult;
      notifyListeners();
      return fastResult;
    }

    final text = rawText.trim();

    if (text.isEmpty) {
      return lastResponse;
    }

    conversation.add(
      DukeConversationMessage(
        role: 'user',
        text: text,
        createdAt: DateTime.now(),
      ),
    );

    if (conversation.length > 100) {
      conversation.removeRange(
        0,
        conversation.length - 100,
      );
    }

    // --------------------------------------------------------
    // DUKE ADVANCED REASONING LAYER
    //
    // If a secure AI endpoint is configured, Duke gets a
    // multi-step plan first. If not, the existing deterministic
    // command system below remains the fallback.
    // --------------------------------------------------------
    if (reasoning.enabled) {
      try {
        final start = conversation.length > 14 ? conversation.length - 14 : 0;

        final recentConversation = conversation
            .skip(start)
            .map(
              (message) => <String, String>{
                'role': message.role,
                'text': message.text,
              },
            )
            .toList();

        final plan = await reasoning.plan(
          userMessage: text,
          page: page,
          symbol: symbol,
          timeframe: timeframe,
          availableActions: availableActions.toList()..sort(),
          conversation: recentConversation,
        );

        if (plan != null) {
          final toolResults = <String>[];

          for (final planned in plan.actions) {
            final normalized =
                planned.name.trim().toLowerCase().replaceAll(' ', '_');

            if (!availableActions.contains(normalized)) {
              continue;
            }

            final result = await execute(
              normalized,
              arguments: planned.arguments,
            );

            if (result.trim().isNotEmpty) {
              toolResults.add(result.trim());
            }
          }

          final responseParts = <String>[];

          if (plan.reply.trim().isNotEmpty) {
            responseParts.add(plan.reply.trim());
          }

          if (toolResults.isNotEmpty) {
            responseParts.add(toolResults.join(' '));
          }

          if (responseParts.isNotEmpty) {
            return _answer(
              responseParts.join(' '),
            );
          }
        }
      } catch (_) {
        // Never take Duke offline because the advanced
        // reasoning service is unavailable.
        // Continue into deterministic app-control routing.
      }
    }

    final q = text.toLowerCase();

    if (_containsAny(q, [
      'go back',
      'take me back',
      'previous page',
      'back one page',
    ])) {
      return execute('navigate_back');
    }

    if (_containsAny(q, [
      'scanner',
      'main scanner',
      'all the pairs',
      'pair screen',
      'home screen',
    ])) {
      return execute('open_scanner');
    }

    if (_containsAny(q, [
      'advanced chart',
      'open chart',
      'show chart',
      'chart page',
    ])) {
      return execute('open_advanced_chart');
    }

    if (_containsAny(q, [
      'multi chart',
      'multiple charts',
    ])) {
      return execute('open_multi_chart');
    }

    if (_containsAny(q, [
      'indicator center',
      'indicators page',
      'show indicators',
    ])) {
      return execute(
        'open_indicators',
        arguments: {'command': text},
      );
    }

    if (_containsAny(q, [
      'drawing tools',
      'drawings page',
    ])) {
      return execute('open_drawings');
    }

    if (_containsAny(q, [
      'alerts',
      'alert center',
    ])) {
      return execute('open_alerts');
    }

    if (_containsAny(q, [
      'replay',
      'market replay',
      'trade replay',
    ])) {
      return execute('open_replay');
    }

    if (_containsAny(q, [
      'chart layouts',
      'layouts',
    ])) {
      return execute('open_layouts');
    }

    if (_containsAny(q, [
      'risk tools',
      'risk center',
    ])) {
      return execute('open_risk_tools');
    }

    if (_containsAny(q, [
      'intelligence center',
      'intelligence tools',
    ])) {
      return execute('open_intelligence');
    }

    if (_containsAny(q, [
      'tools center',
      'all tools',
    ])) {
      return execute('open_tools');
    }

    if (_containsAny(q, [
      'markets',
      'market center',
    ])) {
      return execute('open_markets');
    }

    if (q.contains('analytics')) {
      return execute('open_analytics');
    }

    if (_containsAny(q, [
      'tracker',
      'trade tracker',
    ])) {
      return execute('open_tracker');
    }

    if (_containsAny(q, [
      'scan everything',
      'scan all',
      'scan every pair',
      'rank all',
    ])) {
      return execute('scan_all');
    }

    if (_containsAny(q, [
      'deep scan',
      'scan this pair',
      'analyze this pair',
    ])) {
      return execute(
        'deep_scan',
        arguments: {'symbol': symbol},
      );
    }

    if (_containsAny(q, [
      'explain this',
      'explain signal',
      'why buy',
      'why sell',
      'why this trade',
      'what do you see',
    ])) {
      return execute('explain_signal');
    }

    if (q.contains('zoom in')) {
      return execute('chart_zoom_in');
    }

    if (q.contains('zoom out')) {
      return execute('chart_zoom_out');
    }

    if (_containsAny(q, [
      'reset zoom',
      'normal zoom',
    ])) {
      return execute('chart_zoom_reset');
    }

    if (_containsAny(q, [
      'undo drawing',
      'undo last drawing',
    ])) {
      return execute('drawing_undo');
    }

    if (_containsAny(q, [
      'redo drawing',
      'redo last drawing',
    ])) {
      return execute('drawing_redo');
    }

    if (_containsAny(q, [
      'clear drawings',
      'delete all drawings',
      'remove all drawings',
    ])) {
      return execute('drawing_clear');
    }

    if (_containsAny(q, [
      'support and resistance',
      'support resistance',
      'key levels',
    ])) {
      return execute('support_resistance');
    }

    if (_containsAny(q, [
      'fibonacci',
      ' fib ',
      'draw fib',
    ])) {
      return execute('fibonacci');
    }

    if (q.contains('pattern')) {
      return execute('pattern_scanner');
    }

    if (q.contains('breakout')) {
      return execute('breakout_detector');
    }

    if (q.contains('liquidity')) {
      return execute('liquidity_analysis');
    }

    if (_containsAny(q, [
      'backtest',
      'back test',
    ])) {
      return execute('backtester');
    }

    if (_containsAny(q, [
      'strategy lab',
      'build strategy',
      'create strategy',
      'strategy builder',
    ])) {
      return execute(
        'strategy_lab',
        arguments: {'prompt': text},
      );
    }

    final frame = _extractTimeframe(text);

    if (frame != null &&
        _containsAny(q, [
          'timeframe',
          'switch',
          'change',
          'set',
          'put it on',
        ])) {
      return execute(
        'set_timeframe',
        arguments: {'timeframe': frame},
      );
    }

    final pair = _extractPair(text);

    if (pair != null &&
        _containsAny(q, [
          'switch',
          'change',
          'select',
          'pair',
          'show me',
          'go to',
        ])) {
      return execute(
        'set_pair',
        arguments: {'symbol': pair},
      );
    }

    if (_containsAny(q, [
      'autonomous mode on',
      'turn automation on',
      'turn autonomous on',
      'start automation',
    ])) {
      autonomousMode = true;
      notifyListeners();

      return _answer(
        'Autonomous analysis mode is on. I will coordinate the registered scanner and analysis tools.',
      );
    }

    if (_containsAny(q, [
      'autonomous mode off',
      'turn automation off',
      'stop automation',
    ])) {
      autonomousMode = false;
      notifyListeners();

      return _answer(
        'Autonomous analysis mode is off.',
      );
    }

    final generic = _actions['natural_command'];

    if (generic != null && generic.isNotEmpty) {
      return execute(
        'natural_command',
        arguments: {'text': text},
      );
    }

    return _answer(
      'I am on $page with $symbol on $timeframe. '
      'I understood your request, but that exact control has not been registered with my app command bus yet.',
    );
  }

  String _answer(String text) {
    lastResponse = text;

    conversation.add(
      DukeConversationMessage(
        role: 'duke',
        text: text,
        createdAt: DateTime.now(),
      ),
    );

    if (conversation.length > 100) {
      conversation.removeRange(
        0,
        conversation.length - 100,
      );
    }

    notifyListeners();
    return text;
  }

  String _normalizeAction(String value) =>
      value.trim().toLowerCase().replaceAll(' ', '_');

  bool _containsAny(String source, List<String> values) =>
      values.any(source.contains);

  String? _extractPair(String text) {
    final upper = text.toUpperCase().replaceAll('/', '');

    final match = RegExp(
      r'\b([A-Z]{6}(?:_OTC)?)\b',
    ).firstMatch(upper);

    return match?.group(1);
  }

  String? _extractTimeframe(String text) {
    final upper = text.toUpperCase();

    const frames = <String>[
      'M1',
      'M5',
      'M15',
      'M30',
      'M45',
      'H1',
      'H2',
      'H4',
      'H8',
      'D1',
      'W1',
      'MN1',
    ];

    for (final frame in frames) {
      if (RegExp(
        '(^|[^A-Z0-9])$frame([^A-Z0-9]|\$)',
      ).hasMatch(upper)) {
        return frame;
      }
    }

    if (upper.contains('ONE MINUTE') || upper.contains('1 MINUTE')) {
      return 'M1';
    }

    if (upper.contains('FIVE MINUTE') || upper.contains('5 MINUTE')) {
      return 'M5';
    }

    if (upper.contains('FIFTEEN MINUTE') || upper.contains('15 MINUTE')) {
      return 'M15';
    }

    if (upper.contains('ONE HOUR') || upper.contains('1 HOUR')) {
      return 'H1';
    }

    if (upper.contains('FOUR HOUR') || upper.contains('4 HOUR')) {
      return 'H4';
    }

    return null;
  }
}
