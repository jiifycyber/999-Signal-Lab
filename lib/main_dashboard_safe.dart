import 'package:flutter/material.dart';

void main() {
  runApp(const NexusFxScannerApp());
}

class NexusFxScannerApp extends StatelessWidget {
  const NexusFxScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXUS FX Scanner Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020811),
        useMaterial3: true,
      ),
      home: const ScannerTwinScreen(),
    );
  }
}

class ScannerTwinScreen extends StatelessWidget {
  const ScannerTwinScreen({super.key});

  static const double designWidth = 1536;
  static const double designHeight = 1024;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020811),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          final scaleX = viewportWidth / designWidth;
          final scaleY = viewportHeight / designHeight;
          final scale = scaleX < scaleY ? scaleX : scaleY;
          final renderedWidth = designWidth * scale;
          final renderedHeight = designHeight * scale;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(color: const Color(0xFF020811)),
              ),
              Center(
                child: SizedBox(
                  width: renderedWidth,
                  height: renderedHeight,
                  child: Image.asset(
                    'assets/images/nexus_fx_scanner_reference.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
