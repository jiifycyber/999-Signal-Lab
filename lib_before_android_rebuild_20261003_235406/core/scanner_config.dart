class ScannerConfig {
  static const List<String> forexPairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'AUD/USD',
    'USD/CHF',
    'USD/CAD',
    'NZD/USD',
    'EUR/GBP',
  ];

  static const List<String> timeframes = [
    '1M',
    '5M',
    '15M',
    '1H',
    '4H',
    '1D',
  ];

  static const String defaultPair = 'EUR/USD';
  static const String defaultTimeframe = '1H';
}
