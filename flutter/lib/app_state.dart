import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

String pad2(int n) => n.toString().padLeft(2, '0');
String dateKey(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';
int dowOf(DateTime d) => d.weekday; // 1 = Monday … 7 = Sunday
int toMin(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String fromMin(int m) => '${pad2((m ~/ 60) % 24)}:${pad2(m % 60)}';

class Kid {
  Kid({required this.id, required this.name, required this.av, required this.tint, required this.lang, required this.img});
  final String id;
  String name;
  String av;
  int tint;
  String lang;
  bool img;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'av': av, 'tint': tint, 'lang': lang, 'img': img};
  static Kid fromJson(Map<String, dynamic> j) => Kid(
        id: j['id'] as String,
        name: j['name'] as String,
        av: j['av'] as String,
        tint: j['tint'] as int,
        lang: j['lang'] as String,
        img: j['img'] as bool,
      );
}

class Slot {
  Slot(this.d, this.t);
  int d;
  String t;
}

class Sched {
  Sched(this.slots, this.bell);
  List<Slot> slots;
  bool bell;

  Map<String, dynamic> toJson() => {
        'slots': [for (final s in slots) {'d': s.d, 't': s.t}],
        'bell': bell,
      };
  static Sched fromJson(Map<String, dynamic> j) => Sched(
        [for (final s in (j['slots'] as List)) Slot((s as Map)['d'] as int, s['t'] as String)],
        j['bell'] as bool,
      );
}

class Note {
  Note({required this.id, required this.kid, required this.date, required this.ts, required this.text, this.audio});
  final String id;
  final String kid;
  final String date;
  final int ts;
  final String text;
  final String? audio; // path of the voice recording on the tablet

  Map<String, dynamic> toJson() => {'id': id, 'kid': kid, 'date': date, 'ts': ts, 'text': text, 'audio': audio};
  static Note fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        kid: j['kid'] as String,
        date: j['date'] as String,
        ts: j['ts'] as int,
        text: (j['text'] as String?) ?? '',
        audio: j['audio'] as String?,
      );
}

class RoutineAt {
  const RoutineAt(this.r, this.t);
  final Routine r;
  final String t;
}

/// Everything the app remembers: profiles, schedule, today's progress, step names and order, notes.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'imm-state-1';

  List<Kid> kids = [Kid(id: 'ostap', name: 'Ostap', av: 'ostap', tint: 0xFFE2F1EF, lang: 'it', img: true)];
  Map<String, Map<String, Sched>> sched = {};
  Map<String, List<bool>> progress = {};
  Map<String, List<String?>> names = {};
  Map<String, List<int>> order = {};
  Map<String, List<String>> rorder = {};
  List<Note> notes = [];
  int simDay = 0;
  String ui = 'it';

  /// The child who is playing now
  String kidId = 'ostap';

  /// Parents' area was opened from the child's screens – shows «Torna al gioco»
  bool cameFromChild = false;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(prefs);
    s.sched = {
      'ostap': {for (final e in defaultSchedule().entries) e.key: Sched.fromJson(e.value)},
    };
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        s._fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return s;
  }

  void _fromJson(Map<String, dynamic> j) {
    kids = [for (final k in (j['kids'] as List)) Kid.fromJson(k as Map<String, dynamic>)];
    sched = {
      for (final e in (j['sched'] as Map<String, dynamic>).entries)
        e.key: {for (final r in (e.value as Map<String, dynamic>).entries) r.key: Sched.fromJson(r.value as Map<String, dynamic>)},
    };
    progress = {for (final e in (j['progress'] as Map<String, dynamic>).entries) e.key: [for (final v in (e.value as List)) v == true]};
    names = {for (final e in (j['names'] as Map<String, dynamic>).entries) e.key: [for (final v in (e.value as List)) v as String?]};
    order = {for (final e in (j['order'] as Map<String, dynamic>).entries) e.key: [for (final v in (e.value as List)) v as int]};
    rorder = {for (final e in (j['rorder'] as Map<String, dynamic>).entries) e.key: [for (final v in (e.value as List)) v as String]};
    notes = [for (final n in (j['notes'] as List)) Note.fromJson(n as Map<String, dynamic>)];
    simDay = (j['simDay'] as int?) ?? 0;
    ui = (j['ui'] as String?) ?? 'it';
  }

  Map<String, dynamic> _toJson() => {
        'kids': [for (final k in kids) k.toJson()],
        'sched': {for (final e in sched.entries) e.key: {for (final r in e.value.entries) r.key: r.value.toJson()}},
        'progress': progress,
        'names': names,
        'order': order,
        'rorder': rorder,
        'notes': [for (final n in notes) n.toJson()],
        'simDay': simDay,
        'ui': ui,
      };

  void save({bool notify = true}) {
    _prefs.setString(_key, jsonEncode(_toJson()));
    if (notify) notifyListeners();
  }

  // ---------- Profiles ----------
  Kid kidBy(String id) => kids.firstWhere((k) => k.id == id, orElse: () => kids.first);
  Kid get kid => kidBy(kidId);

  /// Language of the child's screens
  String get lang => kid.lang;

  // ---------- Texts ----------
  String tr(String key) => uiText[lang]![key] ?? key;
  String routineName(String rid, [String? lg]) => routineNames[lg ?? lang]![rid]!;
  String stepName(String kidId_, String rid, int i, [String? lg]) {
    final custom = names['$kidId_|$rid'];
    if (custom != null && i < custom.length && custom[i] != null && custom[i]!.isNotEmpty) return custom[i]!;
    return stepNames[lg ?? lang]![rid]![i];
  }

  String voice() => voiceOf[lang]!;
  String l(String it, String uk) => ui == 'uk' ? uk : it;

  // ---------- Dates ----------
  /// "Giorno per la prova" shows the day as if it were another weekday of this week
  DateTime today() {
    final n = DateTime.now();
    final d = DateTime(n.year, n.month, n.day, 12);
    if (simDay == 0) return d;
    return d.add(Duration(days: (simDay - dowOf(d) + 7) % 7));
  }

  String longDate(DateTime d) => '${dayLong[ui]![dowOf(d)]}, ${d.day} ${monthNames[ui]![d.month - 1]}';

  // ---------- Routines ----------
  Sched? schedOf(String k, String rid) => sched[k]?[rid];

  /// The kid's routines in mom's order (long-press and drag in Routine)
  List<Routine> kidRoutines(String k) {
    final o = rorder[k] ?? const <String>[];
    int pos(String id) {
      final i = o.indexOf(id);
      return i < 0 ? 999 + routines.indexWhere((r) => r.id == id) : i;
    }

    final list = routines.where((r) => schedOf(k, r.id) != null).toList();
    list.sort((a, b) => pos(a.id) - pos(b.id));
    return list;
  }

  List<Routine> childRoutines() => kidRoutines(kidId).where((r) => !hiddenForChild.contains(r.id)).toList();

  List<RoutineAt> routinesOn(String k, DateTime date) {
    final dw = dowOf(date);
    final list = <RoutineAt>[];
    for (final r in kidRoutines(k)) {
      final slots = schedOf(k, r.id)!.slots.where((s) => s.d == dw);
      if (slots.isNotEmpty) list.add(RoutineAt(r, slots.first.t));
    }
    final out = list.where((x) {
      final skip = skipIf[x.r.id];
      return skip == null || !skip.any((id) => list.any((y) => y.r.id == id));
    }).toList();
    out.sort((a, b) => toMin(a.t) - toMin(b.t));
    return out;
  }

  String _pKey(String k, DateTime d, String rid) => '$k|${dateKey(d)}|$rid';
  List<bool> progOf(String k, DateTime d, String rid) {
    final n = routineById(rid).steps.length;
    final p = progress[_pKey(k, d, rid)];
    if (p == null || p.length != n) return List<bool>.filled(n, false);
    return p;
  }

  bool isDoneOn(String k, DateTime d, String rid) => progOf(k, d, rid).every((x) => x);

  // child screens: the playing kid, today
  List<bool> progressOf(String rid) => progOf(kidId, today(), rid);
  bool isDone(String rid) => isDoneOn(kidId, today(), rid);

  void toggleStep(String rid, int i) {
    final p = List<bool>.from(progressOf(rid));
    p[i] = !p[i];
    progress[_pKey(kidId, today(), rid)] = p;
    save();
  }

  void resetRoutine(String rid) {
    progress.remove(_pKey(kidId, today(), rid));
    save();
  }

  void resetDay(String k) {
    final prefix = '$k|${dateKey(today())}|';
    progress.removeWhere((key, _) => key.startsWith(prefix));
    save();
  }

  List<int> orderOf(String k, String rid) {
    final n = routineById(rid).steps.length;
    final o = order['$k|$rid'];
    if (o == null || o.length != n) return List<int>.generate(n, (i) => i);
    return o;
  }

  void moveStep(String k, String rid, int from, int to) {
    if (from == to) return;
    final o = List<int>.from(orderOf(k, rid));
    final x = o.removeAt(from);
    o.insert(to, x);
    order['$k|$rid'] = o;
    save();
  }

  void setRoutineOrder(String k, List<String> ids) {
    rorder[k] = ids;
    save();
  }

  void setStepName(String k, String rid, int i, String name) {
    final n = routineById(rid).steps.length;
    final arr = List<String?>.from(names['$k|$rid'] ?? List<String?>.filled(n, null));
    while (arr.length < n) {
      arr.add(null);
    }
    arr[i] = name.trim().isEmpty ? null : name.trim();
    names['$k|$rid'] = arr;
    save(notify: false);
  }

  void toggleDay(String k, String rid, int d) {
    final sc = schedOf(k, rid)!;
    final i = sc.slots.indexWhere((s) => s.d == d);
    if (i >= 0) {
      sc.slots.removeAt(i);
    } else {
      sc.slots.add(Slot(d, sc.slots.isNotEmpty ? sc.slots.first.t : '08:00'));
    }
    save();
  }

  void setTime(String k, String rid, String t, {int? day}) {
    final sc = schedOf(k, rid)!;
    for (final s in sc.slots) {
      if (day == null || s.d == day) s.t = t;
    }
    save();
  }

  void toggleBell(String k, String rid) {
    final sc = schedOf(k, rid)!;
    sc.bell = !sc.bell;
    save();
  }

  // ---------- Notes ----------
  List<Note> notesFor(String k, [String? date]) {
    final list = notes.where((n) => n.kid == k && (date == null || n.date == date)).toList();
    list.sort((a, b) => b.ts - a.ts);
    return list;
  }

  void addNote(String k, DateTime date, String text, {String? audio}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    notes.add(Note(id: 'n$ts', kid: k, date: dateKey(date), ts: ts, text: text, audio: audio));
    save();
  }

  void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
    save();
  }

  // ---------- Settings ----------
  void setUi(String l) {
    ui = l;
    for (final k in kids) {
      k.lang = l;
    }
    save();
  }

  void setSimDay(int d) {
    simDay = d;
    save();
  }

  void updateKid(String id, void Function(Kid k) change) {
    change(kidBy(id));
    save();
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
  Future<void> play(String key, {VoidCallback? onEnd}) => _playSource(AssetSource('snd/$key.mp3'), onEnd);

  /// Plays a voice note recorded on the tablet
  Future<void> playFile(String path, {VoidCallback? onEnd}) => _playSource(DeviceFileSource(path), onEnd);

  Future<void> _playSource(Source src, VoidCallback? onEnd) async {
    final token = await stop();
    _onEnd = onEnd;
    await _endSub?.cancel();
    _endSub = _player.onPlayerComplete.listen((_) => _finish(token));
    try {
      await _player.play(src);
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
