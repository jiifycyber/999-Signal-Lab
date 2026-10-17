class DukeMarketContext {
  String page;
  String symbol;
  String timeframe;

  String? direction;
  double? confidence;
  double? qualityScore;

  double? support;
  double? resistance;

  String? trend;
  String? momentum;
  String? liquidity;
  String? pattern;
  String? breakout;

  final List<String> activeIndicators = [];

  DukeMarketContext({
    this.page = 'AI SCANNER',
    this.symbol = 'EURUSD',
    this.timeframe = 'M1',
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'symbol': symbol,
      'timeframe': timeframe,
      'direction': direction,
      'confidence': confidence,
      'quality_score': qualityScore,
      'support': support,
      'resistance': resistance,
      'trend': trend,
      'momentum': momentum,
      'liquidity': liquidity,
      'pattern': pattern,
      'breakout': breakout,
      'active_indicators': List<String>.from(activeIndicators),
    };
  }
}
