import 'package:flutter/material.dart';

class ChartLayoutsScreen extends StatelessWidget {
  const ChartLayoutsScreen({super.key});

  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF27FF88);
  static const purple = Color(0xFFB388FF);
  static const amber = Color(0xFFFFC857);

  static const layouts = <_LayoutPreset>[
    _LayoutPreset(
      id: 'professional',
      title: 'Professional',
      subtitle: 'Full professional chart workspace.',
      icon: Icons.workspace_premium_outlined,
      color: cyan,
    ),
    _LayoutPreset(
      id: 'chart_only',
      title: 'Chart Only',
      subtitle: 'Maximum chart workspace.',
      icon: Icons.candlestick_chart,
      color: green,
    ),
    _LayoutPreset(
      id: 'chart_volume',
      title: 'Chart + Volume',
      subtitle: 'Live chart with market activity.',
      icon: Icons.bar_chart,
      color: amber,
    ),
    _LayoutPreset(
      id: 'chart_indicators',
      title: 'Chart + Indicators',
      subtitle: 'Technical indicator workspace.',
      icon: Icons.query_stats,
      color: purple,
    ),
    _LayoutPreset(
      id: 'scalping',
      title: 'Scalping',
      subtitle: 'Fast M1-focused trading workspace.',
      icon: Icons.bolt,
      color: amber,
    ),
    _LayoutPreset(
      id: 'momentum',
      title: 'Momentum',
      subtitle: 'Momentum and scanner workspace.',
      icon: Icons.speed,
      color: purple,
    ),
    _LayoutPreset(
      id: 'trend',
      title: 'Trend Analysis',
      subtitle: 'Trend and market-structure workspace.',
      icon: Icons.trending_up,
      color: cyan,
    ),
    _LayoutPreset(
      id: 'four_chart',
      title: 'Four Chart',
      subtitle: 'Four simultaneous live markets.',
      icon: Icons.grid_view_rounded,
      color: green,
    ),
    _LayoutPreset(
      id: 'full_intelligence',
      title: 'Full Intelligence',
      subtitle: 'Chart, volume, scanner and Duke workspace.',
      icon: Icons.psychology_alt_outlined,
      color: cyan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: const Text(
          'TRADINGVIEW LAYOUTS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1050
              ? 4
              : constraints.maxWidth >= 700
                  ? 3
                  : 2;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: layouts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              final preset = layouts[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop(preset.id);
                  },
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: preset.color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07131E),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: preset.color.withValues(alpha: .30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          preset.icon,
                          color: preset.color,
                          size: 25,
                        ),
                        const Spacer(),
                        Text(
                          preset.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.subtitle,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'OPEN WORKSPACE',
                              style: TextStyle(
                                color: preset.color,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: preset.color,
                              size: 11,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LayoutPreset {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _LayoutPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
