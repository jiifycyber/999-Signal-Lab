import 'package:flutter/material.dart';

class IndicatorCenterScreen extends StatefulWidget {
  const IndicatorCenterScreen({super.key});

  @override
  State<IndicatorCenterScreen> createState() => _IndicatorCenterScreenState();
}

class _IndicatorCenterScreenState extends State<IndicatorCenterScreen> {
  static const bg = Color(0xFF020811);
  static const panel = Color(0xFF06121E);
  static const cyan = Color(0xFF00E5FF);
  static const purple = Color(0xFFB388FF);

  String search = '';

  final Set<String> favorites = {};

  static const indicators = [
    'Moving Average',
    'Exponential Moving Average',
    'Weighted Moving Average',
    'Hull Moving Average',
    'Bollinger Bands',
    'Donchian Channels',
    'Keltner Channels',
    'Relative Strength Index',
    'MACD',
    'Stochastic Oscillator',
    'Stochastic RSI',
    'Average True Range',
    'ADX / DMI',
    'Commodity Channel Index',
    'Williams %R',
    'Momentum',
    'Rate of Change',
    'Awesome Oscillator',
    'Money Flow Index',
    'On Balance Volume',
    'VWAP',
    'Parabolic SAR',
    'Ichimoku Cloud',
    'Williams Alligator',
    'Supertrend',
    'Fractals',
    'Pivot Points',
    'ZigZag',
  ];

  @override
  Widget build(BuildContext context) {
    final results = indicators
        .where(
          (item) => item.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: const Text(
          'INDICATOR CENTER',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => search = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: cyan),
                hintText: 'Search technical indicators',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: panel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _preset('SCALPING', 'EMA 9/21 • RSI • MACD'),
                _preset('MOMENTUM', 'RSI • MACD • ADX'),
                _preset('TREND', 'EMA • ADX • SUPERTREND'),
                _preset('VOLATILITY', 'ATR • BB • KELTNER'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 330,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: results.length,
                itemBuilder: (_, index) {
                  final item = results[index];
                  final favorite = favorites.contains(item);

                  return Container(
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cyan.withValues(alpha: .18),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            if (favorite) {
                              favorites.remove(item);
                            } else {
                              favorites.add(item);
                            }
                          });
                        },
                        icon: Icon(
                          favorite ? Icons.star : Icons.star_border,
                          color: favorite ? purple : Colors.white38,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preset(String title, String description) {
    return Expanded(
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: purple.withValues(alpha: .24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: purple,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
