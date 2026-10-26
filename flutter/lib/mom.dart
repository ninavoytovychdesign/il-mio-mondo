// Parents' area: Oggi · Calendario · Diario · Routine · Bambini, plus the routine editor,
// a child's profile and the settings. Same tokens as the child screens, compact density.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'data.dart';
import 'screens.dart';
import 'ui.dart';

// ---------- Icons used only here ----------
class MI {
  static const gear = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 7h9M17 7h3M4 17h3M11 17h9" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><circle cx="15" cy="7" r="2.2" stroke="currentColor" stroke-width="2"/><circle cx="9" cy="17" r="2.2" stroke="currentColor" stroke-width="2"/></svg>';
  static const play = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M8 5.5v13l10.5-6.5z" fill="currentColor"/></svg>';
  static const stop = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="7" y="7" width="10" height="10" rx="2" fill="currentColor"/></svg>';
  static const plus = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 5v14M5 12h14" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/></svg>';
  static const mic = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="9" y="3.5" width="6" height="11" rx="3" stroke="currentColor" stroke-width="2"/><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v2.5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const trash = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5 7h14M10 7V5h4v2M7 7l1 12h8l1-12" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const bell = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/><path d="M10 20.5a2 2 0 0 0 4 0" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const clock = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="8.5" stroke="currentColor" stroke-width="2"/><path d="M12 7.5V12l3 2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const chevR = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m9 6 6 6-6 6" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const chevL = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m15 6-6 6 6 6" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const grip = r'<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><circle cx="9" cy="6" r="1.7"/><circle cx="15" cy="6" r="1.7"/><circle cx="9" cy="12" r="1.7"/><circle cx="15" cy="12" r="1.7"/><circle cx="9" cy="18" r="1.7"/><circle cx="15" cy="18" r="1.7"/></svg>';
  static const calAdd = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="5.5" width="16" height="14" rx="3" stroke="currentColor" stroke-width="2"/><path d="M4 10h16M9 3.5v4M15 3.5v4M12 12.5v5M9.5 15h5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  // dock: outline when not chosen, filled when chosen
  static const tOggi = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="4" stroke="currentColor" stroke-width="2"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const fOggi = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="5" fill="currentColor"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const tCal = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="4" y="5.5" width="16" height="14" rx="3" stroke="currentColor" stroke-width="2"/><path d="M4 10h16M9 3.5v4M15 3.5v4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const fCal = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3.5" y="5" width="17" height="15" rx="3.5" fill="currentColor"/><path d="M9 3.5v4M15 3.5v4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M4 10h16" stroke="#E6ECE7" stroke-width="1.8"/><circle cx="8.5" cy="14.5" r="1.3" fill="#E6ECE7"/><circle cx="12" cy="14.5" r="1.3" fill="#E6ECE7"/></svg>';
  static const tDiario = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="5.5" y="3.5" width="13" height="17" rx="2.5" stroke="currentColor" stroke-width="2"/><path d="M9 8.5h6M9 12h6M9 15.5h4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const fDiario = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="5" y="3" width="14" height="18" rx="3" fill="currentColor"/><path d="M9 8.5h6M9 12h6M9 15.5h4" stroke="#E6ECE7" stroke-width="2" stroke-linecap="round"/></svg>';
  static const tRoutine = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m4 6.5 1.6 1.6L8.5 5M4 12.5l1.6 1.6 2.9-3.1M4 18.5l1.6 1.6 2.9-3.1M11.5 7h8.5M11.5 13h8.5M11.5 19h8.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const fRoutine = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="3" y="3.5" width="5.5" height="5.5" rx="1.8" fill="currentColor"/><rect x="3" y="9.25" width="5.5" height="5.5" rx="1.8" fill="currentColor"/><rect x="3" y="15" width="5.5" height="5.5" rx="1.8" fill="currentColor"/><path d="m4.3 6.3.9.9 1.7-1.8M4.3 12l.9.9 1.7-1.8M4.3 17.8l.9.9 1.7-1.8" stroke="#E6ECE7" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/><path d="M11.5 6.25h9M11.5 12h9M11.5 17.75h9" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/></svg>';
  static const tKids = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="9" cy="8.5" r="3.5" stroke="currentColor" stroke-width="2"/><circle cx="17" cy="9.5" r="2.7" stroke="currentColor" stroke-width="2"/><path d="M3 19.5c.6-3.3 3-5 6-5s5.4 1.7 6 5M15.5 14.6c2.6-.3 4.9 1.1 5.5 4.4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>';
  static const fKids = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="9" cy="8" r="4" fill="currentColor"/><circle cx="17" cy="9.5" r="3" fill="currentColor"/><path d="M2.5 20c.5-3.8 3.1-5.8 6.5-5.8s6 2 6.5 5.8z" fill="currentColor"/><path d="M16.5 14.2c2.9-.2 5 1.5 5.5 5.8h-4.6c-.2-2.4-.6-4.3-.9-5.8z" fill="currentColor"/></svg>';
}

const Color _action = Color(0xFF3E4C43); // selection: dark neutral
const Color _peach = Color(0xFFFCEBE3);
const Color _apptInk = Color(0xFF8A3B12);
const Color _dash = Color(0xFFCFD8D1);

void toast(BuildContext context, String msg) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    width: 520,
    backgroundColor: C.ink,
    elevation: 0,
    duration: const Duration(milliseconds: 2600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Text(msg, textAlign: TextAlign.center, style: ts(17, color: Colors.white)),
  ));
}

// =====================================================================
// Small shared pieces
// =====================================================================

/// Pill button: 56 high (44 when small). On the white page it is grey-green, on a tinted block – white.
class PlainBtn extends StatelessWidget {
  const PlainBtn({super.key, required this.label, required this.onTap, this.svg, this.small = false, this.onBlock = false, this.primary = false, this.expand = false, this.textColor});
  final String label;
  final VoidCallback? onTap;
  final String? svg;
  final bool small;
  final bool onBlock;
  final bool primary;
  final bool expand;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? C.success : (onBlock ? Colors.white : C.nav);
    final fg = primary ? Colors.white : (textColor ?? C.ink);
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (svg != null) ...[icon(svg!, 22, fg), const SizedBox(width: 10)],
        Flexible(child: Text(label, style: ts(small ? 17 : 20, color: fg, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
    return Press(
      onTap: onTap,
      color: bg,
      radius: 999,
      height: small ? 44 : 56,
      padding: EdgeInsets.symmetric(horizontal: small ? 20 : 28),
      child: Center(widthFactor: expand ? null : 1, child: row),
    );
  }
}

class Box extends StatelessWidget {
  const Box({super.key, required this.children, this.title, this.warm = false, this.color, this.gap = 14});
  final List<Widget> children;
  final String? title;
  final bool warm;
  final Color? color;
  final double gap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: color ?? (warm ? C.cardWarm : C.cardGreen), borderRadius: BorderRadius.circular(rCard)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[Text(title!, style: ts(22)), SizedBox(height: gap + 4)],
            for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
          ],
        ),
      );
}

Widget noteText(String t) => Text(t, style: ts(15, w: FontWeight.w500, color: C.ink2, height: 1.45));
Widget emptyNote(String t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), child: Text(t, style: ts(16, w: FontWeight.w500, color: C.ink2, height: 1.4)));
Widget lbl(String t) => Text(t.toUpperCase(), style: ts(14, color: C.ink2, spacing: 0.84));

/// Two columns side by side in landscape (1.5 : 1 or even), one under the other in portrait
Widget cols(BuildContext context, Widget a, Widget b, {bool even = false}) {
  if (isPortrait(context)) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 24), b]);
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Expanded(flex: even ? 1 : 3, child: a), const SizedBox(width: 24), Expanded(flex: even ? 1 : 2, child: b)],
  );
}

/// Rounded picture plate (routine cover or step) – white for 3D art, tinted for flat placeholders
Widget thumb(String img, {double w = 56, double h = 48, double r = 14, Color? bg, double scale = 1}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: bg ?? C.surface, borderRadius: BorderRadius.circular(r)),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(flatArt.containsKey(img) ? w * 0.1 : 0),
      child: Transform.scale(scale: scale, child: picture(img)),
    );

/// Segmented control: grey-green track, the chosen option is a white pill
class Seg extends StatelessWidget {
  const Seg({super.key, required this.options, required this.value, required this.onChanged});
  final List<MapEntry<String, String>> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: C.nav, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options) ...[
              if (o != options.first) const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onChanged(o.key),
                child: Semantics(
                  button: true,
                  selected: o.key == value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: o.key == value ? soft3d(Colors.white, radius: BorderRadius.circular(999)) : null,
                    foregroundDecoration: o.key == value ? soft3dOverlay(radius: BorderRadius.circular(999)) : null,
                    child: Text(o.value, style: ts(17, w: o.key == value ? FontWeight.w700 : FontWeight.w600, color: o.key == value ? C.ink : C.ink2)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// Settings row: title and explanation on the left, the control on the right (wraps under on narrow screens)
class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, this.text, this.control});
  final String title;
  final String? text;
  final Widget? control;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: C.cardGreen, borderRadius: BorderRadius.circular(rCard)),
        child: LayoutBuilder(builder: (context, box) {
          final txt = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ts(20)),
              if (text != null) ...[const SizedBox(height: 2), noteText(text!)],
            ],
          );
          if (control == null) return txt;
          if (box.maxWidth < 640) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [txt, const SizedBox(height: 16), control!]);
          }
          return Row(children: [Expanded(child: txt), const SizedBox(width: 24), control!]);
        }),
      );
}

class Toggle extends StatelessWidget {
  const Toggle({super.key, required this.on, required this.onTap, required this.label});
  final bool on;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: on,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 64,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: on ? _action : const Color(0xFFB9C7BD), borderRadius: BorderRadius.circular(999)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(width: 28, height: 28, decoration: soft3d(Colors.white, circle: true)),
            ),
          ),
        ),
      );
}

/// Dashed outline for the "add a child" placeholders
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, this.radius = 28, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashPainter(radius),
        child: Padding(padding: padding, child: child),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.r);
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _dash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)).deflate(1));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 7, m.length)), p);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.r != r;
}

String schedText(AppState s, Sched sc) {
  if (sc.slots.isEmpty) return s.l('Nessun giorno', 'Без днів');
  final dd = [for (final x in sc.slots) x.d]..sort();
  final same = sc.slots.every((x) => x.t == sc.slots.first.t);
  String range(List<int> arr) {
    if (arr.length == 7) return s.l('Ogni giorno', 'Щодня');
    var run = true;
    for (var i = 1; i < arr.length; i++) {
      if (arr[i] != arr[i - 1] + 1) run = false;
    }
    if (run && arr.length > 2) return '${dayShort[s.ui]![arr.first]}–${dayShort[s.ui]![arr.last]}';
    return arr.map((d) => dayShort[s.ui]![d]).join(', ');
  }

  if (same) return '${range(dd)} · ${sc.slots.first.t}';
  final sorted = List<Slot>.from(sc.slots)..sort((a, b) => a.d - b.d);
  return sorted.map((x) => '${dayShort[s.ui]![x.d]} ${x.t}').join(' · ');
}

// =====================================================================
// The parents' shell: header, scrolling body and the floating dock
// =====================================================================
enum _Sub { none, editor, kid, settings }

class MomShell extends StatefulWidget {
  const MomShell({super.key});

  @override
  State<MomShell> createState() => _MomShellState();
}

class _MomShellState extends State<MomShell> {
  String tab = 'oggi';
  _Sub sub = _Sub.none;
  String subId = '';
  String momKid = 'ostap';
  DateTime? calDate;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void goTab(String t) {
    setState(() {
      tab = t;
      sub = _Sub.none;
      if (t == 'cal') calDate = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void openSub(_Sub s, [String id = '']) {
    setState(() {
      sub = s;
      subId = id;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void closeSub() => setState(() => sub = _Sub.none);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.kids.every((k) => k.id != momKid)) momKid = s.kids.first.id;
    late final _Page page;
    switch (sub) {
      case _Sub.settings:
        page = _settings(s);
      case _Sub.editor:
        page = _Page(
          title: s.routineName(subId, s.ui),
          subtitle: '${s.l('Routine di', 'Рутина:')} ${s.kidBy(momKid).name}',
          back: closeSub,
          extra: [PlainBtn(label: s.l('Anteprima', 'Перегляд'), onTap: () => previewRoutine(context, momKid, subId))],
          body: RoutineEditor(key: ValueKey('$momKid|$subId'), kidId: momKid, rid: subId),
        );
      case _Sub.kid:
        page = _Page(
          title: s.kidBy(subId).name,
          subtitle: s.l('Profilo', 'Профіль'),
          back: closeSub,
          body: KidProfile(key: ValueKey(subId), kidId: subId),
        );
      case _Sub.none:
        page = switch (tab) {
          'cal' => _cal(s),
          'diario' => _diario(s),
          'routine' => _routines(s),
          'bambini' => _kids(s),
          _ => _oggi(s),
        };
    }
    final pad = isPortrait(context) ? 32.0 : 40.0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (sub != _Sub.none) closeSub();
      },
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1200 + pad * 2),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(s, page),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scroll,
                            padding: const EdgeInsets.only(bottom: 80 + 16 + 24),
                            child: page.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 16, child: Center(child: _dock(s))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppState s, _Page p) {
    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(p.title, style: ts(32), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (p.subtitle != null) Text(p.subtitle!, style: ts(16, w: FontWeight.w600, color: C.ink2), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
    final actions = <Widget>[
      ...p.extra,
      if (s.cameFromChild)
        PlainBtn(
          label: s.l('Torna al gioco', 'Назад до гри'),
          svg: MI.play,
          primary: true,
          onTap: () => startPlay(context, s.kidId),
        ),
      if (sub != _Sub.settings) NavBtn(svg: MI.gear, label: s.l('Impostazioni', 'Налаштування'), onTap: () => openSub(_Sub.settings)),
    ];
    final left = Row(children: [
      if (p.back != null) ...[NavBtn(svg: Ic.back, label: s.l('Indietro', 'Назад'), onTap: p.back), const SizedBox(width: 16)],
      Expanded(child: titles),
    ]);
    final right = Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 12), actions[i]],
    ]);
    if (isPortrait(context) && p.extra.isNotEmpty && s.cameFromChild) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 16), Align(alignment: Alignment.centerRight, child: right)]);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(children: [Expanded(child: left), const SizedBox(width: 16), right]),
    );
  }

  Widget _dock(AppState s) {
    final tabs = [
      ['oggi', s.l('Oggi', 'Сьогодні'), MI.tOggi, MI.fOggi],
      ['cal', s.l('Calendario', 'Календар'), MI.tCal, MI.fCal],
      ['diario', s.l('Diario', 'Щоденник'), MI.tDiario, MI.fDiario],
      ['routine', s.l('Routine', 'Рутини'), MI.tRoutine, MI.fRoutine],
      ['bambini', s.l('Bambini', 'Діти'), MI.tKids, MI.fKids],
    ];
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x143E4C43)),
        boxShadow: const [BoxShadow(color: Color(0x1A3E4C43), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in tabs) ...[
            if (t != tabs.first) const SizedBox(width: 4),
            _DockItem(
              label: t[1],
              svg: (tab == t[0] && sub != _Sub.settings) ? t[3] : t[2],
              on: tab == t[0] && sub != _Sub.settings,
              onTap: () => goTab(t[0]),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Oggi ----------
  _Page _oggi(AppState s) {
    final d = s.today();
    final nn = s.notesFor(momKid, dateKey(d));
    final players = [
      for (final k in s.kids) _Player(kid: k, sub: s.l('Libri sonori e giornata', 'Звукові книжечки й день'), onTap: () => startPlay(context, k.id)),
      _AddPlayer(
        title: s.l('Aggiungi un bambino', 'Додати дитину'),
        sub: s.l('Un profilo per ogni figlio', 'Окремий профіль для кожної дитини'),
        onTap: () => toast(context, s.l('Aggiungere un profilo – nel prossimo passo', 'Додавання профілю – на наступному кроці')),
      ),
    ];
    return _Page(
      title: s.l('Oggi', 'Сьогодні'),
      subtitle: s.longDate(d) + (s.simDay != 0 ? ' · ${s.l('giorno di prova', 'тестовий день')}' : ''),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.l('Chi gioca adesso?', 'Хто зараз грає?'), style: ts(22)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, box) {
            final n = box.maxWidth < 560 ? 1 : 2;
            final w = (box.maxWidth - 16 * (n - 1)) / n;
            return Wrap(spacing: 16, runSpacing: 16, children: [for (final p in players) SizedBox(width: w, child: p)]);
          }),
          const SizedBox(height: 24),
          cols(
            context,
            Box(title: s.l('Routine di oggi', 'Рутини на сьогодні'), gap: 12, children: _dayRows(s, d)),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Box(warm: true, title: s.l('Appuntamenti', 'Візити'), children: _appts(s, d)),
              const SizedBox(height: 24),
              Box(title: s.l('Diario', 'Щоденник'), children: [
                NoteComposer(key: const ValueKey('o-composer'), kidId: momKid, date: d),
                if (nn.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PlainBtn(
                      small: true,
                      onBlock: true,
                      label: '${_noteWord(s, nn.length)} ${s.l('di oggi · Apri il diario', 'за сьогодні · Відкрити щоденник')}',
                      onTap: () => goTab('diario'),
                    ),
                  ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  String _noteWord(AppState s, int n) {
    if (s.ui == 'uk') return n == 1 ? '1 нотатка' : '$n ${n < 5 ? 'нотатки' : 'нотаток'}';
    return n == 1 ? '1 nota' : '$n note';
  }

  List<Widget> _dayRows(AppState s, DateTime date, {bool appt = false}) {
    final items = s.routinesOn(momKid, date);
    if (items.isEmpty) return [emptyNote(s.l('Nessuna routine in questo giorno. Puoi aggiungerla in Routine.', 'У цей день рутин немає. Додати можна у вкладці «Рутини».'))];
    return [
      for (final x in items)
        _DayRow(
          time: x.t,
          cover: x.r.cover,
          coverTint: x.r.tint,
          name: s.routineName(x.r.id, s.ui),
          done: s.isDoneOn(momKid, date, x.r.id),
          doneLabel: s.l('Fatta', 'Готово'),
          appt: appt && x.r.therapy ? s.l('Appuntamento', 'Візит') : null,
          bell: s.schedOf(momKid, x.r.id)!.bell,
          onTap: () => openSub(_Sub.editor, x.r.id),
        ),
    ];
  }

  List<Widget> _appts(AppState s, DateTime d) {
    final ap = s.routinesOn(momKid, d).where((x) => x.r.therapy).toList();
    if (ap.isEmpty) return [emptyNote(s.l('Nessun appuntamento oggi.', 'Сьогодні візитів немає.'))];
    return [
      for (final x in ap) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 56, child: Text(x.t, style: ts(18))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(therapyShort[s.ui]![x.r.id] ?? '', style: ts(18)),
              Text('${s.l('Routine', 'Рутина')}: ${s.routineName(x.r.id, s.ui)}', style: ts(15, w: FontWeight.w500, color: C.ink2)),
            ]),
          ),
        ]),
        if (s.schedOf(momKid, x.r.id)!.bell)
          Row(children: [
            icon(MI.bell, 20, C.ink2),
            const SizedBox(width: 8),
            Expanded(child: Text('${s.l('Promemoria sul telefono alle', 'Нагадування на телефон о')} ${fromMin(toMin(x.t) - 10)}', style: ts(15, w: FontWeight.w500, color: C.ink2))),
          ]),
      ],
    ];
  }

  // ---------- Calendario ----------
  _Page _cal(AppState s) {
    final sel = calDate ?? s.today();
    final mon = sel.subtract(Duration(days: dowOf(sel) - 1));
    final tk = dateKey(s.today());
    final nn = s.notesFor(momKid, dateKey(sel));
    final week = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Mini(svg: MI.chevL, label: s.l('Settimana precedente', 'Попередній тиждень'), onTap: () => setState(() => calDate = sel.subtract(const Duration(days: 7)))),
        const SizedBox(width: 8),
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _WeekDay(
              letter: dayShort[s.ui]![i + 1],
              day: mon.add(Duration(days: i)).day,
              dots: [for (final x in s.routinesOn(momKid, mon.add(Duration(days: i)))) x.r.therapy],
              today: dateKey(mon.add(Duration(days: i))) == tk,
              selected: dateKey(mon.add(Duration(days: i))) == dateKey(sel),
              onTap: () => setState(() => calDate = mon.add(Duration(days: i))),
            ),
          ),
        ],
        const SizedBox(width: 8),
        _Mini(svg: MI.chevR, label: s.l('Settimana successiva', 'Наступний тиждень'), onTap: () => setState(() => calDate = sel.add(const Duration(days: 7)))),
      ],
    );
    return _Page(
      title: s.l('Calendario', 'Календар'),
      subtitle: '${s.kidBy(momKid).name} · ${s.l('settimana dal', 'тиждень з')} ${mon.day} ${monthNames[s.ui]![mon.month - 1]}',
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        week,
        const SizedBox(height: 24),
        cols(
          context,
          Box(title: s.longDate(sel), gap: 12, children: _dayRows(s, sel, appt: true)),
          Box(warm: true, title: s.l('Note del giorno', 'Нотатки дня'), gap: 12, children: [
            if (nn.isEmpty) emptyNote(s.l('Nessuna nota in questo giorno.', 'У цей день нотаток немає.')),
            for (final n in nn) NoteItem(note: n),
          ]),
        ),
        const SizedBox(height: 24),
        noteText(s.l('Punti grigi – routine, arancioni – appuntamenti. Le routine con un orario compaiono qui da sole.',
            'Сірі точки – рутини, помаранчеві – візити. Рутини з розкладом з\'являються тут самі.')),
      ]),
    );
  }

  // ---------- Diario ----------
  _Page _diario(AppState s) {
    final nn = s.notesFor(momKid);
    return _Page(
      title: s.l('Diario', 'Щоденник'),
      subtitle: '${s.l('Note su', 'Нотатки про')} ${s.kidBy(momKid).name}',
      body: cols(
        context,
        Box(title: '${s.l('Nuova nota', 'Нова нотатка')} · ${s.longDate(s.today())}', children: [
          NoteComposer(key: const ValueKey('d-composer'), kidId: momKid, date: s.today()),
          noteText(s.l('Qui va quello che noti: «oggi ha premuto da solo la volpe tre volte». Le note restano legate al giorno e si vedono anche nel Calendario.',
              'Сюди – те, що помічаєш: «сьогодні сам натиснув лисичку тричі». Нотатки прив\'язані до дня і видні в Календарі.')),
        ]),
        Box(warm: true, title: s.l('Tutte le note', 'Усі нотатки'), gap: 12, children: [
          if (nn.isEmpty) emptyNote(s.l('Ancora nessuna nota.', 'Нотаток ще немає.')),
          for (final n in nn) NoteItem(note: n, withDate: true),
        ]),
        even: true,
      ),
    );
  }

  // ---------- Routine ----------
  _Page _routines(AppState s) {
    final list = s.kidRoutines(momKid);
    return _Page(
      title: s.l('Routine', 'Рутини'),
      subtitle: '${s.kidBy(momKid).name} · ${list.length} ${s.l('routine', 'рутин')}',
      extra: [
        PlainBtn(
          label: s.l('Nuova routine', 'Нова рутина'),
          svg: MI.plus,
          onTap: () => toast(context, s.l('Creare una routine nuova – nel prossimo passo', 'Нова рутина – на наступному кроці')),
        ),
      ],
      body: list.isEmpty
          ? Box(title: '${s.kidBy(momKid).name} ${s.l('non ha ancora routine', 'ще не має рутин')}', children: const [])
          : RoutineGrid(
              kidId: momKid,
              items: list,
              onOpen: (rid) => openSub(_Sub.editor, rid),
            ),
    );
  }

  // ---------- Bambini ----------
  _Page _kids(AppState s) {
    final cards = <Widget>[
      for (final k in s.kids)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Color(k.tint), borderRadius: BorderRadius.circular(rCard)),
          child: Column(children: [
            Avatar(av: k.av, size: 112),
            const SizedBox(height: 16),
            Text(k.name, style: ts(28)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(rImg)),
              child: Column(children: [
                _fact(s.l('Lingua dei giochi', 'Мова ігор'), k.lang == 'uk' ? 'Українська' : 'Italiano'),
                _fact(s.l("Suono toccando l'immagine", 'Звук від дотику до картинки'), k.img ? s.l('Sì', 'Так') : s.l('No', 'Ні')),
                _fact(s.l('Routine', 'Рутини'), '${s.kidRoutines(k.id).length}'),
                _fact(s.l('Libri sonori', 'Звукові книжечки'), '${books.length} ${s.l('visibili', 'видно')}'),
              ]),
            ),
            const SizedBox(height: 16),
            PlainBtn(label: s.l('Modifica', 'Змінити'), onBlock: true, onTap: () => openSub(_Sub.kid, k.id)),
          ]),
        ),
      GestureDetector(
        onTap: () => toast(context, s.l('Aggiungere un profilo – nel prossimo passo', 'Додавання профілю – на наступному кроці')),
        child: DashedBox(
          radius: rCard,
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 380,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 112, height: 112, decoration: const BoxDecoration(color: C.surface, shape: BoxShape.circle), child: Center(child: icon(MI.plus, 40, C.navInk))),
              const SizedBox(height: 16),
              Text(s.l('Aggiungi un bambino', 'Додати дитину'), style: ts(22)),
              const SizedBox(height: 8),
              SizedBox(
                width: 260,
                child: Text(s.l('Nome, avatar e routine proprie. I profili restano separati.', "Ім'я, аватар і свої рутини. Профілі не змішуються."),
                    textAlign: TextAlign.center, style: ts(15, w: FontWeight.w500, color: C.ink2, height: 1.4)),
              ),
            ]),
          ),
        ),
      ),
    ];
    return _Page(
      title: s.l('Bambini', 'Діти'),
      subtitle: s.l('Profili su questo tablet', 'Профілі на цьому планшеті'),
      body: LayoutBuilder(builder: (context, box) {
        final n = isPortrait(context) ? 1 : 2;
        final w = (box.maxWidth - 24 * (n - 1)) / n;
        return Wrap(spacing: 24, runSpacing: 24, children: [for (final c in cards) SizedBox(width: w, child: c)]);
      }),
    );
  }

  Widget _fact(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Text(a, style: ts(15, w: FontWeight.w500, color: C.ink2))),
          Text(b, style: ts(17)),
        ]),
      );

  // ---------- Impostazioni ----------
  _Page _settings(AppState s) {
    return _Page(
      title: s.l('Impostazioni', 'Налаштування'),
      subtitle: s.l('Valgono per tutto il tablet', 'Діють для всього планшета'),
      back: closeSub,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Panel(
          title: s.l('Lingua', 'Мова'),
          text: s.l("Lingua dell'app. Cambia anche la lingua dei giochi di tutti i bambini; per un singolo bambino si può cambiare nel suo profilo.",
              'Мова застосунку. Змінює й мову ігор для всіх дітей; для окремої дитини її можна змінити в профілі.'),
          control: Seg(options: const [MapEntry('it', 'Italiano'), MapEntry('uk', 'Українська')], value: s.ui, onChanged: s.setUi),
        ),
        const SizedBox(height: 24),
        Panel(
          title: s.l('Giorno per la prova', 'Тестовий день'),
          text: s.l('Mostra la giornata come se oggi fosse un altro giorno della settimana. Utile per provare le routine.',
              'Показує день так, ніби сьогодні інший день тижня. Зручно, щоб перевірити рутини.'),
          control: Seg(
            options: [MapEntry('0', s.l('Oggi', 'Сьогодні')), for (var d = 1; d <= 7; d++) MapEntry('$d', dayLetter[s.ui]![d])],
            value: '${s.simDay}',
            onChanged: (v) => s.setSimDay(int.parse(v)),
          ),
        ),
        const SizedBox(height: 24),
        Panel(title: s.l('Crediti dei suoni', 'Звідки звуки'), text: soundCredits),
      ]),
    );
  }
}

class _Page {
  _Page({required this.title, required this.body, this.subtitle, this.back, this.extra = const []});
  final String title;
  final String? subtitle;
  final VoidCallback? back;
  final List<Widget> extra;
  final Widget body;
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.label, required this.svg, required this.on, required this.onTap});
  final String label;
  final String svg;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 84),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: on ? soft3d(C.nav, radius: BorderRadius.circular(999)) : null,
            foregroundDecoration: on ? soft3dOverlay(radius: BorderRadius.circular(999)) : null,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              icon(svg, 24, on ? C.ink : C.ink2),
              const SizedBox(height: 4),
              Text(label, style: ts(13, w: on ? FontWeight.w800 : FontWeight.w600, color: on ? C.ink : C.ink2, height: 1.1)),
            ]),
          ),
        ),
      );
}

class _Mini extends StatelessWidget {
  const _Mini({required this.svg, required this.onTap, required this.label});
  final String svg;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Press(onTap: onTap, color: C.nav, circle: true, width: 44, height: 44, label: label, child: Center(child: icon(svg, 22, C.navInk)));
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({required this.letter, required this.day, required this.dots, required this.today, required this.selected, required this.onTap});
  final String letter;
  final int day;
  final List<bool> dots;
  final bool today;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : C.ink;
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: selected
              ? soft3d(_action, radius: BorderRadius.circular(rImg))
              : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(rImg),
                  border: Border.all(color: today ? C.ink3 : C.nav, width: 2),
                ),
          child: Column(children: [
            Text(letter.toUpperCase(), style: ts(13, color: selected ? Colors.white : C.ink2, spacing: 0.5)),
            const SizedBox(height: 4),
            Text('$day', style: ts(22, color: fg)),
            const SizedBox(height: 4),
            SizedBox(
              height: 8,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (final ap in dots)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? const Color(0xD9FFFFFF) : (ap ? const Color(0xFFC4673B) : C.ink3),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.time,
    required this.cover,
    required this.coverTint,
    required this.name,
    required this.done,
    required this.doneLabel,
    required this.bell,
    required this.onTap,
    this.appt,
  });
  final String time;
  final String cover;
  final Color coverTint;
  final String name;
  final bool done;
  final String doneLabel;
  final String? appt;
  final bool bell;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget? right;
    if (done) {
      right = Row(mainAxisSize: MainAxisSize.min, children: [
        const DoneBadge(size: 28),
        const SizedBox(width: 6),
        Text(doneLabel, style: ts(15, color: C.ink2)),
      ]);
    } else if (appt != null) {
      right = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: _peach, borderRadius: BorderRadius.circular(999)),
        child: Text(appt!, style: ts(15, w: FontWeight.w800, color: _apptInk)),
      );
    } else if (bell) {
      right = icon(MI.bell, 24, C.ink2);
    }
    return CardRow(
      onTap: onTap,
      child: Row(children: [
        SizedBox(width: 56, child: Text(time, style: ts(18, w: done ? FontWeight.w600 : FontWeight.w700, color: done ? C.ink3 : C.ink))),
        const SizedBox(width: 16),
        thumb(cover, bg: flatArt.containsKey(cover) ? coverTint : C.surface),
        const SizedBox(width: 16),
        Expanded(child: Text(name, style: ts(18), maxLines: 2, overflow: TextOverflow.ellipsis)),
        if (right != null) ...[const SizedBox(width: 12), right],
      ]),
    );
  }
}

/// White list row (24 radius) that presses in a little
class CardRow extends StatefulWidget {
  const CardRow({super.key, required this.child, required this.onTap, this.color = Colors.white, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12)});
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsets padding;

  @override
  State<CardRow> createState() => _CardRowState();
}

class _CardRowState extends State<CardRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          constraints: const BoxConstraints(minHeight: 64),
          transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(rImg)),
          child: widget.child,
        ),
      );
}

class _Player extends StatelessWidget {
  const _Player({required this.kid, required this.sub, required this.onTap});
  final Kid kid;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CardRow(
        onTap: onTap,
        color: Color(kid.tint),
        padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
        child: Row(children: [
          Avatar(av: kid.av, size: 84),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kid.name, style: ts(26)),
              Text(sub, style: ts(15, w: FontWeight.w600, color: C.ink2)),
            ]),
          ),
          const SizedBox(width: 16),
          Container(
            width: 64,
            height: 64,
            decoration: soft3d(C.success, circle: true),
            foregroundDecoration: soft3dOverlay(circle: true),
            child: Center(child: Padding(padding: const EdgeInsets.only(left: 3), child: icon(MI.play, 28, Colors.white))),
          ),
        ]),
      );
}

class _AddPlayer extends StatelessWidget {
  const _AddPlayer({required this.title, required this.sub, required this.onTap});
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: DashedBox(
          radius: 28,
          child: Row(children: [
            Container(width: 84, height: 84, decoration: const BoxDecoration(color: C.surface, shape: BoxShape.circle), child: Center(child: icon(MI.plus, 32, C.navInk))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: ts(20)),
                Text(sub, style: ts(15, w: FontWeight.w600, color: C.ink2)),
              ]),
            ),
          ]),
        ),
      );
}

// =====================================================================
// Notes: composer (text + voice) and one note
// =====================================================================
class NoteComposer extends StatefulWidget {
  const NoteComposer({super.key, required this.kidId, required this.date});
  final String kidId;
  final DateTime date;

  @override
  State<NoteComposer> createState() => _NoteComposerState();
}

class _NoteComposerState extends State<NoteComposer> {
  final TextEditingController _text = TextEditingController();
  AudioRecorder? _rec;
  bool _recording = false;

  @override
  void dispose() {
    _text.dispose();
    _rec?.dispose();
    super.dispose();
  }

  void _save(AppState s) {
    final v = _text.text.trim();
    if (v.isEmpty) {
      toast(context, s.l('Scrivi prima qualcosa', 'Спершу напиши щось'));
      return;
    }
    s.addNote(widget.kidId, widget.date, v);
    _text.clear();
    FocusScope.of(context).unfocus();
    toast(context, s.l('Nota salvata', 'Нотатку збережено'));
  }

  Future<void> _mic(AppState s) async {
    try {
      final rec = _rec ??= AudioRecorder();
      if (_recording) {
        final path = await rec.stop();
        setState(() => _recording = false);
        if (path != null) {
          s.addNote(widget.kidId, widget.date, _text.text.trim(), audio: path);
          _text.clear();
          if (mounted) toast(context, s.l('Nota vocale salvata', 'Голосову нотатку збережено'));
        }
        return;
      }
      if (!await rec.hasPermission()) {
        if (mounted) toast(context, s.l('Il microfono non è disponibile', 'Мікрофон недоступний'));
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/nota_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await Sound.instance.stop();
      await rec.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() => _recording = true);
    } catch (_) {
      setState(() => _recording = false);
      if (mounted) toast(context, s.l('Il microfono non è disponibile', 'Мікрофон недоступний'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(minHeight: 120),
        child: TextField(
          controller: _text,
          minLines: 4,
          maxLines: 8,
          style: ts(16, w: FontWeight.w500, height: 1.45),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: s.l("Com'è andata oggi? Scrivi una nota o registra un messaggio vocale…", 'Як минув день? Напиши нотатку або запиши голосову…'),
            hintStyle: ts(16, w: FontWeight.w500, color: C.ink3, height: 1.45),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: PlainBtn(expand: true, onBlock: true, svg: MI.plus, label: s.l('Nuova nota', 'Нова нотатка'), onTap: () => _save(s))),
        const SizedBox(width: 12),
        Expanded(
          child: PlainBtn(
            expand: true,
            onBlock: true,
            svg: _recording ? MI.stop : MI.mic,
            textColor: _recording ? const Color(0xFFB4441E) : null,
            label: _recording ? s.l('Ferma', 'Зупинити') : s.l('Nota vocale', 'Голосова'),
            onTap: () => _mic(s),
          ),
        ),
      ]),
    ]);
  }
}

class NoteItem extends StatefulWidget {
  const NoteItem({super.key, required this.note, this.withDate = false});
  final Note note;
  final bool withDate;

  @override
  State<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
  bool _playing = false;

  @override
  void dispose() {
    if (_playing) Sound.instance.stop(notify: false);
    super.dispose();
  }

  void _toggle() {
    if (_playing) {
      Sound.instance.stop();
      return;
    }
    Sound.instance.playFile(widget.note.audio!, onEnd: () {
      if (mounted) setState(() => _playing = false);
    });
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final n = widget.note;
    final k = s.kidBy(n.kid);
    final d = DateTime.fromMillisecondsSinceEpoch(n.ts);
    final hasAudio = n.audio != null && File(n.audio!).existsSync();
    final meta = [
      if (widget.withDate) '${dayShort[s.ui]![dowOf(d)]} ${d.day} ${monthNames[s.ui]![d.month - 1]}',
      '${pad2(d.hour)}:${pad2(d.minute)}',
      if (n.audio != null) s.l('Nota vocale', 'Голосова нотатка'),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(rImg)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Avatar(av: k.av, size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meta.toUpperCase(), style: ts(13, color: C.ink2, spacing: 0.5)),
            const SizedBox(height: 2),
            if (n.text.isNotEmpty) SelectableText(n.text, style: ts(16, w: FontWeight.w500, height: 1.45)),
            if (hasAudio) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: PlainBtn(
                  small: true,
                  svg: _playing ? MI.stop : MI.play,
                  label: _playing ? s.l('Ferma', 'Зупинити') : s.l('Ascolta', 'Слухати'),
                  onTap: _toggle,
                ),
              ),
            ] else if (n.audio != null)
              Text(s.l('Audio non trovato sul tablet', 'Аудіо не знайдено на планшеті'), style: ts(15, w: FontWeight.w500, color: C.ink3)),
          ]),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: s.l('Elimina nota', 'Видалити нотатку'),
          child: GestureDetector(
            onTap: () => s.deleteNote(n.id),
            child: SizedBox(width: 36, height: 36, child: Center(child: icon(MI.trash, 20, C.ink3))),
          ),
        ),
      ]),
    );
  }
}

// =====================================================================
// Routine list: long-press a card, then drag it to another place
// =====================================================================
class RoutineGrid extends StatefulWidget {
  const RoutineGrid({super.key, required this.kidId, required this.items, required this.onOpen});
  final String kidId;
  final List<Routine> items;
  final ValueChanged<String> onOpen;

  @override
  State<RoutineGrid> createState() => _RoutineGridState();
}

class _RoutineGridState extends State<RoutineGrid> {
  List<String>? _ids; // visual order while dragging
  String? _drag;
  int _from = 0;
  Offset _offset = Offset.zero;

  static const double _gap = 16;
  static const double _h = 96;

  Rect _slot(int i, int cols, double w) {
    final c = i % cols, r = i ~/ cols;
    return Rect.fromLTWH(c * (w + _gap), r * (_h + _gap), w, _h);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ids = _ids ?? [for (final r in widget.items) r.id];
    return LayoutBuilder(builder: (context, box) {
      final cols = isPortrait(context) ? 1 : 2;
      final w = (box.maxWidth - _gap * (cols - 1)) / cols;
      final rows = (ids.length / cols).ceil();
      final order = [...ids.where((id) => id != _drag), if (_drag != null) _drag!];
      return SizedBox(
        height: rows * _h + math.max(0, rows - 1) * _gap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final id in order)
              Builder(key: ValueKey('rt-$id'), builder: (context) {
                final dragging = id == _drag;
                final rect = dragging ? _slot(_from, cols, w).shift(_offset) : _slot(ids.indexOf(id), cols, w);
                final r = routineById(id);
                final sc = s.schedOf(widget.kidId, id)!;
                return AnimatedPositioned(
                  key: ValueKey(id),
                  duration: dragging ? Duration.zero : const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: GestureDetector(
                    onTap: () => widget.onOpen(id),
                    onLongPressStart: (_) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _ids = List<String>.from(ids);
                        _drag = id;
                        _from = ids.indexOf(id);
                        _offset = Offset.zero;
                      });
                    },
                    onLongPressMoveUpdate: (d) {
                      final cur = _ids!;
                      final center = _slot(_from, cols, w).center + d.offsetFromOrigin;
                      var best = 0;
                      var bd = double.infinity;
                      for (var k = 0; k < cur.length; k++) {
                        final dist = (_slot(k, cols, w).center - center).distance;
                        if (dist < bd) {
                          bd = dist;
                          best = k;
                        }
                      }
                      setState(() {
                        _offset = d.offsetFromOrigin;
                        cur.remove(id);
                        cur.insert(best, id);
                      });
                    },
                    onLongPressEnd: (_) {
                      final next = _ids!;
                      setState(() {
                        _drag = null;
                        _ids = null;
                      });
                      AppScope.of(context).setRoutineOrder(widget.kidId, next);
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      scale: dragging ? 1.02 : 1,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
                        decoration: BoxDecoration(
                          color: C.cardGreen,
                          borderRadius: BorderRadius.circular(rImg),
                          boxShadow: dragging ? const [BoxShadow(color: Color(0x2E3E4C43), blurRadius: 28, offset: Offset(0, 12))] : const [],
                        ),
                        child: Row(children: [
                          thumb(r.cover, w: 88, h: 68, r: 16, bg: flatArt.containsKey(r.cover) ? r.tint : Colors.white),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.routineName(id, s.ui), style: ts(18), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(schedText(s, sc), style: ts(15, w: FontWeight.w500, color: C.ink2), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          if (sc.bell) ...[const SizedBox(width: 12), icon(MI.bell, 24, C.ink2)],
                          const SizedBox(width: 12),
                          icon(MI.chevR, 24, C.ink2),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      );
    });
  }
}

// =====================================================================
// Routine editor: steps (drag the grip to reorder, rename) and when it happens
// =====================================================================
class RoutineEditor extends StatefulWidget {
  const RoutineEditor({super.key, required this.kidId, required this.rid});
  final String kidId;
  final String rid;

  @override
  State<RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<RoutineEditor> {
  final Map<int, TextEditingController> _ctl = {};
  bool _perDay = false;
  String _ctlLang = '';

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(AppState s, int i) {
    if (_ctlLang != s.ui) {
      // language changed: names come from the other language
      for (final c in _ctl.values) {
        c.dispose();
      }
      _ctl.clear();
      _ctlLang = s.ui;
    }
    return _ctl.putIfAbsent(i, () => TextEditingController(text: s.stepName(widget.kidId, widget.rid, i, s.ui)));
  }

  Future<void> _pickTime(AppState s, String current, {int? day}) async {
    final p = current.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t == null) return;
    s.setTime(widget.kidId, widget.rid, '${pad2(t.hour)}:${pad2(t.minute)}', day: day);
  }

  List<MapEntry<String, String>> _calendarLinks(AppState s) {
    final sc = s.schedOf(widget.kidId, widget.rid)!;
    final groups = <String, List<int>>{};
    for (final x in sc.slots) {
      groups.putIfAbsent(x.t, () => []).add(x.d);
    }
    const by = ['', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    String f(DateTime d) => '${d.year}${pad2(d.month)}${pad2(d.day)}T${pad2(d.hour)}${pad2(d.minute)}00';
    return [
      for (final e in groups.entries)
        () {
          final dd = e.value..sort();
          final base = s.today();
          final first = base.add(Duration(days: (dd.first - dowOf(base) + 7) % 7));
          final p = e.key.split(':');
          final st0 = DateTime(first.year, first.month, first.day, int.parse(p[0]), int.parse(p[1]));
          final en = st0.add(const Duration(minutes: 30));
          final text = '${s.kidBy(widget.kidId).name}: ${s.routineName(widget.rid, s.ui)}';
          final details = '${s.l('Tra 10 minuti: ', 'За 10 хвилин: ')}${s.routineName(widget.rid, s.ui)}. Il mio mondo.';
          final url = 'https://calendar.google.com/calendar/render?action=TEMPLATE'
              '&text=${Uri.encodeComponent(text)}'
              '&dates=${f(st0)}/${f(en)}'
              '&ctz=Europe/Rome'
              '&recur=${Uri.encodeComponent('RRULE:FREQ=WEEKLY;BYDAY=${dd.map((d) => by[d]).join(',')}')}'
              '&details=${Uri.encodeComponent(details)}';
          return MapEntry('${dd.map((d) => dayShort[s.ui]![d]).join(', ')} · ${e.key}', url);
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = routineById(widget.rid);
    final sc = s.schedOf(widget.kidId, widget.rid)!;
    final k = s.kidBy(widget.kidId);
    final ord = s.orderOf(widget.kidId, widget.rid);
    final on = {for (final x in sc.slots) x.d};
    final same = sc.slots.every((x) => x.t == (sc.slots.isNotEmpty ? sc.slots.first.t : ''));
    final perDay = _perDay || !same;
    final links = sc.slots.isNotEmpty ? _calendarLinks(s) : const <MapEntry<String, String>>[];

    final steps = ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, anim) => Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rImg),
            boxShadow: const [BoxShadow(color: Color(0x293E4C43), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: child,
        ),
      ),
      onReorder: (from, to) {
        if (to > from) to -= 1;
        s.moveStep(widget.kidId, widget.rid, from, to);
      },
      children: [
        for (var pos = 0; pos < ord.length; pos++)
          Padding(
            key: ValueKey('step-${ord[pos]}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(rImg)),
              child: Row(children: [
                ReorderableDragStartListener(
                  index: pos,
                  child: Semantics(
                    label: '${s.l('Trascina per spostare', 'Перетягни, щоб перемістити')}: ${s.stepName(widget.kidId, widget.rid, ord[pos], s.ui)}',
                    child: SizedBox(width: 44, height: 56, child: Center(child: icon(MI.grip, 24, C.ink3))),
                  ),
                ),
                const SizedBox(width: 12),
                thumb(r.steps[ord[pos]].img, w: 56, h: 56, bg: r.steps[ord[pos]].tint, scale: 0.86),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _c(s, ord[pos]),
                    style: ts(18),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                    onChanged: (v) => s.setStepName(widget.kidId, widget.rid, ord[pos], v),
                  ),
                ),
              ]),
            ),
          ),
      ],
    );

    Widget timeField(String t, {int? day}) => Press(
          onTap: () => _pickTime(s, t, day: day),
          color: Colors.white,
          radius: 16,
          height: 56,
          flat: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (day != null) ...[SizedBox(width: 40, child: Text(dayShort[s.ui]![day], style: ts(16, color: C.ink2))), const SizedBox(width: 6)],
            icon(MI.clock, 22, C.ink2),
            const SizedBox(width: 10),
            Text(t, style: ts(20)),
          ]),
        );

    final sortedSlots = List<Slot>.from(sc.slots)..sort((a, b) => a.d - b.d);
    final when = Box(warm: true, title: s.l('Quando', 'Коли'), children: [
      lbl(s.l('Giorni', 'Дні')),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var d = 1; d <= 7; d++)
          Semantics(
            button: true,
            selected: on.contains(d),
            label: dayLong[s.ui]![d],
            child: GestureDetector(
              onTap: () => s.toggleDay(widget.kidId, widget.rid, d),
              child: Container(
                width: 52,
                height: 52,
                decoration: on.contains(d)
                    ? soft3d(_action, circle: true)
                    : BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: C.nav, width: 2)),
                child: Center(child: Text(dayLetter[s.ui]![d], style: ts(18, color: on.contains(d) ? Colors.white : C.ink2))),
              ),
            ),
          ),
      ]),
      lbl(s.l('Ora', 'Час')),
      if (sc.slots.isEmpty)
        emptyNote(s.l('Scegli almeno un giorno.', 'Вибери хоча б один день.'))
      else if (perDay)
        Wrap(spacing: 12, runSpacing: 12, children: [for (final x in sortedSlots) timeField(x.t, day: x.d)])
      else
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          timeField(sc.slots.first.t),
          if (sc.slots.length > 1)
            PlainBtn(small: true, onBlock: true, label: s.l('Ora diversa per giorno', 'Різний час по днях'), onTap: () => setState(() => _perDay = true)),
        ]),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.l('Promemoria sul telefono', 'Нагадування на телефон'), style: ts(18)),
            Text(s.l('10 minuti prima', 'За 10 хвилин'), style: ts(15, w: FontWeight.w500, color: C.ink2)),
          ]),
        ),
        Toggle(on: sc.bell, label: s.l('Promemoria sul telefono', 'Нагадування на телефон'), onTap: () => s.toggleBell(widget.kidId, widget.rid)),
      ]),
      if (links.isNotEmpty) ...[
        if (links.length > 1) lbl(s.l('Aggiungi a Google Calendar', 'Додати в Google Календар')),
        for (final l in links)
          PlainBtn(
            expand: true,
            onBlock: true,
            small: links.length > 1,
            svg: MI.calAdd,
            label: links.length == 1 ? s.l('Aggiungi a Google Calendar', 'Додати в Google Календар') : l.key,
            onTap: () => launchUrl(Uri.parse(l.value), mode: LaunchMode.externalApplication),
          ),
      ],
      noteText('${k.name} ${s.l("vede questa routine solo nei giorni scelti. Il promemoria arriva dal calendario del telefono: se cambi l'ora, aggiungila di nuovo.", 'бачить цю рутину лише у вибрані дні. Нагадування приходить з календаря телефона: якщо змінюєш час, додай подію ще раз.')}'),
    ]);

    return cols(
      context,
      Box(title: s.l('Passi', 'Кроки'), children: [
        steps,
        Align(
          alignment: Alignment.centerLeft,
          child: PlainBtn(
            onBlock: true,
            svg: MI.plus,
            label: s.l('Aggiungi passo', 'Додати крок'),
            onTap: () => toast(context, s.l('Aggiungere passi con le foto – nel prossimo passo', 'Додавання кроків із фото – на наступному кроці')),
          ),
        ),
        noteText('${s.l("Il nome del passo è anche quello che il tablet dice ad alta voce. L'ordine qui è l'ordine che vede", 'Назву кроку планшет промовляє вголос. Порядок тут – той, який бачить')} ${k.name}.'),
      ]),
      when,
      even: true,
    );
  }
}

// =====================================================================
// A child's profile
// =====================================================================
class KidProfile extends StatefulWidget {
  const KidProfile({super.key, required this.kidId});
  final String kidId;

  @override
  State<KidProfile> createState() => _KidProfileState();
}

class _KidProfileState extends State<KidProfile> {
  late final TextEditingController _name;
  int _confirm = 0; // 0 – idle, 1 – asks to confirm, 2 – done

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reset(AppState s) {
    if (_confirm != 1) {
      setState(() => _confirm = 1);
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted && _confirm == 1) setState(() => _confirm = 0);
      });
      return;
    }
    s.resetDay(widget.kidId);
    setState(() => _confirm = 2);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _confirm == 2) setState(() => _confirm = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final k = s.kidBy(widget.kidId);
    if (_name.text.isEmpty) _name.text = k.name;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Panel(
        title: s.l('Nome', "Ім'я"),
        control: Container(
          width: 240,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: TextField(
              controller: _name,
              style: ts(18),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              onSubmitted: (v) => s.updateKid(k.id, (x) => x.name = v.trim().isEmpty ? x.name : v.trim()),
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
                final v = _name.text.trim();
                if (v.isNotEmpty && v != k.name) s.updateKid(k.id, (x) => x.name = v);
              },
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Panel(
        title: s.l('Avatar', 'Аватар'),
        text: s.l('Al posto della foto – dal set di prova', 'Замість фото – з тестового набору'),
        control: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final a in avatars) ...[
            if (a != avatars.first) const SizedBox(width: 12),
            Semantics(
              button: true,
              selected: k.av == a,
              label: 'Avatar $a',
              child: GestureDetector(
                onTap: () => s.updateKid(k.id, (x) => x.av = a),
                child: Container(
                  foregroundDecoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: k.av == a ? _action : C.nav, width: k.av == a ? 4 : 2)),
                  child: Avatar(av: a, size: 72),
                ),
              ),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 24),
      Panel(
        title: s.l('Lingua dei giochi', 'Мова ігор'),
        text: '${s.l('Nomi degli animali, passi delle routine e voce per', 'Назви тварин, кроки рутин і озвучка для')} ${k.name}',
        control: Seg(
          options: const [MapEntry('it', 'Italiano'), MapEntry('uk', 'Українська')],
          value: k.lang,
          onChanged: (v) => s.updateKid(k.id, (x) => x.lang = v),
        ),
      ),
      const SizedBox(height: 24),
      Panel(
        title: s.l("Suono toccando l'immagine", 'Звук від дотику до картинки'),
        text: s.l("Il suono parte anche toccando l'illustrazione, non solo il pulsante del suono", 'Звук вмикає не лише кнопка звуку, а й сама ілюстрація'),
        control: Seg(
          options: [MapEntry('1', s.l('Sì', 'Так')), MapEntry('0', s.l('No', 'Ні'))],
          value: k.img ? '1' : '0',
          onChanged: (v) => s.updateKid(k.id, (x) => x.img = v == '1'),
        ),
      ),
      const SizedBox(height: 24),
      Panel(
        title: s.l('La giornata di oggi', 'Сьогоднішній день'),
        text: s.l('Azzera i passi segnati di oggi in tutte le routine', 'Знімає сьогоднішні позначки в усіх рутинах'),
        control: PlainBtn(
          onBlock: true,
          label: switch (_confirm) {
            1 => s.l('Tocca ancora per confermare', 'Натисни ще раз, щоб підтвердити'),
            2 => s.l('Fatto', 'Готово'),
            _ => s.l('Ricomincia', 'Почати знову'),
          },
          onTap: () => _reset(s),
        ),
      ),
    ]);
  }
}
