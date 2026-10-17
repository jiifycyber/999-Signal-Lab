import 'package:flutter/material.dart';
import 'module_context.dart';
import 'module_shell.dart';

Widget metric(String name, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(color: Colors.white70)),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget buildIntelligenceModule(String title, ModuleContext data) {
  final pair = data.pair;
  final tf = data.timeframe;
  final price = data.price?.toStringAsFixed(5) ?? 'Loading';

  switch (title) {
    case 'AI Opportunity Scan':
      return ModuleShell(
        title: title,
        subtitle: 'Probability and opportunity intelligence',
        icon: Icons.auto_awesome,
        children: [
          metric('Pair', pair),
          metric('Timeframe', tf),
          metric('Current Price', price),
          metric('Signal Fusion', 'ACTIVE'),
          metric('Probability Engine', 'ACTIVE'),
          metric('Setup Ranking', 'ENABLED'),
        ],
      );

    case 'Multi-Timeframe Alignment':
      return ModuleShell(
        title: title,
        subtitle: 'Cross-timeframe trend confirmation',
        icon: Icons.timeline,
        children: [
          metric('M1 Structure', 'MONITORING'),
          metric('M5 Structure', 'MONITORING'),
          metric('M15 Structure', 'MONITORING'),
          metric('H1 Structure', 'MONITORING'),
          metric('Selected', tf),
        ],
      );

    case 'Order Flow & Liquidity':
      return ModuleShell(
        title: title,
        subtitle: 'Liquidity, imbalance and order-flow analysis',
        icon: Icons.waterfall_chart,
        children: [
          metric('Liquidity Sweep', 'SCANNING'),
          metric('Order Imbalance', 'SCANNING'),
          metric('Supply / Demand', 'ACTIVE'),
          metric('Institutional Footprint', 'ACTIVE'),
        ],
      );

    case 'Sentiment Engine':
      return ModuleShell(
        title: title,
        subtitle: 'Market sentiment intelligence',
        icon: Icons.psychology,
        children: [
          metric('Directional Bias', 'CALCULATING'),
          metric('Risk Sentiment', 'MONITORING'),
          metric('Momentum Sentiment', 'ACTIVE'),
          metric('Consensus Engine', 'ACTIVE'),
        ],
      );

    case 'Macro & Fundamental':
      return ModuleShell(
        title: title,
        subtitle: 'Fundamental and macro environment',
        icon: Icons.public,
        children: [
          metric('Macro Bias', 'MONITORING'),
          metric('Central Bank Risk', 'MONITORING'),
          metric('Event Risk', 'MONITORING'),
          metric('Pair', pair),
        ],
      );

    case 'Volatility & Risk':
      return ModuleShell(
        title: title,
        subtitle: 'Volatility and risk intelligence',
        icon: Icons.speed,
        children: [
          metric('Volatility Regime', 'CALCULATING'),
          metric('Risk State', 'MONITORING'),
          metric('Position Risk', 'CONTROLLED'),
          metric('Adaptive Risk', 'ACTIVE'),
        ],
      );

    case 'Trade Automation':
      return ModuleShell(
        title: title,
        subtitle: 'Trade execution readiness',
        icon: Icons.smart_toy,
        children: [
          metric('Trade Gate', 'MANUAL'),
          metric('Signal Confirmation', 'REQUIRED'),
          metric('Risk Check', 'ACTIVE'),
          metric('Execution', 'LOCKED'),
        ],
      );

    case 'Market Heatmap':
      return ModuleShell(
        title: title,
        subtitle: 'Relative market strength',
        icon: Icons.grid_view,
        children: [
          metric('USD', 'SCANNING'),
          metric('EUR', 'SCANNING'),
          metric('GBP', 'SCANNING'),
          metric('JPY', 'SCANNING'),
          metric('Strength Matrix', 'ACTIVE'),
        ],
      );

    case 'Global Sessions':
      return ModuleShell(
        title: title,
        subtitle: 'Global trading-session intelligence',
        icon: Icons.language,
        children: [
          metric('Sydney', 'MONITORING'),
          metric('Tokyo', 'MONITORING'),
          metric('London', 'MONITORING'),
          metric('New York', 'MONITORING'),
        ],
      );

    case 'News & Macro Impact':
      return ModuleShell(
        title: title,
        subtitle: 'Economic-event risk analysis',
        icon: Icons.newspaper,
        children: [
          metric('News Risk', 'MONITORING'),
          metric('High Impact Events', 'WATCHING'),
          metric('Currency Exposure', pair),
          metric('Protection Engine', 'ACTIVE'),
        ],
      );

    case 'Pair Deep Scanner':
      return ModuleShell(
        title: title,
        subtitle: 'Deep intelligence for $pair',
        icon: Icons.manage_search,
        children: [
          metric('Pair', pair),
          metric('Timeframe', tf),
          metric('Price', price),
          metric('Structure', 'SCANNING'),
          metric('Momentum', 'SCANNING'),
          metric('Liquidity', 'SCANNING'),
        ],
      );

    case 'Trade Plan AI':
      return ModuleShell(
        title: title,
        subtitle: 'Structured trade-planning assistant',
        icon: Icons.assignment,
        children: [
          metric('Instrument', pair),
          metric('Current Price', price),
          metric('Bias', 'CALCULATING'),
          metric('Entry Model', 'ANALYZING'),
          metric('Risk Model', 'ACTIVE'),
          metric('Trade Status', 'WAIT'),
        ],
      );

    case 'Smart Money Tracker':
      return ModuleShell(
        title: title,
        subtitle: 'Institutional activity intelligence',
        icon: Icons.account_balance,
        children: [
          metric('Liquidity Zones', 'TRACKING'),
          metric('Order Blocks', 'TRACKING'),
          metric('Structure Shift', 'MONITORING'),
          metric('Institutional Bias', 'CALCULATING'),
        ],
      );

    case 'AI Prediction Engine':
      return ModuleShell(
        title: title,
        subtitle: 'Probabilistic directional forecasting',
        icon: Icons.insights,
        children: [
          metric('Pair', pair),
          metric('Forecast Horizon', tf),
          metric('Bullish Probability', 'CALCULATING'),
          metric('Bearish Probability', 'CALCULATING'),
          metric('Confidence Model', 'ACTIVE'),
        ],
      );

    case 'Market Regime Detection':
      return ModuleShell(
        title: title,
        subtitle: 'Adaptive market-condition classifier',
        icon: Icons.hub,
        children: [
          metric('Trend Regime', 'DETECTING'),
          metric('Volatility Regime', 'DETECTING'),
          metric('Liquidity Regime', 'DETECTING'),
          metric('Adaptive Model', 'ACTIVE'),
        ],
      );

    case 'Risk & Position Sizing':
      return ModuleShell(
        title: title,
        subtitle: 'Position sizing and capital protection',
        icon: Icons.shield,
        children: [
          metric('Account Risk', '1.00%'),
          metric('Position Model', 'ACTIVE'),
          metric('Drawdown Protection', 'ON'),
          metric('Risk Gate', 'ENABLED'),
        ],
      );

    case 'Alerts & Automation':
      return ModuleShell(
        title: title,
        subtitle: 'Signal monitoring and automation center',
        icon: Icons.notifications_active,
        children: [
          metric('Signal Alerts', 'ON'),
          metric('Price Alerts', 'READY'),
          metric('Risk Alerts', 'ON'),
          metric('Automation Rules', 'READY'),
          metric('Notification Engine', 'ACTIVE'),
        ],
      );

    default:
      return ModuleShell(
        title: title,
        subtitle: '999 Signal Intelligence module',
        icon: Icons.memory,
        children: [
          metric('Module', 'ACTIVE'),
          metric('Pair', pair),
          metric('Timeframe', tf),
        ],
      );
  }
}
