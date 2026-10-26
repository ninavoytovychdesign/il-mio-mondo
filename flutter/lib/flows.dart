// Flows of the parents' area: modals, adding a child, onboarding, new routine, adding a step, photos.
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'app_state.dart';
import 'data.dart';
import 'mom.dart';
import 'ui.dart';

const int nameMax = 24;
const int stepMax = 40;
const List<String> coverKeys = ['sun', 'school', 'lunch', 'park', 'house', 'moon', 'blocks', 'teddy'];
const List<String> stepLib = ['makebed', 'teeth', 'hands', 'towel', 'dress', 'shoes', 'jacket', 'backpack', 'stroller', 'busstop', 'bus', 'house', 'chair', 'pasta', 'water', 'pajamas', 'waitroom', 'blocks', 'exercise'];
const Map<String, Map<String, String>> stepLibNames = {
  'it': {'makebed': 'Rifaccio il letto', 'teeth': 'Lavo i denti', 'hands': 'Lavo le mani', 'towel': 'Mi asciugo le mani', 'dress': 'Mi vesto', 'shoes': 'Metto le scarpe', 'jacket': 'Metto la giacca', 'backpack': 'Prendo lo zaino', 'stroller': 'Mi siedo nel passeggino', 'busstop': 'Andiamo alla fermata', 'bus': "Saliamo sull'autobus", 'house': 'Arriviamo a casa', 'chair': 'Mi siedo a tavola', 'pasta': 'Mangio', 'water': "Bevo l'acqua", 'pajamas': 'Metto il pigiama', 'waitroom': 'Aspettiamo', 'blocks': 'Giochiamo', 'exercise': 'Faccio gli esercizi'},
  'uk': {'makebed': 'Застеляю ліжко', 'teeth': 'Чищу зубки', 'hands': 'Мию ручки', 'towel': 'Витираю ручки', 'dress': 'Одягаюся', 'shoes': 'Взуваюся', 'jacket': 'Одягаю куртку', 'backpack': 'Беру рюкзачок', 'stroller': 'Сідаю у візочок', 'busstop': 'Йдемо на зупинку', 'bus': 'Сідаємо в автобус', 'house': 'Приходимо додому', 'chair': 'Сідаю за стіл', 'pasta': 'Їм', 'water': "П'ю воду", 'pajamas': 'Одягаю піжамку', 'waitroom': 'Чекаємо', 'blocks': 'Граємося', 'exercise': 'Роблю вправи'},
};

// =====================================================================
// Modal: a card in the middle on a tablet, a sheet from below on a phone
// =====================================================================
Future<T?> openModal<T>(BuildContext context, WidgetBuilder builder, {bool wide = false}) {
  if (isPhone(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.92), child: builder(ctx)),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0x613A3328),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCard)),
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 760 : 560), child: builder(ctx)),
    ),
  );
}

/// Title, text, content and buttons of a modal. [dirty] = there is something typed: closing asks first.
class ModalFrame extends StatelessWidget {
  const ModalFrame({super.key, required this.title, this.text, this.child, required this.actions, this.dirty});
  final String title;
  final String? text;
  final Widget? child;
  final List<Widget> actions;
  final bool Function()? dirty;

  @override
  Widget build(BuildContext context) {
    final pad = isPhone(context) ? 20.0 : 28.0;
    final content = Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: ts(isPhone(context) ? 21 : 24)),
          if (text != null) ...[const SizedBox(height: 12), Text(text!, style: ts(17, w: FontWeight.w500, color: C.ink2, height: 1.45))],
          if (child != null) ...[const SizedBox(height: 16), Flexible(child: SingleChildScrollView(child: child))],
          const SizedBox(height: 20),
          Wrap(alignment: WrapAlignment.end, spacing: 12, runSpacing: 12, children: actions),
        ],
      ),
    );
    if (dirty == null) return content;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (!dirty!() || await confirmLeave(context)) nav.pop();
      },
      child: content,
    );
  }
}

class DangerBtn extends StatelessWidget {
  const DangerBtn({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Press(
        onTap: onTap,
        color: const Color(0xFFB4441E),
        radius: 999,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(widthFactor: 1, child: Text(label, style: ts(20, color: Colors.white))),
      );
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String text, required String ok, bool danger = false}) async {
  final s = AppScope.of(context);
  final r = await openModal<bool>(
    context,
    (ctx) => ModalFrame(title: title, text: text, actions: [
      PlainBtn(label: s.l('Annulla', 'Скасувати'), onTap: () => Navigator.pop(ctx, false)),
      danger ? DangerBtn(label: ok, onTap: () => Navigator.pop(ctx, true)) : PlainBtn(label: ok, primary: true, onTap: () => Navigator.pop(ctx, true)),
    ]),
  );
  return r == true;
}

Future<bool> confirmLeave(BuildContext context) {
  final s = AppScope.of(context);
  return confirmDialog(context,
      title: s.l('Uscire senza salvare?', 'Вийти без збереження?'),
      text: s.l('Quello che hai scritto andrà perso.', 'Те, що ти ввела, не збережеться.'),
      ok: s.l('Esci', 'Вийти'),
      danger: true);
}

Future<bool> micExplain(BuildContext context) {
  final s = AppScope.of(context);
  return confirmDialog(context,
      title: s.l('Note vocali', 'Голосові нотатки'),
      text: s.l('Il microfono serve solo per registrare le tue note nel diario. Le registrazioni restano su questo dispositivo e non vengono inviate a nessuno.',
          'Мікрофон потрібен лише, щоб записувати твої нотатки в щоденник. Записи лишаються на цьому пристрої й нікуди не надсилаються.'),
      ok: s.l('Continua', 'Продовжити'));
}

/// A photo from the gallery, made small and kept in the app's own folder
Future<String?> pickPhoto(BuildContext context) async {
  final s = AppScope.of(context);
  try {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 900, maxHeight: 900, imageQuality: 85);
    if (x == null) return null;
    if (kIsWeb) return x.path;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(x.path).copy(path);
    return path;
  } catch (_) {
    if (context.mounted) toast(context, s.l('Non è stato possibile aprire le foto', 'Не вдалося відкрити фото'));
    return null;
  }
}

// =====================================================================
// A child's form: name, avatar (set or own photo), language, starting routines
// =====================================================================
class KidDraft {
  String name = '';
  String av = 'ostap';
  String? photo;
  String lang = 'it';
  Set<String> templates = {'mattina', 'pranzo', 'nanna'};
}

class KidForm extends StatefulWidget {
  const KidForm({super.key, required this.draft, required this.onChanged, this.withRoutines = true});
  final KidDraft draft;
  final VoidCallback onChanged;
  final bool withRoutines;

  @override
  State<KidForm> createState() => _KidFormState();
}

class _KidFormState extends State<KidForm> {
  late final TextEditingController _name = TextEditingController(text: widget.draft.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = widget.draft;
    final left = nameMax - _name.text.length;
    final avSize = isPhone(context) ? 56.0 : 72.0;
    Widget avBtn({required bool on, required Widget child, required VoidCallback onTap, String? label}) => Semantics(
          button: true,
          selected: on,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: avSize,
              height: avSize,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: C.surface),
              foregroundDecoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? C.success : C.nav, width: on ? 4 : 2)),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      lbl(s.l('Nome', "Ім'я")),
      const SizedBox(height: 8),
      _Field(
        controller: _name,
        hint: s.l('Come si chiama?', 'Як звати дитину?'),
        max: nameMax,
        onChanged: (v) {
          d.name = v;
          _changed();
        },
      ),
      if (left <= 6) Padding(padding: const EdgeInsets.only(top: 6), child: Text(s.l('Ancora $left caratteri', 'Залишилось $left символів'), style: ts(14, w: FontWeight.w500, color: C.ink2))),
      const SizedBox(height: 16),
      lbl(s.l('Avatar', 'Аватар')),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (final a in avatars)
          avBtn(
            on: d.photo == null && d.av == a,
            label: 'Avatar $a',
            onTap: () {
              d.av = a;
              d.photo = null;
              _changed();
            },
            child: Avatar(av: a, size: avSize),
          ),
        avBtn(
          on: d.photo != null,
          label: s.l('La tua foto', 'Своє фото'),
          onTap: () async {
            final p = await pickPhoto(context);
            if (p != null) {
              d.photo = p;
              _changed();
            }
          },
          child: d.photo != null ? photoImage(d.photo!) : Center(child: icon(MI.plus, 28, C.navInk)),
        ),
      ]),
      const SizedBox(height: 16),
      lbl(s.l('Lingua dei giochi', 'Мова ігор')),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: Seg(
          options: const [MapEntry('it', 'Italiano'), MapEntry('uk', 'Українська')],
          value: d.lang,
          onChanged: (v) {
            d.lang = v;
            _changed();
          },
        ),
      ),
      if (widget.withRoutines) ...[
        const SizedBox(height: 16),
        lbl(s.l('Routine per iniziare', 'Рутини для початку')),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final n = box.maxWidth < 480 ? 1 : 2;
          final w = (box.maxWidth - 8 * (n - 1)) / n;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in routines.where((r) => !r.therapy))
              SizedBox(
                width: w,
                child: GestureDetector(
                  onTap: () {
                    d.templates.contains(r.id) ? d.templates.remove(r.id) : d.templates.add(r.id);
                    _changed();
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(rImg)),
                    child: Row(children: [
                      Checkbox(value: d.templates.contains(r.id), activeColor: C.success, onChanged: (_) {
                        d.templates.contains(r.id) ? d.templates.remove(r.id) : d.templates.add(r.id);
                        _changed();
                      }),
                      thumb(r.cover, w: 52, h: 44, bg: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(routineNames[d.lang]![r.id]!, style: ts(16), maxLines: 2)),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
        const SizedBox(height: 8),
        noteText(s.l('Potrai cambiarle, aggiungerne altre o crearne di nuove in Routine.', 'Їх можна буде змінити, додати інші або створити нові у «Рутинах».')),
      ],
    ]);
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, required this.max, required this.onChanged, this.white = false});
  final TextEditingController controller;
  final String hint;
  final int max;
  final ValueChanged<String> onChanged;
  final bool white;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: white ? Colors.white : C.surface, borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: controller,
          maxLength: max,
          style: ts(18),
          decoration: InputDecoration(border: InputBorder.none, counterText: '', hintText: hint, hintStyle: ts(18, w: FontWeight.w500, color: C.ink3)),
          onChanged: onChanged,
        ),
      );
}

Widget textField({required TextEditingController controller, required String hint, required int max, required ValueChanged<String> onChanged, bool white = false}) =>
    _Field(controller: controller, hint: hint, max: max, onChanged: onChanged, white: white);

Future<void> openAddKid(BuildContext context, {ValueChanged<String>? onAdded}) {
  final s = AppScope.of(context);
  final d = KidDraft()..lang = s.ui;
  return openModal<void>(
    context,
    wide: true,
    (ctx) => StatefulBuilder(
      builder: (ctx, set) => ModalFrame(
        title: s.l('Aggiungi un bambino', 'Додати дитину'),
        dirty: () => d.name.trim().isNotEmpty || d.photo != null,
        child: KidForm(draft: d, onChanged: () => set(() {})),
        actions: [
          PlainBtn(label: s.l('Annulla', 'Скасувати'), onTap: () => Navigator.maybePop(ctx)),
          PlainBtn(
            label: s.l('Aggiungi', 'Додати'),
            primary: true,
            onTap: d.name.trim().isEmpty
                ? null
                : () {
                    final id = s.addKid(name: d.name, av: d.av, photo: d.photo, lang: d.lang, templates: d.templates.toList());
                    Navigator.pop(ctx);
                    toast(context, s.l('${d.name.trim()} è stato aggiunto', '${d.name.trim()} – профіль створено'));
                    onAdded?.call(id);
                  },
          ),
        ],
      ),
    ),
  );
}

// =====================================================================
// Onboarding: first start, or after «Elimina tutti i dati»
// =====================================================================
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int step = 0;
  final KidDraft d = KidDraft();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (step == 0 && d.name.isEmpty) d.lang = s.ui;
    final titles = [s.l('Benvenuti in Il mio mondo', 'Вітаємо в Il mio mondo'), s.l('Il primo bambino', 'Перша дитина'), s.l('La zona genitori', 'Батьківська частина')];
    final dots = Row(children: [
      for (var i = 0; i < 3; i++)
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: i == step ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(color: i == step ? C.success : C.nav, borderRadius: BorderRadius.circular(4)),
        ),
    ]);
    Widget card(List<Widget> children) => Container(
          padding: EdgeInsets.all(isPhone(context) ? 20 : 32),
          decoration: BoxDecoration(color: C.cardGreen, borderRadius: BorderRadius.circular(rCard)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );
    final Widget body;
    if (step == 0) {
      final text = card([
        Text(s.l('Routine con le immagini e libri sonori', 'Рутини з картинками і звукові книжечки'), style: ts(22)),
        const SizedBox(height: 12),
        noteText(s.l('Il bambino vede la sua giornata passo dopo passo e accende una lampadina per ogni passo fatto. Tu prepari le routine, segui il calendario e scrivi il diario.',
            'Дитина бачить свій день крок за кроком і запалює лампочку за кожен зроблений крок. Ти готуєш рутини, ведеш календар і щоденник.')),
        const SizedBox(height: 18),
        lbl(s.l("Lingua dell'app", 'Мова застосунку')),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: Seg(options: const [MapEntry('it', 'Italiano'), MapEntry('uk', 'Українська')], value: s.ui, onChanged: s.setUi)),
        const SizedBox(height: 24),
        Align(alignment: Alignment.centerLeft, child: PlainBtn(label: s.l('Inizia', 'Почати'), primary: true, onTap: () => setState(() => step = 1))),
        const SizedBox(height: 16),
        dots,
      ]);
      body = isPortrait(context)
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SizedBox(height: 280, child: picture('day')), const SizedBox(height: 24), text])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: AspectRatio(aspectRatio: 1, child: picture('day'))), const SizedBox(width: 32), Expanded(child: text)]);
    } else if (step == 1) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: card([
            KidForm(draft: d, onChanged: () => setState(() {})),
            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: PlainBtn(label: s.l('Avanti', 'Далі'), primary: true, onTap: d.name.trim().isEmpty ? null : () => setState(() => step = 2))),
            const SizedBox(height: 16),
            dots,
          ]),
        ),
      );
    } else {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: card([
            Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 72, height: 72, decoration: const BoxDecoration(color: C.nav, shape: BoxShape.circle), child: Center(child: icon(Ic.lock, 36, C.navInk))),
            ),
            const SizedBox(height: 18),
            Text(s.l('Per tornare qui: tieni premuto il lucchetto per 2 secondi', 'Щоб повернутися сюди: утримуй замок 2 секунди'), style: ts(22)),
            const SizedBox(height: 12),
            noteText(s.l("Nelle schermate di ${d.name.trim()} c'è un lucchetto in alto. Un tocco veloce non fa niente, così il bambino non esce per sbaglio.",
                'На екранах ${d.name.trim()} угорі є замок. Короткий дотик нічого не робить, тож дитина не вийде випадково.')),
            const SizedBox(height: 12),
            noteText(s.l('Tutti i dati restano su questo dispositivo: non servono account e niente viene inviato.', 'Усі дані лишаються на цьому пристрої: акаунт не потрібен, нічого нікуди не надсилається.')),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: PlainBtn(
                label: s.l('Apri Il mio mondo', 'Відкрити Il mio mondo'),
                primary: true,
                onTap: () {
                  s.clearWiped();
                  s.addKid(name: d.name, av: d.av, photo: d.photo, lang: d.lang, templates: d.templates.toList());
                },
              ),
            ),
            const SizedBox(height: 16),
            dots,
          ]),
        ),
      );
    }
    final pad = isPhone(context) ? 20.0 : (isPortrait(context) ? 32.0 : 40.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step > 0) setState(() => step--);
      },
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                if (step > 0) ...[NavBtn(svg: Ic.back, label: s.l('Indietro', 'Назад'), onTap: () => setState(() => step--)), const SizedBox(width: 16)],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titles[step], style: ts(isPhone(context) ? 26 : 32), maxLines: 2),
                    Text('${s.l('Passo', 'Крок')} ${step + 1} ${s.l('di', 'з')} 3', style: ts(16, w: FontWeight.w600, color: C.ink2)),
                  ]),
                ),
              ]),
              const SizedBox(height: 24),
              Expanded(child: SingleChildScrollView(child: body)),
            ]),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// New routine: from scratch or from a template
// =====================================================================
Future<void> openNewRoutine(BuildContext context, String kidId, ValueChanged<String> onCreated) {
  final s = AppScope.of(context);
  final have = {for (final r in s.kidRoutines(kidId)) r.base};
  Widget row({required Widget pic, required String name, required String sub, required VoidCallback onTap, bool blank = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CardRow(
          onTap: onTap,
          color: blank ? C.pGreen : C.surface,
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(children: [
            pic,
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: ts(17)),
                Text(sub, style: ts(14, w: FontWeight.w500, color: C.ink2)),
              ]),
            ),
            icon(MI.chevR, 24, C.ink2),
          ]),
        ),
      );
  return openModal<void>(
    context,
    wide: true,
    (ctx) => ModalFrame(
      title: s.l('Nuova routine', 'Нова рутина'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        row(
          blank: true,
          pic: Container(width: 64, height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Center(child: icon(MI.plus, 28, C.navInk))),
          name: s.l('Routine vuota', 'Порожня рутина'),
          sub: s.l('Scegli tu nome, immagine e passi', 'Назву, картинку й кроки обираєш сама'),
          onTap: () {
            final rid = s.addBlankRoutine(kidId);
            Navigator.pop(ctx);
            onCreated(rid);
          },
        ),
        const SizedBox(height: 8),
        lbl(s.l('Oppure parti da un modello', 'Або почни з шаблону')),
        const SizedBox(height: 8),
        for (final r in routines)
          row(
            pic: thumb(r.cover, w: 64, h: 52, bg: flatArt.containsKey(r.cover) ? r.tint : Colors.white),
            name: routineNames[s.ui]![r.id]!,
            sub: '${r.steps.length} ${s.l('passi', 'кроки')}${have.contains(r.id) ? ' · ${s.l('già in uso, ne fai una copia', 'вже є, буде копія')}' : ''}',
            onTap: () {
              final rid = s.addRoutineFrom(kidId, r.id);
              Navigator.pop(ctx);
              onCreated(rid);
            },
          ),
      ]),
      actions: [PlainBtn(label: s.l('Annulla', 'Скасувати'), onTap: () => Navigator.pop(ctx))],
    ),
  );
}

// =====================================================================
// Add a step: a picture from the set or own photo, and the name the tablet says
// =====================================================================
Future<void> openAddStep(BuildContext context, String kidId, String rid) {
  final s = AppScope.of(context);
  String? img;
  String? photo;
  var auto = true;
  final name = TextEditingController();
  return openModal<void>(
    context,
    wide: true,
    (ctx) => StatefulBuilder(builder: (ctx, set) {
      final ok = (img != null || photo != null) && name.text.trim().isNotEmpty;
      final cell = isPhone(ctx) ? 72.0 : 88.0;
      Widget tile({required bool on, required Widget child, required VoidCallback onTap, String? label}) => Semantics(
            button: true,
            selected: on,
            label: label,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: cell,
                height: cell,
                decoration: BoxDecoration(color: on ? C.pGreen : C.surface, borderRadius: BorderRadius.circular(18)),
                foregroundDecoration: on ? BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: C.success, width: 4)) : null,
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(6),
                child: child,
              ),
            ),
          );
      return ModalFrame(
        title: s.l('Aggiungi un passo', 'Додати крок'),
        dirty: () => img != null || photo != null || name.text.trim().isNotEmpty,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          lbl(s.l('Immagine', 'Картинка')),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            tile(
              on: photo != null,
              label: s.l('La tua foto', 'Своє фото'),
              onTap: () async {
                final p = await pickPhoto(ctx);
                if (p != null) set(() {
                  photo = p;
                  img = null;
                });
              },
              child: photo != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: photoImage(photo!))
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [icon(MI.plus, 24, C.navInk), const SizedBox(height: 4), Text(s.l('La tua foto', 'Своє фото'), style: ts(12, color: C.navInk), textAlign: TextAlign.center)]),
            ),
            for (final k in stepLib)
              tile(
                on: img == k,
                label: stepLibNames[s.ui]![k],
                onTap: () => set(() {
                  img = k;
                  photo = null;
                  if (auto) name.text = stepLibNames[s.lang]![k] ?? '';
                }),
                child: picture(k),
              ),
          ]),
          const SizedBox(height: 16),
          lbl(s.l('Nome del passo – il tablet lo dice ad alta voce', 'Назва кроку – планшет її промовляє')),
          const SizedBox(height: 8),
          textField(
            controller: name,
            hint: s.l('Per esempio: Lavo le mani', 'Наприклад: Мию ручки'),
            max: stepMax,
            onChanged: (v) => set(() => auto = v.isEmpty),
          ),
        ]),
        actions: [
          PlainBtn(label: s.l('Annulla', 'Скасувати'), onTap: () => Navigator.maybePop(ctx)),
          PlainBtn(
            label: s.l('Aggiungi', 'Додати'),
            primary: true,
            onTap: !ok
                ? null
                : () {
                    s.addStep(kidId, rid, StepDef(img: img ?? 'blocks', tint: 0xFFE9F3E5, name: name.text.trim(), photo: photo));
                    Navigator.pop(ctx);
                    toast(context, s.l('Passo aggiunto', 'Крок додано'));
                  },
          ),
        ],
      );
    }),
  );
}
