import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

String _pad(int n) => n.toString().padLeft(2, '0');
String dateKey(DateTime d) => '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

/// Saved state of the child mode: language and today's progress of each routine.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);
  final SharedPreferences _prefs;

  String lang = 'it';
  final Map<String, List<bool>> _progress = {};

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(prefs);
    s.lang = prefs.getString('lang') ?? 'it';
    final raw = prefs.getString('progress');
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        m.forEach((k, v) {
          s._progress[k] = (v as List).map((e) => e == true).toList();
        });
      } catch (_) {}
    }
    return s;
  }

  String tr(String key) => uiText[lang]![key] ?? key;
  String routineName(String rid) => routineNames[lang]![rid]!;
  String stepName(String rid, int i) => stepNames[lang]![rid]![i];
  String voice() => voiceOf[lang]!;

  /// Routines the child sees, in the order of the day
  List<Routine> childRoutines() => routines.where((r) => !hiddenForChild.contains(r.id)).toList();

  String _key(String rid) => 'ostap|${dateKey(DateTime.now())}|$rid';
  List<bool> progressOf(String rid) {
    final p = _progress[_key(rid)];
    final n = routineById(rid).steps.length;
    if (p == null || p.length != n) return List<bool>.filled(n, false);
    return p;
  }

  bool isDone(String rid) => progressOf(rid).every((x) => x);

  void toggleStep(String rid, int i) {
    final p = List<bool>.from(progressOf(rid));
    p[i] = !p[i];
    _progress[_key(rid)] = p;
    _save();
    notifyListeners();
  }

  void resetRoutine(String rid) {
    _progress.remove(_key(rid));
    _save();
    notifyListeners();
  }

  void setLang(String l) {
    lang = l;
    _prefs.setString('lang', l);
    notifyListeners();
  }

  void _save() {
    _prefs.setString('progress', jsonEncode(_progress));
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// One voice at a time: a book sound, a melody or a spoken step name.
/// Starting something new stops whatever was playing.
class Sound {
  Sound._();
  static final Sound instance = Sound._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  StreamSubscription<void>? _endSub;
  int _token = 0;
  VoidCallback? _onEnd;

  void _finish(int token) {
    if (token != _token) return;
    final cb = _onEnd;
    _onEnd = null;
    cb?.call();
  }

  /// Stops everything. [notify] = false is used when the screen is closing, so no callback reaches it.
  Future<int> stop({bool notify = true}) async {
    _token++;
    final cb = _onEnd;
    _onEnd = null;
    if (notify) cb?.call();
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    return _token;
  }

  /// Plays assets/snd/<key>.mp3 (recordings and melodies are already at the same loudness)
  Future<void> play(String key, {VoidCallback? onEnd}) async {
    final token = await stop();
    _onEnd = onEnd;
    await _endSub?.cancel();
    _endSub = _player.onPlayerComplete.listen((_) => _finish(token));
    try {
      await _player.play(AssetSource('snd/$key.mp3'));
    } catch (_) {
      _finish(token);
    }
  }

  /// Says a word slowly in the child's language
  Future<void> speak(String text, String voice, {double volume = 0.9, VoidCallback? onEnd}) async {
    final token = await stop();
    _onEnd = onEnd;
    try {
      await _tts.setLanguage(voice);
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(volume);
      _tts.setCompletionHandler(() => _finish(token));
      _tts.setErrorHandler((dynamic _) => _finish(token));
      await _tts.speak(text);
    } catch (_) {
      _finish(token);
    }
    // a safety net, so the picture never stays "speaking" if the engine is silent
    Future<void>.delayed(const Duration(milliseconds: 3500), () => _finish(token));
  }
}
