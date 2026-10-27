# Технічна частина

## Репозиторій

`github.com/ninavoytovychdesign/il-mio-mondo` (публічний)

| Шлях | Що там |
|---|---|
| `/` (index.html, sw.js, manifest) | Перша PWA-версія, GitHub Pages |
| `/privacy/` | Політика конфіденційності (IT, UK, EN) |
| `/flutter/` | Застосунок на Flutter |
| `/.github/workflows/android.yml` | Збірка в GitHub Actions |
| `/docs/` | Ця документація |

## Flutter-код (`flutter/lib`)

| Файл | Що робить |
|---|---|
| `main.dart` | Запуск, тема, локалізація |
| `data.dart` | Тексти, книжечки, шаблони рутин, розклад за замовчуванням, кредити звуків |
| `app_state.dart` | Стан: діти, розклад, рутини дитини, прогрес, нотатки; збереження й міграції; звук і озвучення |
| `ui.dart` | Спільні елементи: кнопки, аватари, картинки, 3D-поверхня |
| `screens.dart` | Дитячі екрани: головна, полиця, книжечка, мій день, кроки |
| `mom.dart` | Батьківська зона: усі вкладки, редактор рутини, профіль дитини, налаштування |
| `flows.dart` | Модалки й флоу: додати дитину, онбординг, нова рутина, новий крок, підтвердження, вибір фото |

Пакети: flutter_svg, audioplayers, flutter_tts, shared_preferences, wakelock_plus, path_provider, record, image_picker, url_launcher, flutter_localizations; flutter_launcher_icons для іконки.

## Збірка (GitHub Actions)

Кожен push у `main`, що змінює `flutter/**`, запускає `android.yml`:

1. `flutter create` генерує Android-проєкт; `ci/patch_android.py` вписує назву, дозволи, `allowBackup="false"`, `applicationId = it.pasetto.app`, `targetSdk = 36`.
2. Іконка, аналіз коду.
3. **APK** (для встановлення напряму, підписаний сталим debug-ключем) → реліз `android-latest` на GitHub.
4. **AAB** для Play – без підпису (`ci/unsign_release.py`), номер збірки = номер запуску CI, версія 0.3.0.
5. Веб-збірка для перевірки екранів.
6. Логи, AAB і веб-збірка – у гілку `ci-logs`.

## Підпис для Google Play

- Ключ завантаження: `pasetto-upload-keystore.jks`, аліас `upload`, SHA-256 `E2:B3:32:8B:DA:BA:E6:37:4D:F0:F3:CD:60:8F:33:CA:10:F5:65:6A:3B:DE:F4:C5:34:48:A1:7E:36:2A:36:1A`.
- Файл і пароль зберігаються в Ніни (менеджер паролів), **не в репозиторії**.
- Play App Signing увімкнений: ключ підпису для користувачів тримає Google. Якщо ключ завантаження загубиться, його скидають через підтримку Play.

Як підписати новий AAB:

```bash
cp pasetto-unsigned.aab pasetto-X.Y.Z.aab
jarsigner -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore pasetto-upload-keystore.jks pasetto-X.Y.Z.aab upload
jarsigner -verify pasetto-X.Y.Z.aab
```

Можна перенести підпис у CI: додати в GitHub Secrets ключ (base64) і пароль. Тоді AAB підписуватиметься сам.

## Як випустити нову версію

1. Змінити код, push у `main`.
2. Дочекатися зеленої збірки (`ci-logs/status.txt`).
3. Узяти `pasetto-unsigned.aab` з гілки `ci-logs`, підписати.
4. Play Console → потрібний трек → Create release → завантажити → нотатки → Review.
5. Якщо змінюється версія для людей – поправити `--build-name` у `android.yml`.

## Прототип

HTML-прототип (усі екрани й флоу) – окремий артефакт; його джерела в робочій папці, не в репозиторії. У прототипі ще стара назва «Il mio mondo».
