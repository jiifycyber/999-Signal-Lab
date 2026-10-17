import 'package:flutter/material.dart';
import '../platform_shell.dart';

class ToolsCenter extends StatelessWidget {
  const ToolsCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformShell(
      title: '999 Trading Tools',
      subtitle: 'Professional trading intelligence toolbox',
      icon: Icons.build_circle,
      children: [
        _section('ADVANCED CHARTING'),
        const PlatformToolTile(
          title: 'Advanced Chart',
          description: 'TradingView-style professional chart workspace.',
          icon: Icons.candlestick_chart,
        ),
        const PlatformToolTile(
          title: 'Multi-Chart View',
          description: 'Monitor multiple pairs simultaneously.',
          icon: Icons.grid_view,
        ),
        const PlatformToolTile(
          title: 'Drawing Tools',
          description: 'Trendlines, levels, Fibonacci and annotations.',
          icon: Icons.draw,
        ),
        const PlatformToolTile(
          title: 'Indicators',
          description: 'Technical indicators and overlays.',
          icon: Icons.query_stats,
        ),
        _section('SMART TECHNICAL ANALYSIS'),
        const PlatformToolTile(
          title: 'Auto Trendlines',
          description: 'TrendSpider-style automated trend detection.',
          icon: Icons.trending_up,
        ),
        const PlatformToolTile(
          title: 'Auto Support / Resistance',
          description: 'Automatically identify important price levels.',
          icon: Icons.horizontal_rule,
        ),
        const PlatformToolTile(
          title: 'Pattern Scanner',
          description: 'Detect technical price patterns automatically.',
          icon: Icons.polyline,
        ),
        const PlatformToolTile(
          title: 'Breakout Detector',
          description: 'Find developing and confirmed breakouts.',
          icon: Icons.open_in_full,
        ),
        const PlatformToolTile(
          title: 'Multi-Timeframe Confirmation',
          description: 'Confirm setups across multiple timeframes.',
          icon: Icons.layers,
        ),
        _section('STRATEGY & TESTING'),
        const PlatformToolTile(
          title: 'Backtester',
          description: 'Test scanner logic against historical data.',
          icon: Icons.science,
        ),
        const PlatformToolTile(
          title: 'Strategy Lab',
          description: 'Compare strategies without changing the live engine.',
          icon: Icons.biotech,
        ),
        const PlatformToolTile(
          title: 'Trade Replay',
          description: 'Replay historical markets candle-by-candle.',
          icon: Icons.replay,
        ),
        _section('TRAINING CENTER'),
        const PlatformToolTile(
          title: 'Training Mode',
          description: 'Practice BUY, SELL and NO TRADE decisions.',
          icon: Icons.school,
        ),
        const PlatformToolTile(
          title: 'Duke Coach',
          description: 'AI-guided explanations and trade education.',
          icon: Icons.psychology,
        ),
        const PlatformToolTile(
          title: 'Pattern Training',
          description: 'Practice recognizing market structures.',
          icon: Icons.auto_graph,
        ),
        const PlatformToolTile(
          title: 'Progress Tracker',
          description: 'Track training scores and improvement.',
          icon: Icons.workspace_premium,
        ),
        _section('RISK TOOLS'),
        const PlatformToolTile(
          title: 'Risk Manager',
          description: 'Account and trading risk controls.',
          icon: Icons.shield,
        ),
        const PlatformToolTile(
          title: 'Position Calculator',
          description: 'Calculate position and risk sizing.',
          icon: Icons.calculate,
        ),
        const PlatformToolTile(
          title: 'Drawdown Monitor',
          description: 'Track account and strategy drawdown.',
          icon: Icons.trending_down,
        ),
        _section('INTELLIGENCE TOOLS'),
        const PlatformToolTile(
          title: 'AI Learning Center',
          description: 'Analyze what the scanner learns from outcomes.',
          icon: Icons.memory,
        ),
        const PlatformToolTile(
          title: 'Pair Analyzer',
          description: 'Deep analysis for individual trading pairs.',
          icon: Icons.currency_exchange,
        ),
        const PlatformToolTile(
          title: 'Session Analyzer',
          description: 'Analyze performance by market session.',
          icon: Icons.public,
        ),
        const PlatformToolTile(
          title: 'Signal Quality Analyzer',
          description: 'Measure signal strength against real outcomes.',
          icon: Icons.verified,
        ),
        const PlatformToolTile(
          title: 'Scanner Diagnostics',
          description: 'Scanner engine, bridge, feed and latency health.',
          icon: Icons.monitor_heart,
        ),
      ],
    );
  }

  static Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF13D8FF),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
