import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app_state.dart';
import 'data.dart';
import 'ui.dart';

void _go(BuildContext context, Widget screen) {
  Sound.instance.stop();
  Navigator.of(context).push(PageRouteBuilder<void>(
    pageBuilder: (_, __, ___) => screen,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

/// The lock on the child's home: back to the parents' area (the first screen), with «Torna al gioco»
void openParents(BuildContext context) {
  Sound.instance.stop();
  final s = AppScope.of(context);
  s.cameFromChild = true;
  s.save();
  Navigator.of(context).popUntil((r) => r.isFirst);
}

/// Opens the child's home for a kid (from the parents' area)
void startPlay(BuildContext context, String kidId) {
  final s = AppScope.of(context);
  s.kidId = kidId;
  s.cameFromChild = false;
  s.save();
  _go(context, const HomeScreen());
}

/// Parents' preview of a routine – exactly what the child sees
void previewRoutine(BuildContext context, String kidId, String rid) {
  AppScope.of(context).kidId = kidId;
  _go(context, StepsScreen(rid: rid, preview: true));
}

void _back(BuildContext context) {
  Sound.instance.stop();
  Navigator.of(context).maybePop();
}

/// Keeps the screen on while a book or a routine is open
mixin _KeepAwake<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    Sound.instance.stop(notify: false);
    super.dispose();
  }
}

// =====================================================================
// HOME
// =====================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final portrait = isPortrait(context);
    final cards = [
      _SectionCard(
        color: C.cardGreen,
        image: 'book',
        title: s.tr('books'),
        subtitle: s.tr('booksSub'),
        onTap: () => _go(context, const ShelfScreen()),
      ),
      _SectionCard(
        color: C.cardWarm,
        image: 'day',
        title: s.tr('day'),
        subtitle: s.tr('daySub'),
        onTap: () => _go(context, const RoutinesScreen()),
      ),
    ];
    return PopScope(
      canPop: false,
      child: Frame(
        head: SizedBox(
          height: 72,
          child: Row(
            children: [
              Avatar(av: s.kid.av, photo: s.kid.photo),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PASETTO', style: ts(15, w: FontWeight.w600, color: C.ink2, spacing: 0.9)),
                    Text(s.tr('homeTitle'), style: ts(isPhone(context) ? 28 : 40), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              HoldButton(hint: s.tr('holdHint'), onOpen: () => openParents(context)),
            ],
          ),
        ),
        body: portrait
            ? Column(children: [Expanded(child: cards[0]), const SizedBox(height: 24), Expanded(child: cards[1])])
            : Row(children: [Expanded(child: cards[0]), const SizedBox(width: 32), Expanded(child: cards[1])]),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.color, required this.image, required this.title, required this.subtitle, required this.onTap});
  final Color color;
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CardPress(
        color: color,
        onTap: onTap,
        label: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(rImg)),
                clipBehavior: Clip.antiAlias,
                child: picture(image),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ts(isPhone(context) ? 20 : 24)),
                        Text(subtitle, style: ts(isPhone(context) ? 15 : 18, w: FontWeight.w600, color: C.ink2, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: soft3d(Colors.white, circle: true),
                    foregroundDecoration: soft3dOverlay(circle: true),
                    child: Center(child: icon(Ic.arrow, 24, C.ink)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Parents' area opens only after a 2-second hold, so a child's stray tap does not leave the child screens.
/// A short tap shows a hint.
class HoldButton extends StatefulWidget {
  const HoldButton({super.key, required this.hint, required this.onOpen});
  final String hint;
  final VoidCallback onOpen;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        _pointer = null;
        _c.value = 0;
        widget.onOpen();
      }
    });
  int? _pointer;
  bool _hint = false;
  int _hintToken = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    setState(() => _hint = false);
    _c.forward(from: 0);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_c.isAnimating) {
      _c.stop();
      _c.value = 0;
      final token = ++_hintToken;
      setState(() => _hint = true);
      Future<void>.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && token == _hintToken) setState(() => _hint = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.hint,
        child: Listener(
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: SizedBox(
            width: navSize,
            height: navSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: soft3d(C.nav, circle: true),
                  foregroundDecoration: soft3dOverlay(circle: true),
                  child: Center(child: icon(Ic.lock, 24, C.navInk)),
                ),
                Positioned(
                  left: -6,
                  top: -6,
                  right: -6,
                  bottom: -6,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) => CustomPaint(painter: _RingPainter(_c.value)),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: navSize + 10,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hint ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(12)),
                        child: Text(widget.hint, style: ts(16, color: Colors.white), softWrap: false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0) return;
    final p = Paint()
      ..color = C.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * v, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v;
}

// =====================================================================
// SOUND BOOKS – shelf
// =====================================================================
class ShelfScreen extends StatelessWidget {
  const ShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final portrait = isPortrait(context);
    return Frame(
      head: Head(title: s.tr('books'), onBack: () => _back(context)),
      body: LayoutBuilder(builder: (context, box) {
        const gap = 24.0;
        final cols = portrait ? 2 : 3;
        final vis = s.kid.books ?? List<int>.generate(books.length, (i) => i);
        final rows = math.max(1, (vis.length / cols).ceil());
        final w = ((box.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
        final h = ((box.maxHeight - gap * (rows - 1)) / rows).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final i in vis)
              SizedBox(
                width: w,
                height: h,
                child: _Tile(
                  color: bookTints[i],
                  image: bookCover(i),
                  scale: smallCovers.contains(bookCover(i)) ? 0.86 : 1,
                  title: bookNames[s.lang]![i],
                  onTap: () => _go(context, BookScreen(book: i)),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// Tile with a white cover and a title (books, routines)
class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.image, required this.title, required this.onTap, this.scale = 1, this.done = false});
  final Color color;
  final String image;
  final String title;
  final VoidCallback onTap;
  final double scale;
  final bool done;

  @override
  Widget build(BuildContext context) => CardPress(
        color: color,
        onTap: onTap,
        label: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(rImg)),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(child: FractionallySizedBox(heightFactor: scale, widthFactor: 1, child: picture(image))),
                    if (done) const Positioned(top: 12, right: 12, child: DoneBadge()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(title, style: ts(isPhone(context) ? 17 : 24), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

// =====================================================================
// SOUND BOOKS – one page
// =====================================================================
class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.book});
  final int book;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> with _KeepAwake<BookScreen> {
  int _page = 0;
  bool _pressed = false;
  bool _playing = false;
  int _playId = 0;
  int? _pointer;
  int _lastHit = 0;

  List<String> get _pages => books[widget.book];

  void _turn(int d) {
    Sound.instance.stop();
    setState(() {
      _page = math.max(0, math.min(_pages.length - 1, _page + d));
      _playId++;
      _playing = false;
    });
  }

  // Fires on touch (no need to release). The first finger or palm on the button or the picture counts,
  // further contacts are ignored while it stays down; taps closer than 300 ms are ignored.
  void _hit(PointerDownEvent e, {bool picture = false}) {
    if (picture && !AppScope.of(context).kid.img) return;
    if (_pointer != null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHit < 300) return;
    _lastHit = now;
    _pointer = e.pointer;
    setState(() => _pressed = true);
    _play();
  }

  void _release(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (mounted) setState(() => _pressed = false);
  }

  void _play() {
    // play() first ends the previous sound (its callback resets the flag), then the flag is set again
    // first the sound or music, then the name is said once (Nina, 26.10)
    final s = AppScope.of(context);
    final name = pageNames[s.lang]![widget.book][_page];
    final id = ++_playId;
    Sound.instance.play(_pages[_page], onEnd: () {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || !_playing || id != _playId) return;
        Sound.instance.speak(name, s.voice(), onEnd: () {
          if (mounted) setState(() => _playing = false);
        });
      });
    });
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final key = _pages[_page];
    final name = pageNames[s.lang]![widget.book][_page];
    final active = _pressed || _playing;
    return Frame(
      head: Head(
        title: bookNames[s.lang]![widget.book],
        onBack: () => _back(context),
        trailing: Text.rich(TextSpan(children: [
          TextSpan(text: '${_page + 1}', style: ts(20, color: C.ink)),
          TextSpan(text: ' / ${_pages.length}', style: ts(20, color: C.ink2)),
        ])),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NavBtn(svg: Ic.back, round: false, onTap: _page > 0 ? () => _turn(-1) : null),
              const SizedBox(width: 16),
              Expanded(child: Text(name, style: ts(isPhone(context) ? 28 : 36), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 16),
              NavBtn(svg: Ic.next, round: false, onTap: _page < _pages.length - 1 ? () => _turn(1) : null),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Listener(
              onPointerDown: (e) => _hit(e, picture: true),
              onPointerUp: _release,
              onPointerCancel: _release,
              child: Semantics(
                image: true,
                label: name,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(rCard)),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.scale(scale: 1.12, child: picture(key)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Listener(
              onPointerDown: _hit,
              onPointerUp: _release,
              onPointerCancel: _release,
              child: Semantics(
                button: true,
                label: s.tr('listen'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: isPhone(context) ? 148 : 200,
                  height: isPhone(context) ? 148 : 200,
                  transform: Matrix4.translationValues(0, _pressed ? 2 : (_playing ? 1 : 0), 0),
                  decoration: BoxDecoration(
                    color: active ? C.audioPlay : C.audio,
                    shape: BoxShape.circle,
                    boxShadow: _pressed ? const [] : const [BoxShadow(color: Color(0x382E628C), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  foregroundDecoration: soft3dOverlay(circle: true, pressed: _pressed),
                  child: Center(child: icon(Ic.listen, isPhone(context) ? 78 : 104, Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// LA MIA GIORNATA – catalog of routines
// =====================================================================
class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final portrait = isPortrait(context);
    final items = s.childRoutines();
    final n = items.length;
    final cols = portrait ? (n <= 2 ? 1 : 2) : (n <= 3 ? math.max(n, 1) : (n == 4 ? 2 : 3));
    return Frame(
      head: Head(title: s.tr('day'), onBack: () => _back(context), trailing: Avatar(av: s.kid.av, photo: s.kid.photo)),
      body: n == 0
          ? Center(child: Text(s.tr('noRoutines'), style: ts(28, color: C.ink2)))
          : LayoutBuilder(builder: (context, box) {
              const gap = 24.0;
              // Three rows fit on the screen; the fourth and later rows scroll
              final h = (box.maxHeight - gap * 2) / 3;
              return GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  mainAxisExtent: h,
                ),
                itemCount: n,
                itemBuilder: (context, i) {
                  final r = items[i];
                  return _Tile(
                    color: Color(r.tint),
                    image: r.cover,
                    title: s.routineName(r.id),
                    done: s.isDone(r.id),
                    onTap: () => _go(context, StepsScreen(rid: r.id)),
                  );
                },
              );
            }),
    );
  }
}

// =====================================================================
// ROUTINE – steps with a lamp button
// =====================================================================
class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key, required this.rid, this.preview = false});
  final String rid;
  final bool preview;

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> with _KeepAwake<StepsScreen> {
  int? _speaking;
  int _lastTap = 0;

  List<int> ord0(AppState s) => List<int>.generate(s.def(s.kidId, widget.rid)?.steps.length ?? 0, (i) => i);

  // Tapping the picture only says the name; it never changes the status
  void _say(AppState s, int i) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTap < 300) return;
    _lastTap = now;
    Sound.instance.speak(s.stepName(s.kidId, widget.rid, i), s.voice(), onEnd: () {
      if (mounted && _speaking == i) setState(() => _speaking = null);
    });
    setState(() => _speaking = i);
  }

  void _toggle(AppState s, int i) {
    final wasDone = s.isDone(widget.rid);
    s.toggleStep(widget.rid, i);
    if (!wasDone && s.isDone(widget.rid)) {
      Sound.instance.speak(s.tr('finito'), s.voice(), volume: 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.def(s.kidId, widget.rid);
    if (r == null) return const Scaffold(backgroundColor: C.bg);
    final done = s.progressOf(widget.rid);
    final all = done.every((x) => x);
    final curPos = ord0(s).indexWhere((i) => !done[i]);
    final cur = curPos < 0 ? -1 : ord0(s)[curPos];
    final portrait = isPortrait(context);

    final finito = _Finito(
      compact: portrait,
      text: s.tr('finito'),
      again: s.tr('again'),
      onAgain: () => s.resetRoutine(widget.rid),
    );

    Widget step(int i, {required bool row}) => _StepView(
          row: row,
          step: r.steps[i],
          name: s.stepName(s.kidId, widget.rid, i),
          done: done[i],
          current: i == cur,
          speaking: _speaking == i,
          labelDone: '${done[i] ? s.tr('isDone') : s.tr('markDone')}: ${s.stepName(s.kidId, widget.rid, i)}',
          onPicture: () => _say(s, i),
          onLamp: () => _toggle(s, i),
        );

    final ord = List<int>.generate(s.def(s.kidId, widget.rid)?.steps.length ?? 0, (i) => i);
    final n = ord.length;
    final Widget flow;
    if (portrait) {
      flow = Column(
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) SizedBox(height: 24, child: Center(child: Transform.rotate(angle: math.pi / 2, child: icon(Ic.sep, 28, C.navInk)))),
            Expanded(child: step(ord[i], row: true)),
          ],
        ],
      );
    } else {
      flow = LayoutBuilder(builder: (context, box) {
        // the picture is as large as the space allows: 1 : 1.2, under it the name and the lamp
        const sepW = 32.0, gap = 24.0;
        final colW = (box.maxWidth - (n - 1) * (sepW + gap * 2)) / n;
        final picH = math.min(colW * 1.2, box.maxHeight - 14 - 58 - 14 - 108 - 40);
        final picW = picH / 1.2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) ...[
                const SizedBox(width: gap),
                SizedBox(width: sepW, child: icon(Ic.sep, 32, C.navInk)),
                const SizedBox(width: gap),
              ],
              Expanded(child: Center(child: SizedBox(width: math.min(colW, math.max(picW, 160)), child: step(ord[i], row: false)))),
            ],
          ],
        );
      });
    }

    final page = Frame(
      head: Head(
        title: s.routineName(widget.rid),
        onBack: () => _back(context),
        trailing: portrait && all ? finito : null,
      ),
      body: portrait
          ? flow
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: flow),
                const SizedBox(height: 32),
                Visibility(visible: all, maintainSize: true, maintainAnimation: true, maintainState: true, child: finito),
              ],
            ),
    );
    if (!widget.preview) return page;
    return Stack(children: [
      page,
      Positioned(
        left: 0,
        right: 0,
        bottom: 16,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(999)),
            child: Text(s.l('Anteprima – così la vede il bambino', 'Перегляд – так бачить дитина'),
                style: ts(16, color: Colors.white).copyWith(decoration: TextDecoration.none)),
          ),
        ),
      ),
    ]);
  }
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.row,
    required this.step,
    required this.name,
    required this.done,
    required this.current,
    required this.speaking,
    required this.labelDone,
    required this.onPicture,
    required this.onLamp,
  });
  final bool row;
  final StepDef step;
  final String name;
  final bool done;
  final bool current;
  final bool speaking;
  final String labelDone;
  final VoidCallback onPicture;
  final VoidCallback onLamp;

  @override
  Widget build(BuildContext context) {
    final pic = Listener(
      onPointerDown: (_) => onPicture(),
      child: Semantics(
        button: true,
        label: name,
        child: LayoutBuilder(builder: (context, box) {
          final side = box.maxWidth.isFinite ? box.maxWidth : box.maxHeight;
          return Container(
            decoration: BoxDecoration(color: Color(step.tint), borderRadius: BorderRadius.circular(rImg)),
            foregroundDecoration: speaking
                ? BoxDecoration(borderRadius: BorderRadius.circular(rImg), border: Border.all(color: C.audio, width: 6))
                : null,
            clipBehavior: Clip.antiAlias,
            padding: step.photo != null ? EdgeInsets.zero : EdgeInsets.all(side * (row ? 0.03 : 0.08)),
            child: stepPicture(step, fit: step.photo != null ? BoxFit.cover : BoxFit.contain),
          );
        }),
      ),
    );
    final phone = isPhone(context);
    final lamp = Lamp(on: done, current: current, size: phone ? 76 : (row ? 120 : 108), label: labelDone, onTap: onLamp);
    if (row) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (phone)
            LayoutBuilder(builder: (context, box) => SizedBox(width: math.min(box.maxHeight, 150), child: Center(child: AspectRatio(aspectRatio: 1, child: pic))))
          else
            AspectRatio(aspectRatio: 1, child: pic),
          SizedBox(width: phone ? 14 : 20),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: Text(name, style: ts(phone ? 20 : 28)))),
          const SizedBox(width: 16),
          Center(child: lamp),
          // room for the lamp's glow, so it is not cut at the screen edge
          SizedBox(width: phone ? 20 : 28),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(aspectRatio: 1 / 1.2, child: pic),
        const SizedBox(height: 14),
        SizedBox(height: 58, child: Center(child: Text(name, style: ts(24), textAlign: TextAlign.center, maxLines: 2))),
        const SizedBox(height: 14),
        lamp,
      ],
    );
  }
}

/// The big "done" button. Not done – a quiet ring; done – a bright yellow lamp that glows.
/// The glow is steady: no blinking or pulsing (epilepsy).
class Lamp extends StatelessWidget {
  const Lamp({super.key, required this.on, required this.current, required this.size, required this.label, required this.onTap});
  final bool on;
  final bool current;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deco = on
        ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(0, -0.16),
              radius: 0.77,
              colors: [Color(0xFFFFF8DC), Color(0xFFFFE27A), Color(0xFFFFC93A)],
              stops: [0, 0.5, 1],
            ),
            border: Border.fromBorderSide(BorderSide(color: Color(0xFFF2B52E), width: 3)),
            boxShadow: [
              BoxShadow(color: Color(0x99FFBE28), blurRadius: 40, spreadRadius: 12),
              BoxShadow(color: Color(0x59FFD65A), spreadRadius: 10),
            ],
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: current ? C.ink3 : C.ring, width: current ? 4 : 3),
            boxShadow: const [BoxShadow(color: Color(0x1A3E4C43), blurRadius: 3, offset: Offset(0, 1))],
          );
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(width: size, height: size, decoration: deco),
      ),
    );
  }
}

class _Finito extends StatelessWidget {
  const _Finito({required this.compact, required this.text, required this.again, required this.onAgain});
  final bool compact;
  final String text;
  final String again;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final againBtn = Press(
      onTap: onAgain,
      color: compact ? C.nav : Colors.white,
      radius: 999,
      height: compact ? 48 : 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(widthFactor: 1, child: Text(again, style: ts(18, color: C.ink2))),
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DoneBadge(size: compact ? 44 : 56),
        SizedBox(width: compact ? 12 : 20),
        Text(text, style: ts(compact ? 26 : 32, w: FontWeight.w800)),
        SizedBox(width: compact ? 16 : 32),
        againBtn,
      ],
    );
    if (compact) return row;
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: C.pGreen, borderRadius: BorderRadius.circular(rCard)),
      child: Center(child: row),
    );
  }
}

