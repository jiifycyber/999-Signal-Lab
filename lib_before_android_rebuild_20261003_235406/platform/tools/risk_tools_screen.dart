import 'package:flutter/material.dart';
import '../../ui/intelligence_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform_shell.dart';

const cyan = IntelligenceTheme.cyan;
const green = IntelligenceTheme.green;
const amber = IntelligenceTheme.amber;
const red = IntelligenceTheme.red;
const panel = IntelligenceTheme.panel;

class RiskToolsScreen extends StatefulWidget {
  final bool Function() liveModeProvider;

  const RiskToolsScreen({
    super.key,
    required this.liveModeProvider,
  });

  @override
  State<RiskToolsScreen> createState() => _RiskToolsScreenState();
}

class _RiskToolsScreenState extends State<RiskToolsScreen> {
  final demo = TextEditingController();
  final live = TextEditingController();

  final riskPercent = TextEditingController(text: '2');
  final dailyLossPercent = TextEditingController(text: '5');
  final maxLosses = TextEditingController(text: '3');
  final maxExposurePercent = TextEditingController(text: '10');

  final entry = TextEditingController();
  final stop = TextEditingController();
  final peak = TextEditingController();

  bool saved = false;

  @override
  void initState() {
    super.initState();
    _load();

    for (final c in [
      demo,
      live,
      riskPercent,
      dailyLossPercent,
      maxLosses,
      maxExposurePercent,
      entry,
      stop,
      peak,
    ]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double? _n(TextEditingController c) {
    final text = c.text.replaceAll('\$', '').replaceAll(',', '').trim();

    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get isLive => widget.liveModeProvider();

  double? get demoBalance => _n(demo);
  double? get liveBalance => _n(live);
  double? get activeBalance => isLive ? liveBalance : demoBalance;

  double get riskPct => _n(riskPercent) ?? 0;
  double get dailyPct => _n(dailyLossPercent) ?? 0;
  double get exposurePct => _n(maxExposurePercent) ?? 0;

  double? get riskAmount {
    final b = activeBalance;
    if (b == null) return null;
    return b * riskPct / 100;
  }

  double? get dailyLossAmount {
    final b = activeBalance;
    if (b == null) return null;
    return b * dailyPct / 100;
  }

  double? get exposureAmount {
    final b = activeBalance;
    if (b == null) return null;
    return b * exposurePct / 100;
  }

  double? get distance {
    final e = _n(entry);
    final s = _n(stop);

    if (e == null || s == null || e == s) return null;

    return (e - s).abs();
  }

  double? get positionSize {
    final risk = riskAmount;
    final d = distance;

    if (risk == null || d == null || d <= 0) return null;

    return risk / d;
  }

  double? get drawdownAmount {
    final p = _n(peak);
    final b = activeBalance;

    if (p == null || b == null || p <= b) return 0;

    return p - b;
  }

  double? get drawdownPercent {
    final p = _n(peak);
    final amount = drawdownAmount;

    if (p == null || amount == null || p <= 0) return null;

    return amount / p * 100;
  }

  String money(double? value) =>
      value == null ? '--' : '\$${value.toStringAsFixed(2)}';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final d = prefs.getDouble('risk_demo_balance');
    final l = prefs.getDouble('risk_live_balance');

    if (d != null) demo.text = d.toStringAsFixed(2);
    if (l != null) live.text = l.toStringAsFixed(2);

    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final d = demoBalance;
    final l = liveBalance;

    if (d != null) {
      await prefs.setDouble('risk_demo_balance', d);
    }

    if (l != null) {
      await prefs.setDouble('risk_live_balance', l);
    }

    if (!mounted) return;

    setState(() => saved = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformShell(
      title: '999 Risk Command Center',
      subtitle: 'Account protection + position control',
      icon: Icons.shield_outlined,
      children: [
        section('ACCOUNT BALANCES'),
        LayoutBuilder(
          builder: (_, c) {
            final cards = [
              balanceCard(
                'DEMO BALANCE',
                demo,
                amber,
                'Pocket Option demo account',
              ),
              balanceCard(
                'LIVE BALANCE',
                live,
                green,
                'Pocket Option real account',
              ),
              metricCard(
                'ACTIVE ACCOUNT',
                isLive ? 'LIVE' : 'DEMO',
                'Active Equity ${money(activeBalance)}',
                isLive ? green : amber,
              ),
            ];

            if (c.maxWidth < 850) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _save,
            icon: Icon(saved ? Icons.check_circle : Icons.save),
            label: Text(
              saved ? 'BALANCES SAVED' : 'SAVE BALANCES',
            ),
          ),
        ),
        section('CORE RISK CONTROL'),
        LayoutBuilder(
          builder: (_, c) {
            final manager = box(
              'RISK MANAGER',
              Icons.security,
              [
                result('Active Equity', money(activeBalance), cyan),
                input('Risk Per Trade %', riskPercent),
                result('Risk Amount', money(riskAmount), cyan),
                input('Daily Loss Limit %', dailyLossPercent),
                result(
                  'Daily Loss Limit',
                  money(dailyLossAmount),
                  amber,
                ),
                input('Max Consecutive Losses', maxLosses),
                input('Maximum Exposure %', maxExposurePercent),
                result(
                  'Maximum Exposure',
                  money(exposureAmount),
                  cyan,
                ),
              ],
            );

            final calculator = box(
              'POSITION CALCULATOR',
              Icons.calculate,
              [
                result('Active Balance', money(activeBalance), cyan),
                result(
                  'Risk Per Trade',
                  '${riskPct.toStringAsFixed(2)}%',
                  cyan,
                ),
                result('Risk Amount', money(riskAmount), cyan),
                input('Entry Price', entry),
                input('Stop / Reference Price', stop),
                result(
                  'Price Distance',
                  distance?.toStringAsFixed(6) ?? '--',
                  amber,
                ),
                result(
                  'Position Size',
                  positionSize?.toStringAsFixed(4) ?? '--',
                  green,
                ),
              ],
            );

            if (c.maxWidth < 850) {
              return Column(
                children: [
                  manager,
                  const SizedBox(height: 12),
                  calculator,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: manager),
                const SizedBox(width: 12),
                Expanded(child: calculator),
              ],
            );
          },
        ),
        section('DRAWDOWN MONITOR'),
        box(
          'ACCOUNT DRAWDOWN',
          Icons.trending_down,
          [
            input('Peak Balance', peak),
            result('Current Equity', money(activeBalance), cyan),
            result(
              'Drawdown Dollars',
              money(drawdownAmount),
              (drawdownPercent ?? 0) >= 10 ? red : amber,
            ),
            result(
              'Drawdown %',
              drawdownPercent == null
                  ? '--'
                  : '${drawdownPercent!.toStringAsFixed(2)}%',
              (drawdownPercent ?? 0) >= 10
                  ? red
                  : (drawdownPercent ?? 0) >= 5
                      ? amber
                      : green,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              minHeight: 10,
              value: ((drawdownPercent ?? 0) / 20).clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
            ),
          ],
        ),
      ],
    );
  }

  Widget balanceCard(
    String title,
    TextEditingController controller,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: decoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: 'Enter balance',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$subtitle • Editable',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget metricCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: decoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color)),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38),
          ),
        ],
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

  Widget input(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget result(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
