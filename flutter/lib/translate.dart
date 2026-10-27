// Diary notes in the other language: Ukrainian ↔ Italian, translated on the device.
// Google ML Kit downloads each language model once (about 30 MB); after that it works offline
// and the text of the notes never leaves the tablet.
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// 'uk' if the text is mostly Cyrillic, otherwise 'it'
String noteLang(String text) {
  var cyr = 0, lat = 0;
  for (final r in text.runes) {
    if (r >= 0x0400 && r <= 0x04FF) {
      cyr++;
    } else if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A) || (r >= 0xC0 && r <= 0x24F)) {
      lat++;
    }
  }
  return cyr > lat ? 'uk' : 'it';
}

class NoteTranslator {
  NoteTranslator._();
  static final NoteTranslator instance = NoteTranslator._();

  /// Works only in the Android app (ML Kit has no web version)
  bool get available => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final Map<String, OnDeviceTranslator> _tr = {};
  final Map<String, Future<String?>> _running = {};

  static TranslateLanguage _lang(String code) => code == 'uk' ? TranslateLanguage.ukrainian : TranslateLanguage.italian;

  /// The translated text, or null when it is not possible right now (no model yet and no internet)
  Future<String?> translate(String text, String from, String to) {
    if (!available || from == to || text.trim().isEmpty) return Future.value(null);
    final key = '$from>$to|$text';
    return _running[key] ??= _run(text, from, to).whenComplete(() => _running.remove(key));
  }

  Future<String?> _run(String text, String from, String to) async {
    try {
      final mm = OnDeviceTranslatorModelManager();
      for (final code in [from, to]) {
        final bcp = _lang(code).bcpCode;
        if (!await mm.isModelDownloaded(bcp)) {
          final ok = await mm.downloadModel(bcp, isWifiRequired: false);
          if (!ok) return null;
        }
      }
      final t = _tr['$from>$to'] ??= OnDeviceTranslator(sourceLanguage: _lang(from), targetLanguage: _lang(to));
      final out = await t.translateText(text);
      return out.trim().isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }
}
