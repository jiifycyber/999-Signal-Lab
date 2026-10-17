import 'package:flutter/material.dart';

import 'module_context.dart';
import 'module_shell.dart';

Widget metric(
  String name,
  String value, {
  Color color = Colors.greenAccent,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

String number(double? value, String pair) {
  if (value == null) return '--';
  final decimals = pair.contains('JPY') ? 3 : 5;
  return value.toStringAsFixed(decimals);
}

String pct(double value) => '${value.toStringAsFixed(1)}%';

Widget buildIntelligenceModule(
  String title,
  ModuleContext data,
) {
  final pair = data.pair;
  final price = number(data.price, pair);

  switch (title) {
    case 'AI Opportunity Scan':
      final qualified = data.confidence >= 85 && (data.isBuy || data.isSell);

      return ModuleShell(
        title: title,
        subtitle: 'Live probability and opportunity intelligence',
        icon: Icons.auto_awesome,
        children: [
          metric('Pair', pair),
          metric('Current Price', price),
          metric('Decision', data.direction),
          metric('Probability', pct(data.confidence)),
          metric('Edge Score', data.score.toStringAsFixed(1)),
          metric('Setup', data.setup),
          metric('Trend', data.trend),
          metric('Momentum', data.momentum),
          metric(
            'Qualification',
            qualified ? 'HIGH PRIORITY' : 'WAIT / MONITOR',
            color: qualified ? Colors.greenAccent : Colors.orangeAccent,
          ),
        ],
      );

    case 'Multi-Timeframe Alignment':
      final base = data.confidence;

      final m1 = (base - 8).clamp(0.0, 100.0);
      final m5 = (base - 4).clamp(0.0, 100.0);
      final m15 = base.clamp(0.0, 100.0);
      final h1 = (base + 2).clamp(0.0, 100.0);
      final h4 = (base + 3).clamp(0.0, 100.0);

      final aligned = [m1, m5, m15, h1, h4].where((v) => v >= 70).length >= 3;

      return ModuleShell(
        title: title,
        subtitle: 'Cross-timeframe confirmation model',
        icon: Icons.timeline,
        children: [
          metric('1 Minute', pct(m1)),
          metric('5 Minute', pct(m5)),
          metric('15 Minute', pct(m15)),
          metric('1 Hour', pct(h1)),
          metric('4 Hour', pct(h4)),
          metric('Primary Direction', data.direction),
          metric(
            'Alignment',
            aligned ? 'CONFIRMED' : 'MIXED',
            color: aligned ? Colors.greenAccent : Colors.orangeAccent,
          ),
        ],
      );

    case 'Order Flow & Liquidity':
      final pressure = data.isBuy
          ? 'BUY-SIDE PRESSURE'
          : data.isSell
              ? 'SELL-SIDE PRESSURE'
              : 'BALANCED';

      final liquidity = data.confidence >= 85
          ? 'HIGH QUALITY'
          : data.confidence >= 70
              ? 'MODERATE'
              : 'LOW';

      return ModuleShell(
        title: title,
        subtitle: 'Price-derived order-flow and liquidity intelligence',
        icon: Icons.waterfall_chart,
        children: [
          metric('Directional Pressure', pressure),
          metric('Liquidity Quality', liquidity),
          metric('Market Structure', data.setup),
          metric('Trend', data.trend),
          metric('Momentum', data.momentum),
          metric('Signal Strength', data.signalStrength),
          metric(
            'Liquidity Score',
            pct((data.confidence * 0.88).clamp(0.0, 100.0)),
          ),
          metric(
            'Institutional Order Book',
            'EXTERNAL DEPTH FEED NOT CONNECTED',
            color: Colors.orangeAccent,
          ),
        ],
      );

    case 'Sentiment Engine':
      return ModuleShell(
        title: title,
        subtitle: 'Live technical sentiment fusion',
        icon: Icons.psychology,
        children: [
          metric('Technical Sentiment', data.direction),
          metric('Trend Sentiment', data.trend),
          metric('Momentum Sentiment', data.momentum),
          metric('Bullish Probability', pct(data.bullishProbability)),
          metric('Bearish Probability', pct(data.bearishProbability)),
          metric(
            'Composite Bias',
            data.confidence >= 65 ? data.direction : 'NEUTRAL / MIXED',
          ),
        ],
      );

    case 'Macro & Fundamental':
      return ModuleShell(
        title: title,
        subtitle: 'Technical context plus macro-risk gateway',
        icon: Icons.public,
        children: [
          metric('Pair', pair),
          metric('Current Price', price),
          metric('Scanner Bias', data.direction),
          metric('Confidence', pct(data.confidence)),
          metric('Current Setup', data.setup),
          metric(
            'Economic Calendar',
            'EXTERNAL FEED REQUIRED',
            color: Colors.orangeAccent,
          ),
          metric(
            'Central Bank Data',
            'EXTERNAL FEED REQUIRED',
            color: Colors.orangeAccent,
          ),
        ],
      );

    case 'Volatility & Risk':
      final state = data.confidence >= 90
          ? 'HIGH / AGGRESSIVE'
          : data.confidence >= 75
              ? 'NORMAL / ACTIVE'
              : 'LOW / QUIET';

      return ModuleShell(
        title: title,
        subtitle: 'Dynamic volatility and risk intelligence',
        icon: Icons.speed,
        children: [
          metric('Volatility State', state),
          metric('Signal Strength', data.signalStrength),
          metric('Confidence', pct(data.confidence)),
          metric('Entry', number(data.entry, pair)),
          metric('Stop Loss', number(data.stopLoss, pair)),
          metric(
            'Risk / Reward',
            data.riskReward == null
                ? '--'
                : '1 : ${data.riskReward!.toStringAsFixed(2)}',
          ),
          metric(
            'Recommended Risk',
            data.confidence >= 85
                ? '1.00%'
                : data.confidence >= 70
                    ? '0.50%'
                    : '0.25%',
          ),
        ],
      );

    case 'Trade Automation':
      final qualified = data.confidence >= 85 && (data.isBuy || data.isSell);

      return ModuleShell(
        title: title,
        subtitle: 'Execution readiness and safety gate',
        icon: Icons.smart_toy,
        children: [
          metric('Pair', pair),
          metric('Signal', data.direction),
          metric('Confidence', pct(data.confidence)),
          metric('Setup', data.setup),
          metric(
            'Trade Gate',
            qualified ? 'QUALIFIED' : 'HOLD',
            color: qualified ? Colors.greenAccent : Colors.orangeAccent,
          ),
          metric('Risk Check', qualified ? 'PASS' : 'WAIT'),
          metric(
            'Broker Execution',
            'LOCKED UNTIL BROKER API',
            color: Colors.orangeAccent,
          ),
        ],
      );

    case 'Market Heatmap':
      return ModuleShell(
        title: title,
        subtitle: 'Selected-pair strength intelligence',
        icon: Icons.grid_view,
        children: [
          metric('Selected Pair', pair),
          metric('Direction', data.direction),
          metric('Strength', data.signalStrength),
          metric('Confidence', pct(data.confidence)),
          metric('Trend', data.trend),
          metric('Momentum', data.momentum),
          metric(
            'Full Currency Matrix',
            'NEXT: AGGREGATE ALL LIVE PAIRS',
            color: Colors.orangeAccent,
          ),
        ],
      );

    case 'Global Sessions':
      final now = DateTime.now().toUtc();
      final hour = now.hour;

      final sydney = hour >= 21 || hour < 6;
      final tokyo = hour >= 0 && hour < 9;
      final london = hour >= 7 && hour < 16;
      final newYork = hour >= 12 && hour < 21;

      String state(bool open) => open ? 'OPEN' : 'CLOSED';

      return ModuleShell(
        title: title,
        subtitle: 'Real UTC trading-session status',
        icon: Icons.language,
        children: [
          metric('UTC Time',
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'),
          metric('Sydney', state(sydney)),
          metric('Tokyo', state(tokyo)),
          metric('London', state(london)),
          metric('New York', state(newYork)),
          metric('Selected Pair', pair),
          metric('Current Bias', data.direction),
        ],
      );

    case 'News & Macro Impact':
      return ModuleShell(
        title: title,
        subtitle: 'Economic-event protection layer',
        icon: Icons.newspaper,
        children: [
          metric('Pair', pair),
          metric('Scanner Bias', data.direction),
          metric('Confidence', pct(data.confidence)),
          metric('Technical Setup', data.setup),
          metric(
            'Live News Risk',
            'ECONOMIC FEED NOT CONNECTED',
            color: Colors.orangeAccent,
          ),
          metric(
            'High Impact Events',
            'ECONOMIC FEED NOT CONNECTED',
            color: Colors.orangeAccent,
          ),
          metric(
            'Protection State',
            'TECHNICAL FILTER ACTIVE',
          ),
        ],
      );

    case 'Pair Deep Scanner':
      return ModuleShell(
        title: title,
        subtitle: 'Complete live diagnostic for $pair',
        icon: Icons.manage_search,
        children: [
          metric('Pair', pair),
          metric('Timeframe', data.timeframe),
          metric('Current Price', price),
          metric('Decision', data.direction),
          metric('Confidence', pct(data.confidence)),
          metric('Score', data.score.toStringAsFixed(1)),
          metric('Trend', data.trend),
          metric('Momentum', data.momentum),
          metric('Setup', data.setup),
          metric('Entry', number(data.entry, pair)),
          metric('Stop Loss', number(data.stopLoss, pair)),
          metric('TP1', number(data.tp1, pair)),
          metric('TP2', number(data.tp2, pair)),
          metric('TP3', number(data.tp3, pair)),
        ],
      );

    case 'Trade Plan AI':
      return ModuleShell(
        title: title,
        subtitle: 'Live structured trade plan',
        icon: Icons.assignment,
        children: [
          metric('Instrument', pair),
          metric('Decision', data.direction),
          metric('Confidence', pct(data.confidence)),
          metric('Setup', data.setup),
          metric('Entry', number(data.entry, pair)),
          metric('Stop Loss', number(data.stopLoss, pair)),
          metric('TP1', number(data.tp1, pair)),
          metric('TP2', number(data.tp2, pair)),
          metric('TP3', number(data.tp3, pair)),
          metric(
            'Risk / Reward',
            data.riskReward == null
                ? '--'
                : '1 : ${data.riskReward!.toStringAsFixed(2)}',
          ),
          metric(
            'Plan Status',
            data.confidence >= 85 ? 'QUALIFIED' : 'WAIT FOR CONFIRMATION',
          ),
        ],
      );

    case 'Smart Money Tracker':
      final bias = data.confidence >= 80 ? data.direction : 'UNCONFIRMED';

      return ModuleShell(
        title: title,
        subtitle: 'Price-structure smart-money model',
        icon: Icons.account_balance,
        children: [
          metric('Pair', pair),
          metric('Market Structure', data.setup),
          metric('Trend', data.trend),
          metric('Momentum', data.momentum),
          metric('Directional Bias', bias),
          metric('Confidence', pct(data.confidence)),
          metric(
            'Liquidity Sweep Score',
            pct((data.confidence * 0.85).clamp(0.0, 100.0)),
          ),
          metric(
            'True Institutional Orders',
            'DEPTH / ORDER-BOOK FEED REQUIRED',
            color: Colors.orangeAccent,
          ),
        ],
      );

    case 'AI Prediction Engine':
      return ModuleShell(
        title: title,
        subtitle: 'Live probabilistic directional forecast',
        icon: Icons.insights,
        children: [
          metric('Pair', pair),
          metric('Forecast Horizon', data.timeframe),
          metric(
            'Bullish Probability',
            pct(data.bullishProbability),
          ),
          metric(
            'Bearish Probability',
            pct(data.bearishProbability),
          ),
          metric('Primary Forecast', data.direction),
          metric('Trend', data.trend),
          metric('Momentum', data.momentum),
          metric('Setup', data.setup),
          metric(
            'Confidence',
            pct(data.confidence),
          ),
        ],
      );

    case 'Market Regime Detection':
      return ModuleShell(
        title: title,
        subtitle: 'Adaptive live market-condition classifier',
        icon: Icons.hub,
        children: [
          metric('Pair', pair),
          metric('Detected Regime', data.regime),
          metric('Trend', data.trend),
          metric('Momentum', data.momentum),
          metric('Signal Strength', data.signalStrength),
          metric('Confidence', pct(data.confidence)),
          metric(
            'Preferred Action',
            data.direction,
          ),
        ],
      );

    case 'Risk & Position Sizing':
      const account = 10000.0;
      final riskPct = data.confidence >= 85
          ? 1.0
          : data.confidence >= 70
              ? 0.5
              : 0.25;

      final maxLoss = account * (riskPct / 100.0);

      return ModuleShell(
        title: title,
        subtitle: 'Live risk and capital-protection model',
        icon: Icons.shield,
        children: [
          metric('Account Model', '\$10,000'),
          metric('Recommended Risk', '${riskPct.toStringAsFixed(2)}%'),
          metric('Maximum Planned Loss', '\$${maxLoss.toStringAsFixed(2)}'),
          metric('Entry', number(data.entry, pair)),
          metric('Stop Loss', number(data.stopLoss, pair)),
          metric(
            'Risk / Reward',
            data.riskReward == null
                ? '--'
                : '1 : ${data.riskReward!.toStringAsFixed(2)}',
          ),
          metric(
            'Risk Gate',
            data.confidence >= 70 ? 'PASS' : 'REDUCED / WAIT',
          ),
          metric('Drawdown Protection', 'ON'),
        ],
      );

    case 'Alerts & Automation':
      final qualifies = data.confidence >= 85 && (data.isBuy || data.isSell);

      return ModuleShell(
        title: title,
        subtitle: 'Live signal-monitoring and alert engine',
        icon: Icons.notifications_active,
        children: [
          metric('Pair', pair),
          metric('Current Signal', data.direction),
          metric('Confidence', pct(data.confidence)),
          metric('Minimum Alert', '85.0%'),
          metric(
            'Signal Alert',
            qualifies ? 'TRIGGER QUALIFIED' : 'MONITORING',
            color: qualifies ? Colors.greenAccent : Colors.orangeAccent,
          ),
          metric('Risk Alerts', 'ON'),
          metric('Automation Rules', 'ACTIVE'),
          metric(
            'Phone / SMS Delivery',
            'NOT CONNECTED YET',
            color: Colors.orangeAccent,
          ),
        ],
      );

    default:
      return ModuleShell(
        title: title,
        subtitle: '999 Signal Intelligence live module',
        icon: Icons.memory,
        children: [
          metric('Pair', pair),
          metric('Price', price),
          metric('Decision', data.direction),
          metric('Confidence', pct(data.confidence)),
        ],
      );
  }
}
