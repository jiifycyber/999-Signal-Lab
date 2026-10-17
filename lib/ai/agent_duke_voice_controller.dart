import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum DukeVoiceState {
  idle,
  listening,
  processing,
  speaking,
  unavailable,
}

class AgentDukeVoiceController extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  DukeVoiceState state = DukeVoiceState.idle;

  String transcript = '';
  String lastResponse = '';

  bool voiceRepliesEnabled = true;
  bool initialized = false;

  bool wakeModeEnabled = true;
  bool _wakeListening = false;
  bool _wakeRestartPending = false;

  bool get wakeListening => _wakeListening;

  FutureOr<void> Function(String command)? _commandHandler;

  Timer? _silenceTimer;
  Timer? _idleTimer;
  bool _dispatchingCommand = false;

  static const Duration _commandSilence = Duration(milliseconds: 1200);

  static const Duration _idleTimeout = Duration(seconds: 8);

  String get statusText {
    switch (state) {
      case DukeVoiceState.idle:
        return 'READY';
      case DukeVoiceState.listening:
        return 'LISTENING';
      case DukeVoiceState.processing:
        return 'THINKING';
      case DukeVoiceState.speaking:
        return 'SPEAKING';
      case DukeVoiceState.unavailable:
        return 'VOICE UNAVAILABLE';
    }
  }

  Future<void> initialize() async {
    if (initialized) return;

    final available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (_) {
        state = DukeVoiceState.unavailable;
        notifyListeners();
      },
    );

    if (!available) {
      state = DukeVoiceState.unavailable;
      notifyListeners();
      return;
    }

    await _configureDukeVoice();

    _tts.setStartHandler(() {
      state = DukeVoiceState.speaking;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      state = DukeVoiceState.idle;
      notifyListeners();

      if (wakeModeEnabled) {
        Future<void>.delayed(
          const Duration(milliseconds: 450),
          () async {
            await rearmWakeMode();
          },
        );
      }
    });

    _tts.setCancelHandler(() {
      state = DukeVoiceState.idle;
      notifyListeners();
    });

    _tts.setErrorHandler((_) {
      state = DukeVoiceState.idle;
      notifyListeners();
    });

    initialized = true;
    state = DukeVoiceState.idle;
    notifyListeners();
  }

  Future<void> _configureDukeVoice() async {
    await _tts.setLanguage('en-US');

    // Clear, normal American speaking voice.
    await _tts.setSpeechRate(0.50);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    try {
      final dynamic rawVoices = await _tts.getVoices;

      if (rawVoices is! List) {
        debugPrint('DUKE VOICE: Browser returned no voice list.');
        return;
      }

      final voices = rawVoices
          .whereType<Map>()
          .map(
            (voice) => voice.map(
              (key, value) => MapEntry(
                key.toString(),
                value,
              ),
            ),
          )
          .toList();

      for (final voice in voices) {
        debugPrint(
          'DUKE AVAILABLE VOICE: '
          '${voice['name'] ?? voice['voice']} '
          '(${voice['locale']})',
        );
      }

      // macOS / Chrome American male priority.
      const preferredAmericanMaleVoices = <String>[
        'Alex',
        'Aaron',
        'Evan',
        'Reed',
        'Nathan',
        'Tom',
        'Fred',
        'Bruce',
        'Albert',
      ];

      Map<String, dynamic>? selected;

      for (final preferred in preferredAmericanMaleVoices) {
        for (final raw in voices) {
          final name = (raw['name'] ?? raw['voice'] ?? '').toString();

          final locale = (raw['locale'] ?? '').toString().toLowerCase();

          if (name.toLowerCase() == preferred.toLowerCase() &&
              locale.startsWith('en-us')) {
            selected = Map<String, dynamic>.from(raw);
            break;
          }
        }

        if (selected != null) {
          break;
        }
      }

      // Some browsers expose Alex without a precise locale match.
      selected ??= voices
          .where(
            (voice) {
              final name = (voice['name'] ?? voice['voice'] ?? '')
                  .toString()
                  .toLowerCase();

              return name == 'alex';
            },
          )
          .map(Map<String, dynamic>.from)
          .cast<Map<String, dynamic>?>()
          .firstOrNull;

      // Last-resort US English fallback.
      selected ??= voices
          .where(
            (voice) {
              final locale = (voice['locale'] ?? '').toString().toLowerCase();

              return locale.startsWith('en-us');
            },
          )
          .map(Map<String, dynamic>.from)
          .cast<Map<String, dynamic>?>()
          .firstOrNull;

      if (selected != null) {
        final name = (selected['name'] ?? selected['voice']).toString();

        final locale = (selected['locale'] ?? 'en-US').toString();

        await _tts.setVoice({
          'name': name,
          'locale': locale,
        });

        debugPrint(
          'DUKE AMERICAN MALE VOICE SELECTED: '
          '$name ($locale)',
        );
      } else {
        debugPrint(
          'DUKE VOICE: No en-US browser voice found.',
        );
      }
    } catch (error) {
      debugPrint(
        'DUKE VOICE CONFIG ERROR: $error',
      );
    }
  }

  // DUKE_MALE_VOICE_PRIORITY
  Future<void> selectDukeMaleVoice() async {
    try {
      final dynamic voices = await _tts.getVoices;

      if (voices is! List) {
        return;
      }

      const preferredNames = <String>[
        'Alex',
        'Daniel',
        'Aaron',
        'Fred',
        'Tom',
        'Ralph',
        'Albert',
        'Bruce',
        'Junior',
        'Arthur',
        'Eddy',
        'Reed',
      ];

      Map<String, dynamic>? chosen;

      for (final preferred in preferredNames) {
        for (final dynamic raw in voices) {
          if (raw is! Map) {
            continue;
          }

          final name = (raw['name'] ?? raw['voice'] ?? '').toString();

          final locale = (raw['locale'] ?? '').toString();

          if (name.toLowerCase() == preferred.toLowerCase() &&
              locale.toLowerCase().startsWith('en')) {
            chosen = Map<String, dynamic>.from(raw);
            break;
          }
        }

        if (chosen != null) {
          break;
        }
      }

      if (chosen != null) {
        final name = (chosen['name'] ?? chosen['voice']).toString();

        final locale = (chosen['locale'] ?? 'en-US').toString();

        await _tts.setVoice({
          'name': name,
          'locale': locale,
        });
      }

      await _tts.setPitch(0.82);
      await _tts.setSpeechRate(0.45);
    } catch (_) {
      await _tts.setPitch(0.82);
      await _tts.setSpeechRate(0.45);
    }
  }

  Future<void> startWakeMode(
    FutureOr<void> Function()? onWake,
  ) async {
    wakeModeEnabled = true;

    await initialize();

    if (state == DukeVoiceState.unavailable) {
      return;
    }

    if (_dispatchingCommand ||
        state == DukeVoiceState.processing ||
        state == DukeVoiceState.speaking) {
      return;
    }

    if (_speech.isListening) {
      return;
    }

    _wakeListening = true;
    _wakeRestartPending = false;

    notifyListeners();

    try {
      await _speech.listen(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        onResult: (result) async {
          if (!wakeModeEnabled || _dispatchingCommand) {
            return;
          }

          final heard = result.recognizedWords.trim().toLowerCase();

          if (heard.isEmpty) {
            return;
          }

          final woke =
              heard.contains('hey duke') || heard.contains('hey agent duke');

          if (!woke) {
            return;
          }

          _wakeListening = false;

          if (_speech.isListening) {
            await _speech.stop();
          }

          state = DukeVoiceState.speaking;
          notifyListeners();

          await speak(
            'Yes, I am here.',
          );

          if (onWake != null) {
            await onWake();
          }

          // After acknowledging the wake phrase,
          // immediately transition into command capture.
          // Give the user a natural response window after
          // Duke acknowledges the wake phrase.
          await Future<void>.delayed(
            const Duration(seconds: 5),
          );

          if (wakeModeEnabled) {
            await startListening(
              _commandHandler ?? (_) async {},
            );
          }
        },
      );
    } catch (error) {
      _wakeListening = false;

      debugPrint(
        'DUKE WAKE MODE START ERROR: $error',
      );

      notifyListeners();
    }
  }

  Future<void> stopWakeMode() async {
    wakeModeEnabled = false;
    _wakeListening = false;
    _wakeRestartPending = false;

    if (_speech.isListening) {
      await _speech.stop();
    }

    state = DukeVoiceState.idle;
    notifyListeners();
  }

  Future<void> rearmWakeMode() async {
    if (!wakeModeEnabled ||
        _wakeRestartPending ||
        _dispatchingCommand ||
        state == DukeVoiceState.processing ||
        state == DukeVoiceState.speaking) {
      return;
    }

    _wakeRestartPending = true;

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    _wakeRestartPending = false;

    if (!wakeModeEnabled || _speech.isListening) {
      return;
    }

    await startWakeMode(null);
  }

  Future<void> startListening(
    FutureOr<void> Function(String command) onFinalCommand,
  ) async {
    await initialize();

    if (state == DukeVoiceState.unavailable) {
      return;
    }

    _commandHandler = onFinalCommand;

    if (_speech.isListening) {
      await stopListening();
      return;
    }

    _silenceTimer?.cancel();
    _idleTimer?.cancel();

    _dispatchingCommand = false;
    transcript = '';

    state = DukeVoiceState.listening;
    notifyListeners();

    void armIdleTimeout() {
      _idleTimer?.cancel();

      _idleTimer = Timer(
        _idleTimeout,
        () async {
          if (_dispatchingCommand) {
            return;
          }

          if (_speech.isListening) {
            await _speech.stop();
          }

          state = DukeVoiceState.idle;
          notifyListeners();
        },
      );
    }

    void armCommandSilence(String speech) {
      _silenceTimer?.cancel();

      _silenceTimer = Timer(
        _commandSilence,
        () async {
          await _dispatchRecognizedCommand(
            speech,
          );
        },
      );
    }

    armIdleTimeout();

    await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      onResult: (result) async {
        final recognized = result.recognizedWords.trim();

        transcript = recognized;
        notifyListeners();

        if (recognized.isEmpty || _dispatchingCommand) {
          return;
        }

        // Every speech update means the user is active.
        armIdleTimeout();

        if (result.finalResult) {
          _silenceTimer?.cancel();

          await _dispatchRecognizedCommand(
            recognized,
          );

          return;
        }

        // Chrome often keeps dictation open instead of producing
        // finalResult quickly. Silence becomes our natural
        // "the user finished speaking" signal.
        armCommandSilence(recognized);
      },
    );
  }

  Future<void> _dispatchRecognizedCommand(
    String rawSpeech,
  ) async {
    if (_dispatchingCommand) {
      return;
    }

    final raw = rawSpeech.trim();

    if (raw.isEmpty) {
      return;
    }

    final lowerRaw = raw.toLowerCase();

    final wakeOnly = lowerRaw == 'hey duke' ||
        lowerRaw == 'hey agent duke' ||
        lowerRaw == 'agent duke' ||
        lowerRaw == 'duke';

    final command = _stripWakePhrase(raw);

    if (wakeOnly) {
      _dispatchingCommand = true;

      _silenceTimer?.cancel();
      _idleTimer?.cancel();

      if (_speech.isListening) {
        await _speech.stop();
      }

      state = DukeVoiceState.speaking;
      notifyListeners();

      await speak(
        'Yes, I am here.',
      );

      _dispatchingCommand = false;
      return;
    }

    if (command.isEmpty) {
      return;
    }

    _dispatchingCommand = true;

    _silenceTimer?.cancel();
    _idleTimer?.cancel();

    // Siri-style behavior:
    // listening ENDS as soon as the command is captured.
    if (_speech.isListening) {
      await _speech.stop();
    }

    state = DukeVoiceState.processing;
    notifyListeners();

    try {
      final handler = _commandHandler;

      if (handler != null) {
        await handler(command);
      }
    } finally {
      _dispatchingCommand = false;

      if (state == DukeVoiceState.processing) {
        state = DukeVoiceState.idle;
        notifyListeners();
      }

      if (wakeModeEnabled) {
        await rearmWakeMode();
      }
    }
  }

  String _stripWakePhrase(String raw) {
    var text = raw.trim();

    final lower = text.toLowerCase();

    const wakePhrases = <String>[
      'hey agent duke',
      'hey duke',
      'agent duke',
      'duke',
    ];

    for (final wake in wakePhrases) {
      if (lower.startsWith(wake)) {
        text = text.substring(wake.length).trim();

        text = text.replaceFirst(
          RegExp(r'^[,\-:\s]+'),
          '',
        );

        return text.trim();
      }
    }

    // Tap-to-talk also works without requiring the wake phrase.
    return text;
  }

  void setProcessing() {
    state = DukeVoiceState.processing;
    notifyListeners();
  }

  void finishProcessing() {
    if (state == DukeVoiceState.processing) {
      state = DukeVoiceState.idle;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    _idleTimer?.cancel();

    _dispatchingCommand = false;

    if (_speech.isListening) {
      await _speech.stop();
    }

    state = DukeVoiceState.idle;
    notifyListeners();
  }

  Future<void> cancelListening() async {
    _silenceTimer?.cancel();
    _idleTimer?.cancel();

    _dispatchingCommand = false;

    if (_speech.isListening) {
      await _speech.cancel();
    }

    transcript = '';
    state = DukeVoiceState.idle;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (!voiceRepliesEnabled || text.trim().isEmpty) {
      return;
    }

    await initialize();

    lastResponse = text.trim();

    if (_speech.isListening) {
      await _speech.stop();
    }

    state = DukeVoiceState.speaking;
    notifyListeners();

    await _tts.stop();
    await _tts.speak(lastResponse);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();

    if (state == DukeVoiceState.speaking) {
      state = DukeVoiceState.idle;
      notifyListeners();
    }
  }

  void _onSpeechStatus(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'listening') {
      state = DukeVoiceState.listening;
    } else if ((normalized == 'done' || normalized == 'notlistening') &&
        state == DukeVoiceState.listening) {
      state = DukeVoiceState.idle;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _idleTimer?.cancel();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;

    if (!iterator.moveNext()) return null;

    return iterator.current;
  }
}
