class DukeSignalRecord {
  final String id;
  final String symbol;
  final String decision;
  final double confidence;
  final double entryPrice;
  final DateTime openedAt;

  double? exitPrice;
  DateTime? closedAt;
  String status;
  String outcome;
  double pnlPercent;

  DukeSignalRecord({
    required this.id,
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.entryPrice,
    required this.openedAt,
    this.exitPrice,
    this.closedAt,
    this.status = 'OPEN',
    this.outcome = 'PENDING',
    this.pnlPercent = 0,
  });

  bool get isOpen => status == 'OPEN';
}

class DukePerformanceSummary {
  final int totalSignals;
  final int closedSignals;
  final int wins;
  final int losses;
  final int breakeven;
  final double winRate;
  final double averagePnlPercent;
  final double totalPnlPercent;

  const DukePerformanceSummary({
    required this.totalSignals,
    required this.closedSignals,
    required this.wins,
    required this.losses,
    required this.breakeven,
    required this.winRate,
    required this.averagePnlPercent,
    required this.totalPnlPercent,
  });
}

class AgentDukeSignalMemory {
  final List<DukeSignalRecord> _records = [];

  List<DukeSignalRecord> get records => List.unmodifiable(_records);

  DukeSignalRecord recordSignal({
    required String symbol,
    required String decision,
    required double confidence,
    required double entryPrice,
  }) {
    final now = DateTime.now();

    final record = DukeSignalRecord(
      id: '${symbol}_${now.microsecondsSinceEpoch}',
      symbol: symbol,
      decision: decision,
      confidence: confidence,
      entryPrice: entryPrice,
      openedAt: now,
    );

    _records.add(record);
    return record;
  }

  DukeSignalRecord? closeSignal({
    required String id,
    required double exitPrice,
  }) {
    DukeSignalRecord? record;

    for (final item in _records) {
      if (item.id == id) {
        record = item;
        break;
      }
    }

    if (record == null || !record.isOpen) {
      return null;
    }

    double pnl;

    if (record.decision == 'BUY') {
      pnl = ((exitPrice - record.entryPrice) / record.entryPrice) * 100;
    } else if (record.decision == 'SELL') {
      pnl = ((record.entryPrice - exitPrice) / record.entryPrice) * 100;
    } else {
      pnl = 0;
    }

    record.exitPrice = exitPrice;
    record.closedAt = DateTime.now();
    record.status = 'CLOSED';
    record.pnlPercent = pnl;

    if (pnl > 0.01) {
      record.outcome = 'WIN';
    } else if (pnl < -0.01) {
      record.outcome = 'LOSS';
    } else {
      record.outcome = 'BREAKEVEN';
    }

    return record;
  }

  DukePerformanceSummary performance() {
    final closed = _records.where((record) => !record.isOpen).toList();

    final wins = closed.where((record) => record.outcome == 'WIN').length;
    final losses = closed.where((record) => record.outcome == 'LOSS').length;
    final breakeven =
        closed.where((record) => record.outcome == 'BREAKEVEN').length;

    final totalPnl = closed.fold<double>(
      0,
      (sum, record) => sum + record.pnlPercent,
    );

    final winRate = closed.isEmpty ? 0.0 : (wins / closed.length) * 100;

    final averagePnl = closed.isEmpty ? 0.0 : totalPnl / closed.length;

    return DukePerformanceSummary(
      totalSignals: _records.length,
      closedSignals: closed.length,
      wins: wins,
      losses: losses,
      breakeven: breakeven,
      winRate: winRate,
      averagePnlPercent: averagePnl,
      totalPnlPercent: totalPnl,
    );
  }
}
