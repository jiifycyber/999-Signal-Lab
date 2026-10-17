import 'package:flutter/material.dart';

import 'models/scan_signal.dart';
import 'services/scanner_controller.dart';

class ScannerTestPage extends StatefulWidget {
  const ScannerTestPage({super.key});

  @override
  State<ScannerTestPage> createState() => _ScannerTestPageState();
}

class _ScannerTestPageState extends State<ScannerTestPage> {
  late final ScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = ScannerController();
    controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Color signalColor(TradeDirection direction) {
    switch (direction) {
      case TradeDirection.buy:
        return Colors.greenAccent;
      case TradeDirection.sell:
        return Colors.redAccent;
      case TradeDirection.wait:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09121C),
        title: const Text(
          'NEXUS SCANNER ENGINE TEST',
        ),
      ),
      body: StreamBuilder<List<ScanSignal>>(
        stream: controller.signalStream,
        builder: (context, snapshot) {
          final signals = snapshot.data ?? [];

          if (signals.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: signals.length,
            itemBuilder: (context, index) {
              final signal = signals[index];
              final color = signalColor(signal.direction);

              return Card(
                color: const Color(0xFF0B1622),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '#${index + 1}  ${signal.symbol}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          signal.directionText,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${signal.confidence.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          signal.trend,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          signal.entry.toStringAsFixed(
                            signal.symbol.contains('JPY') ? 3 : 5,
                          ),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                    ],
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
