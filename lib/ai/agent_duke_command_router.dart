import 'agent_duke_command.dart';

class AgentDukeCommandRouter {
  const AgentDukeCommandRouter();

  DukeCommand interpret(String input) {
    final raw = input.trim();
    final q = raw.toLowerCase();

    if (q.isEmpty) {
      return DukeCommand(
        type: DukeCommandType.unknown,
        rawText: raw,
      );
    }

    if (q.contains('scan all') ||
        q.contains('scan every') ||
        q.contains('all pairs')) {
      return DukeCommand(
        type: DukeCommandType.scanAll,
        rawText: raw,
      );
    }

    if (q.contains('deep scan') ||
        q.contains('scan this pair') ||
        q.contains('scan the pair')) {
      return DukeCommand(
        type: DukeCommandType.deepScan,
        rawText: raw,
      );
    }

    if (q.contains('support') || q.contains('resistance')) {
      return DukeCommand(
        type: DukeCommandType.supportResistance,
        rawText: raw,
      );
    }

    if (q.contains('liquidity')) {
      return DukeCommand(
        type: DukeCommandType.liquidity,
        rawText: raw,
      );
    }

    if (q.contains('fibonacci') || q.contains(' fib')) {
      return DukeCommand(
        type: DukeCommandType.fibonacci,
        rawText: raw,
      );
    }

    if (q.contains('pattern')) {
      return DukeCommand(
        type: DukeCommandType.patterns,
        rawText: raw,
      );
    }

    if (q.contains('breakout')) {
      return DukeCommand(
        type: DukeCommandType.breakout,
        rawText: raw,
      );
    }

    if (q.contains('open chart') ||
        q.contains('advanced chart') ||
        q.contains('show chart')) {
      return DukeCommand(
        type: DukeCommandType.openChart,
        rawText: raw,
      );
    }

    final timeframe = _extractTimeframe(q);

    if (timeframe != null &&
        (q.contains('timeframe') ||
            q.contains('set ') ||
            q.contains('switch ') ||
            q.contains('change '))) {
      return DukeCommand(
        type: DukeCommandType.setTimeframe,
        rawText: raw,
        value: timeframe,
      );
    }

    final pair = _extractPair(q);

    if (pair != null &&
        (q.contains('switch') ||
            q.contains('change') ||
            q.contains('select') ||
            q.contains('go to') ||
            q.contains('show'))) {
      return DukeCommand(
        type: DukeCommandType.selectPair,
        rawText: raw,
        value: pair,
      );
    }

    if (q.contains('analyze') ||
        q.contains('analysis') ||
        q.contains('what do you see') ||
        q.contains('what are you seeing')) {
      return DukeCommand(
        type: DukeCommandType.analyze,
        rawText: raw,
      );
    }

    return DukeCommand(
      type: DukeCommandType.conversation,
      rawText: raw,
    );
  }

  String? _extractTimeframe(String q) {
    const values = [
      'MN1',
      'W1',
      'D1',
      'H8',
      'H4',
      'H2',
      'H1',
      'M45',
      'M30',
      'M15',
      'M5',
      'M1',
    ];

    final upper = q.toUpperCase();

    for (final value in values) {
      if (RegExp(r'(^|\s)' + value + r'($|\s)').hasMatch(upper)) {
        return value;
      }
    }

    if (q.contains('one minute') || q.contains('1 minute')) {
      return 'M1';
    }

    if (q.contains('five minute') || q.contains('5 minute')) {
      return 'M5';
    }

    if (q.contains('fifteen minute') || q.contains('15 minute')) {
      return 'M15';
    }

    if (q.contains('one hour') || q.contains('1 hour')) {
      return 'H1';
    }

    return null;
  }

  String? _extractPair(String q) {
    const pairs = [
      'EURUSD',
      'GBPUSD',
      'USDJPY',
      'USDCHF',
      'USDCAD',
      'AUDUSD',
      'NZDUSD',
      'EURGBP',
      'GBPJPY',
      'EURJPY',
      'AUDJPY',
      'XAUUSD',
      'BTCUSD',
    ];

    final compact = q
        .toUpperCase()
        .replaceAll('/', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');

    for (final pair in pairs) {
      if (compact.contains(pair)) {
        return pair;
      }
    }

    return null;
  }
}
