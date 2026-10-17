enum DukeCommandType {
  conversation,
  selectPair,
  setTimeframe,
  deepScan,
  scanAll,
  analyze,
  liquidity,
  supportResistance,
  fibonacci,
  patterns,
  breakout,
  openChart,
  addIndicator,
  removeIndicator,
  unknown,
}

class DukeCommand {
  final DukeCommandType type;
  final String rawText;
  final String? value;
  final Map<String, dynamic> arguments;

  const DukeCommand({
    required this.type,
    required this.rawText,
    this.value,
    this.arguments = const {},
  });
}

class DukeCommandResult {
  final bool success;
  final String message;
  final DukeCommandType type;

  const DukeCommandResult({
    required this.success,
    required this.message,
    required this.type,
  });
}
