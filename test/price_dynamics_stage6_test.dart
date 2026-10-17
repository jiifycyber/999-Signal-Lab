import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_fx_scanner_flutter_twin/intelligence/price_dynamics_engine.dart';

void main() {
  test('999 Price Dynamics mathematical verification', () {
    final start = DateTime.utc(2026, 1, 1);
    final rising = List.generate(
        8,
        (i) =>
            PriceObservation(1.0 + i * 0.001, start.add(Duration(seconds: i))));
    final result = PriceDynamicsEngine.analyze(rising);
    expect(result.ready, isTrue);
    expect(result.velocity, greaterThan(0));
    expect(result.acceleration.abs(), lessThan(1e-9));
    expect(result.jerk.abs(), lessThan(1e-9));
    final insufficient = PriceDynamicsEngine.analyze(rising.take(2).toList());
    expect(insufficient.ready, isFalse);
    print('PASS: positive velocity');
    print('PASS: constant-increment acceleration');
    print('PASS: constant-increment jerk');
    print('PASS: insufficient-data gate');
  });
}
