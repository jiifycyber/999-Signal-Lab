import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/scan_signal.dart';
import '../ai/agent_duke_master_engine.dart';
import '../services/scanner_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:passkeys/authenticator.dart';

class ProLiveDashboard extends StatefulWidget {
  const ProLiveDashboard({super.key});

  @override
  State<ProLiveDashboard> createState() => _ProLiveDashboardState();
}

class _ProLiveDashboardState extends State<ProLiveDashboard> {
  static const Color bg = Color(0xFF01050D);
  static const Color panel = Color(0xFF04101C);
  static const Color panel2 = Color(0xFF071B2C);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color green = Color(0xFF27FF88);
  static const Color red = Color(0xFFFF4057);
  static const Color amber = Color(0xFFFFD23F);
  static const Color purple = Color(0xFF9A5CFF);

  static List<BoxShadow> get hudGlow => [
        BoxShadow(
          color: cyan.withValues(alpha: 0.18),
          blurRadius: 14,
          spreadRadius: 0.5,
        ),
        BoxShadow(
          color: const Color(0xFF0077FF).withValues(alpha: 0.10),
          blurRadius: 28,
          spreadRadius: 1,
        ),
      ];

  static BoxDecoration hudPanelDecoration({
    Color? borderColor,
    double radius = 7,
    bool strongGlow = false,
  }) {
    final glowColor = borderColor ?? cyan;

    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF071828),
          Color(0xFF03101C),
          Color(0xFF020A13),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glowColor.withValues(alpha: 0.62),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(
            alpha: strongGlow ? 0.24 : 0.12,
          ),
          blurRadius: strongGlow ? 18 : 10,
          spreadRadius: strongGlow ? 1.2 : 0.2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.48),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  late final ScannerController scannerController;

  StreamSubscription<List<ScanSignal>>? signalSubscription;
  StreamSubscription? quoteSubscription;

  final Map<String, double> latestPrices = {};
  final Map<String, List<double>> histories = {};
  final Set<String> watchlist = {};
  String? strengthCurrencyFilter;

  List<ScanSignal> liveSignals = [];

  // MOBILE TOP-12 SNAPSHOT
  // Symbols stay fixed until SCAN ALL LIVE MARKETS is pressed again.
  final List<String> lockedTop12Symbols = [];
  final Map<String, ScanSignal> lastSignalBySymbol = {};
  bool refreshTop12Requested = false;

  DateTime? top12LockedAt;
  static const Duration top12LockDuration = Duration(seconds: 60);

  String selectedPair = 'EURUSD';
  String timeframe = 'M1';
  String pairFilter = 'ALL';
  String search = '';
  String selectedNav = 'AI SCANNER';

  bool connected = false;
  bool liveMode = true;
  bool strictMode = true;

  @override
  void initState() {
    super.initState();

    scannerController = ScannerController();

    signalSubscription = scannerController.signalStream.listen((signals) {
      if (!mounted) return;

      setState(() {
        liveSignals = signals;
        connected = true;

        // Keep the newest signal for every symbol so a locked row does
        // not disappear just because an individual stream update changes.
        for (final signal in signals) {
          lastSignalBySymbol[_normalize(signal.symbol)] = signal;
        }

        // Initial dashboard load: lock the strongest 12.
        if (lockedTop12Symbols.isEmpty && signals.length >= 12) {
          _lockTop12(signals);
        }

        // Manual rescan overrides the timer immediately.
        if (refreshTop12Requested && signals.length >= 12) {
          _lockTop12(signals);
          refreshTop12Requested = false;
        } else if (signals.length >= 12 &&
            top12LockedAt != null &&
            DateTime.now().difference(top12LockedAt!) >= top12LockDuration) {
          // After 60 seconds, allow a fresh strongest Top 12.
          _lockTop12(signals);
        }

        // Never automatically change the pair the user is viewing.
        // Scanner updates may change data, but not the selected pair.
      });
    });

    quoteSubscription = scannerController.quoteStream.listen((quotes) {
      if (!mounted) return;

      setState(() {
        for (final quote in quotes) {
          final symbol = _normalize(quote.symbol);

          latestPrices[symbol] = quote.price;

          if (symbol == _normalize(selectedPair)) {
            debugPrint(
              'LIVE TICK ${DateTime.now().toIso8601String()} '
              '$symbol = ${quote.price}',
            );
          }

          final history = histories.putIfAbsent(symbol, () => <double>[]);
          history.add(quote.price);

          if (history.length > 120) {
            history.removeAt(0);
          }
        }
      });
    });

    scannerController.marketDataService.setTimeframe(timeframe);
    scannerController.setLiveMode();
    scannerController.start();
  }

  @override
  void dispose() {
    signalSubscription?.cancel();
    quoteSubscription?.cancel();
    scannerController.dispose();
    super.dispose();
  }

  String _normalize(String symbol) {
    return symbol.replaceAll('/', '').toUpperCase();
  }

  ScanSignal? _signalFor(String symbol) {
    final target = _normalize(symbol);

    for (final signal in liveSignals) {
      if (_normalize(signal.symbol) == target) {
        return signal;
      }
    }

    return null;
  }

  String _direction(ScanSignal? signal) {
    if (signal == null) return 'WAIT';

    final raw = signal.directionText.toUpperCase();

    if (raw == 'BUY') return 'CALL';
    if (raw == 'SELL') return 'PUT';

    return raw;
  }

  bool _actionable(ScanSignal signal) {
    final value = _direction(signal);
    return value == 'CALL' || value == 'PUT';
  }

  List<ScanSignal> get rankedSignals {
    final rows = List<ScanSignal>.from(liveSignals);

    rows.sort((a, b) {
      final aa = _actionable(a);
      final bb = _actionable(b);

      if (aa != bb) return aa ? -1 : 1;

      return b.confidence.compareTo(a.confidence);
    });

    return rows;
  }

  void _lockTop12(List<ScanSignal> signals) {
    final ranked = List<ScanSignal>.from(signals)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    lockedTop12Symbols
      ..clear()
      ..addAll(
        ranked.take(12).map((signal) => _normalize(signal.symbol)),
      );

    top12LockedAt = DateTime.now();
  }

  List<ScanSignal> get lockedTop12Signals {
    // lockedTop12Symbols defines the permanent visual order.
    return lockedTop12Symbols
        .map((symbol) => lastSignalBySymbol[_normalize(symbol)])
        .whereType<ScanSignal>()
        .toList(growable: false);
  }

  String _category(String symbol) {
    final s = _normalize(symbol);

    if (s.endsWith('_OTC')) return 'OTC';

    const cryptos = [
      'BTC',
      'ETH',
      'LTC',
      'XRP',
      'DOGE',
      'SOL',
      'ADA',
      'BNB',
      'TRX',
      'TON',
    ];

    if (cryptos.any((token) => s.contains(token))) {
      return 'CRYPTO';
    }

    const fiat = {
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CHF',
      'CAD',
      'AUD',
      'NZD',
    };

    if (s.length == 6) {
      final a = s.substring(0, 3);
      final b = s.substring(3, 6);

      if (fiat.contains(a) && fiat.contains(b)) {
        return 'FOREX';
      }
    }

    return 'OTHER';
  }

  List<ScanSignal> get filteredSignals {
    var rows = rankedSignals;

    if (pairFilter == 'OTC') {
      rows = rows.where((s) => _category(s.symbol) == 'OTC').toList();
    } else if (pairFilter == 'FOREX') {
      rows = rows.where((s) => _category(s.symbol) == 'FOREX').toList();
    } else if (pairFilter == 'CRYPTO') {
      rows = rows.where((s) => _category(s.symbol) == 'CRYPTO').toList();
    }

    final q = search.trim().toUpperCase();

    if (q.isNotEmpty) {
      rows = rows.where((s) => _normalize(s.symbol).contains(q)).toList();
    }

    return rows;
  }

  double? _priceFor(String symbol) {
    return latestPrices[_normalize(symbol)];
  }

  List<double> _historyFor(String symbol) {
    return histories[_normalize(symbol)] ?? const [];
  }

  String _age(ScanSignal signal) {
    final duration = DateTime.now().difference(signal.timestamp);

    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    if (duration.inSeconds < 0) return '0s';

    return '${duration.inSeconds}s';
  }

  Color _directionColor(String value) {
    if (value == 'CALL') return green;
    if (value == 'PUT') return red;
    return amber;
  }

  Future<void> _registerFaceId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please log in normally before setting up Face ID.',
            ),
          ),
        );
        return;
      }

      final authenticator = PasskeyAuthenticator();

      await Supabase.instance.client.auth.registerPasskey(
        authenticator,
        friendlyName: '999 Intelligence Pro Face ID',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Face ID passkey setup complete.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Face ID setup failed: ${e.message}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Face ID setup failed: $e',
          ),
        ),
      );
    }
  }

  void _setMode(bool live) {
    if (live) {
      scannerController.marketDataService.setTimeframe(timeframe);
      scannerController.setLiveMode();
    } else {
      scannerController.setDemoMode();
    }

    setState(() {
      liveMode = live;
      connected = false;
    });
  }

  void _setTimeframe(String value) {
    scannerController.marketDataService.setTimeframe(value);

    setState(() {
      timeframe = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final actualScreenWidth = MediaQuery.of(context).size.width;

          if (actualScreenWidth < 1100) {
            return _mobileDashboard();
          }

          final width = max(constraints.maxWidth, 1450.0);
          final height = constraints.maxHeight;

          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: [
                  Color(0xFF06213A),
                  bg,
                ],
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: height,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    children: [
                      _topNav(),
                      const SizedBox(height: 4),
                      _statusStrip(),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 235,
                              child: _leftRail(),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _scannerPanel(),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 310,
                              child: _dukePanel(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 145,
                        child: _bottomRail(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mobileDashboard() {
    final signal = _signalFor(selectedPair);
    final duke = scannerController.dukeResults[selectedPair];
    final price = _priceFor(selectedPair);
    final decision = duke?.decision ?? _direction(signal);
    final approved = duke?.tradeApproved ?? false;

    final decisionColor = approved
        ? green
        : decision == 'BUY' || decision == 'CALL'
            ? green
            : decision == 'SELL' || decision == 'PUT'
                ? red
                : amber;

    // Locked Top 12: live values update, but symbols/order stay fixed.
    final rows = lockedTop12Signals;

    final remaining =
        signal == null ? 0 : (60 - signal.age.inSeconds).clamp(0, 60);

    final executionState = signal == null
        ? 'WAIT'
        : remaining <= 0
            ? 'EXPIRED'
            : approved && remaining <= 15
                ? 'ENTER NOW'
                : approved && remaining <= 30
                    ? 'GET READY'
                    : signal.direction == TradeDirection.wait
                        ? 'WAIT'
                        : 'WATCH';

    final executionColor = executionState == 'ENTER NOW'
        ? green
        : executionState == 'GET READY'
            ? cyan
            : executionState == 'EXPIRED'
                ? red
                : amber;

    final performance = scannerController.dukePerformance;
    final measuredWinRate = performance.closedSignals == 0
        ? '--'
        : '${performance.winRate.toStringAsFixed(1)}%';

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.35,
            colors: [
              Color(0xFF07304C),
              Color(0xFF03101A),
              Color(0xFF020811),
            ],
          ),
        ),
        child: Column(
          children: [
            // =========================
            // MOBILE HEADER
            // =========================
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xCC03101A),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0x3325D9FF),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cyan.withValues(alpha: .55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withValues(alpha: .15),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Text(
                      '9',
                      style: TextStyle(
                        color: cyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '999 SIGNAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                      Text(
                        'INTELLIGENCE 2.0',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // FACE ID
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _registerFaceId,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: cyan.withValues(alpha: .35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.face,
                            size: 12,
                            color: cyan,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'FACE ID',
                            style: TextStyle(
                              color: cyan,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  // LOG OUT
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: .35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout,
                            size: 11,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'LOG OUT',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: (connected ? green : amber).withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            (connected ? green : amber).withValues(alpha: .35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connected ? green : amber,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          connected ? 'LIVE' : 'SYNC',
                          style: TextStyle(
                            color: connected ? green : amber,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 94),
                child: Column(
                  children: [
                    // =========================
                    // PAIR + TIMEFRAME
                    // =========================
                    _glass(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LIVE PAIR',
                                  style: TextStyle(
                                    color: cyan,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _pairSelector(),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            color: Colors.white10,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TIMEFRAME',
                                  style: TextStyle(
                                    color: cyan,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 32,
                                  child: _timeframeSelector(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =========================
                    // MAIN SIGNAL CARD
                    // =========================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF08223A),
                            Color(0xFF04131F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: decisionColor.withValues(alpha: .38),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: decisionColor.withValues(alpha: .10),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cyan.withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.psychology_alt_outlined,
                                  color: cyan,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI OPPORTUNITY SCANNER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '999 NETWORK LIVE ANALYSIS',
                                      style: TextStyle(
                                        color: green,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: (approved ? green : amber)
                                      .withValues(alpha: .08),
                                  border: Border.all(
                                    color: (approved ? green : amber)
                                        .withValues(alpha: .28),
                                  ),
                                ),
                                child: Text(
                                  approved ? 'DUKE APPROVED' : 'DUKE HOLD',
                                  style: TextStyle(
                                    color: approved ? green : amber,
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedPair.replaceAll('_', ' '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      price?.toString() ?? '--',
                                      style: const TextStyle(
                                        color: cyan,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                decision,
                                style: TextStyle(
                                  color: decisionColor,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _mobileStatusBox(
                                  'EXECUTION',
                                  executionState,
                                  executionColor,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _mobileStatusBox(
                                  'COUNTDOWN',
                                  signal == null ? '--' : '${remaining}s',
                                  cyan,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _mobileStatusBox(
                                  'SETUP SCORE',
                                  signal == null
                                      ? '--'
                                      : signal.confidence.toStringAsFixed(1),
                                  purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showDukeResult(
                                      scannerController.deepScan(
                                        selectedPair,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.radar,
                                      size: 17,
                                    ),
                                    label: const Text('DEEP SCAN'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: cyan,
                                      side: BorderSide(
                                        color: cyan.withValues(alpha: .45),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: _openDukeChat,
                                    icon: const Icon(
                                      Icons.smart_toy_outlined,
                                      size: 17,
                                    ),
                                    label: const Text('ASK DUKE'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: purple,
                                      side: BorderSide(
                                        color: purple.withValues(alpha: .45),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 46,
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  refreshTop12Requested = true;
                                });

                                _showDukeRanking(
                                  scannerController.deepScanAll(),
                                );
                              },
                              icon: const Icon(
                                Icons.travel_explore,
                                size: 18,
                              ),
                              label: const Text(
                                'SCAN ALL LIVE MARKETS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .3,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: cyan.withValues(alpha: .16),
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: cyan.withValues(alpha: .60),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white10,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: cyan,
                                  size: 14,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    duke?.explanation ??
                                        'Duke is monitoring the live feed.',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 8.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =========================
                    // PERFORMANCE
                    // =========================
                    _glass(
                      title: 'PERFORMANCE SUMMARY',
                      padding: const EdgeInsets.fromLTRB(
                        10,
                        12,
                        10,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _mobileStat(
                              'WIN RATE',
                              measuredWinRate,
                              green,
                            ),
                          ),
                          _mobileDivider(),
                          Expanded(
                            child: _mobileStat(
                              'WINS',
                              '${performance.wins}',
                              green,
                            ),
                          ),
                          _mobileDivider(),
                          Expanded(
                            child: _mobileStat(
                              'LOSSES',
                              '${performance.losses}',
                              red,
                            ),
                          ),
                          _mobileDivider(),
                          Expanded(
                            child: _mobileStat(
                              'TIES',
                              '${performance.breakeven}',
                              amber,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =========================
                    // OPPORTUNITIES
                    // =========================
                    _glass(
                      title: 'TOP LIVE OPPORTUNITIES',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          for (final s in rows.take(12)) _mobileSignalRow(s),
                          if (rows.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 34),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.radar,
                                    color: Colors.white24,
                                    size: 27,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Waiting for live scanner data...',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================
            // MOBILE NAV
            // =========================
            Container(
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xF203101A),
                border: Border(
                  top: BorderSide(
                    color: Color(0x3325D9FF),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _mobileNav(
                    Icons.radar,
                    'SCAN',
                    _openScannerModule,
                    active: true,
                  ),
                  _mobileNav(
                    Icons.currency_exchange,
                    'MARKETS',
                    _openMarketsModule,
                  ),
                  _mobileNav(
                    Icons.smart_toy_outlined,
                    'DUKE',
                    _openDukeChat,
                  ),
                  _mobileNav(
                    Icons.track_changes,
                    'TRACKER',
                    _openTrackerModule,
                  ),
                  _mobileNav(
                    Icons.tune,
                    'TOOLS',
                    _openToolsModule,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white10,
    );
  }

  Widget _mobileStatusBox(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: .28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 6.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStat(
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 6.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileSignalRow(ScanSignal s) {
    final d = scannerController.dukeResults[s.symbol];
    final decision = d?.decision ?? _direction(s);
    final approved = d?.tradeApproved == true;

    final color = approved
        ? green
        : decision == 'BUY' || decision == 'CALL'
            ? green
            : decision == 'SELL' || decision == 'PUT'
                ? red
                : amber;

    final remaining = (60 - s.age.inSeconds).clamp(0, 60);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => selectedPair = s.symbol);
      },
      onLongPress: () {
        setState(() => selectedPair = s.symbol);
        _showDukeResult(
          scannerController.deepScan(s.symbol),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: Colors.white.withValues(alpha: .018),
          border: Border.all(
            color: Colors.white.withValues(alpha: .05),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_border_rounded,
              color: Colors.white30,
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.symbol.replaceAll('_', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${remaining}s remaining',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(
                minWidth: 56,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: .35),
                ),
              ),
              child: Text(
                decision,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              child: Text(
                s.confidence.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right,
              color: Colors.white24,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileNav(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: active ? cyan.withValues(alpha: .08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(
                    color: cyan.withValues(alpha: .22),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? cyan : Colors.white54,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? cyan : Colors.white54,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topNav() {
    const items = <MapEntry<String, IconData>>[
      MapEntry('AI SCANNER', Icons.memory),
      MapEntry('MARKETS', Icons.candlestick_chart),
      MapEntry('ANALYTICS', Icons.analytics_outlined),
      MapEntry('TRACKER', Icons.track_changes),
      MapEntry('ALERTS', Icons.notifications_active_outlined),
      MapEntry('TOOLS', Icons.settings_suggest_outlined),
    ];

    return _glass(
      height: 48,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cyan.withValues(alpha: 0.08),
              border: Border.all(
                color: cyan.withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: cyan.withValues(alpha: 0.28),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.memory,
              color: cyan,
              size: 15,
            ),
          ),
          const SizedBox(width: 7),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '999 SIGNAL INTELLIGENCE PRO',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'ADVANCED AI TRADING TERMINAL',
                maxLines: 1,
                style: TextStyle(
                  color: cyan,
                  fontSize: 6.5,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _navButton(
                        item.key,
                        item.value,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: green.withValues(alpha: 0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.10),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? green : amber,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (connected ? green : amber).withValues(alpha: 0.65),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  connected ? 'BRAIN 3.0 ONLINE' : 'BRAIN 3.0 SYNC',
                  maxLines: 1,
                  style: TextStyle(
                    color: connected ? green : amber,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Icon(
            connected ? Icons.wifi : Icons.wifi_tethering,
            color: connected ? green : amber,
            size: 17,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.notifications_none,
            color: Colors.white60,
            size: 17,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.settings_outlined,
            color: Colors.white60,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    String item,
    IconData icon,
  ) {
    final selected = selectedNav == item;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedNav = item;
          });

          _openNavModule(item);
        },
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 33,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? cyan.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color:
                  selected ? cyan.withValues(alpha: 0.65) : Colors.transparent,
              width: 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cyan.withValues(alpha: 0.14),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: selected ? cyan : Colors.white54,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontSize: 8.5,
                    height: 1.0,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNavModule(String item) {
    switch (item) {
      case 'AI SCANNER':
        _openScannerModule();
        break;
      case 'MARKETS':
        _openMarketsModule();
        break;
      case 'ANALYTICS':
        _openAnalyticsModule();
        break;
      case 'TRACKER':
        _openTrackerModule();
        break;
      case 'ALERTS':
        _openAlertsModule();
        break;
      case 'TOOLS':
        _openToolsModule();
        break;
    }
  }

  List<String> get _allLivePairs {
    final pairs = <String>{
      ...latestPrices.keys,
      ...liveSignals.map((s) => s.symbol),
    }.toList()
      ..sort();

    if (selectedPair.isNotEmpty && !pairs.contains(selectedPair)) {
      pairs.insert(0, selectedPair);
    }

    return pairs;
  }

  Widget _pairSelector() {
    final pairs = _allLivePairs;

    if (pairs.isEmpty) {
      return const SizedBox(
        height: 30,
        child: Center(
          child: Text(
            'WAITING FOR LIVE PAIRS',
            style: TextStyle(
              color: amber,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    final current = pairs.contains(selectedPair) ? selectedPair : pairs.first;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current,
        isExpanded: true,
        menuMaxHeight: 420,
        dropdownColor: const Color(0xFF041320),
        iconEnabledColor: cyan,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
        items: pairs.map((pair) {
          return DropdownMenuItem<String>(
            value: pair,
            child: Text(
              pair.replaceAll('_', ' '),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (pair) {
          if (pair == null) return;

          setState(() {
            selectedPair = pair;
          });
        },
      ),
    );
  }

  Future<void> _showFunctionWindow({
    required String title,
    required Widget child,
    double width = 880,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: min(width, size.width - 48),
            constraints: BoxConstraints(
              maxHeight: size.height - 70,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF03111E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cyan.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: cyan.withValues(alpha: 0.12),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.memory,
                      color: cyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openScannerModule() {
    _showFunctionWindow(
      title: 'AI SCANNER COMMAND CENTER',
      width: 760,
      child: ListView(
        children: [
          const Text(
            'SELECT LIVE POCKET OPTION INSTRUMENT',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: panel2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: cyan.withValues(alpha: 0.35),
              ),
            ),
            child: _pairSelector(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showDukeResult(
                      scannerController.deepScan(selectedPair),
                    );
                  },
                  icon: const Icon(Icons.radar),
                  label: const Text('DEEP SCAN PAIR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showDukeRanking(
                      scannerController.deepScanAll(),
                    );
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('SCAN ALL MARKETS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _functionMetric(
            'LIVE INSTRUMENTS',
            '${latestPrices.length}',
            cyan,
          ),
          _functionMetric(
            'LIVE SIGNALS',
            '${liveSignals.length}',
            green,
          ),
          _functionMetric(
            'PENDING 1-MIN TESTS',
            '${scannerController.pendingPredictions}',
            amber,
          ),
        ],
      ),
    );
  }

  void _openMarketsModule() {
    final signals = [...liveSignals]..sort(
        (a, b) => b.confidence.compareTo(a.confidence),
      );

    _showFunctionWindow(
      title: 'LIVE POCKET OPTION MARKETS',
      width: 1000,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: panel2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: cyan.withValues(alpha: 0.30),
              ),
            ),
            child: _pairSelector(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: signals.length,
              itemBuilder: (context, index) {
                final signal = signals[index];

                final duke = scannerController.dukeResults[signal.symbol];

                return ListTile(
                  dense: true,
                  onTap: () {
                    setState(() {
                      selectedPair = signal.symbol;
                    });

                    Navigator.of(context).pop();

                    _showDukeResult(
                      scannerController.deepScan(signal.symbol),
                    );
                  },
                  leading: Icon(
                    signal.direction == TradeDirection.buy
                        ? Icons.arrow_upward
                        : signal.direction == TradeDirection.sell
                            ? Icons.arrow_downward
                            : Icons.remove,
                    color: signal.direction == TradeDirection.buy
                        ? green
                        : signal.direction == TradeDirection.sell
                            ? red
                            : amber,
                  ),
                  title: Text(
                    signal.symbol.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    '${signal.trend} • ${signal.setup}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 215,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          (latestPrices[_normalize(signal.symbol)] ??
                                  signal.entry)
                              .toString(),
                          style: const TextStyle(
                            color: cyan,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          signal.confidence.toStringAsFixed(1),
                          style: const TextStyle(
                            color: amber,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          duke?.tradeApproved == true ? 'APPROVED' : 'HOLD',
                          style: TextStyle(
                            color: duke?.tradeApproved == true
                                ? green
                                : Colors.white38,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openAnalyticsModule() {
    final performance = scannerController.dukePerformance;
    final learning = scannerController.learningSnapshot;

    _showFunctionWindow(
      title: '999 PERFORMANCE ANALYTICS',
      width: 800,
      child: ListView(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _analyticsTile(
                'MEASURED WIN RATE',
                performance.closedSignals == 0
                    ? '--'
                    : '${performance.winRate.toStringAsFixed(1)}%',
                green,
              ),
              _analyticsTile(
                'TOTAL SIGNALS',
                '${performance.totalSignals}',
                cyan,
              ),
              _analyticsTile(
                'CLOSED',
                '${performance.closedSignals}',
                purple,
              ),
              _analyticsTile(
                'WINS',
                '${performance.wins}',
                green,
              ),
              _analyticsTile(
                'LOSSES',
                '${performance.losses}',
                red,
              ),
              _analyticsTile(
                'TIES',
                '${performance.breakeven}',
                amber,
              ),
              _analyticsTile(
                'LEARNING SAMPLE',
                '${learning.totalTrades}',
                cyan,
              ),
              _analyticsTile(
                'AVG RESULT R',
                learning.averageR.toStringAsFixed(2),
                purple,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'SETUP LEARNING',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (learning.setupScores.isEmpty)
            const Text(
              'Waiting for resolved one-minute outcomes.',
              style: TextStyle(color: Colors.white54),
            ),
          for (final entry in learning.setupScores.entries)
            ListTile(
              dense: true,
              title: Text(
                entry.key,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Text(
                entry.value.toStringAsFixed(1),
                style: const TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openTrackerModule() {
    final outcomes = scannerController.intelligenceStore.tradeOutcomes;

    _showFunctionWindow(
      title: '1-MIN OUTCOME TRACKER',
      width: 900,
      child: outcomes.isEmpty
          ? const Center(
              child: Text(
                'No resolved outcomes yet.\n'
                'V4 will automatically record qualified signals and resolve them after 60 seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
            )
          : ListView.builder(
              itemCount: outcomes.length,
              itemBuilder: (context, index) {
                final outcome = outcomes[index];

                final outcomeColor = outcome.outcome == 'WIN'
                    ? green
                    : outcome.outcome == 'LOSS'
                        ? red
                        : amber;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    outcome.outcome == 'WIN'
                        ? Icons.check_circle
                        : outcome.outcome == 'LOSS'
                            ? Icons.cancel
                            : Icons.remove_circle_outline,
                    color: outcomeColor,
                  ),
                  title: Text(
                    '${outcome.symbol} • ${outcome.direction}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    '${outcome.setup} • setup score '
                    '${outcome.confidence.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white38,
                    ),
                  ),
                  trailing: Text(
                    outcome.outcome,
                    style: TextStyle(
                      color: outcomeColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _openAlertsModule() {
    final rules = scannerController.intelligenceStore.alertRules;

    _showFunctionWindow(
      title: 'LIVE SIGNAL ALERT ENGINE',
      width: 700,
      child: ListView(
        children: [
          for (final rule in rules)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: panel2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: cyan.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    rule.enabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: rule.enabled ? green : Colors.white38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${rule.symbol} • minimum score '
                      '${rule.minConfidence.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    rule.dukeApprovedOnly ? 'DUKE ONLY' : 'SCANNER',
                    style: const TextStyle(
                      color: cyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openToolsModule() {
    final weights = scannerController.dukeBridge.duke.learningWeights();

    _showFunctionWindow(
      title: '999 INTELLIGENCE TOOLS',
      width: 760,
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(
              Icons.public,
              color: cyan,
            ),
            title: const Text(
              'Run All-Market Deep Scan',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _showDukeRanking(
                scannerController.deepScanAll(),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.memory,
              color: purple,
            ),
            title: const Text(
              'Adaptive Duke Weights',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Trend ${(weights['trend'] ?? 0).toStringAsFixed(3)} • '
              'Momentum ${(weights['momentum'] ?? 0).toStringAsFixed(3)} • '
              'Structure ${(weights['structure'] ?? 0).toStringAsFixed(3)} • '
              'Volatility ${(weights['volatility'] ?? 0).toStringAsFixed(3)}',
              style: const TextStyle(
                color: Colors.white38,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.currency_exchange,
              color: green,
            ),
            title: const Text(
              'Live Instruments',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Text(
              '${latestPrices.length}',
              style: const TextStyle(
                color: green,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.history,
              color: amber,
            ),
            title: const Text(
              'Signal Memory',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Text(
              '${scannerController.intelligenceStore.signalHistory.length}',
              style: const TextStyle(
                color: amber,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsTile(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      width: 170,
      height: 78,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _functionMetric(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showDukeResult(
    DukeMasterResult? result,
  ) {
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No live scanner result available for that pair yet.',
          ),
        ),
      );
      return;
    }

    final normalized = _normalize(result.symbol);

    final signal =
        lastSignalBySymbol[normalized] ?? lastSignalBySymbol[result.symbol];

    // Lock the time this Deep Scan was opened.
    // Time is now used only to measure signal age.
    final scanTime = DateTime.now();

    String priceText(double? value) {
      if (value == null || !value.isFinite) {
        return '--';
      }

      if (result.symbol.contains('JPY')) {
        return value.toStringAsFixed(3);
      }

      if (value.abs() >= 1000) {
        return value.toStringAsFixed(2);
      }

      if (value.abs() >= 100) {
        return value.toStringAsFixed(3);
      }

      return value.toStringAsFixed(5);
    }

    String durationText(int totalSeconds) {
      final safe = totalSeconds < 0 ? 0 : totalSeconds;

      final minutes = safe ~/ 60;
      final seconds = safe % 60;

      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    _showFunctionWindow(
      title: 'AGENT DUKE DEEP SCAN • ${result.symbol}',
      width: 700,
      child: StreamBuilder<int>(
        stream: Stream<int>.periodic(
          const Duration(milliseconds: 500),
          (value) => value,
        ),
        initialData: 0,
        builder: (context, snapshot) {
          final now = DateTime.now();

          final currentPrice = latestPrices[normalized] ??
              latestPrices[result.symbol] ??
              signal?.entry;

          final fullHistory =
              histories[normalized] ?? histories[result.symbol] ?? <double>[];

          // Use recent market movement rather than the entire stored history.
          final recentHistory = fullHistory.length > 60
              ? fullHistory.sublist(fullHistory.length - 60)
              : List<double>.from(fullHistory);

          // Advanced structural values calculated by ScannerEngine.
          double? support = signal?.support;
          double? resistance = signal?.resistance;
          double? minEntry = signal?.minEntry;
          double? maxEntry = signal?.maxEntry;

          // Legacy raw-price history is startup fallback only.
          if ((support == null ||
                  resistance == null ||
                  minEntry == null ||
                  maxEntry == null) &&
              recentHistory.isNotEmpty) {
            final legacySupport = recentHistory.reduce(
              (a, b) => a < b ? a : b,
            );

            final legacyResistance = recentHistory.reduce(
              (a, b) => a > b ? a : b,
            );

            final range = legacyResistance - legacySupport;

            support ??= legacySupport;
            resistance ??= legacyResistance;

            if (range > 0) {
              if (result.decision == 'BUY') {
                minEntry ??= legacySupport + (range * 0.15);
                maxEntry ??= legacySupport + (range * 0.45);
              } else if (result.decision == 'SELL') {
                minEntry ??= legacyResistance - (range * 0.45);
                maxEntry ??= legacyResistance - (range * 0.15);
              }
            }
          }

          // Fallback while very little history has accumulated.
          if (currentPrice != null && (minEntry == null || maxEntry == null)) {
            final fallbackDistance = result.symbol.contains('JPY')
                ? 0.020
                : currentPrice.abs() >= 1000
                    ? currentPrice * 0.00020
                    : 0.00020;

            minEntry = currentPrice - fallbackDistance;
            maxEntry = currentPrice + fallbackDistance;

            support ??= minEntry;
            resistance ??= maxEntry;
          }

          final signalAge = now.difference(scanTime).inSeconds;

          // For an M1 setup, don't leave an old analysis
          // active indefinitely.
          final stale = signalAge >= 300;

          late final String status;
          late final Color statusColor;

          if (stale) {
            status = 'RESCAN - SETUP STALE';
            statusColor = red;
          } else if (currentPrice == null ||
              minEntry == null ||
              maxEntry == null) {
            status = 'WAITING FOR LIVE PRICE';
            statusColor = amber;
          } else if (currentPrice >= minEntry && currentPrice <= maxEntry) {
            status = 'ENTRY ZONE';
            statusColor = green;
          } else if (result.decision == 'BUY') {
            if (currentPrice > maxEntry) {
              status = 'ABOVE ZONE - WAIT FOR PULLBACK';
              statusColor = amber;
            } else {
              status = 'BELOW ZONE - WAIT FOR PRICE';
              statusColor = cyan;
            }
          } else if (result.decision == 'SELL') {
            if (currentPrice < minEntry) {
              status = 'BELOW ZONE - DO NOT CHASE';
              statusColor = amber;
            } else {
              status = 'ABOVE ZONE - WAIT FOR PRICE';
              statusColor = cyan;
            }
          } else {
            status = 'RESCAN';
            statusColor = amber;
          }

          return ListView(
            children: [
              _functionMetric(
                'DECISION',
                result.decision,
                result.decision == 'BUY'
                    ? green
                    : result.decision == 'SELL'
                        ? red
                        : amber,
              ),
              _functionMetric(
                'CURRENT PRICE',
                priceText(currentPrice),
                cyan,
              ),
              _functionMetric(
                'SUPPORT',
                priceText(support),
                green,
              ),
              _functionMetric(
                'RESISTANCE',
                priceText(resistance),
                red,
              ),
              _functionMetric(
                'MIN ENTRY PRICE',
                priceText(minEntry),
                cyan,
              ),
              _functionMetric(
                'MAX ENTRY PRICE',
                priceText(maxEntry),
                cyan,
              ),
              _functionMetric(
                'ENTRY STATUS',
                status,
                statusColor,
              ),
              _functionMetric(
                'SIGNAL AGE',
                durationText(signalAge),
                signalAge >= 240 ? amber : Colors.white70,
              ),
              _functionMetric(
                'CONFIDENCE',
                '${result.confidence.toStringAsFixed(1)}%',
                cyan,
              ),
              _functionMetric(
                'QUALITY SCORE',
                result.qualityScore.toStringAsFixed(1),
                purple,
              ),
              _functionMetric(
                'TRADE GATE',
                result.tradeApproved ? 'APPROVED' : 'HOLD',
                result.tradeApproved ? green : red,
              ),
              const SizedBox(height: 10),
              Text(
                stale
                    ? 'This setup is more than 5 minutes old. '
                        'Run a fresh Deep Scan.'
                    : status == 'ENTRY ZONE'
                        ? 'Price is inside Duke\'s calculated entry zone. '
                            'Recheck the live chart and market structure '
                            'before execution.'
                        : 'Duke is waiting for price to reach the '
                            'calculated entry zone.',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.explanation,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDukeRanking(
    List<DukeMasterResult> results,
  ) {
    _showFunctionWindow(
      title: 'DUKE ALL-MARKET DEEP SCAN',
      width: 900,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];

          return ListTile(
            dense: true,
            onTap: () {
              setState(() {
                selectedPair = result.symbol;
              });

              Navigator.of(context).pop();

              _showDukeResult(result);
            },
            leading: Text(
              '${index + 1}',
              style: const TextStyle(
                color: cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
            title: Text(
              result.symbol.replaceAll('_', ' '),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              result.decision,
              style: TextStyle(
                color: result.tradeApproved ? green : amber,
              ),
            ),
            trailing: Text(
              'Q ${result.qualityScore.toStringAsFixed(1)}',
              style: const TextStyle(
                color: cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDukeChat() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF041320),
          title: const Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: cyan,
              ),
              SizedBox(width: 8),
              Text(
                'ASK AGENT DUKE',
                style: TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Try: scan all markets, show performance, show tracker, show markets, deep scan this pair',
                hintStyle: TextStyle(
                  color: Colors.white30,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white24,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: cyan,
                  ),
                ),
              ),
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop();
                _runDukeCommand(controller.text);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _runDukeCommand(controller.text);
              },
              child: const Text('SEND TO DUKE'),
            ),
          ],
        );
      },
    );
  }

  void _runDukeCommand(String input) {
    final command = input.trim().toLowerCase();

    if (command.isEmpty) return;

    if (command.contains('scan all') ||
        command.contains('best pair') ||
        command.contains('strongest') ||
        command.contains('all market')) {
      _showDukeRanking(
        scannerController.deepScanAll(),
      );
      return;
    }

    if (command.contains('performance') ||
        command.contains('win rate') ||
        command.contains('analytics')) {
      _openAnalyticsModule();
      return;
    }

    if (command.contains('tracker') ||
        command.contains('history') ||
        command.contains('outcome')) {
      _openTrackerModule();
      return;
    }

    if (command.contains('market') ||
        command.contains('pair') ||
        command.contains('currency')) {
      _openMarketsModule();
      return;
    }

    if (command.contains('alert')) {
      _openAlertsModule();
      return;
    }

    if (command.contains('tool') || command.contains('weight')) {
      _openToolsModule();
      return;
    }

    _showDukeResult(
      scannerController.deepScan(selectedPair),
    );
  }

  Widget _timeframeSelector() {
    const frames = [
      'M1',
      'M5',
      'M15',
      'M30',
      'M45',
      'H1',
      'H2',
      'H4',
      'H8',
      'D1',
      'W1',
      'MN1',
    ];

    final current = frames.contains(timeframe) ? timeframe : 'M1';

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current,
        dropdownColor: const Color(0xFF041320),
        iconEnabledColor: cyan,
        menuMaxHeight: 420,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
        items: frames.map((frame) {
          return DropdownMenuItem<String>(
            value: frame,
            child: Text(frame),
          );
        }).toList(),
        onChanged: (frame) {
          if (frame == null) return;
          _setTimeframe(frame);
        },
      ),
    );
  }

  Widget _statusStrip() {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 235,
            child: _glass(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              child: Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected ? green : amber,
                      boxShadow: [
                        BoxShadow(
                          color: (connected ? green : amber)
                              .withValues(alpha: 0.55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE MARKET DATA FEED',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            height: 1.0,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          connected
                              ? 'POCKET OPTION BRIDGE • ONLINE'
                              : 'MARKET BRIDGE • SYNCHRONIZING',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: connected ? green : amber,
                            fontSize: 7,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    height: 20,
                    child: CustomPaint(
                      painter: _SparkPainter(
                        values: _historyFor(selectedPair),
                        color: cyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _glass(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TIMEFRAME',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 6.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: _timeframeSelector(),
                        ),
                      ],
                    ),
                  ),
                  _verticalLine(),
                  _statusCompact(
                    'EXECUTION',
                    timeframe == 'M1' ? 'M1 HIGH SPEED' : timeframe,
                    color: cyan,
                  ),
                  _verticalLine(),
                  _statusCompact(
                    'ACCOUNT',
                    liveMode ? 'LIVE' : 'DEMO',
                    color: liveMode ? green : amber,
                  ),
                  const SizedBox(width: 6),
                  _tinyButton(
                    'LIVE',
                    liveMode,
                    () => _setMode(true),
                  ),
                  const SizedBox(width: 3),
                  _tinyButton(
                    'DEMO',
                    !liveMode,
                    () => _setMode(false),
                  ),
                  const Spacer(),
                  _statusCompact(
                    'ACTIVE PAIR',
                    selectedPair.replaceAll('_', ' '),
                    color: cyan,
                  ),
                  _verticalLine(),
                  _statusCompact(
                    'AI CORE',
                    connected ? 'ONLINE' : 'SYNC',
                    color: connected ? green : amber,
                  ),
                  _verticalLine(),
                  _statusCompact(
                    'INSTRUMENTS',
                    '${latestPrices.length}',
                  ),
                  _verticalLine(),
                  _statusCompact(
                    'SIGNALS',
                    '${liveSignals.length}',
                  ),
                  _verticalLine(),
                  _statusCompact(
                    'SYSTEM',
                    connected ? 'OPERATIONAL' : 'SYNC',
                    color: connected ? green : amber,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCompact(
    String label,
    String value, {
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 6.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 9,
              height: 1.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftRail() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: _strengthMatrix(),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 5,
          child: _watchlist(),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 4,
          child: _networkHealth(),
        ),
      ],
    );
  }

  Widget _strengthMatrix() {
    const currencies = [
      'EUR',
      'USD',
      'GBP',
      'JPY',
      'AUD',
      'CAD',
      'CHF',
      'NZD',
      'XAU',
      'BTC',
    ];

    return _glass(
      onTap: _openMarketsModule,
      borderColor: cyan.withValues(alpha: 0.46),
      title: 'LIVE STRENGTH MATRIX',
      child: Column(
        children: [
          const Row(
            children: [
              SizedBox(width: 34),
              Expanded(
                child: Text(
                  'STRONG',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                  ),
                ),
              ),
              Text(
                'WEAK',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (int r = 0; r < currencies.length; r++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final currency = currencies[r];
                  final selected = strengthCurrencyFilter == currency;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (strengthCurrencyFilter == currency) {
                            strengthCurrencyFilter = null;
                            search = '';
                          } else {
                            strengthCurrencyFilter = currency;
                            search = currency;
                          }
                        });
                      },
                      hoverColor: cyan.withValues(alpha: 0.10),
                      splashColor: cyan.withValues(alpha: 0.16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? cyan.withValues(alpha: 0.10)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: selected ? cyan : Colors.transparent,
                              width: selected ? 2 : 0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 34,
                              child: Text(
                                currency,
                                style: TextStyle(
                                  color: selected ? cyan : Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            for (int c = 0; c < 8; c++)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: _heatColor(r, c),
                                    border: selected
                                        ? Border.all(
                                            color: cyan.withValues(
                                              alpha: 0.18,
                                            ),
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _heatColor(r, c)
                                            .withValues(alpha: 0.14),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  strengthCurrencyFilter == null
                      ? 'CLICK CURRENCY TO FILTER'
                      : 'FILTER: $strengthCurrencyFilter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: strengthCurrencyFilter == null ? cyan : green,
                    fontSize: 5.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (strengthCurrencyFilter != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      strengthCurrencyFilter = null;
                      search = '';
                    });
                  },
                  child: const Text(
                    'CLEAR',
                    style: TextStyle(
                      color: amber,
                      fontSize: 5.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _heatColor(int row, int col) {
    final signal = liveSignals.isEmpty
        ? null
        : liveSignals[(row + col) % liveSignals.length];

    final confidence = signal?.confidence ?? 0;
    final direction = _direction(signal);

    final intensity = ((confidence / 100) * 0.85 + 0.08).clamp(0.08, 0.92);

    if (direction == 'CALL') {
      return green.withValues(alpha: intensity);
    }

    if (direction == 'PUT') {
      return red.withValues(alpha: intensity);
    }

    final trend = signal?.trend.toUpperCase() ?? '';

    if (trend.contains('BULL')) {
      return green.withValues(
        alpha: min(max(intensity * 0.70, 0.12), 0.58),
      );
    }

    if (trend.contains('BEAR')) {
      return red.withValues(
        alpha: min(max(intensity * 0.70, 0.12), 0.58),
      );
    }

    return amber.withValues(
      alpha: min(max(intensity * 0.65, 0.10), 0.46),
    );
  }

  Widget _watchlist() {
    // LOCKED WATCHLIST:
    // Pair names and row positions never move because confidence changes.
    // Favorites remain favorites, but favoriting a pair does NOT reorder rows.
    // A new Top 12 is selected only after a manual market rescan.
    final rows = lockedTop12Signals.take(12).toList(growable: false);

    return _glass(
      borderColor: green.withValues(alpha: 0.40),
      title: 'SMART WATCHLIST • STRONGEST PAIRS',
      child: rows.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radar,
                    color: cyan,
                    size: 18,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SCANNING FOR STRONGEST LIVE PAIRS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const SizedBox(
                  height: 13,
                  child: Row(
                    children: [
                      SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          'PAIR',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 5.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          'TYPE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 5.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          'SCORE',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 5.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final signal = rows[index];
                      final symbol = _normalize(signal.symbol);
                      final isPinned = watchlist.contains(symbol);
                      final isSelected = _normalize(selectedPair) == symbol;
                      final color = _directionColor(_direction(signal));

                      return SizedBox(
                        height: 22,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedPair = signal.symbol;
                              });
                            },
                            hoverColor: cyan.withValues(alpha: 0.14),
                            splashColor: cyan.withValues(alpha: 0.20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cyan.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color:
                                        isSelected ? cyan : Colors.transparent,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  right: BorderSide(
                                    color: isSelected
                                        ? cyan.withValues(alpha: 0.55)
                                        : Colors.transparent,
                                    width: isSelected ? 1 : 0,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(
                                      alpha: 0.035,
                                    ),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 13,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isPinned) {
                                            watchlist.remove(symbol);
                                          } else {
                                            watchlist.add(symbol);
                                          }
                                        });
                                      },
                                      child: Icon(
                                        isPinned
                                            ? Icons.star
                                            : Icons.star_border,
                                        color:
                                            isPinned ? amber : Colors.white30,
                                        size: 9,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      signal.symbol.replaceAll('_', ' '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? cyan
                                            : Colors.white
                                                .withValues(alpha: 0.78),
                                        fontSize: 6.6,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isPinned ? amber : cyan)
                                            .withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: (isPinned ? amber : cyan)
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        isPinned ? 'PIN' : 'AUTO',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isPinned ? amber : cyan,
                                          fontSize: 5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  SizedBox(
                                    width: 31,
                                    child: Text(
                                      '${signal.confidence.toStringAsFixed(0)}%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 6.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'AI TOP SETUPS • LIVE',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 4.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${watchlist.length} PINNED',
                      style: const TextStyle(
                        color: amber,
                        fontSize: 4.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _openNetworkDiagnostics() {
    final duke = scannerController.dukeResults[selectedPair];

    final systemColor = connected ? green : amber;
    final status = connected ? 'OPERATIONAL' : 'SYNCING';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(28),
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(14),
            decoration: hudPanelDecoration(
              borderColor: systemColor,
              radius: 10,
              strongGlow: true,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      color: systemColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '999 SYSTEM DIAGNOSTICS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'LIVE TRADING TERMINAL HEALTH MONITOR',
                            style: TextStyle(
                              color: cyan,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _diagnosticRow(
                  'SYSTEM STATUS',
                  status,
                  systemColor,
                ),
                _diagnosticRow(
                  'BRIDGE',
                  connected ? 'CONNECTED' : 'SYNCING',
                  systemColor,
                ),
                _diagnosticRow(
                  'POCKET OPTION FEED',
                  connected ? 'LIVE' : 'SYNCING',
                  systemColor,
                ),
                _diagnosticRow(
                  'SIGNAL ENGINE',
                  '${liveSignals.length} SIGNALS',
                  cyan,
                ),
                _diagnosticRow(
                  'INSTRUMENTS',
                  '${latestPrices.length} ACTIVE',
                  cyan,
                ),
                _diagnosticRow(
                  'MODE',
                  liveMode ? 'LIVE' : 'DEMO',
                  liveMode ? green : amber,
                ),
                _diagnosticRow(
                  'SELECTED PAIR',
                  selectedPair.replaceAll('_', ' '),
                  cyan,
                ),
                _diagnosticRow(
                  'TIMEFRAME',
                  timeframe,
                  purple,
                ),
                _diagnosticRow(
                  'AI BRAIN 3.0',
                  connected ? 'ONLINE' : 'SYNC',
                  systemColor,
                ),
                _diagnosticRow(
                  'DUKE DECISION',
                  duke?.decision ?? 'WAIT',
                  duke?.tradeApproved == true ? green : amber,
                ),
                _diagnosticRow(
                  'DUKE QUALITY',
                  duke == null ? '--' : duke.qualityScore.toStringAsFixed(1),
                  purple,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: systemColor,
                        boxShadow: [
                          BoxShadow(
                            color: systemColor.withValues(alpha: 0.60),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connected
                          ? 'ALL CORE SYSTEMS RESPONDING'
                          : 'SYSTEM SYNCHRONIZATION IN PROGRESS',
                      style: TextStyle(
                        color: systemColor,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _openToolsModule();
                      },
                      child: const Text(
                        'OPEN TOOLS',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _diagnosticRow(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF04111D),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkHealth() {
    return _glass(
      onTap: _openNetworkDiagnostics,
      borderColor: (connected ? green : amber).withValues(alpha: 0.42),
      title: 'NETWORK HEALTH • SYSTEM DIAGNOSTICS',
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: connected ? 1.0 : 0.45,
                  strokeWidth: 7,
                  color: connected ? green : amber,
                  backgroundColor: Colors.white10,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      connected ? '100%' : 'SYNC',
                      style: TextStyle(
                        color: connected ? green : amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'HEALTH',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 5.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _healthLine(
                  'Bridge',
                  connected ? 'Connected' : 'Sync',
                ),
                _healthLine(
                  'Price Feed',
                  '${latestPrices.length}',
                ),
                _healthLine(
                  'Signal Engine',
                  '${liveSignals.length}',
                ),
                _healthLine(
                  'Mode',
                  liveMode ? 'Live' : 'Demo',
                ),
                const SizedBox(height: 3),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'CLICK FOR DIAGNOSTICS',
                    style: TextStyle(
                      color: cyan,
                      fontSize: 5.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerPanel() {
    final rows = filteredSignals.take(12).toList();

    return _glass(
      glow: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.08),
                  border: Border.all(color: cyan.withValues(alpha: 0.50)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI OPPORTUNITY SCANNER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'REAL-TIME - HIGHEST PROBABILITY SETUPS ONLY',
                    style: TextStyle(
                      color: green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _miniSelector(
                'LIVE PAIRS',
                pairFilter,
              ),
              const SizedBox(width: 6),
              _miniSelector(
                'TIMEFRAME',
                timeframe,
              ),
              const SizedBox(width: 7),
              const Text(
                'AI STRICT',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                ),
              ),
              Switch(
                value: strictMode,
                activeThumbColor: green,
                onChanged: (value) {
                  setState(() {
                    strictMode = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final item in const [
                'TOP 40',
                'ALL',
                'OTC',
                'FOREX',
                'CRYPTO',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: _filterButton(item),
                ),
              const SizedBox(width: 6),
              SizedBox(
                width: 190,
                height: 34,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search live pairs',
                    hintStyle: const TextStyle(
                      color: Colors.white30,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: cyan,
                      size: 16,
                    ),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: panel2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: cyan.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _scannerHeader(),
          const Divider(
            height: 1,
            color: Colors.white10,
          ),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'WAITING FOR 999 NETWORK LIVE DATA',
                      style: TextStyle(
                        color: Colors.white30,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      return _scannerRow(index + 1, rows[index]);
                    },
                  ),
          ),
          Row(
            children: [
              Text(
                'Showing ${rows.length} of ${filteredSignals.length} instruments',
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.circle,
                color: green,
                size: 6,
              ),
              const SizedBox(width: 4),
              const Text(
                'Updates every tick',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scannerHeader() {
    const style = TextStyle(
      color: Colors.white38,
      fontSize: 7,
      fontWeight: FontWeight.w800,
    );

    return const SizedBox(
      height: 28,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#', style: style),
          ),
          SizedBox(
            width: 126,
            child: Text('PAIR', style: style),
          ),
          SizedBox(
            width: 82,
            child: Text(
              'DIRECTION',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 66,
            child: Text(
              'CONFIDENCE',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 82,
            child: Text(
              'PRICE',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'TREND',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              'MOMENTUM',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          Expanded(
            child: Text(
              'SETUP',
              style: style,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              'AGE',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              'RR',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              'SCORE',
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          SizedBox(width: 26),
        ],
      ),
    );
  }

  Widget _scannerRow(int index, ScanSignal signal) {
    final symbol = _normalize(signal.symbol);
    final selected = _normalize(selectedPair) == symbol;

    final rawDirection = signal.direction.name.toUpperCase();

    final direction = rawDirection == 'BUY'
        ? 'CALL'
        : rawDirection == 'SELL'
            ? 'PUT'
            : 'WAIT';

    final directionColor = _directionColor(direction);

    final expired = signal.isExpired;
    final actionable = direction == 'CALL' || direction == 'PUT';
    final priority = actionable && !expired;

    final risk = (signal.entry - signal.stopLoss).abs();
    final reward = (signal.takeProfit1 - signal.entry).abs();

    final rr = risk > 0 ? (reward / risk).toStringAsFixed(1) : '--';

    return Opacity(
      opacity: expired ? 0.42 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: 31,
        decoration: BoxDecoration(
          color: selected
              ? cyan.withValues(alpha: 0.14)
              : priority
                  ? directionColor.withValues(alpha: 0.035)
                  : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected
                  ? cyan
                  : priority
                      ? directionColor.withValues(alpha: 0.32)
                      : Colors.transparent,
              width: selected ? 3 : 1,
            ),
            right: BorderSide(
              color:
                  selected ? cyan.withValues(alpha: 0.45) : Colors.transparent,
              width: selected ? 1 : 0,
            ),
            bottom: const BorderSide(
              color: Colors.white10,
            ),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cyan.withValues(alpha: 0.08),
                    blurRadius: 7,
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            _scannerSelectCell(
              width: 28,
              signal: signal,
              child: Text(
                '$index',
                style: TextStyle(
                  color: selected ? cyan : Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _scannerDetailCell(
              width: 126,
              signal: signal,
              section: 'PAIR',
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  signal.symbol.replaceAll('_', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? cyan : Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            _scannerDetailCell(
              width: 82,
              signal: signal,
              section: 'DIRECTION',
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: directionColor.withValues(
                    alpha: priority ? 0.16 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: directionColor.withValues(
                      alpha: priority ? 0.80 : 0.45,
                    ),
                  ),
                ),
                child: Text(
                  signal.directionText,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: directionColor,
                    fontSize: 7,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            _scannerDetailCell(
              width: 66,
              signal: signal,
              section: 'CONFIDENCE',
              child: Center(
                child: Text(
                  '${signal.confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: priority ? directionColor : amber,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            _scannerSelectCell(
              width: 82,
              signal: signal,
              child: Center(
                child: Text(
                  signal.entry.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 7.5,
                  ),
                ),
              ),
            ),
            _scannerDetailCell(
              width: 70,
              signal: signal,
              section: 'TREND',
              child: Center(
                child: Text(
                  signal.trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: signal.trend.toUpperCase().contains('BULL')
                        ? green
                        : signal.trend.toUpperCase().contains('BEAR')
                            ? red
                            : amber,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            _scannerDetailCell(
              width: 78,
              signal: signal,
              section: 'MOMENTUM',
              child: Center(
                child: Text(
                  signal.momentum,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 7,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _scannerDetailCell(
                signal: signal,
                section: 'SETUP',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    signal.setup,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 7,
                    ),
                  ),
                ),
              ),
            ),
            _scannerSelectCell(
              width: 44,
              signal: signal,
              child: Center(
                child: Text(
                  _age(signal),
                  style: TextStyle(
                    color: expired ? red : Colors.white54,
                    fontSize: 7,
                  ),
                ),
              ),
            ),
            _scannerSelectCell(
              width: 34,
              signal: signal,
              child: Center(
                child: Text(
                  rr,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 7,
                  ),
                ),
              ),
            ),
            _scannerDetailCell(
              width: 38,
              signal: signal,
              section: 'SCORE',
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.06),
                  border: Border.all(
                    color: cyan.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  signal.score.toStringAsFixed(0),
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 26,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    if (watchlist.contains(symbol)) {
                      watchlist.remove(symbol);
                    } else {
                      watchlist.add(symbol);
                    }
                  });
                },
                icon: Icon(
                  watchlist.contains(symbol) ? Icons.star : Icons.star_border,
                  size: 15,
                  color: watchlist.contains(symbol) ? amber : Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scannerDetailCell({
    double? width,
    required ScanSignal signal,
    required String section,
    required Widget child,
  }) {
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        hoverColor: cyan.withValues(alpha: 0.10),
        splashColor: cyan.withValues(alpha: 0.18),
        highlightColor: cyan.withValues(alpha: 0.06),
        onTap: () {
          setState(() {
            selectedPair = signal.symbol;
          });

          _openSignalIntelligence(
            signal,
            section,
          );
        },
        onDoubleTap: () {
          setState(() {
            selectedPair = signal.symbol;
          });

          _showDukeResult(
            scannerController.deepScan(signal.symbol),
          );
        },
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: child,
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        height: 31,
        child: content,
      );
    }

    return SizedBox(
      height: 31,
      child: content,
    );
  }

  Widget _scannerSelectCell({
    required double width,
    required ScanSignal signal,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: 31,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          hoverColor: cyan.withValues(alpha: 0.06),
          onTap: () {
            setState(() {
              selectedPair = signal.symbol;
            });
          },
          onDoubleTap: () {
            setState(() {
              selectedPair = signal.symbol;
            });

            _showDukeResult(
              scannerController.deepScan(signal.symbol),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: child,
          ),
        ),
      ),
    );
  }

  void _openSignalIntelligence(
    ScanSignal signal,
    String section,
  ) {
    final duke = scannerController.dukeResults[signal.symbol];
    final direction = signal.direction == TradeDirection.buy
        ? 'CALL / BUY'
        : signal.direction == TradeDirection.sell
            ? 'PUT / SELL'
            : 'WAIT';

    Color statusColor = cyan;

    if (signal.direction == TradeDirection.buy) {
      statusColor = green;
    } else if (signal.direction == TradeDirection.sell) {
      statusColor = red;
    } else {
      statusColor = amber;
    }

    final details = <MapEntry<String, String>>[];

    switch (section) {
      case 'PAIR':
        details.addAll([
          MapEntry('SYMBOL', signal.symbol.replaceAll('_', ' ')),
          MapEntry('TIMEFRAME', timeframe),
          MapEntry('CURRENT ACTION', direction),
          MapEntry('ENTRY', signal.entry.toString()),
          MapEntry('SIGNAL AGE', _age(signal)),
          MapEntry(
            'STATUS',
            signal.isExpired ? 'EXPIRED' : 'ACTIVE',
          ),
        ]);
        break;

      case 'DIRECTION':
        details.addAll([
          MapEntry('AI DIRECTION', direction),
          MapEntry('EXECUTION', signal.executionState),
          MapEntry('ENTRY TIMING', signal.entryTimingText),
          MapEntry('CONFIDENCE', '${signal.confidence.toStringAsFixed(1)}%'),
          MapEntry('SETUP QUALITY', signal.setupQuality),
          MapEntry(
            'CAN ENTER NOW',
            signal.canEnterNow ? 'YES' : 'NO',
          ),
        ]);
        break;

      case 'CONFIDENCE':
        details.addAll([
          MapEntry(
            'CONFIDENCE',
            '${signal.confidence.toStringAsFixed(1)}%',
          ),
          MapEntry(
            'RAW SCORE',
            signal.score.toStringAsFixed(1),
          ),
          MapEntry('SETUP QUALITY', signal.setupQuality),
          MapEntry('TREND', signal.trend),
          MapEntry('MOMENTUM', signal.momentum),
          MapEntry('AI DIRECTION', direction),
        ]);
        break;

      case 'TREND':
        details.addAll([
          MapEntry('TREND STATE', signal.trend),
          MapEntry('AI DIRECTION', direction),
          MapEntry('MOMENTUM', signal.momentum),
          MapEntry(
            'CONFIDENCE',
            '${signal.confidence.toStringAsFixed(1)}%',
          ),
          MapEntry('SETUP', signal.setup),
          MapEntry('QUALITY', signal.setupQuality),
        ]);
        break;

      case 'MOMENTUM':
        details.addAll([
          MapEntry('MOMENTUM STATE', signal.momentum),
          MapEntry('TREND', signal.trend),
          MapEntry('AI DIRECTION', direction),
          MapEntry(
            'CONFIDENCE',
            '${signal.confidence.toStringAsFixed(1)}%',
          ),
          MapEntry('EXECUTION', signal.executionState),
          MapEntry('SIGNAL AGE', _age(signal)),
        ]);
        break;

      case 'SETUP':
        details.addAll([
          MapEntry('DETECTED SETUP', signal.setup),
          MapEntry('QUALITY', signal.setupQuality),
          MapEntry('ENTRY', signal.entry.toString()),
          MapEntry('STOP LOSS', signal.stopLoss.toString()),
          MapEntry('TARGET 1', signal.takeProfit1.toString()),
          MapEntry('TARGET 2', signal.takeProfit2.toString()),
          MapEntry('TARGET 3', signal.takeProfit3.toString()),
        ]);
        break;

      case 'SCORE':
        details.addAll([
          MapEntry(
            'SCANNER SCORE',
            signal.score.toStringAsFixed(1),
          ),
          MapEntry(
            'CONFIDENCE',
            '${signal.confidence.toStringAsFixed(1)}%',
          ),
          MapEntry('QUALITY', signal.setupQuality),
          MapEntry(
            'DUKE QUALITY',
            duke == null
                ? 'NOT YET ANALYZED'
                : duke.qualityScore.toStringAsFixed(1),
          ),
          MapEntry(
            'DUKE DECISION',
            duke?.decision ?? 'WAITING',
          ),
          MapEntry(
            'TRADE GATE',
            duke?.tradeApproved == true ? 'APPROVED' : 'NOT APPROVED',
          ),
        ]);
        break;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(28),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(14),
            decoration: hudPanelDecoration(
              borderColor: statusColor,
              radius: 10,
              strongGlow: true,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.08),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Icon(
                        Icons.psychology_alt_outlined,
                        color: statusColor,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${signal.symbol.replaceAll('_', ' ')} • $section',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'AI BRAIN 3.0 • TRADE INTELLIGENCE DETAIL',
                            style: TextStyle(
                              color: cyan,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF04111D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (final item in details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.key,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  item.value,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      signal.isExpired
                          ? 'SIGNAL EXPIRED'
                          : 'LIVE SIGNAL • ${signal.executionState}',
                      style: TextStyle(
                        color: signal.isExpired ? red : statusColor,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _showDukeResult(
                          scannerController.deepScan(signal.symbol),
                        );
                      },
                      child: const Text(
                        'RUN DUKE DEEP SCAN',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _momentumBars(double score, Color color) {
    final active = ((score / 100) * 6).round().clamp(1, 6);

    return Row(
      children: [
        for (int i = 0; i < 6; i++)
          Container(
            width: 4,
            height: 5 + i.toDouble(),
            margin: const EdgeInsets.only(right: 2),
            color: i < active ? color : Colors.white10,
          ),
      ],
    );
  }

  Widget _dukePanel() {
    final signal = _signalFor(selectedPair);
    final duke = scannerController.dukeResults[selectedPair];
    final direction = duke?.decision ?? _direction(signal);
    final approved = duke?.tradeApproved ?? false;

    final directionColor = approved
        ? green
        : direction == 'BUY' || direction == 'CALL'
            ? green
            : direction == 'SELL' || direction == 'PUT'
                ? red
                : amber;

    final price = _priceFor(selectedPair);
    final history = _historyFor(selectedPair);

    final adaptiveScore = duke?.qualityScore ?? 0.0;
    final confidence = duke?.confidence ?? signal?.confidence ?? 0.0;

    final alignmentText = approved
        ? 'STRONG'
        : adaptiveScore >= 60
            ? 'FORMING'
            : 'MONITORING';

    return _glass(
      glow: true,
      padding: const EdgeInsets.all(8),
      borderColor: cyan.withValues(alpha: 0.78),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI BRAIN 3.0',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '999 TRADING INTELLIGENCE CORE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 6.8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: green.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: green.withValues(alpha: 0.14),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connected ? green : amber,
                        boxShadow: [
                          BoxShadow(
                            color: (connected ? green : amber)
                                .withValues(alpha: 0.70),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      connected ? 'CORE ONLINE' : 'CORE SYNC',
                      style: TextStyle(
                        color: connected ? green : amber,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _dukeBox(
            borderColor: cyan.withValues(alpha: 0.55),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              cyan.withValues(alpha: 0.16),
                              const Color(0xFF04101C),
                            ],
                          ),
                          border: Border.all(
                            color: cyan.withValues(alpha: 0.72),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyan.withValues(alpha: 0.28),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                const Color(0xFF0077FF).withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF071B2C),
                          border: Border.all(
                            color: cyan.withValues(alpha: 0.72),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyan.withValues(alpha: 0.22),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_alt_outlined,
                          color: cyan,
                          size: 27,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BRAIN STATUS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 6.5,
                        ),
                      ),
                      Text(
                        connected ? 'FULLY OPERATIONAL' : 'SYNCHRONIZING',
                        style: TextStyle(
                          color: connected ? green : amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _brainMetricLine(
                        'ADAPTIVE SCORE',
                        adaptiveScore <= 0
                            ? '--'
                            : adaptiveScore.toStringAsFixed(1),
                        purple,
                      ),
                      const SizedBox(height: 5),
                      _brainMetricLine(
                        'CONFIDENCE',
                        confidence <= 0
                            ? '--'
                            : '${confidence.toStringAsFixed(1)}%',
                        cyan,
                      ),
                      const SizedBox(height: 5),
                      _brainMetricLine(
                        'MARKET ALIGNMENT',
                        alignmentText,
                        approved ? green : amber,
                      ),
                      const SizedBox(height: 5),
                      _brainMetricLine(
                        'DECISION',
                        direction,
                        directionColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          _dukeBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT LIVE PAIR',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 6.5,
                  ),
                ),
                _pairSelector(),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 27,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showDukeResult(
                        scannerController.deepScan(selectedPair),
                      );
                    },
                    icon: const Icon(Icons.radar, size: 11),
                    label: const Text(
                      'DEEP SCAN',
                      style: TextStyle(fontSize: 7),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: cyan,
                      side: BorderSide(
                        color: cyan.withValues(alpha: 0.50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openDukeChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 11),
                    label: const Text(
                      'ASK DUKE',
                      style: TextStyle(fontSize: 7),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: green,
                      side: BorderSide(
                        color: green.withValues(alpha: 0.50),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showDukeRanking(
                        scannerController.deepScanAll(),
                      );
                    },
                    icon: const Icon(Icons.public, size: 11),
                    label: const Text(
                      'SCAN ALL',
                      style: TextStyle(fontSize: 7),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: amber,
                      side: BorderSide(
                        color: amber.withValues(alpha: 0.50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          _dukeBox(
            borderColor: directionColor.withValues(alpha: 0.55),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTIVE SIGNAL',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 6.5,
                          ),
                        ),
                        Text(
                          direction,
                          style: TextStyle(
                            color: directionColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedPair.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 84,
                    height: 48,
                    child: CustomPaint(
                      painter: _SparkPainter(
                        values: history,
                        color: directionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _dukeMetric(
                  'CURRENT PRICE',
                  price?.toString() ?? '--',
                  cyan,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _dukeMetric(
                  'ADAPTIVE SCORE',
                  duke == null ? '--' : duke.qualityScore.toStringAsFixed(1),
                  purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: _dukeBox(
              borderColor: purple.withValues(alpha: 0.35),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'LIVE INTELLIGENCE FEED',
                          style: TextStyle(
                            color: cyan,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          duke == null
                              ? 'WAIT'
                              : duke.tradeApproved
                                  ? 'ACTIVE'
                                  : 'MONITORING',
                          style: TextStyle(
                            color: duke?.tradeApproved == true ? green : amber,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      duke?.explanation ??
                          'Trading Brain 3.0 is monitoring the live market feed and waiting for a qualified setup.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Text(
                'TRADE GATE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 7,
                ),
              ),
              const Spacer(),
              Text(
                approved ? 'APPROVED' : 'HOLD',
                style: TextStyle(
                  color: approved ? green : amber,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: duke == null ? 0 : (duke.qualityScore / 100).clamp(0.0, 1.0),
            minHeight: 5,
            color: directionColor,
            backgroundColor: Colors.white10,
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Expanded(
                  child: _tradeButton('CALL', green),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _tradeButton('PUT', red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brainMetricLine(
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 6.3,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _bottomRail() {
    final signal = _signalFor(selectedPair);
    final history = _historyFor(selectedPair);
    final performance = scannerController.dukePerformance;

    final direction = _direction(signal);
    final directionColor = _directionColor(direction);

    final confidence = signal?.confidence ?? 0.0;

    final winRate = performance.closedSignals == 0
        ? 0.0
        : performance.winRate.clamp(0.0, 100.0).toDouble();

    final rsiText = _estimateRsi(history);
    final rsiValue = double.tryParse(rsiText) ?? 50.0;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _glass(
            glow: true,
            onTap: _openScannerModule,
            padding: const EdgeInsets.all(7),
            title:
                'TECHNICAL OVERVIEW • ${selectedPair.replaceAll('_', ' ')} • $timeframe',
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _hudMeterLine(
                        'TREND',
                        signal?.trend ?? '--',
                        confidence / 100,
                        cyan,
                      ),
                      const SizedBox(height: 5),
                      _hudMeterLine(
                        'RSI',
                        rsiText,
                        rsiValue / 100,
                        purple,
                      ),
                      const SizedBox(height: 5),
                      _hudMeterLine(
                        'MOMENTUM',
                        signal?.momentum ?? '--',
                        confidence / 100,
                        amber,
                      ),
                      const SizedBox(height: 5),
                      _hudMeterLine(
                        'AI SCORE',
                        signal == null
                            ? '--'
                            : signal.confidence.toStringAsFixed(1),
                        confidence / 100,
                        directionColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SparkPainter(
                            values: history,
                            color: cyan,
                            candles: true,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cyan.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: cyan.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            direction,
                            style: TextStyle(
                              color: directionColor,
                              fontSize: 6.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _glass(
            onTap: _openAnalyticsModule,
            padding: const EdgeInsets.all(7),
            title: 'MULTI-TIMEFRAME MATRIX',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _hudTfMeter('M1', timeframe == 'M1', 0.92),
                _hudTfMeter('M5', timeframe == 'M5', 0.74),
                _hudTfMeter('M15', timeframe == 'M15', 0.61),
                _hudTfMeter('M30', timeframe == 'M30', 0.48),
                _hudTfMeter('H1', timeframe == 'H1', 0.36),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _glass(
            glow: true,
            onTap: () => _showDukeResult(
              scannerController.deepScan(selectedPair),
            ),
            borderColor: directionColor.withValues(alpha: 0.60),
            padding: const EdgeInsets.all(7),
            title: 'AI PREDICTION ENGINE',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT 1 MINUTE FORECAST',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 6.5,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        direction,
                        style: TextStyle(
                          color: directionColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      signal == null
                          ? '--'
                          : '${signal.confidence.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: (confidence / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  color: directionColor,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: CustomPaint(
                    painter: _SparkPainter(
                      values: history,
                      color: directionColor,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: signal == null ? amber : green,
                        boxShadow: [
                          BoxShadow(
                            color: (signal == null ? amber : green)
                                .withValues(alpha: 0.55),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        signal == null
                            ? 'SCANNING FOR QUALIFIED SETUP'
                            : 'LIVE AI SIGNAL PROCESSING',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 6.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _glass(
            glow: performance.closedSignals > 0,
            onTap: _openTrackerModule,
            borderColor: green.withValues(alpha: 0.48),
            padding: const EdgeInsets.all(7),
            title: 'PERFORMANCE CORE',
            child: Row(
              children: [
                SizedBox(
                  width: 67,
                  height: 67,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: winRate / 100,
                          strokeWidth: 5,
                          color: green,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            performance.closedSignals == 0
                                ? '--'
                                : '${winRate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'WIN RATE',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 5.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _miniPerformanceLine(
                        'TRADES',
                        '${performance.closedSignals}',
                        cyan,
                      ),
                      const SizedBox(height: 5),
                      _miniPerformanceLine(
                        'WINS',
                        '${performance.wins}',
                        green,
                      ),
                      const SizedBox(height: 5),
                      _miniPerformanceLine(
                        'LOSSES',
                        '${performance.losses}',
                        red,
                      ),
                      const SizedBox(height: 5),
                      _miniPerformanceLine(
                        'TIES',
                        '${performance.breakeven}',
                        amber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _glass(
            onTap: _openMarketsModule,
            borderColor: amber.withValues(alpha: 0.42),
            padding: const EdgeInsets.all(7),
            title: 'MARKET INTELLIGENCE FEED',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: amber.withValues(alpha: 0.07),
                        border: Border.all(
                          color: amber.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: amber.withValues(alpha: 0.10),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.public,
                        color: amber,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MACRO FEED',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'AWAITING LIVE SOURCE',
                            style: TextStyle(
                              color: amber,
                              fontSize: 6.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Container(
                  height: 1,
                  color: amber.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No simulated market news. Live macro integration will populate this command feed.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 6.6,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'SOURCE STATUS: STANDBY',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 5.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hudMeterLine(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 47,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 5.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 6.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 3,
            color: color,
            backgroundColor: Colors.white10,
          ),
        ),
      ],
    );
  }

  Widget _hudTfMeter(
    String label,
    bool active,
    double strength,
  ) {
    final color = active ? green : cyan;

    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            label,
            style: TextStyle(
              color: active ? green : Colors.white54,
              fontSize: 6.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: strength.clamp(0.0, 1.0),
              minHeight: 4,
              color: color,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 31,
          child: Text(
            active ? 'ACTIVE' : 'READY',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: active ? green : cyan,
              fontSize: 5.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniPerformanceLine(
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 5.8,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  String _estimateRsi(List<double> values) {
    if (values.length < 2) return '--';

    final start = max(1, values.length - 14);
    double gains = 0;
    double losses = 0;

    for (int i = start; i < values.length; i++) {
      final change = values[i] - values[i - 1];

      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }

    if (gains == 0 && losses == 0) return '50.0';
    if (losses == 0) return '100.0';

    final rs = gains / losses;
    final rsi = 100 - (100 / (1 + rs));

    return rsi.toStringAsFixed(1);
  }

  Widget _hudFrameOverlay({
    Color accent = cyan,
    bool intense = false,
  }) {
    final edge = accent.withValues(alpha: intense ? 0.50 : 0.28);
    final glow = accent.withValues(alpha: intense ? 0.18 : 0.08);

    Widget corner({
      required bool top,
      required bool left,
    }) {
      return SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          children: [
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: edge,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: glow,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: Container(
                width: 2,
                height: 14,
                decoration: BoxDecoration(
                  color: edge,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: glow,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget hudDot(double alpha) {
      return Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: alpha),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: alpha * 0.7),
              blurRadius: 5,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.015),
                  Colors.transparent,
                  accent.withValues(alpha: intense ? 0.030 : 0.015),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: corner(top: true, left: true),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: corner(top: true, left: false),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: corner(top: false, left: true),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: corner(top: false, left: false),
        ),
        Positioned(
          top: 9,
          left: 12,
          right: 60,
          child: Container(
            height: 1,
            color: accent.withValues(alpha: intense ? 0.22 : 0.12),
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: Row(
            children: [
              hudDot(0.18),
              hudDot(0.32),
              hudDot(0.55),
            ],
          ),
        ),
        Positioned(
          bottom: 8,
          left: 12,
          right: 12,
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.035),
          ),
        ),
      ],
    );
  }

  Widget _glass({
    required Widget child,
    String? title,
    double? height,
    bool glow = false,
    Color? borderColor,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    VoidCallback? onTap,
  }) {
    final accent = borderColor ?? cyan;

    final content = title == null
        ? child
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: child),
            ],
          );

    final body = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: _hudFrameOverlay(
              accent: accent,
              intense: glow,
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: content,
        ),
      ],
    );

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: hudPanelDecoration(
        borderColor: accent,
        radius: 8,
        strongGlow: glow,
      ),
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                hoverColor: accent.withValues(alpha: 0.07),
                splashColor: accent.withValues(alpha: 0.12),
                highlightColor: accent.withValues(alpha: 0.05),
                child: body,
              ),
            ),
    );
  }

  Widget _dukeBox({
    required Widget child,
    Color? borderColor,
  }) {
    final accent = borderColor ?? cyan;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: hudPanelDecoration(
        borderColor: accent,
        radius: 6,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _hudFrameOverlay(
                accent: accent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(7),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _dukeMetric(
    String label,
    String value,
    Color valueColor,
  ) {
    return _dukeBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tradeButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () => _showScannerOnly(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.38),
        foregroundColor: Colors.white,
        side: BorderSide(
          color: color.withValues(alpha: 0.85),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showScannerOnly(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$value selected for $selectedPair - scanner only; no trade was sent.',
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Widget _reason(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            color: green,
            size: 5,
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.circle,
            color: green,
            size: 5,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String label,
    String value, {
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tinyButton(
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return SizedBox(
      height: 29,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? green : Colors.white38,
          side: BorderSide(
            color: selected ? green : Colors.white12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 8),
        ),
      ),
    );
  }

  Widget _verticalLine() {
    return Container(
      width: 1,
      height: 31,
      color: Colors.white10,
    );
  }

  Widget _miniSelector(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: panel2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: cyan.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 7,
        ),
      ),
    );
  }

  Widget _filterButton(String value) {
    final selected = pairFilter == value;

    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            pairFilter = value;
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: selected ? cyan : Colors.white38,
          backgroundColor:
              selected ? cyan.withValues(alpha: 0.08) : Colors.transparent,
          side: BorderSide(
            color: selected ? cyan : Colors.white12,
          ),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 8),
        ),
      ),
    );
  }

  Widget _techLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                color: amber,
                fontSize: 8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tfLine(String label, bool active) {
    return InkWell(
      onTap: () => _setTimeframe(label),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ),
          Text(
            active ? 'ACTIVE' : 'AVAILABLE',
            style: TextStyle(
              color: active ? green : cyan,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool candles;

  const _SparkPainter({
    required this.values,
    required this.color,
    this.candles = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    if (values.length < 2) return;

    final sample =
        values.length > 60 ? values.sublist(values.length - 60) : values;

    final minValue = sample.reduce(min);
    final maxValue = sample.reduce(max);
    final range = max(maxValue - minValue, 0.0000001);

    final path = Path();

    for (int i = 0; i < sample.length; i++) {
      final x = i / max(1, sample.length - 1) * size.width;
      final normalized = (sample[i] - minValue) / range;
      final y = size.height - (normalized * size.height * 0.82) - 4;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);

    final line = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, line);

    if (candles) {
      final candlePaint = Paint()..strokeWidth = 2;

      final step = max(1, sample.length ~/ 18);

      for (int i = step; i < sample.length; i += step) {
        final x = i / max(1, sample.length - 1) * size.width;
        final up = sample[i] >= sample[max(0, i - step)];

        candlePaint.color =
            up ? const Color(0xFF28FF72) : const Color(0xFFFF3E49);

        canvas.drawLine(
          Offset(x, size.height * 0.48),
          Offset(
            x,
            up ? size.height * 0.30 : size.height * 0.66,
          ),
          candlePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return true;
  }
}
