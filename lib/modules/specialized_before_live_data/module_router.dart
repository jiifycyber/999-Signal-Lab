import 'package:flutter/material.dart';
import 'module_context.dart';
import 'intelligence_modules.dart';

Future<void> openSpecializedModule(
  BuildContext context,
  String title, {
  required String pair,
  required String timeframe,
  double? price,
}) async {
  final data = ModuleContext(
    pair: pair,
    timeframe: timeframe,
    price: price,
  );

  await showDialog<void>(
    context: context,
    builder: (_) => buildIntelligenceModule(title, data),
  );
}
