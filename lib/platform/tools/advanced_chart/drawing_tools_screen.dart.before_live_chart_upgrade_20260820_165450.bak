import 'package:flutter/material.dart';

class DrawingToolsScreen extends StatefulWidget {
  const DrawingToolsScreen({super.key});

  @override
  State<DrawingToolsScreen> createState() => _DrawingToolsScreenState();
}

class _DrawingToolsScreenState extends State<DrawingToolsScreen> {
  static const bg = Color(0xFF020811);
  static const panel = Color(0xFF06121E);
  static const cyan = Color(0xFF00E5FF);

  String selected = 'Trendline';

  static const tools = [
    'Trendline',
    'Horizontal Line',
    'Vertical Line',
    'Ray',
    'Fibonacci Retracement',
    'Rectangle / Zone',
    'Channel',
    'Arrow',
    'Text Annotation',
    'Measure',
    'Eraser',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF070A0F),
        foregroundColor: Colors.white,
        title: const Text(
          'DRAWING TOOLS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 235,
            color: panel,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tools.length,
              itemBuilder: (_, index) {
                final tool = tools[index];
                final active = tool == selected;

                return ListTile(
                  dense: true,
                  selected: active,
                  leading: Icon(
                    _icon(tool),
                    color: active ? cyan : Colors.white54,
                  ),
                  title: Text(
                    tool,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => setState(() => selected = tool),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF030B13),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: cyan.withValues(alpha: .25),
                ),
              ),
              child: Center(
                child: Text(
                  '$selected ACTIVE\n\n'
                  'Drawing workspace ready for chart integration',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.w900,
                    height: 1.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String tool) {
    if (tool.contains('Fibonacci')) return Icons.stacked_line_chart;
    if (tool.contains('Horizontal')) return Icons.horizontal_rule;
    if (tool.contains('Vertical')) return Icons.more_vert;
    if (tool.contains('Rectangle')) return Icons.crop_square;
    if (tool.contains('Text')) return Icons.text_fields;
    if (tool.contains('Eraser')) return Icons.cleaning_services;
    return Icons.show_chart;
  }
}
