import 'package:flutter/material.dart';

import 'agent_duke_master_engine.dart';

class AgentDukeCommandCenter extends StatelessWidget {
  final String selectedPair;
  final DukeMasterResult? result;
  final VoidCallback? onDeepScan;
  final VoidCallback? onWatchlist;

  const AgentDukeCommandCenter({
    super.key,
    required this.selectedPair,
    required this.result,
    this.onDeepScan,
    this.onWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    final decision =
        r?.decision.toString().split('.').last.toUpperCase() ?? 'ANALYZING';
    final confidence = r?.confidence ?? 0;
    final quality = r?.qualityScore ?? 0;
    final approved = r?.tradeApproved ?? false;

    return Container(
      width: 330,
      height: 682,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07131F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: .55),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: .10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10293D),
                  border: Border.all(color: const Color(0xFFFFC857)),
                ),
                child: const Text(
                  'D',
                  style: TextStyle(
                    color: Color(0xFFFFC857),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AGENT DUKE DA BOSS X',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'AI COMMAND CENTER • ONLINE',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: 'PAIR DEEP SCANNER',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedPair,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  r == null
                      ? 'Duke is reading live scanner data...'
                      : 'Live intelligence synchronized',
                  style: const TextStyle(
                    color: Color(0xFF8FA9BB),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'DECISION',
                  decision,
                  approved ? const Color(0xFF00E676) : const Color(0xFFFFC857),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _metric(
                  'CONFIDENCE',
                  '${confidence.toStringAsFixed(1)}%',
                  const Color(0xFF00E5FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'QUALITY',
                  quality.toStringAsFixed(1),
                  const Color(0xFFB388FF),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _metric(
                  'TRADE GATE',
                  approved ? 'APPROVED' : 'HOLD',
                  approved ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _section(
            title: 'DUKE INTELLIGENCE',
            child: Text(
              r?.explanation ??
                  'Waiting for the next qualified scanner signal. Duke is monitoring trend, momentum, structure and signal quality.',
              style: const TextStyle(
                color: Color(0xFFD7E5EE),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 9),
          _section(
            title: 'AI STATUS',
            child: Column(
              children: [
                _status('Live Scanner Feed', true),
                _status('Signal Fusion', r != null),
                _status('Trade Gate', approved),
                _status('Adaptive Intelligence', true),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _button(
                  'DEEP SCAN',
                  Icons.radar,
                  onDeepScan,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _button(
                  'WATCHLIST',
                  Icons.star_border,
                  onWatchlist,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1B29),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF25445A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7DDFFF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }

  Widget _metric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1B29),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF78909C),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: active ? const Color(0xFF00E676) : const Color(0xFF607D8B),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD7E5EE),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(
    String text,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF10293D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: .45),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: const Color(0xFF00E5FF),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
