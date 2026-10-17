import 'package:flutter/material.dart';
import '../platform_shell.dart';

class AnalyticsCenter extends StatelessWidget {
  const AnalyticsCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      title: 'Analytics',
      subtitle: 'Scanner performance intelligence',
      icon: Icons.analytics,
      children: [
        PlatformToolTile(
          title: 'Overall Performance',
          description: 'Total signals, wins, losses and accuracy.',
          icon: Icons.insights,
        ),
        PlatformToolTile(
          title: 'Pair Performance',
          description: 'Accuracy and performance by trading pair.',
          icon: Icons.compare_arrows,
        ),
        PlatformToolTile(
          title: 'Session Performance',
          description: 'Compare results across trading sessions.',
          icon: Icons.schedule,
        ),
        PlatformToolTile(
          title: 'Confidence Accuracy',
          description: 'Measure whether confidence predicts outcomes.',
          icon: Icons.speed,
        ),
        PlatformToolTile(
          title: 'BUY vs SELL',
          description: 'Compare directional signal performance.',
          icon: Icons.swap_vert,
        ),
        PlatformToolTile(
          title: 'Streaks & Drawdown',
          description: 'Winning streaks, losing streaks and drawdown.',
          icon: Icons.waterfall_chart,
        ),
        PlatformToolTile(
          title: 'Reports',
          description: 'Daily, weekly and monthly scanner reporting.',
          icon: Icons.assessment,
        ),
      ],
    );
  }
}
