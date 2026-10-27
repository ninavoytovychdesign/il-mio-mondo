// Design tokens and shared pieces – the same soft 3D language as the web prototype.
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_state.dart';
import 'data.dart';

class C {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F6F2);
  static const ink = Color(0xFF3A3328);
  static const ink2 = Color(0xFF6B6152);
  static const ink3 = Color(0xFF7A7468);
  static const nav = Color(0xFFE6ECE7);
  static const navInk = Color(0xFF3E4C43);
  static const cardGreen = Color(0xFFF1F5F1);
  static const cardWarm = Color(0xFFF8F3EA);
  static const pGreen = Color(0xFFE9F3E5);
  static const audio = Color(0xFF4A9FDB);
  static const audioPlay = Color(0xFF3889C4);
  static const success = Color(0xFF2B8648);
  static const ring = Color(0xFFCFC9BE);
}

const double rCard = 32;
const double rImg = 24;
const double rBtn = 16;
const double navSize = 56;

TextStyle ts(double size, {FontWeight w = FontWeight.w700, Color color = C.ink, double height = 1.2, double spacing = 0}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: w, color: color, height: height, letterSpacing: spacing);

/// Phone: the short side is under 600 – same screens, tighter density
bool isPhone(BuildContext context) => MediaQuery.sizeOf(context).shortestSide < 600;

bool isPortrait(BuildContext context) {
  final s = MediaQuery.of(context).size;
  return s.height > s.width;
}

// ---------- Icons (SVG, currentColor replaced by the wanted colour) ----------
class Ic {
  static const back = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m15 5-7 7 7 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const next = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m9 5 7 7-7 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const arrow = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5 12h13M13 6l6 6-6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const sep = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 12h15M13 6l6 6-6 6" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const check = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m5 12.5 4.5 4.5L19 7.5" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  static const lock = r'<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><rect x="5" y="10.5" width="14" height="10" rx="3" stroke="currentColor" stroke-width="2"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><circle cx="12" cy="15.5" r="1.6" fill="currentColor"/></svg>';
  static const listen = r'<svg viewBox="0 0 104 104" fill="none" xmlns="http://www.w3.org/2000/svg"><g transform="translate(12.432 19.067)" fill="currentColor"><path d="M 33.166 0.433 C 46.166 3.033 51.068 8.933 50.068 22.933 C 47.468 15.567 39.205 13.233 31.405 11.933 L 31.405 52.868 C 30.897 58.182 26.577 63.401 20.14 65.745 C 11.819 68.773 3.114 65.849 0.699 59.215 C -1.714 52.582 2.248 44.962 10.568 41.933 C 14.997 40.321 20.527 41.511 24.166 42.933 L 24.166 0 L 28.666 0 L 33.166 0.433 Z"/><path d="M 70.045 6.551 C 71.931 4.716 74.95 4.754 76.786 6.64 C 83.634 13.677 87.462 23.112 87.463 32.932 C 87.463 42.751 83.633 52.186 76.786 59.224 C 74.95 61.11 71.932 61.152 70.045 59.317 C 68.158 57.481 68.116 54.462 69.952 52.576 C 75.068 47.317 77.933 40.268 77.933 32.932 C 77.932 25.596 75.067 18.55 69.952 13.292 C 68.116 11.405 68.158 8.387 70.045 6.551 Z"/><path d="M 58.801 17.795 C 60.701 15.973 63.72 16.035 65.542 17.934 C 69.412 21.968 71.572 27.342 71.572 32.932 C 71.572 38.522 69.412 43.899 65.542 47.933 C 63.72 49.833 60.701 49.895 58.801 48.073 C 56.901 46.25 56.839 43.231 58.661 41.332 C 60.828 39.072 62.038 36.062 62.038 32.932 C 62.038 29.801 60.828 26.79 58.661 24.532 C 56.84 22.632 56.903 19.617 58.801 17.795 Z"/></g></svg>';
}

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

Widget icon(String svg, double size, Color color) =>
    SvgPicture.string(svg.replaceAll('currentColor', _hex(color)), width: size, height: size);

/// A photo the parent picked (a file on the device; a blob address in the web preview)
Widget photoImage(String path, {BoxFit fit = BoxFit.cover}) =>
    kIsWeb ? Image.network(path, fit: fit) : Image.file(File(path), fit: fit, errorBuilder: (_, __, ___) => const ColoredBox(color: C.surface));

/// A step's picture: the parent's photo, or the picture from the set
Widget stepPicture(StepDef s, {BoxFit fit = BoxFit.contain}) => s.photo != null ? photoImage(s.photo!) : picture(s.img, fit: fit);

/// A routine cover can be the parent's own photo: kept as 'photo:<path>'
bool isPhotoKey(String key) => key.startsWith('photo:');

/// A picture by key: a 3D asset from assets/img, or a flat placeholder SVG
Widget picture(String key, {BoxFit fit = BoxFit.contain}) {
  if (isPhotoKey(key)) return photoImage(key.substring(6));
  final flat = flatArt[key];
  if (flat != null) return SvgPicture.string(flat, fit: fit);
  return Image.asset('assets/img/$key.webp', fit: fit, filterQuality: FilterQuality.medium);
}

// ---------- Soft 3D surface ----------
/// The soft 3D look: a light highlight along the top edge, a faint shade along the bottom
/// and a small soft drop. Pressing moves it 1 px down and the drop disappears.
BoxDecoration soft3d(Color color, {BorderRadius? radius, bool circle = false, bool pressed = false, bool flat = false}) => BoxDecoration(
      color: color,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : radius,
    );

BoxDecoration soft3dOverlay({BorderRadius? radius, bool circle = false, bool pressed = false}) => BoxDecoration(
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : radius,
      // flat like the screens in Figma; only the pressed state gets a soft inner shade on top
      gradient: pressed
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x293E4C43), Color(0x003E4C43), Color(0x003E4C43)],
              stops: [0, 0.12, 1],
            )
          : null,
    );

/// Generic pressable surface (buttons and cards)
class Press extends StatefulWidget {
  const Press({
    super.key,
    required this.child,
    required this.onTap,
    this.color = Colors.white,
    this.radius = rBtn,
    this.circle = false,
    this.width,
    this.height,
    this.padding,
    this.flat = false,
    this.label,
  });
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final bool circle;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool flat;
  final String? label;

  @override
  State<Press> createState() => _PressState();
}

class _PressState extends State<Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final br = BorderRadius.circular(widget.radius);
    final pressed = _down && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            transform: Matrix4.translationValues(0, pressed ? 1 : 0, 0),
            decoration: soft3d(widget.color, radius: br, circle: widget.circle, pressed: pressed, flat: widget.flat || !enabled),
            foregroundDecoration: widget.flat ? null : soft3dOverlay(radius: br, circle: widget.circle, pressed: pressed),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Round or rounded-square navigation button (56 × 56)
class NavBtn extends StatelessWidget {
  const NavBtn({super.key, required this.svg, required this.onTap, this.round = true, this.label});
  final String svg;
  final VoidCallback? onTap;
  final bool round;
  final String? label;

  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        color: C.nav,
        circle: round,
        width: navSize,
        height: navSize,
        label: label,
        child: Center(child: icon(svg, round ? 24 : 28, C.navInk)),
      );
}

/// A pressable card (section cards, book tiles): no shadow, presses in slightly
class CardPress extends StatefulWidget {
  const CardPress({super.key, required this.child, required this.onTap, required this.color, this.label});
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final String? label;

  @override
  State<CardPress> createState() => _CardPressState();
}

class _CardPressState extends State<CardPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: widget.onTap != null,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 90),
            scale: _down && widget.onTap != null ? 0.985 : 1,
            child: Container(
              padding: isPhone(context) ? const EdgeInsets.fromLTRB(10, 10, 10, 16) : const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(isPhone(context) ? 24 : rCard)),
              child: widget.child,
            ),
          ),
        ),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.size = navSize, this.av, this.photo});
  final double size;
  final String? av;
  final String? photo;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: photo != null ? photoImage(photo!) : Transform.scale(scale: 1.12, child: Image.asset('assets/img/av_${av ?? 'ostap'}.webp', fit: BoxFit.cover)),
      );
}

/// Screen frame: white page, 1200 px max width, 40 px padding, header + content with a 32 px gap
class Frame extends StatelessWidget {
  const Frame({super.key, required this.head, required this.body, this.gap = 32});
  final Widget head;
  final Widget body;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final pad = isPhone(context) ? 20.0 : (isPortrait(context) ? 32.0 : 40.0);
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200 + pad * 2),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [head, SizedBox(height: isPhone(context) ? 20 : gap), Expanded(child: body)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header: back button, title, optional right part
class Head extends StatelessWidget {
  const Head({super.key, required this.title, this.onBack, this.trailing});
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: navSize,
        child: Row(
          children: [
            if (onBack != null) ...[NavBtn(svg: Ic.back, label: AppScope.of(context).tr('back'), onTap: onBack), const SizedBox(width: 16)],
            Expanded(child: Text(title, style: ts(isPhone(context) ? 24 : 32), maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (trailing != null) ...[const SizedBox(width: 16), trailing!],
          ],
        ),
      );
}

/// Green round badge with a check mark
class DoneBadge extends StatelessWidget {
  const DoneBadge({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: soft3d(C.success, circle: true),
        foregroundDecoration: soft3dOverlay(circle: true),
        child: Center(child: icon(Ic.check, size * 0.58, Colors.white)),
      );
}
