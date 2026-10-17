import 'package:flutter/material.dart';

import 'agent_duke_global_controller.dart';
import 'agent_duke_voice_controller.dart';

class AgentDukeGlobalPanel extends StatefulWidget {
  final Widget child;

  const AgentDukeGlobalPanel({
    super.key,
    required this.child,
  });

  @override
  State<AgentDukeGlobalPanel> createState() => _AgentDukeGlobalPanelState();
}

class _AgentDukeGlobalPanelState extends State<AgentDukeGlobalPanel> {
  static const cyan = Color(0xFF00E5FF);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF20E39A);

  final duke = AgentDukeGlobalController.instance;
  final command = TextEditingController();

  bool expanded = true;

  @override
  void initState() {
    super.initState();
    duke.addListener(_refresh);
    duke.initializeVoice();
  }

  @override
  void dispose() {
    duke.removeListener(_refresh);
    command.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final text = command.text.trim();

    if (text.isEmpty || duke.busy) {
      return;
    }

    command.clear();

    await duke.submit(text);
  }

  @override
  Widget build(BuildContext context) {
    // HIDE_GLOBAL_DUKE_ON_SCANNER
    // The scanner already contains the preferred embedded Duke panel.
    final currentPage = AgentDukeGlobalController.instance.page.toUpperCase();

    if (currentPage == 'AI SCANNER') {
      return widget.child;
    }

    final media = MediaQuery.of(context);

    final availableHeight =
        media.size.height - media.padding.top - media.padding.bottom;

    final desktop = media.size.width >= 900;

    final panelWidth =
        desktop ? 310.0 : (media.size.width - 24).clamp(260.0, 310.0);

    final desiredHeight = desktop ? 430.0 : availableHeight * .58;

    final panelHeight = desiredHeight.clamp(
      260.0,
      availableHeight - 110.0,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          right: 12,
          top: desktop ? 76 : 64,
          child: SafeArea(
            child: Material(
              type: MaterialType.transparency,
              child: expanded
                  ? SizedBox(
                      width: panelWidth,
                      height: panelHeight,
                      child: _expandedPanel(),
                    )
                  : SizedBox(
                      width: 52,
                      height: 52,
                      child: _collapsedPanel(),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shell({
    required Widget child,
  }) {
    return Material(
      color: const Color(0xF207111D),
      elevation: 10,
      shadowColor: cyan.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cyan.withValues(alpha: .55),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _collapsedPanel() {
    return _shell(
      child: InkWell(
        onTap: () {
          setState(() {
            expanded = true;
          });
        },
        child: const Center(
          child: Icon(
            Icons.psychology_alt,
            color: cyan,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _expandedPanel() {
    return _shell(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${duke.page} • ${duke.symbol} • ${duke.timeframe}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: cyan,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: purple.withValues(alpha: .30),
                  ),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    duke.lastResponse,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: TextField(
                controller: command,
                enabled: !duke.busy,
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                decoration: InputDecoration(
                  hintText: duke.busy
                      ? 'Duke is processing...'
                      : 'Ask Duke anything...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .04),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(
                      color: cyan.withValues(alpha: .25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(
                      color: cyan,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: duke.busy ? null : _submit,
                    icon: const Icon(
                      Icons.send,
                      color: cyan,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _quick(
                    'SCAN',
                    () => duke.execute('deep_scan'),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _quick(
                    'CHART',
                    () => duke.execute('open_advanced_chart'),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _quick(
                    'BACK',
                    () => duke.execute('navigate_back'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: duke.busy ? purple : green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    duke.autonomousMode
                        ? 'AUTONOMOUS ANALYSIS • ON'
                        : duke.busy
                            ? 'DUKE PROCESSING'
                            : 'APP COMMAND SYSTEM • READY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: duke.autonomousMode ? green : Colors.white38,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(
          Icons.psychology_alt,
          color: cyan,
          size: 19,
        ),
        const SizedBox(width: 7),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AGENT DUKE THE BOSS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
              Text(
                '999 INTELLIGENCE OPERATOR',
                style: TextStyle(
                  color: cyan,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: duke.voice.state == DukeVoiceState.listening
              ? 'Stop listening'
              : 'Talk to Agent Duke',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 28,
          ),
          onPressed: duke.busy ? null : duke.toggleVoice,
          icon: Icon(
            duke.voice.state == DukeVoiceState.listening
                ? Icons.mic
                : Icons.mic_none,
            color: duke.voice.state == DukeVoiceState.listening ? green : cyan,
            size: 18,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          onPressed: () {
            setState(() {
              expanded = false;
            });
          },
          icon: const Icon(
            Icons.remove,
            color: Colors.white54,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _quick(
    String label,
    Future<String> Function() action,
  ) {
    return SizedBox(
      height: 27,
      child: OutlinedButton(
        onPressed: duke.busy ? null : action,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: cyan,
          side: BorderSide(
            color: cyan.withValues(alpha: .28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
