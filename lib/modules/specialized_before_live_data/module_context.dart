class ModuleContext {
  final String pair;
  final String timeframe;
  final double? price;

  const ModuleContext({
    required this.pair,
    required this.timeframe,
    this.price,
  });
}
