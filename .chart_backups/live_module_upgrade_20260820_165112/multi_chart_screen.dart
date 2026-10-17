import 'package:flutter/material.dart';

class MultiChartScreen extends StatefulWidget {
  final String initialSymbol;
  final String initialTimeframe;

  const MultiChartScreen({
    super.key,
    required this.initialSymbol,
    required this.initialTimeframe,
  });

  @override
  State<MultiChartScreen> createState() => _MultiChartScreenState();
}

class _MultiChartScreenState extends State<MultiChartScreen> {
  static const bg = Color(0xFF020811);
  static const panel = Color(0xFF06121E);
  static const cyan = Color(0xFF00E5FF);
  static const purple = Color(0xFFB388FF);

  int layout = 4;

  late final List<String> symbols = [
    widget.initialSymbol,
    'GBPUSD',
    'USDJPY',
    'AUDUSD',
  ];

  static const availablePairs = [
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'USDCHF',
    'USDCAD',
    'AUDUSD',
    'NZDUSD',
    'EURGBP',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: const Text(
          'MULTI-CHART VIEW',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          _layoutButton(1),
          _layoutButton(2),
          _layoutButton(4),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: layout == 1
            ? _chartCard(0)
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.55,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: layout,
                itemBuilder: (_, index) => _chartCard(index),
              ),
      ),
    );
  }

  Widget _layoutButton(int count) {
    return TextButton(
      onPressed: () => setState(() => layout = count),
      child: Text(
        '${count}X',
        style: TextStyle(
          color: layout == count ? cyan : Colors.white54,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _chartCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cyan.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: symbols[index],
                  dropdownColor: panel,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.w900,
                  ),
                  items: availablePairs
                      .map(
                        (pair) => DropdownMenuItem(
                          value: pair,
                          child: Text(pair),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => symbols[index] = value);
                    }
                  },
                ),
                const Spacer(),
                Text(
                  widget.initialTimeframe,
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: const _GridPainter(),
              child: Center(
                child: Text(
                  '${symbols[index]} LIVE CHART',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = 1;

    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 1; i < 7; i++) {
      final y = size.height * i / 7;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
