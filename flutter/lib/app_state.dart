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
  Kid({required this.id, required this.name, required this.av, required this.tint, required this.lang, required this.img, this.photo, this.books});
  final String id;
  String name;
  String av;
  int tint;
  String lang;
  bool img;

  /// path of the parent's own photo for the avatar (instead of [av])
  String? photo;

  /// books the child sees; null = all
  List<int>? books;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'av': av, 'tint': tint, 'lang': lang, 'img': img, 'photo': photo, 'books': books};
  static Kid fromJson(Map<String, dynamic> j) => Kid(
        id: j['id'] as String,
        name: j['name'] as String,
        av: j['av'] as String,
        tint: j['tint'] as int,
        lang: j['lang'] as String,
        img: j['img'] as bool,
        photo: j['photo'] as String?,
        books: (j['books'] as List?)?.map((e) => e as int).toList(),
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

/// One step of a child's routine: a picture from the set (or the parent's photo) and a name.
/// [src] points at the template step it came from, so its name follows the language until it is renamed.
class StepDef {
  StepDef({this.src, required this.img, required this.tint, this.name, this.photo});
  int? src;
  String img;
  int tint;
  String? name;
  String? photo;

  Map<String, dynamic> toJson() => {'src': src, 'img': img, 'tint': tint, 'name': name, 'photo': photo};
  static StepDef fromJson(Map<String, dynamic> j) => StepDef(src: j['src'] as int?, img: j['img'] as String, tint: j['tint'] as int, name: j['name'] as String?, photo: j['photo'] as String?);
}

/// A child's own copy of a routine – everything mom can change in the editor.
class RoutineDef {
  RoutineDef({required this.id, this.base, this.name, required this.cover, required this.tint, this.therapy = false, this.who, this.skipIf, this.hidden = false, required this.steps});
  final String id;
  final String? base; // template id, or null for a routine made from scratch
  String? name;
  String cover;
  int tint;
  bool therapy;
  String? who;
  List<String>? skipIf;
  bool hidden;
  List<StepDef> steps;

  Map<String, dynamic> toJson() => {'id': id, 'base': base, 'name': name, 'cover': cover, 'tint': tint, 'therapy': therapy, 'who': who, 'skipIf': skipIf, 'hidden': hidden, 'steps': [for (final s in steps) s.toJson()]};
  static RoutineDef fromJson(Map<String, dynamic> j) => RoutineDef(
        id: j['id'] as String,
        base: j['base'] as String?,
        name: j['name'] as String?,
        cover: j['cover'] as String,
        tint: j['tint'] as int,
        therapy: (j['therapy'] as bool?) ?? false,
        who: j['who'] as String?,
        skipIf: (j['skipIf'] as List?)?.map((e) => e as String).toList(),
        hidden: (j['hidden'] as bool?) ?? false,
        steps: [for (final s in (j['steps'] as List)) StepDef.fromJson(s as Map<String, dynamic>)],
      );

  static RoutineDef fromTemplate(Routine t, {String? id, bool hidden = false}) => RoutineDef(
        id: id ?? t.id,
        base: t.id,
        cover: t.cover,
        tint: t.tint.toARGB32(),
        therapy: t.therapy,
        skipIf: skipIfDefault[t.id],
        hidden: hidden,
        steps: [for (var i = 0; i < t.steps.length; i++) StepDef(src: i, img: t.steps[i].img, tint: t.steps[i].tint.toARGB32())],
      );
}

class Note {
  Note({required this.id, required this.kid, required this.date, required this.ts, required this.text, this.audio});
  final String id;
  final String kid;
  final String date;
  final int ts;
  final String text;
  final String? audio; // path of the voice recording on the device

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
  final RoutineDef r;
  final String t;
}

const List<int> kidTints = [0xFFE2F1EF, 0xFFFBECE4, 0xFFF1EBF8, 0xFFE5F1F7, 0xFFFBF3DC, 0xFFE9F3E5];

/// Everything the app remembers: profiles, each child's routines and schedule, today's progress, notes.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'imm-state-1';
  static const _wiped = 'imm-wiped';

  List<Kid> kids = [];
  Map<String, Map<String, Sched>> sched = {};
  Map<String, RoutineDef> rdef = {}; // "kid|rid"
  Map<String, List<bool>> progress = {};
  Map<String, List<String>> rorder = {};
  List<Note> notes = [];
  int simDay = 0;
  String ui = 'it';
  bool micOk = false;

  /// The child who is playing now
  String kidId = '';

  /// Parents' area was opened from the child's screens – shows «Torna al gioco»
  bool cameFromChild = false;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(prefs);
    final raw = prefs.getString(_key);
    var loaded = false;
    if (raw != null) {
      try {
        s._fromJson(jsonDecode(raw) as Map<String, dynamic>);
        loaded = true;
      } catch (_) {}
    }
    if (!loaded && prefs.getBool(_wiped) != true) s._seedDemo();
    s._migrate();
    s.kidId = s.kids.isNotEmpty ? s.kids.first.id : '';
    return s;
  }

  /// Ostap's profile with the family's routines – the starting data of this build
  void _seedDemo() {
    kids = [Kid(id: 'ostap', name: 'Ostap', av: 'ostap', tint: 0xFFE2F1EF, lang: 'it', img: true)];
    sched = {
      'ostap': {for (final e in defaultSchedule().entries) e.key: Sched.fromJson(e.value)},
    };
  }

  /// Older saves kept step order and names apart from the routines – fold them into each child's copy
  void _migrate() {
    for (final k in kids) {
      for (final rid in (sched[k.id] ?? {}).keys) {
        final key = '${k.id}|$rid';
        if (rdef.containsKey(key)) continue;
        final t = routines.where((r) => r.id == rid).firstOrNull;
        if (t == null) continue;
        final d = RoutineDef.fromTemplate(t, hidden: k.id == 'ostap' && hiddenForChild.contains(rid));
        final ord = _oldOrder[key];
        if (ord != null && ord.length == d.steps.length) {
          d.steps = [for (final i in ord) d.steps[i]];
          for (final pk in progress.keys.toList()) {
            final a = pk.split('|');
            if (a[0] == k.id && a.length == 3 && a[2] == rid && progress[pk]!.length == ord.length) {
              final old = progress[pk]!;
              progress[pk] = [for (final i in ord) old[i]];
            }
          }
        }
        final nm = _oldNames[key];
        if (nm != null) {
          for (final st in d.steps) {
            final n = st.src != null && st.src! < nm.length ? nm[st.src!] : null;
            if (n != null && n.isNotEmpty) st.name = n;
          }
        }
        rdef[key] = d;
      }
    }
    _oldOrder.clear();
    _oldNames.clear();
    // therapy routines got the blue communication book as their picture
    for (final d in rdef.values) {
      if ((d.base == 'logo' || d.base == 'fisio') && (d.cover == 'blocks' || d.cover == 'teddy')) d.cover = 'commbook';
    }
    // once: speech therapy gets the play table with puzzles
    if (coverRev < 1) {
      for (final d in rdef.values) {
        if (d.base == 'logo' && d.cover == 'commbook') d.cover = 'appt_table';
      }
      coverRev = 1;
    }
  }

  final Map<String, List<int>> _oldOrder = {};
  final Map<String, List<String?>> _oldNames = {};

  void _fromJson(Map<String, dynamic> j) {
    kids = [for (final k in (j['kids'] as List)) Kid.fromJson(k as Map<String, dynamic>)];
    sched = {
      for (final e in (j['sched'] as Map<String, dynamic>).entries)
        e.key: {for (final r in (e.value as Map<String, dynamic>).entries) r.key: Sched.fromJson(r.value as Map<String, dynamic>)},
    };
    progress = {for (final e in (j['progress'] as Map<String, dynamic>).entries) e.key: [for (final v in (e.value as List)) v == true]};
    rorder = {for (final e in ((j['rorder'] as Map<String, dynamic>?) ?? {}).entries) e.key: [for (final v in (e.value as List)) v as String]};
    rdef = {for (final e in ((j['rdef'] as Map<String, dynamic>?) ?? {}).entries) e.key: RoutineDef.fromJson(e.value as Map<String, dynamic>)};
    for (final e in ((j['order'] as Map<String, dynamic>?) ?? {}).entries) {
      _oldOrder[e.key] = [for (final v in (e.value as List)) v as int];
    }
    for (final e in ((j['names'] as Map<String, dynamic>?) ?? {}).entries) {
      _oldNames[e.key] = [for (final v in (e.value as List)) v as String?];
    }
    notes = [for (final n in (j['notes'] as List)) Note.fromJson(n as Map<String, dynamic>)];
    simDay = (j['simDay'] as int?) ?? 0;
    ui = (j['ui'] as String?) ?? 'it';
    micOk = (j['micOk'] as bool?) ?? false;
    coverRev = (j['coverRev'] as int?) ?? 0;
  }

  /// which one-time cover updates were already applied
  int coverRev = 0;

  Map<String, dynamic> _toJson() => {
        'kids': [for (final k in kids) k.toJson()],
        'sched': {for (final e in sched.entries) e.key: {for (final r in e.value.entries) r.key: r.value.toJson()}},
        'rdef': {for (final e in rdef.entries) e.key: e.value.toJson()},
        'progress': progress,
        'rorder': rorder,
        'notes': [for (final n in notes) n.toJson()],
        'simDay': simDay,
        'ui': ui,
        'coverRev': coverRev,
        'micOk': micOk,
      };

  void save({bool notify = true}) {
    _prefs.setString(_key, jsonEncode(_toJson()));
    if (notify) notifyListeners();
  }

  // ---------- Profiles ----------
  Kid? kidOrNull(String id) => kids.where((k) => k.id == id).firstOrNull;
  Kid kidBy(String id) => kidOrNull(id) ?? (kids.isNotEmpty ? kids.first : Kid(id: '', name: '', av: 'ostap', tint: kidTints.first, lang: ui, img: true));
  Kid get kid => kidBy(kidId);

  /// Language of the child's screens
  String get lang => kid.lang;

  String addKid({required String name, required String av, String? photo, required String lang, required List<String> templates}) {
    final id = 'k${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    kids.add(Kid(id: id, name: name.trim(), av: av, photo: photo, tint: kidTints[kids.length % kidTints.length], lang: lang, img: true));
    sched[id] = {};
    for (final t in templates) {
      addRoutineFrom(id, t, notify: false);
    }
    if (kidId.isEmpty || kidOrNull(kidId) == null) kidId = id;
    save();
    return id;
  }

  void deleteKid(String id) {
    final pre = '$id|';
    kids.removeWhere((k) => k.id == id);
    sched.remove(id);
    rorder.remove(id);
    rdef.removeWhere((k, _) => k.startsWith(pre));
    progress.removeWhere((k, _) => k.startsWith(pre));
    notes.removeWhere((n) => n.kid == id);
    if (kidId == id) kidId = kids.isNotEmpty ? kids.first.id : '';
    save();
  }

  void updateKid(String id, void Function(Kid k) change) {
    change(kidBy(id));
    save();
  }

  // ---------- Texts ----------
  String tr(String key) => uiText[lang]![key] ?? key;
  String l(String it, String uk) => ui == 'uk' ? uk : it;
  String voice() => voiceOf[lang]!;

  RoutineDef? def(String k, String rid) => rdef['$k|$rid'];

  String routineName(String rid, [String? lg, String? k]) {
    final d = def(k ?? kidId, rid);
    if (d == null) return '';
    return d.name ?? routineNames[lg ?? lang]![d.base] ?? '';
  }

  String stepName(String k, String rid, int i, [String? lg]) {
    final d = def(k, rid);
    if (d == null || i >= d.steps.length) return '';
    final s = d.steps[i];
    if (s.name != null && s.name!.isNotEmpty) return s.name!;
    final list = stepNames[lg ?? lang]![d.base];
    return (list != null && s.src != null && s.src! < list.length) ? list[s.src!] : '';
  }

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
  List<RoutineDef> kidRoutines(String k) {
    final o = rorder[k] ?? const <String>[];
    int pos(String id) {
      final i = o.indexOf(id);
      final b = routines.indexWhere((r) => r.id == id);
      return i < 0 ? 999 + (b < 0 ? 500 : b) : i;
    }

    final ids = (sched[k] ?? {}).keys.where((id) => rdef.containsKey('$k|$id')).toList()..sort((a, b) => pos(a) - pos(b));
    return [for (final id in ids) rdef['$k|$id']!];
  }

  /// What the child sees: routines that are switched on and have steps
  List<RoutineDef> childRoutines() => kidRoutines(kidId).where((r) => !r.hidden && r.steps.isNotEmpty).toList();

  List<RoutineAt> routinesOn(String k, DateTime date) {
    final dw = dowOf(date);
    final list = <RoutineAt>[];
    for (final r in kidRoutines(k)) {
      final slots = schedOf(k, r.id)!.slots.where((s) => s.d == dw);
      if (slots.isNotEmpty) list.add(RoutineAt(r, slots.first.t));
    }
    // on a therapy day the therapy routine takes the place of "Vado a scuola"
    final out = list.where((x) {
      final skip = x.r.skipIf;
      return skip == null || !skip.any((id) => list.any((y) => y.r.id == id));
    }).toList();
    out.sort((a, b) => toMin(a.t) - toMin(b.t));
    return out;
  }

  String _pKey(String k, DateTime d, String rid) => '$k|${dateKey(d)}|$rid';
  List<bool> progOf(String k, DateTime d, String rid) {
    final n = def(k, rid)?.steps.length ?? 0;
    final p = progress[_pKey(k, d, rid)];
    if (p == null || p.length != n) return List<bool>.filled(n, false);
    return p;
  }

  bool isDoneOn(String k, DateTime d, String rid) {
    final p = progOf(k, d, rid);
    return p.isNotEmpty && p.every((x) => x);
  }

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

  /// every saved day of one routine, so the marks follow the steps when they move
  void _eachProgress(String k, String rid, void Function(List<bool> p) f) {
    final n = def(k, rid)?.steps.length;
    for (final e in progress.entries) {
      final a = e.key.split('|');
      if (a.length == 3 && a[0] == k && a[2] == rid && e.value.length == n) f(e.value);
    }
  }

  void moveStep(String k, String rid, int from, int to) {
    if (from == to) return;
    final d = def(k, rid)!;
    _eachProgress(k, rid, (p) {
      final y = p.removeAt(from);
      p.insert(to, y);
    });
    final x = d.steps.removeAt(from);
    d.steps.insert(to, x);
    save();
  }

  void removeStep(String k, String rid, int i) {
    final d = def(k, rid)!;
    _eachProgress(k, rid, (p) => p.removeAt(i));
    d.steps.removeAt(i);
    save();
  }

  void addStep(String k, String rid, StepDef s) {
    final d = def(k, rid)!;
    _eachProgress(k, rid, (p) => p.add(false));
    d.steps.add(s);
    save();
  }

  void setStepName(String k, String rid, int i, String name) {
    final s = def(k, rid)!.steps[i];
    s.name = name.trim().isEmpty ? null : name.trim();
    save(notify: false);
  }

  String addRoutineFrom(String k, String base, {bool notify = true}) {
    final t = routines.firstWhere((r) => r.id == base);
    var rid = base;
    if (sched[k]?.containsKey(rid) ?? false) rid = '${base}_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    rdef['$k|$rid'] = RoutineDef.fromTemplate(t, id: rid);
    final slots = defaultSchedule()[base]?['slots'] as List?;
    sched.putIfAbsent(k, () => {})[rid] = Sched(
      slots == null ? [for (var d = 1; d <= 7; d++) Slot(d, '08:00')] : [for (final x in slots) Slot((x as Map)['d'] as int, x['t'] as String)],
      false,
    );
    if (notify) save();
    return rid;
  }

  String addBlankRoutine(String k) {
    final rid = 'c${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    rdef['$k|$rid'] = RoutineDef(id: rid, name: l('Nuova routine', 'Нова рутина'), cover: 'sun', tint: 0xFFE9F3E5, steps: []);
    sched.putIfAbsent(k, () => {})[rid] = Sched([for (var d = 1; d <= 7; d++) Slot(d, '09:00')], false);
    save();
    return rid;
  }

  void deleteRoutine(String k, String rid) {
    rdef.remove('$k|$rid');
    sched[k]?.remove(rid);
    rorder[k]?.remove(rid);
    progress.removeWhere((key, _) {
      final a = key.split('|');
      return a.length == 3 && a[0] == k && a[2] == rid;
    });
    save();
  }

  void updateRoutine(String k, String rid, void Function(RoutineDef d) change, {bool notify = true}) {
    change(def(k, rid)!);
    save(notify: notify);
  }

  void setRoutineOrder(String k, List<String> ids) {
    rorder[k] = ids;
    save();
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

  /// «Elimina tutti i dati»: the app opens as if just installed
  Future<void> wipeAll() async {
    await _prefs.remove(_key);
    await _prefs.setBool(_wiped, true);
    kids = [];
    sched = {};
    rdef = {};
    progress = {};
    rorder = {};
    notes = [];
    simDay = 0;
    micOk = false;
    kidId = '';
    cameFromChild = false;
    notifyListeners();
  }

  /// prototype only: Ostap's profile back
  Future<void> restoreDemo() async {
    await _prefs.remove(_wiped);
    kids = [];
    sched = {};
    rdef = {};
    progress = {};
    rorder = {};
    notes = [];
    _seedDemo();
    _migrate();
    kidId = kids.first.id;
    save();
  }

  void clearWiped() => _prefs.remove(_wiped);
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
