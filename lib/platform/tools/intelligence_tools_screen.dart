import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/intelligence_theme.dart';

import '../platform_shell.dart';

const cyan = IntelligenceTheme.cyan;
const green = IntelligenceTheme.green;
const amber = IntelligenceTheme.amber;
const red = IntelligenceTheme.red;
const panel = IntelligenceTheme.panel;

class IntelligenceToolsScreen extends StatefulWidget {
  final List<dynamic> Function() signalsProvider;
  final List<dynamic> Function() outcomesProvider;
  final Map<String, double> Function() weightsProvider;
  final bool Function() connectedProvider;
  final bool Function() liveModeProvider;
  final int Function() pendingProvider;
  final String Function() pairProvider;
  final VoidCallback onDeepScan;

  const IntelligenceToolsScreen({
    super.key,
    required this.signalsProvider,
    required this.outcomesProvider,
    required this.weightsProvider,
    required this.connectedProvider,
    required this.liveModeProvider,
    required this.pendingProvider,
    required this.pairProvider,
    required this.onDeepScan,
  });

  @override
  State<IntelligenceToolsScreen> createState() =>
      _IntelligenceToolsScreenState();
}

class _IntelligenceToolsScreenState extends State<IntelligenceToolsScreen> {
  int tab = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  List<dynamic> get signals => widget.signalsProvider();
  List<dynamic> get outcomes => widget.outcomesProvider();
  Map<String, double> get weights => widget.weightsProvider();

  String text(dynamic value) => value?.toString() ?? '--';

  double number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int get wins =>
      outcomes.where((o) => text(o.outcome).toUpperCase() == 'WIN').length;

  int get losses =>
      outcomes.where((o) => text(o.outcome).toUpperCase() == 'LOSS').length;

  int get resolved => wins + losses;

  double get winRate => resolved == 0 ? 0 : wins / resolved * 100;

  @override
  Widget build(BuildContext context) {
    return PlatformShell(
      title: '999 Intelligence Command Center',
      subtitle: 'Scanner learning + analytics + diagnostics',
      icon: Icons.psychology_alt_outlined,
      children: [
        section('LIVE SYSTEM STATUS'),
        statusCards(),
        const SizedBox(height: 18),
        tabs(),
        const SizedBox(height: 14),
        body(),
      ],
    );
  }

  Widget statusCards() {
    return LayoutBuilder(
      builder: (_, c) {
        final width = c.maxWidth >= 900
            ? (c.maxWidth - 36) / 4
            : c.maxWidth >= 600
                ? (c.maxWidth - 12) / 2
                : c.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            statusCard(
              width,
              'SCANNER ENGINE',
              widget.connectedProvider() ? 'ONLINE' : 'SYNCING',
              '${signals.length} signals',
              widget.connectedProvider() ? green : amber,
            ),
            statusCard(
              width,
              'PO BRIDGE',
              widget.connectedProvider() ? 'CONNECTED' : 'WAITING',
              'Pocket Option feed',
              widget.connectedProvider() ? green : amber,
            ),
            statusCard(
              width,
              'DUKE AI',
              'ACTIVE',
              '${widget.pendingProvider()} pending',
              cyan,
            ),
            statusCard(
              width,
              'ACCOUNT MODE',
              widget.liveModeProvider() ? 'LIVE' : 'DEMO',
              widget.pairProvider(),
              widget.liveModeProvider() ? green : amber,
            ),
          ],
        );
      },
    );
  }

  Widget tabs() {
    const labels = [
      'AI LEARNING',
      'PAIR ANALYZER',
      'SESSION ANALYZER',
      'SIGNAL QUALITY',
      'DIAGNOSTICS',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = tab == i;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active ? cyan.withValues(alpha: .12) : panel,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? cyan : Colors.white10,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: active ? cyan : Colors.white54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget body() {
    switch (tab) {
      case 1:
        return pairAnalyzer();
      case 2:
        return sessionAnalyzer();
      case 3:
        return qualityAnalyzer();
      case 4:
        return diagnostics();
      default:
        return learning();
    }
  }

  Widget learning() {
    return Column(
      children: [
        box(
          'LEARNING PERFORMANCE',
          Icons.memory,
          [
            row('Resolved Outcomes', '$resolved'),
            row('Wins', '$wins', green),
            row('Losses', '$losses', red),
            row(
              'Win Rate',
              resolved == 0 ? '--' : '${winRate.toStringAsFixed(1)}%',
              cyan,
            ),
            row(
              'Pending Predictions',
              '${widget.pendingProvider()}',
              amber,
            ),
          ],
        ),
        const SizedBox(height: 12),
        box(
          'ADAPTIVE ENGINE WEIGHTS',
          Icons.tune,
          weights.isEmpty
              ? [
                  row(
                    'Status',
                    'WAITING FOR LEARNING DATA',
                    amber,
                  ),
                ]
              : weights.entries
                  .map(
                    (e) => row(
                      e.key.toUpperCase(),
                      e.value.toStringAsFixed(2),
                      cyan,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget pairAnalyzer() {
    if (signals.isEmpty) {
      return box(
        'PAIR ANALYZER',
        Icons.currency_exchange,
        [
          row('Status', 'WAITING FOR LIVE SIGNALS', amber),
        ],
      );
    }

    final sorted = [...signals];

    sorted.sort(
      (a, b) => number(b.confidence).compareTo(number(a.confidence)),
    );

    return box(
      'LIVE PAIR ANALYZER',
      Icons.currency_exchange,
      [
        for (final s in sorted)
          row(
            text(s.symbol),
            '${number(s.confidence).toStringAsFixed(1)}% • '
            '${text(s.trend)} • ${text(s.momentum)}',
            cyan,
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: widget.onDeepScan,
            icon: const Icon(Icons.radar),
            label: const Text('RUN ALL-MARKET DEEP SCAN'),
          ),
        ),
      ],
    );
  }

  Widget sessionAnalyzer() {
    final counts = {
      'ASIA': 0,
      'LONDON': 0,
      'NEW YORK': 0,
    };

    for (final o in outcomes) {
      final dynamic raw = o.timestamp;

      if (raw is! DateTime) continue;

      final hour = raw.toUtc().hour;

      if (hour < 8) {
        counts['ASIA'] = counts['ASIA']! + 1;
      } else if (hour < 13) {
        counts['LONDON'] = counts['LONDON']! + 1;
      } else {
        counts['NEW YORK'] = counts['NEW YORK']! + 1;
      }
    }

    return box(
      'SESSION ANALYZER',
      Icons.public,
      [
        row('Asia Session', '${counts['ASIA']} records', cyan),
        row('London Session', '${counts['LONDON']} records', cyan),
        row(
          'New York Session',
          '${counts['NEW YORK']} records',
          cyan,
        ),
      ],
    );
  }

  Widget qualityAnalyzer() {
    const buckets = [
      [50.0, 59.999],
      [60.0, 69.999],
      [70.0, 79.999],
      [80.0, 89.999],
      [90.0, 100.0],
    ];

    return box(
      'SIGNAL QUALITY ANALYZER',
      Icons.verified,
      [
        for (final bucket in buckets) qualityRow(bucket[0], bucket[1]),
      ],
    );
  }

  Widget qualityRow(double low, double high) {
    final matches = outcomes.where((o) {
      final c = number(o.confidence);
      return c >= low && c <= high;
    }).toList();

    final w =
        matches.where((o) => text(o.outcome).toUpperCase() == 'WIN').length;

    final l =
        matches.where((o) => text(o.outcome).toUpperCase() == 'LOSS').length;

    final total = w + l;
    final rate = total == 0 ? 0 : w / total * 100;

    return row(
      '${low.toInt()}-${high.ceil()}%',
      total == 0
          ? 'No resolved signals'
          : '$total signals • $w W / $l L • '
              '${rate.toStringAsFixed(1)}%',
      total == 0 ? Colors.white38 : cyan,
    );
  }

  Widget diagnostics() {
    return box(
      'SCANNER DIAGNOSTICS',
      Icons.monitor_heart,
      [
        row(
          'Pocket Option Bridge',
          widget.connectedProvider() ? 'CONNECTED' : 'SYNCING',
          widget.connectedProvider() ? green : amber,
        ),
        row(
          'Scanner Engine',
          widget.connectedProvider() ? 'RUNNING' : 'SYNCING',
          widget.connectedProvider() ? green : amber,
        ),
        row(
          'Market Mode',
          widget.liveModeProvider() ? 'LIVE' : 'DEMO',
          widget.liveModeProvider() ? green : amber,
        ),
        row('Live Signals', '${signals.length}', cyan),
        row(
          'Pending Predictions',
          '${widget.pendingProvider()}',
          cyan,
        ),
        row('Learning Outcomes', '${outcomes.length}', cyan),
        row('Active Pair', widget.pairProvider(), cyan),
      ],
    );
  }

  Widget statusCard(
    double width,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: decoration(color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white38),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget box(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: decoration(Colors.white24),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: cyan),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget row(
    String label,
    String value, [
    Color color = Colors.white,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration decoration(Color color) {
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withValues(alpha: .25),
      ),
    );
  }

  Widget section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: cyan,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}
