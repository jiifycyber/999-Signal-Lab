import 'package:flutter/material.dart';

class ChartAlertsScreen extends StatefulWidget {
  final String symbol;
  final String timeframe;
  final double price;

  const ChartAlertsScreen({
    super.key,
    required this.symbol,
    required this.timeframe,
    required this.price,
  });

  @override
  State<ChartAlertsScreen> createState() => _ChartAlertsScreenState();
}

class _ChartAlertsScreenState extends State<ChartAlertsScreen> {
  final List<String> alerts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: const Text(
          'CHART ALERT CENTER',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            alerts.add(
              '${widget.symbol} • ${widget.timeframe} • '
              '${widget.price.toStringAsFixed(5)}',
            );
          });
        },
        icon: const Icon(Icons.add_alert),
        label: const Text('CREATE ALERT'),
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Text(
                'PRICE • SIGNAL • MOMENTUM • INDICATOR ALERTS',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (_, index) => Card(
                color: const Color(0xFF06121E),
                child: ListTile(
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFFFFD23F),
                  ),
                  title: Text(
                    alerts[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() => alerts.removeAt(index));
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
