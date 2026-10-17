import 'dart:math' as math;

class MarketGeometryPoint {
  final double price;
  final DateTime timestamp;
  const MarketGeometryPoint(this.price, this.timestamp);
}

class MarketGeometryResult {
  final bool ready;
  final double gridSize;
  final int currentZone;
  final double rectilinearScore;
  final double orthogonalEfficiency;
  final int junctionCount;
  final int branchCount;
  final double transitionProbability;
  final double pathError;
  final int observations;

  const MarketGeometryResult({
    required this.ready,
    required this.gridSize,
    required this.currentZone,
    required this.rectilinearScore,
    required this.orthogonalEfficiency,
    required this.junctionCount,
    required this.branchCount,
    required this.transitionProbability,
    required this.pathError,
    required this.observations,
  });
}

class MarketGeometryEngine {
  static MarketGeometryResult analyze(List<MarketGeometryPoint> observations) {
    final valid = observations
        .where((o) => o.price.isFinite && o.price > 0)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (valid.length < 6) {
      return MarketGeometryResult(
          ready: false,
          gridSize: 0,
          currentZone: 0,
          rectilinearScore: 0,
          orthogonalEfficiency: 0,
          junctionCount: 0,
          branchCount: 0,
          transitionProbability: 0,
          pathError: 0,
          observations: valid.length);
    }
    final recent =
        valid.length > 120 ? valid.sublist(valid.length - 120) : valid;
    final moves = <double>[];
    for (var i = 1; i < recent.length; i++) {
      final d = (recent[i].price - recent[i - 1].price).abs();
      if (d > 0) moves.add(d);
    }
    final reference = recent.last.price.abs();
    final avgMove = moves.isEmpty
        ? reference * 0.00001
        : moves.reduce((a, b) => a + b) / moves.length;
    final gridSize = math.max(avgMove * 2.0, reference * 0.000001);
    final origin = recent.first.price;
    final zones =
        recent.map((o) => ((o.price - origin) / gridSize).round()).toList();
    final compressed = <int>[];
    for (final z in zones) {
      if (compressed.isEmpty || compressed.last != z) compressed.add(z);
    }
    var totalSteps = 0.0;
    for (var i = 1; i < compressed.length; i++) {
      totalSteps += (compressed[i] - compressed[i - 1]).abs();
    }
    final netSteps = compressed.length < 2
        ? 0.0
        : (compressed.last - compressed.first).abs().toDouble();
    final orthogonalEfficiency = totalSteps == 0
        ? 0.0
        : (netSteps / totalSteps).clamp(0.0, 1.0).toDouble();
    final neighbors = <int, Set<int>>{};
    final transitions = <int, Map<int, int>>{};
    for (var i = 1; i < compressed.length; i++) {
      final a = compressed[i - 1];
      final b = compressed[i];
      neighbors.putIfAbsent(a, () => <int>{}).add(b);
      neighbors.putIfAbsent(b, () => <int>{}).add(a);
      transitions.putIfAbsent(a, () => <int, int>{})[b] =
          (transitions[a]?[b] ?? 0) + 1;
    }
    final junctionCount = neighbors.values.where((n) => n.length >= 3).length;
    var branchCount = 0;
    for (final n in neighbors.values) {
      if (n.length > 2) branchCount += n.length - 2;
    }
    final revisits = compressed.length - compressed.toSet().length;
    final rectilinearScore = compressed.isEmpty
        ? 0.0
        : ((revisits / compressed.length) * 100.0).clamp(0.0, 100.0).toDouble();
    double transitionProbability = 0;
    double pathError = 0;
    if (compressed.length >= 3) {
      final source = compressed[compressed.length - 2];
      final actual = compressed.last;
      final counts = transitions[source] ?? const <int, int>{};
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      if (total > 0) transitionProbability = (counts[actual] ?? 0) / total;
      if (counts.isNotEmpty) {
        var predicted = counts.keys.first;
        var best = counts[predicted] ?? 0;
        for (final e in counts.entries) {
          if (e.value > best) {
            predicted = e.key;
            best = e.value;
          }
        }
        pathError =
            ((predicted - actual).abs() / (1.0 + compressed.toSet().length))
                .clamp(0.0, 1.0)
                .toDouble();
      }
    }
    return MarketGeometryResult(
        ready: compressed.length >= 4,
        gridSize: gridSize,
        currentZone: zones.last,
        rectilinearScore: rectilinearScore,
        orthogonalEfficiency: orthogonalEfficiency,
        junctionCount: junctionCount,
        branchCount: branchCount,
        transitionProbability: transitionProbability,
        pathError: pathError,
        observations: recent.length);
  }
}
