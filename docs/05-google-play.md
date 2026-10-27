# Публікація в Google Play

## Що вже готово

- Підписаний `pasetto-0.3.0.aab` (it.pasetto.app, target API 36, лише дозвіл на мікрофон).
- Тексти сторінки IT/UK/EN – [06-store-texts.md](06-store-texts.md).
- Іконка 512, банер 1024×500, 32 скріншоти.
- Політика конфіденційності: https://ninavoytovychdesign.github.io/il-mio-mondo/privacy/

## Кроки

1. Перевірити, що політика конфіденційності відкривається без входу.
2. Зареєструвати особистий акаунт розробника в Play Console: 25 $ одноразово, перевірка особи (може тривати кілька днів).
3. **Create app**: назва «Pasetto», мова за замовчуванням – італійська, App, безкоштовний.
4. **Policy → App content** – відповіді нижче.
5. **Store listing** трьома мовами + графіка.
6. **Testing → Closed testing**: трек, завантажити AAB, тестувальники, нотатки, Review.
7. Розіслати запрошення (opt-in посилання).
8. Через 14 днів – **Apply for production**.

## Відповіді для форм Play Console

| Форма | Відповідь | Чому |
|---|---|---|
| Privacy policy | посилання вище | обов'язково для дитячих застосунків; посилання є і в самому застосунку |
| App access | All functionality available without special access | входу немає; батьківська зона – утримання замочка |
| Ads | No | реклами немає |
| Content rating | All other app types, усі відповіді No | очікувано PEGI 3 / Everyone |
| Target audience | «5 and under» і «6–8» | діють правила Families |
| Teacher Approved | поки ні | подати пізніше |
| Data safety | «Does your app collect or share…» – No | усе на пристрої, без інтернету, автобекап вимкнений |
| Health apps | «My app does not have any health features» | освітній застосунок і органайзер; якщо Google заперечить – «Healthcare Services and Management» |
| Advertising ID | No | |
| News / Government / Financial | No | |
| Категорія | Education (Istruzione); запасний варіант – Parenting | |
| Ціна | Free, без покупок | |
| Країни | усі, або там, де живуть тестувальники | |

## Закритий тест

- Нові особисті акаунти (після 13.11.2023): **щонайменше 12 тестувальників, 14 днів поспіль** у тесті. Хто вийшов і повернувся – його 14 днів починаються наново. Кличте 15–20 людей.
- Тестувальникам потрібен Google-акаунт і Android.
- Внутрішнє тестування (Internal testing) цих вимог не має – так можна швидко дати застосунок терапевтам.
- Перевірка першої версії – від кількох годин до кількох днів.

## Важливо

- Версію з Play не встановити поверх APK з GitHub (різні ключі). Перед установкою з Play – видалити старі «Il mio mondo» і «Pasetto»; дані не переносяться.
- Кожна нова версія – той самий ключ завантаження і більший номер збірки (CI робить це сам).
- Target API: з 31.08.2026 нові застосунки й оновлення мають цілитися в API 36 – уже так.

## Джерела

- [Families Policy](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [Health Content and Services](https://support.google.com/googleplay/android-developer/answer/9878878?hl=en-GB)
- [Health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291)
- [Вимоги до тестування для нових особистих акаунтів](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
