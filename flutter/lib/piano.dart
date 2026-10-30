// PIANOFORTE – a toy piano for the child.
// Eight wide rainbow keys; above them a board of soft square "lights".
// «Note» mode: each key plays a note and a column of its colour rises and slowly fades.
// «Classica» mode: each key plays a short classical melody, and its notes light up the board.
// No flashing: lights come up and go down smoothly. Several fingers can play at once.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app_state.dart';
import 'ui.dart';

const List<String> _notes = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'];
/// «Classica» mode: each key plays a short public-domain melody (rendered from the notes
/// with the same piano samples). [notes] = pairs of (ms from start, board column 0–7).
class _Piece {
  const _Piece(this.snd, this.ms, this.it, this.uk, this.notes);
  final String snd;
  final int ms;
  final String it, uk;
  final List<int> notes;
}

const List<_Piece> _pieces = [
  _Piece('cl_ode', 12380, 'Inno alla gioia – Beethoven', '«Ода до радості» – Бетховен', [50, 4, 410, 4, 770, 5, 1130, 7, 1489, 7, 1849, 5, 2209, 4, 2569, 2, 2929, 0, 3289, 0, 3649, 2, 4009, 4, 4369, 4, 4909, 2, 5089, 2, 5809, 4, 6169, 4, 6529, 5, 6890, 7, 7250, 7, 7610, 5, 7970, 4, 8330, 2, 8690, 0, 9049, 0, 9409, 2, 9769, 4, 10129, 2, 10669, 0, 10849, 0]),
  _Piece('cl_twinkle', 14480, 'Ah vous dirai-je, maman – Mozart', '«Ah vous dirai-je, maman» – Моцарт', [50, 0, 390, 0, 730, 5, 1070, 5, 1410, 7, 1750, 7, 2090, 5, 2770, 4, 3110, 4, 3450, 3, 3790, 3, 4130, 2, 4470, 2, 4810, 0, 5489, 5, 5829, 5, 6169, 4, 6509, 4, 6849, 3, 7189, 3, 7529, 2, 8209, 0, 8549, 0, 8889, 5, 9229, 5, 9569, 7, 9909, 7, 10249, 5, 10929, 4, 11269, 4, 11609, 3, 11949, 3, 12289, 2, 12629, 2, 12969, 0]),
  _Piece('cl_lullaby', 11280, 'Ninna nanna – Brahms', 'Колискова – Брамс', [50, 1, 260, 1, 470, 4, 1310, 1, 1520, 1, 1730, 4, 2570, 1, 2780, 4, 2989, 7, 3409, 6, 4040, 5, 4250, 5, 4670, 4, 5090, 0, 5300, 1, 5510, 2, 5930, 0, 6350, 0, 6560, 1, 6770, 2, 7609, 0, 7819, 2, 8029, 6, 8240, 5, 8450, 4, 8870, 6, 9290, 7]),
  _Piece('cl_turca', 8480, 'Marcia turca – Mozart', '«Турецький марш» – Моцарт', [50, 1, 169, 0, 290, 0, 410, 0, 530, 2, 1010, 3, 1130, 2, 1250, 1, 1370, 2, 1490, 4, 1970, 4, 2090, 4, 2210, 3, 2330, 4, 2450, 7, 2570, 6, 2690, 5, 2810, 6, 2930, 7, 3050, 6, 3170, 5, 3290, 6, 3410, 7, 3890, 6, 4130, 7, 4370, 7, 4610, 6, 4850, 5, 5090, 6, 5330, 7, 5570, 6, 5810, 5, 6050, 6, 6290, 7, 6530, 6, 6770, 5, 7010, 4, 7250, 4]),
  _Piece('cl_nacht', 8080, 'Piccola serenata notturna – Mozart', '«Маленька нічна серенада» – Моцарт', [50, 3, 500, 0, 650, 3, 1099, 0, 1249, 3, 1399, 0, 1549, 3, 1699, 5, 1849, 7, 2449, 6, 2899, 4, 3049, 6, 3499, 4, 3649, 6, 3799, 4, 3949, 2, 4099, 4, 4249, 0, 4849, 3, 4999, 3, 5149, 5, 5300, 4, 5450, 3, 5600, 3, 5750, 5, 5900, 4, 6050, 3, 6200, 5, 6350, 7, 6500, 5, 6650, 3]),
  _Piece('cl_spring', 9180, 'La primavera – Vivaldi', '«Весна» – Вівальді', [50, 0, 310, 4, 570, 4, 830, 4, 1090, 2, 1220, 0, 1350, 7, 2130, 7, 2260, 5, 2389, 4, 2649, 4, 2909, 4, 3169, 2, 3299, 0, 3429, 7, 4209, 7, 4339, 5, 4469, 4, 4729, 5, 4859, 7, 4989, 5, 5249, 4, 5509, 2, 6289, 0, 6549, 4, 6809, 4, 7069, 4, 7329, 2, 7459, 0, 7589, 0]),
  _Piece('cl_morning', 9500, 'Il mattino – Grieg', '«Ранок» – Гріг', [50, 5, 410, 3, 770, 2, 1130, 0, 1489, 2, 1849, 3, 2209, 5, 2569, 3, 2929, 2, 3289, 0, 3649, 2, 3829, 3, 4009, 2, 4189, 3, 4369, 5, 4729, 3, 5089, 5, 5449, 7, 5810, 3, 6170, 7, 6530, 5, 6890, 3, 7250, 2, 7610, 0]),
  _Piece('cl_minuet', 11610, 'Minuetto in sol – Petzold', 'Менует соль мажор – Петцольд', [50, 4, 450, 1, 650, 2, 850, 3, 1050, 3, 1250, 4, 1650, 1, 2050, 1, 2449, 5, 2849, 3, 3050, 4, 3250, 5, 3450, 6, 3650, 7, 4050, 1, 4450, 1, 4850, 3, 5250, 4, 5450, 3, 5650, 3, 5850, 2, 6050, 3, 6450, 3, 6650, 3, 6850, 2, 7050, 1, 7250, 2, 7650, 3, 7850, 2, 8050, 1, 8250, 0, 8450, 1]),
];
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
const String _icClassic = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M8 18V6l11-2.5v12" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 9.5l11-2.5" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><circle cx="5.5" cy="18" r="2.5" fill="currentColor"/><circle cx="16.5" cy="15.5" r="2.5" fill="currentColor"/></svg>';

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
  _Light(this.key, this.start, {this.piece = false});
  final int key;
  final Duration start;
  final bool piece;
}

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> with SingleTickerProviderStateMixin {
  bool _classicMode = false;
  final _pool = _NotePool();
  final List<_Light> _lights = [];
  final Map<int, int> _down = {}; // pointer → key
  late final Ticker _ticker;
  Duration _now = Duration.zero;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _ticker = createTicker((t) {
      _now = t;
      // lights that have fully faded are dropped; the ticker sleeps when nothing is lit
      _lights.removeWhere((l) => _now - l.start > (l.piece ? Duration(milliseconds: _pieces[l.key].ms + 1200) : _barLife));
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

  void _press(int pointer, int key) {
    _down[pointer] = key;
    if (!_ticker.isActive) {
      _now = Duration.zero;
      _lights.clear();
      _ticker.start();
    }
    if (_classicMode) {
      // one melody at a time: a new key stops the one that is playing
      _lights.removeWhere((l) => l.piece);
      _lights.add(_Light(key, _now, piece: true));
      Sound.instance.play(_pieces[key].snd);
    } else {
      _lights.add(_Light(key, _now));
      _pool.play(_notes[key]);
    }
    setState(() {});
  }

  void _lift(int pointer) {
    if (_down.remove(pointer) != null) setState(() {});
  }

  void _setMode(bool classic) {
    if (classic == _classicMode) return;
    Sound.instance.stop();
    setState(() {
      _classicMode = classic;
      _lights.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final phone = isPhone(context);
    Widget modeBtn(bool classic, String svg, String label) {
      final on = _classicMode == classic;
      return Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          onTap: () => _setMode(classic),
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
          modeBtn(true, _icClassic, s.tr('pianoClassic')),
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
              painter: _BoardPainter(lights: List.of(_lights), now: _now),
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
        label: _classicMode ? AppScope.of(context).l(_pieces[i].it, _pieces[i].uk) : _notes[i],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
          decoration: BoxDecoration(
            color: pressed ? Color.lerp(c, Colors.black, 0.08) : c,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10), bottom: Radius.circular(22)),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(8),
          child: _classicMode ? Opacity(opacity: 0.85, child: icon(_icClassic, 30, Colors.white)) : null,
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
  _BoardPainter({required this.lights, required this.now});
  final List<_Light> lights;
  final Duration now;

  @override
  void paint(Canvas canvas, Size size) {
    // cells fill the whole board, so every column stands right above its key
    final cw = size.width / _cols, ch = size.height / _rows;
    final g = math.min(cw, ch) * 0.06; // gap between cells
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

    for (final l in lights) {
      final t0 = l.start.inMilliseconds;
      if (l.piece) {
        // the melody: each note lights a short column in its own colour, higher notes to the right
        final n = _pieces[l.key].notes;
        for (var i = 0; i + 1 < n.length; i += 2) {
          final at = t0 + n[i], col = n[i + 1];
          if (now.inMilliseconds < at) break;
          final height = 1 + (col * (_rows - 1) / 7).round();
          for (var k = 0; k < height; k++) {
            lit(_rows - 1 - k, col, _glow(now, at + k * 30, at + 260 + k * 20, 550), keyColors[col]);
          }
        }
        continue;
      }
      // a column of the key's colour above the key: higher notes reach higher
      final height = 1 + (l.key * (_rows - 1) / 7).round();
      for (var k = 0; k < height; k++) {
        final v = _glow(now, t0 + k * 45, t0 + 900 + k * 25, 800);
        lit(_rows - 1 - k, l.key, v, keyColors[l.key]);
      }
    }

    // every cell is a little square lamp: unlit it is soft matte glass, lit it glows from a
    // bright centre into the key's colour and spills a soft halo of that colour around it
    final halo = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.18);
    final lamp = Paint();
    final shine = Paint();
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final rect = cellRect(r, c);
        final rr = round(rect);
        final v = level[r][c];
        final col = color[r][c];
        lamp.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFF4ECDF), _off, Color(0xFFE3D7C2)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);
        canvas.drawRRect(rr, lamp);
        if (v <= 0) continue;
        halo.color = col.withOpacity(0.5 * v);
        canvas.drawRRect(round(rect.inflate(cell * 0.06)), halo);
        lamp.shader = RadialGradient(
          radius: 0.75,
          colors: [
            Color.lerp(col, Colors.white, 0.8)!.withOpacity(v),
            Color.lerp(col, Colors.white, 0.3)!.withOpacity(v),
            col.withOpacity(v),
            Color.lerp(col, Colors.black, 0.1)!.withOpacity(v),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ).createShader(rect);
        canvas.drawRRect(rr, lamp);
        // a soft reflection along the top, like on glass
        shine.color = Colors.white.withOpacity(0.45 * v);
        final w = rect.width, h = rect.height;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + w * 0.16, rect.top + h * 0.1, w * 0.4, h * 0.12), Radius.circular(h * 0.06)),
          shine,
        );
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
