import 'dart:math' as math;

class PriceObservation {
  final double price;
  final DateTime timestamp;
  const PriceObservation(this.price, this.timestamp);
}

class PriceDynamicsResult {
  final bool ready;
  final double velocity;
  final double acceleration;
  final double jerk;
  final double volatility;
  final int observations;
  const PriceDynamicsResult(
      {required this.ready,
      required this.velocity,
      required this.acceleration,
      required this.jerk,
      required this.volatility,
      required this.observations});
}

class PriceDynamicsEngine {
  static PriceDynamicsResult analyze(List<PriceObservation> observations) {
    final valid = observations
        .where((o) => o.price.isFinite && o.price > 0)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recent =
        valid.length > 100 ? valid.sublist(valid.length - 100) : valid;
    final velocities = <double>[];
    final times = <DateTime>[];
    final returns = <double>[];
    for (var i = 1; i < recent.length; i++) {
      final dt = recent[i]
              .timestamp
              .difference(recent[i - 1].timestamp)
              .inMicroseconds /
          1000000.0;
      if (dt <= 0) continue;
      velocities.add((recent[i].price - recent[i - 1].price) / dt);
      times.add(recent[i].timestamp);
      returns.add(math.log(recent[i].price / recent[i - 1].price));
    }
    final accelerations = <double>[];
    final accelerationTimes = <DateTime>[];
    for (var i = 1; i < velocities.length; i++) {
      final dt = times[i].difference(times[i - 1]).inMicroseconds / 1000000.0;
      if (dt <= 0) continue;
      accelerations.add((velocities[i] - velocities[i - 1]) / dt);
      accelerationTimes.add(times[i]);
    }
    final jerks = <double>[];
    for (var i = 1; i < accelerations.length; i++) {
      final dt = accelerationTimes[i]
              .difference(accelerationTimes[i - 1])
              .inMicroseconds /
          1000000.0;
      if (dt <= 0) continue;
      jerks.add((accelerations[i] - accelerations[i - 1]) / dt);
    }
    final mean = returns.isEmpty
        ? 0.0
        : returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.isEmpty
        ? 0.0
        : returns
                .map((r) => math.pow(r - mean, 2).toDouble())
                .reduce((a, b) => a + b) /
            returns.length;
    return PriceDynamicsResult(
        ready: velocities.length >= 3 &&
            accelerations.length >= 2 &&
            jerks.isNotEmpty,
        velocity: velocities.isEmpty ? 0 : velocities.last,
        acceleration: accelerations.isEmpty ? 0 : accelerations.last,
        jerk: jerks.isEmpty ? 0 : jerks.last,
        volatility: math.sqrt(variance),
        observations: recent.length);
  }
}
