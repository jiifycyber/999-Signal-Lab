import 'package:flutter/material.dart';

class ChartReplayScreen extends StatefulWidget {
  final String symbol;
  final String timeframe;

  const ChartReplayScreen({
    super.key,
    required this.symbol,
    required this.timeframe,
  });

  @override
  State<ChartReplayScreen> createState() => _ChartReplayScreenState();
}

class _ChartReplayScreenState extends State<ChartReplayScreen> {
  double position = 60;
  bool playing = false;
  double speed = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: Text(
          'MARKET REPLAY • ${widget.symbol} • ${widget.timeframe}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF030B13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: .25),
                ),
              ),
              child: const Center(
                child: Text(
                  'HISTORICAL CANDLE REPLAY\n'
                  'STEP FORWARD • STEP BACK • PLAYBACK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w900,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF06121E),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => position = (position - 1).clamp(0, 100),
                  ),
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => playing = !playing),
                  icon: Icon(
                    playing ? Icons.pause_circle : Icons.play_circle,
                    color: const Color(0xFF27FF88),
                    size: 34,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => position = (position + 1).clamp(0, 100),
                  ),
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: position,
                    min: 0,
                    max: 100,
                    onChanged: (value) {
                      setState(() => position = value);
                    },
                  ),
                ),
                DropdownButton<double>(
                  value: speed,
                  dropdownColor: const Color(0xFF06121E),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: .5, child: Text('0.5x')),
                    DropdownMenuItem(value: 1, child: Text('1x')),
                    DropdownMenuItem(value: 2, child: Text('2x')),
                    DropdownMenuItem(value: 4, child: Text('4x')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => speed = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
