// PIANOFORTE – a toy piano for the child.
// Eight wide rainbow keys; above them a board of soft square "lights".
// «Note» mode: each key plays a note and a column of its colour rises and slowly fades.
// «Animali» mode: each key shows a pixel animal on the board and plays its voice.
// No flashing: lights come up and go down smoothly. Several fingers can play at once.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app_state.dart';
import 'ui.dart';

const List<String> _notes = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'];
const List<String> _animals = ['dog', 'owl', 'cat', 'cow', 'pig', 'horse', 'rooster', 'bird'];
// voices from assets/snd; the dog and the cat are waiting for Nina's own recordings (dog.mp3, cat.mp3)
const Set<String> _withSound = {'dog', 'owl', 'cat', 'cow', 'pig', 'horse', 'rooster', 'bird'};
const List<Color> keyColors = [
  Color(0xFFEF6B5E), // red
  Color(0xFFF59A45), // orange
  Color(0xFFF5CD4C), // yellow
  Color(0xFF7CC576), // green
  Color(0xFF4FB8AE), // teal
  Color(0xFF4A9FDB), // blue
  Color(0xFF9B7FD8), // violet
  Color(0xFFF08DB4), // pink
];

// big cells: one column per key, so the child can follow what lights up
const int _cols = 8;
const int _rows = 7;
const Color _board = Color(0xFFF7F0E3);
const Color _off = Color(0xFFEDE3D1);

const String _icNote = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M9 18.5a2.5 2.5 0 1 1-2.5-2.5H9V5l10-2v13" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><circle cx="16.5" cy="16" r="2.5" stroke="currentColor" stroke-width="2.2"/></svg>';
const String _icPaw = r'<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><ellipse cx="7" cy="8.5" rx="2" ry="2.6"/><ellipse cx="12" cy="6.5" rx="2" ry="2.6"/><ellipse cx="17" cy="8.5" rx="2" ry="2.6"/><ellipse cx="4.5" cy="13.2" rx="1.8" ry="2.3"/><ellipse cx="19.5" cy="13.2" rx="1.8" ry="2.3"/><path d="M12 11.5c-3 0-6 3.6-6 6.2 0 1.7 1.4 2.3 3 2.3 1.2 0 2-.6 3-.6s1.8.6 3 .6c1.6 0 3-.6 3-2.3 0-2.6-3-6.2-6-6.2Z"/></svg>';

/// Short notes, several at a time
class _NotePool {
  _NotePool() {
    for (var i = 0; i < 6; i++) {
      final p = AudioPlayer();
      if (!kIsWeb) p.setPlayerMode(PlayerMode.lowLatency);
      p.setReleaseMode(ReleaseMode.stop);
      _players.add(p);
    }
  }
  final List<AudioPlayer> _players = [];
  int _next = 0;

  void play(String note) {
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    p.stop().then((_) => p.play(AssetSource('snd/note_$note.mp3'))).catchError((_) {});
  }

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}

class _Light {
  _Light(this.key, this.start, {this.animal = false});
  final int key;
  final Duration start;
  final bool animal;
}

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> with SingleTickerProviderStateMixin {
  bool _animalsMode = false;
  final _pool = _NotePool();
  final List<_Light> _lights = [];
  final Map<int, int> _down = {}; // pointer → key
  late final Ticker _ticker;
  Duration _now = Duration.zero;

  final Map<String, ui.Image> _faces = {};

  Future<void> _loadFaces() async {
    for (final a in _animals) {
      try {
        final data = await rootBundle.load('assets/img/face_$a.webp');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 512);
        _faces[a] = (await codec.getNextFrame()).image;
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadFaces();
    WakelockPlus.enable();
    _ticker = createTicker((t) {
      _now = t;
      // lights that have fully faded are dropped; the ticker sleeps when nothing is lit
      _lights.removeWhere((l) => _now - l.start > (l.animal ? _animalLife : _barLife));
      setState(() {});
      if (_lights.isEmpty) _ticker.stop();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pool.dispose();
    Sound.instance.stop(notify: false);
    WakelockPlus.disable();
    super.dispose();
  }

  static const _barLife = Duration(milliseconds: 1900);
  static const _animalLife = Duration(milliseconds: 3600);

  void _press(int pointer, int key) {
    _down[pointer] = key;
    if (!_ticker.isActive) {
      _now = Duration.zero;
      _lights.clear();
      _ticker.start();
    }
    if (_animalsMode) {
      _lights.removeWhere((l) => l.animal);
      _lights.add(_Light(key, _now, animal: true));
      if (_withSound.contains(_animals[key])) {
        Sound.instance.play(_animals[key]);
      } else {
        Sound.instance.stop();
      }
    } else {
      _lights.add(_Light(key, _now));
      _pool.play(_notes[key]);
    }
    setState(() {});
  }

  void _lift(int pointer) {
    if (_down.remove(pointer) != null) setState(() {});
  }

  void _setMode(bool animals) {
    if (animals == _animalsMode) return;
    Sound.instance.stop();
    setState(() {
      _animalsMode = animals;
      _lights.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final phone = isPhone(context);
    Widget modeBtn(bool animals, String svg, String label) {
      final on = _animalsMode == animals;
      return Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          onTap: () => _setMode(animals),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: phone ? 52 : 64,
            height: phone ? 52 : 64,
            decoration: BoxDecoration(color: on ? C.success : C.nav, shape: BoxShape.circle),
            child: Center(child: icon(svg, phone ? 26 : 32, on ? Colors.white : C.navInk)),
          ),
        ),
      );
    }

    return Frame(
      head: Head(
        title: s.tr('piano'),
        onBack: () {
          Sound.instance.stop();
          Navigator.of(context).maybePop();
        },
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          modeBtn(false, _icNote, s.tr('pianoNotes')),
          const SizedBox(width: 12),
          modeBtn(true, _icPaw, s.tr('pianoAnimals')),
        ]),
      ),
      body: Container(
        padding: EdgeInsets.all(phone ? 12 : 20),
        decoration: BoxDecoration(color: _board, borderRadius: BorderRadius.circular(rCard)),
        child: Column(children: [
          Expanded(
            flex: 5,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BoardPainter(lights: List.of(_lights), now: _now, faces: _faces),
            ),
          ),
          SizedBox(height: phone ? 12 : 20),
          Expanded(
            flex: isPortrait(context) ? 6 : 4,
            child: isPortrait(context)
                // standing tablet: two rows of four wide keys, low notes on top
                ? Column(children: [
                    for (var row = 0; row < 2; row++) ...[
                      if (row > 0) SizedBox(height: phone ? 8 : 12),
                      Expanded(
                        child: Row(children: [
                          for (var i = row * 4; i < row * 4 + 4; i++) ...[
                            if (i > row * 4) SizedBox(width: phone ? 8 : 12),
                            Expanded(child: _key(i)),
                          ],
                        ]),
                      ),
                    ],
                  ])
                : Row(children: [
                    for (var i = 0; i < 8; i++) ...[
                      if (i > 0) SizedBox(width: phone ? 6 : 10),
                      Expanded(child: _key(i)),
                    ],
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _key(int i) {
    final pressed = _down.values.contains(i);
    final c = keyColors[i];
    return Listener(
      onPointerDown: (e) => _press(e.pointer, i),
      onPointerUp: (e) => _lift(e.pointer),
      onPointerCancel: (e) => _lift(e.pointer),
      child: Semantics(
        button: true,
        label: _animalsMode ? _animals[i] : _notes[i],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
          decoration: BoxDecoration(
            color: pressed ? Color.lerp(c, Colors.black, 0.08) : c,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(22)),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(8),
          child: _animalsMode
              ? AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/img/face_${_animals[i]}.webp', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                )
              : null,
        ),
      ),
    );
  }
}

/// Smooth 0…1…0 brightness of a cell that lights at [on] and starts fading at [off]
double _glow(Duration now, int onMs, int offMs, int fadeMs) {
  final t = now.inMilliseconds;
  if (t < onMs) return 0;
  if (t < onMs + 90) return (t - onMs) / 90;
  if (t < offMs) return 1;
  if (t < offMs + fadeMs) return 1 - (t - offMs) / fadeMs;
  return 0;
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.lights, required this.now, required this.faces});
  final List<_Light> lights;
  final Duration now;
  final Map<String, ui.Image> faces;

  @override
  void paint(Canvas canvas, Size size) {
    // cells fill the whole board, so every column stands right above its key
    final cw = size.width / _cols, ch = size.height / _rows;
    final g = math.min(cw, ch) * 0.12; // gap between cells
    const ox = 0.0, oy = 0.0;
    final cell = math.min(cw, ch);
    final level = List.generate(_rows, (_) => List<double>.filled(_cols, 0));
    final color = List.generate(_rows, (_) => List<Color>.filled(_cols, _off));
    Rect cellRect(int r, int c) => Rect.fromLTWH(ox + c * cw + g / 2, oy + r * ch + g / 2, cw - g, ch - g);
    RRect round(Rect r) => RRect.fromRectAndRadius(r, Radius.circular(cell * 0.16));

    void lit(int r, int c, double v, Color col) {
      if (r < 0 || r >= _rows || c < 0 || c >= _cols || v <= level[r][c]) return;
      level[r][c] = v;
      color[r][c] = col;
    }

    _Light? animal;
    for (final l in lights) {
      final t0 = l.start.inMilliseconds;
      if (l.animal) {
        animal = l;
        continue;
      }
      // a column of the key's colour above the key: higher notes reach higher
      final height = 1 + (l.key * (_rows - 1) / 7).round();
      for (var k = 0; k < height; k++) {
        final v = _glow(now, t0 + k * 45, t0 + 900 + k * 25, 800);
        lit(_rows - 1 - k, l.key, v, keyColors[l.key]);
      }
    }

    // every cell is a little lamp: a round bulb that, when lit, glows from a bright centre
    // and spills a soft halo of its colour around it
    final rad = cell * 0.40;
    final halo = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.22);
    final bulb = Paint();
    final shine = Paint();
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final o = cellRect(r, c).center;
        final v = level[r][c];
        final col = color[r][c];
        // unlit glass: a soft warm bead, a little lighter at the top
        bulb.shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: const [Color(0xFFF7F0E4), _off, Color(0xFFDCCFB8)],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: o, radius: rad));
        canvas.drawCircle(o, rad, bulb);
        if (v <= 0) continue;
        // halo
        halo.color = col.withOpacity(0.55 * v);
        canvas.drawCircle(o, rad * 1.25, halo);
        // the lit bulb: almost white in the middle, the key's colour towards the edge
        bulb.shader = RadialGradient(
          colors: [
            Color.lerp(col, Colors.white, 0.85)!.withOpacity(v),
            Color.lerp(col, Colors.white, 0.35)!.withOpacity(v),
            col.withOpacity(v),
            Color.lerp(col, Colors.black, 0.12)!.withOpacity(v),
          ],
          stops: const [0.0, 0.35, 0.8, 1.0],
        ).createShader(Rect.fromCircle(center: o, radius: rad));
        canvas.drawCircle(o, rad, bulb);
        // a tiny reflection, like on glass
        shine.color = Colors.white.withOpacity(0.7 * v);
        canvas.drawCircle(o + Offset(-rad * 0.38, -rad * 0.4), rad * 0.16, shine);
      }
    }

    // the animal: its clay face appears tile by tile, from the bottom row up
    final img = animal == null ? null : faces[_animals[animal.key]];
    if (animal != null && img != null) {
      final t0 = animal.start.inMilliseconds;
      final side = math.min(size.width, size.height); // a square picture in the middle of the board
      final pic = Rect.fromLTWH((size.width - side) / 2, (size.height - side) / 2, side, side);
      final sx = img.width / side, sy = img.height / side;
      final p = Paint()..filterQuality = FilterQuality.medium;
      for (var r = 0; r < _rows; r++) {
        for (var c = 0; c < _cols; c++) {
          final dst = cellRect(r, c);
          final part = dst.intersect(pic);
          if (part.width <= 0 || part.height <= 0) continue;
          final v = _glow(now, t0 + (_rows - 1 - r) * 70 + c * 18, t0 + 2900, 600);
          if (v <= 0) continue;
          final src = Rect.fromLTWH((part.left - pic.left) * sx, (part.top - pic.top) * sy, part.width * sx, part.height * sy);
          canvas.save();
          canvas.clipRRect(round(dst));
          p.color = Color.fromRGBO(255, 255, 255, v);
          canvas.drawImageRect(img, src, part, p);
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}

/// Picture for the child's home card: rainbow keys and a few lit columns
class PianoArt extends StatelessWidget {
  const PianoArt({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        return Padding(
          padding: EdgeInsets.all(box.maxWidth * 0.08),
          child: CustomPaint(size: Size.infinite, painter: _ArtPainter()),
        );
      });
}

class _ArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = 16, rows = 7;
    final keyH = size.height * 0.36;
    final boardH = size.height - keyH - size.height * 0.06;
    final cell = math.min(size.width / cols, boardH / rows);
    final ox = (size.width - cell * cols) / 2;
    const heights = [2, 4, 3, 6, 5, 7, 4, 3];
    final p = Paint();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final k = c ~/ 2;
        final on = rows - r <= heights[k];
        p.color = on ? keyColors[k] : _off;
        final rect = Rect.fromLTWH(ox + c * cell + cell * 0.08, boardH - (rows - r) * cell + cell * 0.08, cell * 0.84, cell * 0.84);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18)), p);
      }
    }
    final kw = (cell * cols - 7 * cell * 0.3) / 8;
    for (var k = 0; k < 8; k++) {
      p.color = keyColors[k];
      final rect = Rect.fromLTWH(ox + k * (kw + cell * 0.3), size.height - keyH, kw, keyH);
      canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: Radius.circular(kw * 0.15), topRight: Radius.circular(kw * 0.15), bottomLeft: Radius.circular(kw * 0.3), bottomRight: Radius.circular(kw * 0.3)), p);
    }
  }

  @override
  bool shouldRepaint(_ArtPainter old) => false;
}
