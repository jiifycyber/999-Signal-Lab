import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/forex_quote.dart';

class TwelveDataService {
  static const String _apiKey = String.fromEnvironment('TWELVE_DATA_API_KEY');

  static const Map<String, String> intervals = {
    'M1': '1min',
    'M5': '5min',
    'M15': '15min',
    'M30': '30min',
    'M45': '45min',
    'H1': '1h',
    'H2': '2h',
    'H4': '4h',
    'H8': '8h',
    'D1': '1day',
    'W1': '1week',
    'MN1': '1month',
  };

  String intervalFor(String timeframe) {
    return intervals[timeframe] ?? '1min';
  }

  Future<ForexQuote?> fetchLatest(
    String symbol,
    String timeframe,
  ) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'TWELVE_DATA_API_KEY missing. '
        'Run Flutter with --dart-define=TWELVE_DATA_API_KEY=YOUR_KEY',
      );
    }

    final interval = intervalFor(timeframe);

    final uri = Uri.https(
      'api.twelvedata.com',
      '/time_series',
      {
        'symbol': symbol,
        'interval': interval,
        'outputsize': '2',
        'apikey': _apiKey,
      },
    );

    print('TWELVE REQUEST: $symbol | $interval');
    print('TWELVE REQUEST: \$symbol | \$interval');
    final response = await http.get(uri);
    print('TWELVE HTTP: \${response.statusCode}');
    print('TWELVE RESPONSE: \${response.body}');
    print('TWELVE HTTP: ${response.statusCode}');
    print('TWELVE RESPONSE: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Twelve Data HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (data['status'] == 'error') {
      throw Exception(
        data['message'] ?? 'Twelve Data request failed',
      );
    }

    final values = data['values'];

    if (values is! List || values.isEmpty) {
      return null;
    }

    final candle = Map<String, dynamic>.from(values.first);

    final open = double.tryParse('${candle['open']}');
    final high = double.tryParse('${candle['high']}');
    final low = double.tryParse('${candle['low']}');
    final close = double.tryParse('${candle['close']}');

    if (open == null || high == null || low == null || close == null) {
      return null;
    }

    final timestamp =
        DateTime.tryParse('${candle['datetime']}') ?? DateTime.now();

    return ForexQuote(
      symbol: symbol,
      price: close,
      open: open,
      high: high,
      low: low,
      timestamp: timestamp,
    );
  }
}
