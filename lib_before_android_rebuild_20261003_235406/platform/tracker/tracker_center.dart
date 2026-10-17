import 'package:flutter/material.dart';
import '../platform_shell.dart';

class TrackerCenter extends StatelessWidget {
  const TrackerCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformShell(
      title: 'Tracker',
      subtitle: 'Automatic signal and trade journal',
      icon: Icons.receipt_long,
      children: [
        PlatformToolTile(
          title: 'Signal Journal',
          description: 'Record every scanner-generated signal.',
          icon: Icons.history,
        ),
        PlatformToolTile(
          title: 'Trade Outcomes',
          description: 'Track wins, losses and expiration results.',
          icon: Icons.fact_check,
        ),
        PlatformToolTile(
          title: 'Entry History',
          description: 'Entry time, price, pair and direction.',
          icon: Icons.login,
        ),
        PlatformToolTile(
          title: 'Signal Notes',
          description: 'Store observations and market conditions.',
          icon: Icons.notes,
        ),
        PlatformToolTile(
          title: 'Search & Filters',
          description: 'Find trades by pair, date or outcome.',
          icon: Icons.manage_search,
        ),
      ],
    );
  }
}
