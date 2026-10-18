import 'dart:async';
import 'dart:math' show max, min;

import '../models/forex_quote.dart';
import 'twelve_data_stream_service.dart';

enum MarketMode { demo, live }

class MarketDataService {
  MarketMode mode = MarketMode.live;

  final TwelveDataStreamService _streamService = TwelveDataStreamService();

  StreamSubscription<TwelveDataStreamTick>? _streamSubscription;

  final StreamController<List<ForexQuote>> _controller =
      StreamController<List<ForexQuote>>.broadcast();

  final Map<String, double> _livePrices = {};

  String timeframe = 'M1';

  final List<String> _symbols = const [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'AUD/USD',
    'USD/CHF',
    'USD/CAD',
    'NZD/USD',
    'EUR/GBP',
  ];

  Stream<List<ForexQuote>> get quoteStream => _controller.stream;

  void start() {
    _startLiveStream();
  }

  void setMode(MarketMode newMode) {
    mode = newMode;

    // LIVE and DEMO both use genuine Twelve Data market ticks.
    _startLiveStream();
  }

  void setTimeframe(String newTimeframe) {
    timeframe = newTimeframe;
  }

  Future<void> _startLiveStream() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    await _streamService.disconnect();

    _streamSubscription = _streamService.tickStream.listen((tick) {
      final oldPrice = _livePrices[tick.symbol] ?? tick.price;

      _livePrices[tick.symbol] = tick.price;

      final quote = ForexQuote(
        symbol: tick.symbol,
        price: tick.price,
        open: oldPrice,
        high: max(oldPrice, tick.price),
        low: min(oldPrice, tick.price),
        timestamp: tick.timestamp,
      );

      if (!_controller.isClosed) {
        _controller.add([quote]);
      }
    });

    try {
      await _streamService.connect(_symbols);
    } catch (_) {
      // Never substitute fake or simulated prices.
      // If Twelve Data does not provide a pair, it remains unavailable/REST.
    }
  }

  Future<void> _stopLiveStream() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _streamService.disconnect();
  }

  Future<void> _refresh() async {
    // Prices arrive continuously from Twelve Data through Render WebSocket.
  }

  void dispose() {
    _streamSubscription?.cancel();
    _streamService.dispose();
    _controller.close();
  }
}
