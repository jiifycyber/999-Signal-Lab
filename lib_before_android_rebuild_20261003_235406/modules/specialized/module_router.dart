import 'package:flutter/material.dart';

import 'module_context.dart';
import 'intelligence_modules.dart';

Future<void> openSpecializedModule(
  BuildContext context,
  String title, {
  required String pair,
  required String timeframe,
  required double? price,
  required String direction,
  required double confidence,
  required double score,
  required String trend,
  required String momentum,
  required String setup,
  required double? entry,
  required double? stopLoss,
  required double? tp1,
  required double? tp2,
  required double? tp3,
}) async {
  final data = ModuleContext(
    pair: pair,
    timeframe: timeframe,
    price: price,
    direction: direction,
    confidence: confidence,
    score: score,
    trend: trend,
    momentum: momentum,
    setup: setup,
    entry: entry,
    stopLoss: stopLoss,
    tp1: tp1,
    tp2: tp2,
    tp3: tp3,
  );

  await showDialog<void>(
    context: context,
    builder: (_) => buildIntelligenceModule(
      title,
      data,
    ),
  );
}
