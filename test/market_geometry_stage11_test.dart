import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_fx_scanner_flutter_twin/intelligence/market_geometry_engine.dart';

void main() {
  test('999 Market Geometry verification', () {
    final t = DateTime.utc(2026, 1, 1);

    final straight = List.generate(
        12,
        (i) => MarketGeometryPoint(
            1.0000 + i * 0.0010, t.add(Duration(seconds: i))));
    final straightResult = MarketGeometryEngine.analyze(straight);
    expect(straightResult.ready, isTrue);
    expect(straightResult.orthogonalEfficiency, greaterThan(0.70));

    final reversalPrices = <double>[
      1.0000,
      1.0010,
      1.0000,
      1.0010,
      1.0000,
      1.0010,
      1.0000,
      1.0010,
      1.0000
    ];
    final reversal = List.generate(
        reversalPrices.length,
        (i) => MarketGeometryPoint(
            reversalPrices[i], t.add(Duration(seconds: i))));
    final reversalResult = MarketGeometryEngine.analyze(reversal);
    expect(reversalResult.ready, isTrue);
    expect(reversalResult.orthogonalEfficiency,
        lessThan(straightResult.orthogonalEfficiency));
    expect(reversalResult.rectilinearScore, greaterThan(0));

    final transitionPrices = <double>[
      1.0000,
      1.0010,
      1.0000,
      1.0010,
      1.0000,
      1.0010,
      1.0000,
      1.0010
    ];
    final transition = List.generate(
        transitionPrices.length,
        (i) => MarketGeometryPoint(
            transitionPrices[i], t.add(Duration(seconds: i))));
    final transitionResult = MarketGeometryEngine.analyze(transition);
    expect(transitionResult.transitionProbability, greaterThan(0));
    expect(transitionResult.pathError, greaterThanOrEqualTo(0));
    expect(transitionResult.pathError, lessThanOrEqualTo(1));

    print('PASS: straight-path efficiency');
    print('PASS: reversal path lowers efficiency');
    print('PASS: repeated-zone rectilinear score');
    print('PASS: transition probability');
    print('PASS: bounded path error');
  });
}
