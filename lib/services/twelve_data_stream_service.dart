import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class TwelveDataStreamTick {
  final String symbol;
  final double price;
  final DateTime timestamp;

  const TwelveDataStreamTick({
    required this.symbol,
    required this.price,
    required this.timestamp,
  });
}

class TwelveDataStreamService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<TwelveDataStreamTick> _controller =
      StreamController<TwelveDataStreamTick>.broadcast();

  Stream<TwelveDataStreamTick> get tickStream => _controller.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(List<String> symbols) async {
    await disconnect();

    if (symbols.isEmpty) return;

    final uri = Uri.parse(
      'wss://bridge.sciool.net/ws/po',
    );

    _channel = WebSocketChannel.connect(uri);

    await _channel!.ready;

    _subscription = _channel!.stream.listen(
      _handleMessage,
      onError: (_) {
        _channel = null;
      },
      onDone: () {
        _channel = null;
      },
    );
  }

  final Map<String, DateTime> _lastAcceptedTick = {};

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      if (data is! Map<String, dynamic>) return;
      if (data['event'] != 'price') return;

      final rawSymbol = '${data['symbol']}';
      final symbol = rawSymbol.replaceFirst(
        RegExp(r'_otc$', caseSensitive: false),
        '_OTC',
      );
      final rawPrice = data['price'];

      final price = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '');

      if (symbol.isEmpty || price == null || !price.isFinite || price <= 0) {
        return;
      }

      final timestampRaw = data['timestamp'];

      DateTime timestamp = DateTime.now();

      if (timestampRaw is num) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
          (timestampRaw.toDouble() * 1000).round(),
        );
      }

      final now = DateTime.now();
      final age = now.difference(timestamp);
      if (age > const Duration(seconds: 3) ||
          age < const Duration(seconds: -2)) {
        return;
      }

      final previous = _lastAcceptedTick[symbol];
      if (previous != null && timestamp.isBefore(previous)) return;
      _lastAcceptedTick[symbol] = timestamp;

      if (!_controller.isClosed) {
        _controller.add(
          TwelveDataStreamTick(
            symbol: symbol,
            price: price,
            timestamp: timestamp,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
