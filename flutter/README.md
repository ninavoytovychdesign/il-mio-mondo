# Il mio mondo – застосунок для Android (Flutter)

Дитячий режим «Il mio mondo» для Остапа: звукові книжечки, рутини дня з кроками й «лампочкою», озвучка назв.

- Код у `lib/`:
  - `data.dart` – тексти, книжечки, рутини;
  - `screens.dart` – екрани;
  - `ui.dart` – токени й компоненти;
  - `app_state.dart` – збереження прогресу, звук і озвучка.
- Асети: `assets/img`, `assets/snd`, шрифт Nunito (`assets/fonts`, OFL).
- APK збирає GitHub Actions (`.github/workflows/android.yml`) при кожному push у `flutter/`. Готовий файл – у релізі «android-latest».
- `ci/debug.keystore` – ключ підпису: з ним оновлення ставляться поверх старої версії, і прогрес не губиться.
