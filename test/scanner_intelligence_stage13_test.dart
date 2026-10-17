import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_fx_scanner_flutter_twin/models/forex_quote.dart';
import 'package:nexus_fx_scanner_flutter_twin/services/scanner_engine.dart';

void main() {
  test('999 Scanner intelligence integration', () {
    final engine = ScannerEngine();
    final start = DateTime.utc(2026, 1, 1, 12, 0, 0);

    for (var i = 0; i < 12; i++) {
      final price = 1.1000 + (i * 0.0001);
      final quote = ForexQuote(
        symbol: 'EURUSD',
        price: price,
        open: i == 0 ? price : price - 0.0001,
        high: price,
        low: price,
        timestamp: start.add(Duration(seconds: i)),
      );
      final signals = engine.analyze([quote]);
      expect(signals, isNotEmpty);
    }

    final dynamics = engine.dynamicsFor('EURUSD');
    final geometry = engine.geometryFor('EURUSD');

    expect(dynamics, isNotNull);
    expect(geometry, isNotNull);
    expect(dynamics!.ready, isTrue);
    expect(geometry!.ready, isTrue);
    expect(dynamics.observations, greaterThanOrEqualTo(4));
    expect(geometry.observations, greaterThanOrEqualTo(6));
    expect(dynamics.velocity, greaterThan(0));
    expect(geometry.orthogonalEfficiency, greaterThan(0));

    print('PASS: scanner still generates signals');
    print('PASS: price dynamics populated through ScannerEngine');
    print('PASS: market geometry populated through ScannerEngine');
    print('PASS: symbol-specific intelligence retrieval works');
  });
}
