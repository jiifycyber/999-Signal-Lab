import 'package:flutter/material.dart';

class ChartLayoutsScreen extends StatefulWidget {
  const ChartLayoutsScreen({super.key});

  @override
  State<ChartLayoutsScreen> createState() => _ChartLayoutsScreenState();
}

class _ChartLayoutsScreenState extends State<ChartLayoutsScreen> {
  String selected = 'Professional';

  static const layouts = [
    'Professional',
    'Chart Only',
    'Chart + Volume',
    'Chart + Indicators',
    'Scalping',
    'Momentum',
    'Trend Analysis',
    'Four Chart',
    'Full Intelligence',
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
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350,
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: layouts.length,
        itemBuilder: (_, index) {
          final name = layouts[index];
          final active = name == selected;

          return InkWell(
            onTap: () => setState(() => selected = name),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF06121E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? const Color(0xFF00E5FF) : Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dashboard_customize,
                        color:
                            active ? const Color(0xFF00E5FF) : Colors.white38,
                      ),
                      const Spacer(),
                      if (active)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF27FF88),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Professional chart workspace preset',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
