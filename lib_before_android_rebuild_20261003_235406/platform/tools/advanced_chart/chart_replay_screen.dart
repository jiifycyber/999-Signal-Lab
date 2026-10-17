import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_tick_store.dart';

class ChartReplayScreen extends StatefulWidget {
  final String symbol;
  final String timeframe;

  const ChartReplayScreen({
    super.key,
    required this.symbol,
    required this.timeframe,
  });

  @override
  State<ChartReplayScreen> createState() => _ChartReplayScreenState();
}

class _ChartReplayScreenState extends State<ChartReplayScreen> {
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF27FF88);
  static const red = Color(0xFFFF4057);
  static const amber = Color(0xFFFFC857);

  List<ChartCandleRecord> _candles = <ChartCandleRecord>[];

  int _replayIndex = 0;
  bool _playing = false;
  bool _loading = true;

  double _speed = 1.0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadReplay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadReplay() async {
    setState(() {
      _loading = true;
      _playing = false;
    });

    _timer?.cancel();

    await ChartTickStore.loadSymbol(widget.symbol);

    final saved = ChartTickStore.savedCandles(widget.symbol).toList()
      ..sort(
        (a, b) => a.bucket.compareTo(b.bucket),
      );

    if (!mounted) {
      return;
    }

    setState(() {
      _candles = saved;
      _loading = false;

      if (_candles.isEmpty) {
        _replayIndex = 0;
      } else {
        // Start far enough into history to give the replay chart context.
        _replayIndex = math.min(
          math.max(1, 20),
          _candles.length,
        );
      }
    });
  }

  List<ChartCandleRecord> get _visibleCandles {
    if (_candles.isEmpty || _replayIndex <= 0) {
      return const <ChartCandleRecord>[];
    }

    return _candles.sublist(
      0,
      _replayIndex.clamp(0, _candles.length),
    );
  }

  ChartCandleRecord? get _currentCandle {
    if (_visibleCandles.isEmpty) {
      return null;
    }

    return _visibleCandles.last;
  }

  double get _progress {
    if (_candles.isEmpty) {
      return 0;
    }

    return (_replayIndex / _candles.length).clamp(0.0, 1.0);
  }

  Duration get _playInterval {
    // 0.5x = 2 sec
    // 1x   = 1 sec
    // 2x   = 500 ms
    // 4x   = 250 ms
    final milliseconds = (1000 / _speed).round();

    return Duration(
      milliseconds: milliseconds.clamp(100, 4000),
    );
  }

  void _restartTimer() {
    _timer?.cancel();

    if (!_playing || _candles.isEmpty) {
      return;
    }

    _timer = Timer.periodic(
      _playInterval,
      (_) => _advance(),
    );
  }

  void _togglePlay() {
    if (_candles.isEmpty) {
      return;
    }

    if (_replayIndex >= _candles.length) {
      setState(() {
        _replayIndex = math.min(20, _candles.length);
      });
    }

    setState(() {
      _playing = !_playing;
    });

    if (_playing) {
      _restartTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _advance() {
    if (_candles.isEmpty) {
      return;
    }

    if (_replayIndex >= _candles.length) {
      _timer?.cancel();

      if (mounted) {
        setState(() {
          _playing = false;
        });
      }

      return;
    }

    setState(() {
      _replayIndex++;
    });
  }

  void _stepForward() {
    _timer?.cancel();

    setState(() {
      _playing = false;

      if (_replayIndex < _candles.length) {
        _replayIndex++;
      }
    });
  }

  void _stepBack() {
    _timer?.cancel();

    setState(() {
      _playing = false;

      if (_replayIndex > 1) {
        _replayIndex--;
      }
    });
  }

  void _resetReplay() {
    _timer?.cancel();

    setState(() {
      _playing = false;
      _replayIndex = _candles.isEmpty
          ? 0
          : math.min(
              20,
              _candles.length,
            );
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDate(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');

    return '${time.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentCandle;

    return Scaffold(
      backgroundColor: const Color(0xFF020811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: Text(
          'MARKET REPLAY • ${widget.symbol} • ${widget.timeframe}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload replay history',
            onPressed: _loadReplay,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Reset replay',
            onPressed: _resetReplay,
            icon: const Icon(Icons.restart_alt),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF030B13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cyan.withValues(alpha: .25),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: cyan,
                      ),
                    )
                  : _candles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'NO SAVED CANDLES AVAILABLE',
                                style: TextStyle(
                                  color: amber,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.symbol} does not have replay history stored yet.',
                                style: const TextStyle(
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadReplay,
                                child: const Text('RELOAD'),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ReplayCandlePainter(
                                  candles: _visibleCandles,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xE6071019),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: cyan.withValues(alpha: .18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.symbol} • ${widget.timeframe}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_replayIndex.toString()} / ${_candles.length}',
                                      style: const TextStyle(
                                        color: cyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (current != null)
                              Positioned(
                                right: 14,
                                top: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xE6071019),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: green.withValues(alpha: .18),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        current.close.toStringAsFixed(5),
                                        style: TextStyle(
                                          color: current.close >= current.open
                                              ? green
                                              : red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_formatDate(current.bucket)} ${_formatTime(current.bucket)}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
          ),
          Container(
            color: const Color(0xFF06121E),
            padding: const EdgeInsets.fromLTRB(
              10,
              8,
              10,
              10,
            ),
            child: Column(
              children: [
                if (_candles.isNotEmpty)
                  Row(
                    children: [
                      const Text(
                        'START',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _replayIndex
                              .clamp(
                                1,
                                math.max(1, _candles.length),
                              )
                              .toDouble(),
                          min: 1,
                          max: math
                              .max(
                                1,
                                _candles.length,
                              )
                              .toDouble(),
                          onChanged: (value) {
                            _timer?.cancel();

                            setState(() {
                              _playing = false;
                              _replayIndex = value.round().clamp(
                                    1,
                                    _candles.length,
                                  );
                            });
                          },
                        ),
                      ),
                      const Text(
                        'END',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Reset',
                      onPressed: _candles.isEmpty ? null : _resetReplay,
                      icon: const Icon(
                        Icons.restart_alt,
                        color: Colors.white70,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Step back one candle',
                      onPressed: _candles.isEmpty ? null : _stepBack,
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: _playing ? 'Pause' : 'Play',
                      onPressed: _candles.isEmpty ? null : _togglePlay,
                      icon: Icon(
                        _playing ? Icons.pause_circle : Icons.play_circle,
                        color: green,
                        size: 36,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Step forward one candle',
                      onPressed: _candles.isEmpty ? null : _stepForward,
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 5,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 14),
                    DropdownButton<double>(
                      value: _speed,
                      dropdownColor: const Color(0xFF06121E),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: .5,
                          child: Text('0.5x'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('1x'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('2x'),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text('4x'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _speed = value;
                        });

                        if (_playing) {
                          _restartTimer();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayCandlePainter extends CustomPainter {
  final List<ChartCandleRecord> candles;

  const _ReplayCandlePainter({
    required this.candles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 18.0;
    const rightPad = 74.0;
    const topPad = 42.0;
    const bottomPad = 32.0;

    final width = math.max(
      1.0,
      size.width - leftPad - rightPad,
    );

    final height = math.max(
      1.0,
      size.height - topPad - bottomPad,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      final x = leftPad + width * i / 10;

      canvas.drawLine(
        Offset(x, topPad),
        Offset(x, topPad + height),
        gridPaint,
      );
    }

    for (int i = 0; i <= 8; i++) {
      final y = topPad + height * i / 8;

      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + width, y),
        gridPaint,
      );
    }

    if (candles.isEmpty) {
      return;
    }

    // Keep the replay visually useful by showing the latest 64
    // revealed candles while preserving the historical progression.
    final visible =
        candles.length <= 64 ? candles : candles.sublist(candles.length - 64);

    double low = visible.first.low;
    double high = visible.first.high;

    for (final candle in visible) {
      low = math.min(low, candle.low);
      high = math.max(high, candle.high);
    }

    var range = high - low;

    if (range.abs() < 0.0000001) {
      final center = visible.last.close;
      final padding = math.max(
        center.abs() * .00015,
        .00005,
      );

      low = center - padding;
      high = center + padding;
      range = high - low;
    } else {
      final padding = range * .10;

      low -= padding;
      high += padding;
      range = high - low;
    }

    double yFor(double price) {
      final normalized = (price - low) / range;

      return topPad + height * (1.0 - normalized);
    }

    final slots = math.max(64, visible.length);
    final slotWidth = width / slots;

    final usedWidth = visible.length * slotWidth;

    final startX = leftPad + math.max(0.0, width - usedWidth);

    final bodyWidth = math.max(
      2.5,
      math.min(
        7.0,
        slotWidth * .78,
      ),
    );

    for (int i = 0; i < visible.length; i++) {
      final candle = visible[i];

      final x = startX + slotWidth * i + slotWidth / 2;

      final bullish = candle.close >= candle.open;

      final color = bullish ? const Color(0xFF27FF88) : const Color(0xFFFF4057);

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2;

      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final highY = yFor(candle.high);
      final lowY = yFor(candle.low);
      final openY = yFor(candle.open);
      final closeY = yFor(candle.close);

      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        wickPaint,
      );

      final top = math.min(openY, closeY);
      final bottom = math.max(openY, closeY);

      canvas.drawRect(
        Rect.fromLTWH(
          x - bodyWidth / 2,
          top,
          bodyWidth,
          math.max(2.0, bottom - top),
        ),
        bodyPaint,
      );
    }

    final last = visible.last;
    final currentY = yFor(last.close);

    final currentPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: .70)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(leftPad, currentY),
      Offset(leftPad + width, currentY),
      currentPaint,
    );

    final priceLabel = TextPainter(
      text: TextSpan(
        text: last.close.toStringAsFixed(5),
        style: const TextStyle(
          color: Color(0xFF27FF88),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    priceLabel.paint(
      canvas,
      Offset(
        leftPad + width + 7,
        currentY - 6,
      ),
    );

    // Time labels.
    final labelCount = math.min(
      6,
      visible.length,
    );

    if (labelCount > 0) {
      for (int i = 0; i < labelCount; i++) {
        final index = labelCount == 1
            ? visible.length - 1
            : ((visible.length - 1) * i / (labelCount - 1)).round();

        final candle = visible[index];
        final x = startX + slotWidth * index + slotWidth / 2;

        final hour = candle.bucket.hour.toString().padLeft(2, '0');
        final minute = candle.bucket.minute.toString().padLeft(2, '0');

        final painter = TextPainter(
          text: TextSpan(
            text: '$hour:$minute',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        painter.paint(
          canvas,
          Offset(
            x - painter.width / 2,
            topPad + height + 7,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _ReplayCandlePainter oldDelegate,
  ) {
    return true;
  }
}
