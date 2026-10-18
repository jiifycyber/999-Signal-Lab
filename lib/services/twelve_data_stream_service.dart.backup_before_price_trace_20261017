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
  static const String _bridgeUrl = 'wss://bridge.sciool.net/ws/po';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;

  bool _disposed = false;
  bool _manualDisconnect = false;
  bool _connecting = false;

  List<String> _symbols = const [];
  DateTime? _lastTickAt;
  int _reconnectAttempt = 0;

  final StreamController<TwelveDataStreamTick> _controller =
      StreamController<TwelveDataStreamTick>.broadcast();

  final Map<String, DateTime> _lastAcceptedTick = {};

  Stream<TwelveDataStreamTick> get tickStream => _controller.stream;

  bool get isConnected => _channel != null;
  DateTime? get lastTickAt => _lastTickAt;

  Future<void> connect(List<String> symbols) async {
    _symbols = List<String>.from(symbols);

    if (_symbols.isEmpty || _disposed) return;

    _manualDisconnect = false;
    _startWatchdog();
    await _openSocket();
  }

  Future<void> _openSocket() async {
    if (_disposed || _manualDisconnect || _connecting || _symbols.isEmpty) {
      return;
    }

    _connecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await _subscription?.cancel();
      _subscription = null;

      await _channel?.sink.close();
      _channel = null;

      final channel = WebSocketChannel.connect(
        Uri.parse(_bridgeUrl),
      );

      _channel = channel;

      await channel.ready;

      if (_disposed || _manualDisconnect) {
        await channel.sink.close();
        if (identical(_channel, channel)) {
          _channel = null;
        }
        return;
      }

      _reconnectAttempt = 0;
      _lastTickAt = DateTime.now();

      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (_) {
          if (identical(_channel, channel)) {
            _channel = null;
          }
          _scheduleReconnect();
        },
        onDone: () {
          if (identical(_channel, channel)) {
            _channel = null;
          }
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (_) {
      _channel = null;
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _manualDisconnect || _symbols.isEmpty) return;
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectAttempt++;

    final seconds = _reconnectAttempt <= 1
        ? 1
        : _reconnectAttempt == 2
            ? 2
            : _reconnectAttempt == 3
                ? 3
                : 5;

    _reconnectTimer = Timer(
      Duration(seconds: seconds),
      () => unawaited(_openSocket()),
    );
  }

  void _startWatchdog() {
    _watchdogTimer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (_disposed || _manualDisconnect || _symbols.isEmpty) {
          return;
        }

        final last = _lastTickAt;
        final stale = last == null ||
            DateTime.now().difference(last) > const Duration(seconds: 5);

        if (_channel == null || stale) {
          unawaited(_openSocket());
        }
      },
    );
  }

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

      // Ignore signal/forecast snapshots whose timestamp is not numeric.
      if (timestampRaw is! num) return;

      final sourceTimestamp = DateTime.fromMillisecondsSinceEpoch(
        (timestampRaw.toDouble() * 1000).round(),
      );

      final now = DateTime.now();
      final age = now.difference(sourceTimestamp);

      late final DateTime timestamp;

      // Pocket Option can report a future-skewed server timestamp.
      // Keep the genuine tick but timestamp it at local arrival time.
      if (age < const Duration(seconds: -2)) {
        timestamp = now;
      } else if (age > const Duration(seconds: 3)) {
        return;
      } else {
        timestamp = sourceTimestamp;
      }

      final previous = _lastAcceptedTick[symbol];
      if (previous != null && timestamp.isBefore(previous)) return;

      _lastAcceptedTick[symbol] = timestamp;
      _lastTickAt = now;

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
    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _lastTickAt = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _controller.close();
  }
}
