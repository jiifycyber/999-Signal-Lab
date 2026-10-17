import 'package:flutter/material.dart';

class TradingModulePanel extends StatelessWidget {
  final String title;
  final String pair;
  final String price;
  final String direction;
  final double confidence;
  final String trend;
  final String momentum;
  final String setup;
  final String entry;
  final String stopLoss;
  final String tp1;
  final String tp2;
  final String tp3;

  const TradingModulePanel({
    super.key,
    required this.title,
    required this.pair,
    required this.price,
    required this.direction,
    required this.confidence,
    required this.trend,
    required this.momentum,
    required this.setup,
    required this.entry,
    required this.stopLoss,
    required this.tp1,
    required this.tp2,
    required this.tp3,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF07131F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: .55),
          ),
        ),
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _marketSummary(),
                    const SizedBox(height: 14),
                    ..._moduleContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1B29),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: Color(0xFF00E5FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const Text(
                  '999 SIGNAL INTELLIGENCE • LIVE MODULE',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _marketSummary() {
    return _card(
      'LIVE MARKET CONTEXT',
      Column(
        children: [
          Row(
            children: [
              Expanded(child: _metric('PAIR', pair, Colors.white)),
              Expanded(child: _metric('PRICE', price, const Color(0xFF00E5FF))),
              Expanded(
                child: _metric(
                  'SIGNAL',
                  direction,
                  direction == 'BUY'
                      ? const Color(0xFF00E676)
                      : direction == 'SELL'
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFC857),
                ),
              ),
              Expanded(
                child: _metric(
                  'CONFIDENCE',
                  '${confidence.toStringAsFixed(1)}%',
                  const Color(0xFFB388FF),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF25445A)),
          _row('Trend', trend),
          _row('Momentum', momentum),
          _row('Setup', setup),
        ],
      ),
    );
  }

  List<Widget> _moduleContent() {
    switch (title) {
      case 'AI Opportunity Scan':
        return [
          _card(
            'OPPORTUNITY ENGINE',
            Column(
              children: [
                _row('Current setup', setup),
                _row('Directional bias', direction),
                _row('Probability score', '${confidence.toStringAsFixed(1)}%'),
                _row(
                  'Qualification',
                  confidence >= 85 ? 'HIGH PRIORITY' : 'MONITOR',
                ),
              ],
            ),
          ),
        ];

      case 'Multi-Timeframe Alignment':
        return [
          _card(
            'TIMEFRAME ALIGNMENT',
            Column(
              children: [
                _timeframe('1M', confidence - 8),
                _timeframe('5M', confidence - 4),
                _timeframe('15M', confidence),
                _timeframe('1H', confidence + 2),
                _timeframe('4H', confidence + 3),
              ],
            ),
          ),
        ];

      case 'Order Flow & Liquidity':
        return [
          _card(
            'ORDER FLOW',
            Column(
              children: [
                _row('Directional pressure', direction),
                _row('Liquidity condition', _strengthLabel(confidence)),
                _row('Structure', setup),
                _row('Momentum confirmation', momentum),
              ],
            ),
          ),
        ];

      case 'Sentiment Engine':
        return [
          _card(
            'MARKET SENTIMENT',
            Column(
              children: [
                _row('Technical sentiment', direction),
                _row('Trend sentiment', trend),
                _row('Momentum sentiment', momentum),
                _row(
                  'Composite bias',
                  confidence >= 70 ? direction : 'MIXED / WAIT',
                ),
              ],
            ),
          ),
        ];

      case 'Macro & Fundamental':
        return [
          _card(
            'MACRO / FUNDAMENTAL',
            Column(
              children: [
                _row('Pair under analysis', pair),
                _row('Technical bias', direction),
                _row('Macro feed', 'READY FOR NEWS API'),
                _row('Economic calendar', 'READY FOR CALENDAR FEED'),
              ],
            ),
          ),
        ];

      case 'Volatility & Risk':
        return [
          _card(
            'VOLATILITY & RISK',
            Column(
              children: [
                _row('Signal confidence', '${confidence.toStringAsFixed(1)}%'),
                _row('Volatility classification', _volatilityLabel(confidence)),
                _row('Current setup', setup),
                _row('Risk state', confidence >= 80 ? 'CONTROLLED' : 'CAUTION'),
              ],
            ),
          ),
        ];

      case 'Trade Automation':
        return [
          _card(
            'AUTOMATION CONTROL',
            Column(
              children: [
                _row('Signal source', 'Agent Duke + Scanner'),
                _row('Current decision', direction),
                _row('Auto execution', 'OFF — SAFETY LOCK'),
                _row('Broker connection', 'NOT CONNECTED'),
              ],
            ),
          ),
        ];

      case 'Market Heatmap':
        return [
          _card(
            'HEATMAP INTELLIGENCE',
            Column(
              children: [
                _row('Selected pair', pair),
                _row('Directional strength', _strengthLabel(confidence)),
                _row('Trend state', trend),
                _row('Momentum state', momentum),
              ],
            ),
          ),
        ];

      case 'Global Sessions':
        return [
          _card(
            'SESSION ANALYSIS',
            Column(
              children: [
                _row('Pair', pair),
                _row('Current scanner bias', direction),
                _row('Trend', trend),
                _row('Session engine', 'LIVE MARKET FEED CONNECTED'),
              ],
            ),
          ),
        ];

      case 'News & Macro Impact':
        return [
          _card(
            'NEWS IMPACT',
            Column(
              children: [
                _row('Current pair', pair),
                _row('Signal before news filter', direction),
                _row('Calendar integration', 'READY FOR LIVE NEWS FEED'),
                _row('High-impact protection', 'MODULE READY'),
              ],
            ),
          ),
        ];

      case 'Pair Deep Scanner':
        return [
          _card(
            'PAIR DEEP SCAN',
            Column(
              children: [
                _row('Pair', pair),
                _row('Price', price),
                _row('Direction', direction),
                _row('Trend', trend),
                _row('Momentum', momentum),
                _row('Setup', setup),
                _row('Confidence', '${confidence.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ];

      case 'Trade Plan AI':
        return [
          _card(
            'TRADE PLAN',
            Column(
              children: [
                _row('Direction', direction),
                _row('Entry', entry),
                _row('Stop Loss', stopLoss),
                _row('TP1', tp1),
                _row('TP2', tp2),
                _row('TP3', tp3),
                _row('Setup', setup),
              ],
            ),
          ),
        ];

      case 'Smart Money Tracker':
        return [
          _card(
            'SMART MONEY',
            Column(
              children: [
                _row('Structure', setup),
                _row('Trend', trend),
                _row('Momentum', momentum),
                _row(
                  'Institutional bias',
                  confidence >= 80 ? direction : 'UNCONFIRMED',
                ),
              ],
            ),
          ),
        ];

      case 'AI Prediction Engine':
        return [
          _card(
            'PREDICTION ENGINE',
            Column(
              children: [
                _row('Current direction', direction),
                _row('Probability', '${confidence.toStringAsFixed(1)}%'),
                _row('Trend input', trend),
                _row('Momentum input', momentum),
                _row('Setup input', setup),
              ],
            ),
          ),
        ];

      case 'Market Regime Detection':
        return [
          _card(
            'MARKET REGIME',
            Column(
              children: [
                _row('Trend state', trend),
                _row('Momentum state', momentum),
                _row(
                  'Detected regime',
                  confidence >= 80 ? 'TRENDING' : 'TRANSITION / RANGE',
                ),
                _row('Preferred action', direction),
              ],
            ),
          ),
        ];

      case 'Risk & Position Sizing':
        return [
          _card(
            'RISK ENGINE',
            Column(
              children: [
                _row('Confidence', '${confidence.toStringAsFixed(1)}%'),
                _row('Entry', entry),
                _row('Stop', stopLoss),
                _row('Target 1', tp1),
                _row(
                  'Risk recommendation',
                  confidence >= 85 ? 'STANDARD RISK' : 'REDUCED RISK',
                ),
              ],
            ),
          ),
        ];

      case 'Alerts & Automation':
        return [
          _card(
            'ALERT RULES',
            Column(
              children: [
                _toggleRow('BUY / SELL signal alerts', true),
                _toggleRow('High-confidence alerts', true),
                _toggleRow('Duke trade-approved alerts', true),
                _toggleRow('Volatility warnings', true),
                _toggleRow('News-impact warnings', false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            'CURRENT ALERT CONTEXT',
            Column(
              children: [
                _row('Pair', pair),
                _row('Current decision', direction),
                _row('Confidence', '${confidence.toStringAsFixed(1)}%'),
                _row(
                  'Alert status',
                  confidence >= 85 ? 'HIGH PRIORITY' : 'MONITORING',
                ),
              ],
            ),
          ),
        ];

      default:
        return [
          _card(
            title,
            const Text(
              'Module ready.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ];
    }
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1B29),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF25445A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7DDFFF),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF78909C),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF90A4AE)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeframe(String timeframe, double value) {
    final score = value.clamp(0.0, 100.0);
    return _row(
      timeframe,
      '${score.toStringAsFixed(1)}% • ${score >= 70 ? direction : 'WAIT'}',
    );
  }

  Widget _toggleRow(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.notifications_active : Icons.notifications_none,
            color: enabled ? const Color(0xFF00E676) : const Color(0xFF78909C),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            enabled ? 'ON' : 'OFF',
            style: TextStyle(
              color:
                  enabled ? const Color(0xFF00E676) : const Color(0xFFFFC857),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _strengthLabel(double value) {
    if (value >= 90) return 'EXTREME';
    if (value >= 80) return 'STRONG';
    if (value >= 65) return 'MODERATE';
    return 'WEAK';
  }

  String _volatilityLabel(double value) {
    if (value >= 90) return 'HIGH';
    if (value >= 75) return 'NORMAL / ACTIVE';
    return 'LOW / QUIET';
  }
}
