import 'package:flutter/material.dart';
import '../../ui/intelligence_theme.dart';
import '../platform_shell.dart';

class ToolsCenter extends StatelessWidget {
  final VoidCallback? onOpenAdvancedChart;
  final VoidCallback? onOpenMultiChart;
  final VoidCallback? onOpenDrawingTools;
  final VoidCallback? onOpenIndicatorCenter;
  final VoidCallback? onOpenChartAlerts;
  final VoidCallback? onOpenChartReplay;
  final VoidCallback? onOpenChartLayouts;
  final VoidCallback? onOpenLiveIntelligenceTools;
  final VoidCallback? onOpenDeepScan;
  final VoidCallback? onOpenRiskTools;
  final VoidCallback? onOpenIntelligenceCenter;

  const ToolsCenter({
    this.onOpenAdvancedChart,
    this.onOpenMultiChart,
    this.onOpenDrawingTools,
    this.onOpenIndicatorCenter,
    this.onOpenChartAlerts,
    this.onOpenChartReplay,
    this.onOpenChartLayouts,
    super.key,
    this.onOpenLiveIntelligenceTools,
    this.onOpenDeepScan,
    this.onOpenRiskTools,
    this.onOpenIntelligenceCenter,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformShell(
      title: '999 Trading Studio',
      subtitle: 'Professional trading intelligence studio',
      icon: Icons.candlestick_chart,
      children: [
        _section('999 TRADING STUDIO'),
        PlatformToolTile(
          title: 'Open 999 Trading Studio',
          description:
              'Launch the complete professional charting, technical analysis, strategy, replay, training and Duke intelligence workspace.',
          icon: Icons.candlestick_chart,
          onTap: onOpenAdvancedChart,
        ),
        _section('RISK TOOLS'),
        PlatformToolTile(
          title: 'Risk Manager',
          description: 'Account and trading risk controls.',
          icon: Icons.shield,
          onTap: onOpenRiskTools,
        ),
        PlatformToolTile(
          title: 'Position Calculator',
          description: 'Calculate position and risk sizing.',
          icon: Icons.calculate,
          onTap: onOpenRiskTools,
        ),
        PlatformToolTile(
          title: 'Drawdown Monitor',
          description: 'Track account and strategy drawdown.',
          icon: Icons.trending_down,
          onTap: onOpenRiskTools,
        ),
        _section('INTELLIGENT TOOLS'),
        PlatformToolTile(
          title: 'AI Learning Center',
          description: 'Analyze what the scanner learns from outcomes.',
          icon: Icons.memory,
          onTap: onOpenLiveIntelligenceTools,
        ),
        PlatformToolTile(
          title: 'Pair Analyzer',
          description:
              'Deep intelligence analysis for individual trading pairs.',
          icon: Icons.currency_exchange,
          onTap: onOpenDeepScan,
        ),
        PlatformToolTile(
          title: 'Session Analyzer',
          description: 'Analyze performance by market session.',
          icon: Icons.public,
          onTap: onOpenIntelligenceCenter,
        ),
        PlatformToolTile(
          title: 'Signal Quality Analyzer',
          description: 'Measure signal strength against real outcomes.',
          icon: Icons.verified,
          onTap: onOpenIntelligenceCenter,
        ),
        PlatformToolTile(
          title: 'Scanner Diagnostics',
          description: 'Scanner engine, bridge, feed and latency health.',
          icon: Icons.monitor_heart,
          onTap: onOpenIntelligenceCenter,
        ),
      ],
    );
  }

  static Widget _section(String title) {
    return IntelligenceSectionTitle(title);
  }
}
