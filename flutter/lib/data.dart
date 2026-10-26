// Content of the child mode: texts (it / uk), sound books and routines.
// Ported from the web prototype (p_text.js, p_books.js, p_app.js).
import 'package:flutter/painting.dart';

const Map<String, String> voiceOf = {'it': 'it-IT', 'uk': 'uk-UA'};

const Map<String, Map<String, String>> uiText = {
  'it': {
    'homeTitle': 'Cosa facciamo oggi?',
    'holdHint': 'Per i genitori: tieni premuto 2 secondi',
    'books': 'Libri sonori',
    'booksSub': 'Animali, musica e suoni',
    'day': 'La mia giornata',
    'daySub': 'Le attività di oggi',
    'finito': 'Finito!',
    'again': 'Ricomincia',
    'markDone': 'Segna come fatto',
    'isDone': 'Fatto',
    'listen': 'Ascolta',
    'noRoutines': 'Oggi niente routine',
  },
  'uk': {
    'homeTitle': 'Чим займемося сьогодні?',
    'holdHint': 'Для батьків: утримуйте 2 секунди',
    'books': 'Звукові книжечки',
    'booksSub': 'Тварини, музика і звуки',
    'day': 'Мій день',
    'daySub': 'Справи на сьогодні',
    'finito': 'Готово!',
    'again': 'Почати знову',
    'markDone': 'Позначити виконаним',
    'isDone': 'Виконано',
    'listen': 'Слухати',
    'noRoutines': 'Сьогодні без рутин',
  },
};

// ---------- Sound books ----------
const List<List<String>> books = [
  ['fox', 'wolf', 'owl', 'woodpecker', 'mouse'],
  ['cow', 'pig', 'horse', 'rooster'],
  ['music', 'piano', 'guitar', 'violin', 'tambourine', 'xylophone'],
  ['whale', 'dolphin', 'shell', 'turtle', 'gull'],
  ['tractor', 'plane', 'car', 'boat', 'heli'],
];
// Each book has its own light tint on the shelf: forest, farm, music, sea, transport
const List<Color> bookTints = [
  Color(0xFFE9F3E5),
  Color(0xFFFBECE4),
  Color(0xFFF1EBF8),
  Color(0xFFE5F1F7),
  Color(0xFFFBF3DC),
];
String bookCover(int i) => i == 4 ? 'heli' : books[i][0];
// Covers drawn a bit smaller so they are not cropped on the tile
const Set<String> smallCovers = {'fox', 'cow', 'whale', 'heli'};

const Map<String, List<String>> bookNames = {
  'it': ['Gli animali del bosco', 'Gli animali della fattoria', 'La musica classica', 'Gli animali del mare', 'I mezzi di trasporto'],
  'uk': ['Лісові тварини', 'Тварини з ферми', 'Класична музика', 'Морські тварини', 'Транспорт'],
};
const Map<String, List<List<String>>> pageNames = {
  'it': [
    ['La volpe', 'Il lupo', 'Il gufo', 'Il picchio', 'Il topo'],
    ['La mucca', 'Il maiale', 'Il cavallo', 'Il gallo'],
    ['Gli strumenti', 'Il pianoforte', 'La chitarra', 'Il violino', 'Il tamburello', 'Lo xilofono'],
    ['La balena', 'Il delfino', 'La conchiglia', 'La tartaruga', 'Il gabbiano'],
    ['Il trattore', "L'aereo", 'La macchina', 'La barca', "L'elicottero"],
  ],
  'uk': [
    ['Лисичка', 'Вовк', 'Сова', 'Дятел', 'Мишка'],
    ['Корова', 'Свинка', 'Конячка', 'Півник'],
    ['Інструменти', 'Піаніно', 'Гітара', 'Скрипка', 'Бубон', 'Ксилофон'],
    ['Кит', 'Дельфін', 'Мушля', 'Черепаха', 'Чайка'],
    ['Трактор', 'Літак', 'Машинка', 'Кораблик', 'Вертоліт'],
  ],
};

// ---------- Routines ----------
class RStep {
  const RStep(this.img, this.tint);
  final String img;
  final Color tint;
}

class Routine {
  const Routine({required this.id, required this.tint, required this.cover, required this.steps, this.therapy = false});
  final String id;
  final Color tint;
  final String cover;
  final bool therapy;
  final List<RStep> steps;
}

const _green = Color(0xFFE9F3E5);
const _yellow = Color(0xFFFBF3DC);
const _blue = Color(0xFFE5F1F7);
const _peach = Color(0xFFFBECE4);
const _lilac = Color(0xFFF1EBF8);
const _night = Color(0xFFE8EAF6);

const List<Routine> routines = [
  Routine(id: 'mattina', tint: _yellow, cover: 'sun', steps: [RStep('makebed', _lilac), RStep('teeth', _blue), RStep('hands', _green), RStep('towel', _peach)]),
  Routine(id: 'scuola', tint: _blue, cover: 'school', steps: [RStep('dress', _lilac), RStep('shoes', _yellow), RStep('jacket', _blue), RStep('stroller', _green)]),
  Routine(id: 'logo', tint: Color(0xFFE5F2F8), cover: 'blocks', therapy: true, steps: [RStep('stroller', _green), RStep('busstop', _yellow), RStep('bus', _blue), RStep('blocks', Color(0xFFE5F2F8))]),
  Routine(id: 'fisio', tint: _peach, cover: 'teddy', therapy: true, steps: [RStep('shoes', _yellow), RStep('jacket', _blue), RStep('stroller', _green), RStep('exercise', _peach)]),
  Routine(id: 'pranzo', tint: _blue, cover: 'lunch', steps: [RStep('hands', _blue), RStep('chair', _yellow), RStep('pasta', _peach), RStep('water', _green)]),
  Routine(id: 'passeggio', tint: _green, cover: 'park', steps: [RStep('shoes', _yellow), RStep('jacket', _blue), RStep('backpack', _peach), RStep('stroller', _green)]),
  Routine(id: 'casa', tint: _peach, cover: 'house', steps: [RStep('stroller', _green), RStep('busstop', _yellow), RStep('bus', _blue), RStep('house', _peach)]),
  Routine(id: 'nanna', tint: _night, cover: 'moon', steps: [RStep('pajamas', _night), RStep('teeth', _blue), RStep('hands', _green), RStep('towel', _peach)]),
];
Routine routineById(String id) => routines.firstWhere((r) => r.id == id);
// Speech therapy and physiotherapy cards are hidden from the child catalog for now (Nina's choice)
const Set<String> hiddenForChild = {'logo', 'fisio'};

const Map<String, Map<String, String>> routineNames = {
  'it': {
    'mattina': 'La mia mattina',
    'scuola': 'Vado a scuola',
    'logo': 'Andiamo a terapia',
    'fisio': 'Andiamo da Ilaria',
    'pranzo': 'Il pranzo',
    'passeggio': 'Andiamo a passeggio',
    'casa': 'Torno a casa',
    'nanna': 'La nanna',
  },
  'uk': {
    'mattina': 'Мій ранок',
    'scuola': 'Їду до садочка',
    'logo': 'Йдемо на терапію',
    'fisio': 'Йдемо до Іларії',
    'pranzo': 'Обід',
    'passeggio': 'Збираємося гуляти',
    'casa': 'Повертаюся додому',
    'nanna': 'Час спати',
  },
};

const Map<String, Map<String, List<String>>> stepNames = {
  'it': {
    'mattina': ['Rifaccio il letto', 'Lavo i denti', 'Lavo le mani', 'Mi asciugo le mani'],
    'scuola': ['Mi vesto', 'Metto le scarpe', 'Metto la giacca', 'Mi siedo nel passeggino'],
    'logo': ['Mi siedo nel passeggino', 'Andiamo alla fermata', "Saliamo sull'autobus", 'Aspettiamo Natalina'],
    'fisio': ['Metto le scarpe', 'Metto la giacca', 'Mi siedo nel passeggino', 'Aspettiamo Ilaria'],
    'pranzo': ['Lavo le mani', 'Mi siedo a tavola', 'Mangio la pasta', "Bevo l'acqua"],
    'passeggio': ['Metto le scarpe', 'Metto la giacca', 'Prendo lo zaino', 'Mi siedo nel passeggino'],
    'casa': ['Mi siedo nel passeggino', 'Andiamo alla fermata', "Saliamo sull'autobus", 'Arriviamo a casa'],
    'nanna': ['Metto il pigiama', 'Lavo i denti', 'Lavo le mani', 'Mi asciugo le mani'],
  },
  'uk': {
    'mattina': ['Застеляю ліжко', 'Чищу зубки', 'Мию ручки', 'Витираю ручки'],
    'scuola': ['Одягаюся', 'Взуваюся', 'Одягаю куртку', 'Сідаю у візочок'],
    'logo': ['Сідаю у візочок', 'Йдемо на зупинку', 'Сідаємо в автобус', 'Чекаємо Наталіну'],
    'fisio': ['Взуваюся', 'Одягаю куртку', 'Сідаю у візочок', 'Чекаємо Іларію'],
    'pranzo': ['Мию руки', 'Сідаю за стіл', 'Їм пасту', "П'ю воду"],
    'passeggio': ['Взуваюся', 'Одягаю куртку', 'Беру рюкзачок', 'Сідаю у візочок'],
    'casa': ['Сідаю у візочок', 'Йдемо на зупинку', 'Сідаємо в автобус', 'Приходимо додому'],
    'nanna': ['Одягаю піжамку', 'Чищу зубки', 'Мию ручки', 'Витираю ручки'],
  },
};

// Flat placeholders for pictures that have no 3D asset yet (therapy routines only)
const Map<String, String> flatArt = {
  'blocks': r'<svg viewBox="0 0 200 170" xmlns="http://www.w3.org/2000/svg"><rect x="70" y="22" width="56" height="56" rx="10" fill="#F6C453"/><rect x="34" y="84" width="60" height="60" rx="12" fill="#E88B8B"/><rect x="100" y="84" width="60" height="60" rx="12" fill="#6FA8DC"/><circle cx="166" cy="118" r="26" fill="#7FB685"/></svg>',
  'teddy': r'<svg viewBox="0 0 200 170" xmlns="http://www.w3.org/2000/svg"><circle cx="66" cy="40" r="20" fill="#B98F6A"/><circle cx="134" cy="40" r="20" fill="#B98F6A"/><circle cx="66" cy="40" r="10" fill="#E8C9A6"/><circle cx="134" cy="40" r="10" fill="#E8C9A6"/><ellipse cx="100" cy="128" rx="54" ry="40" fill="#C9A07A"/><circle cx="100" cy="70" r="44" fill="#C9A07A"/><ellipse cx="100" cy="84" rx="18" ry="13" fill="#E8C9A6"/><circle cx="84" cy="64" r="5" fill="#3A3328"/><circle cx="116" cy="64" r="5" fill="#3A3328"/><circle cx="100" cy="79" r="5" fill="#3A3328"/><ellipse cx="100" cy="132" rx="26" ry="22" fill="#E8C9A6"/></svg>',
  'exercise': r'<svg viewBox="0 0 200 170" xmlns="http://www.w3.org/2000/svg"><ellipse cx="100" cy="154" rx="78" ry="10" fill="#DCE3DE"/><circle cx="100" cy="88" r="64" fill="#7FB8E0"/><path d="M42 70c30 14 86 14 116 0" stroke="#FFFFFF" stroke-width="8" fill="none" stroke-linecap="round"/><path d="M48 116c28-12 76-12 104 0" stroke="#5E9ACB" stroke-width="8" fill="none" stroke-linecap="round"/></svg>',
};
