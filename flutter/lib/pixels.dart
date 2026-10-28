// Pixel animals for the piano game: 12×11 cells, one letter per cell, '.' = empty.
// Simple, chunky shapes like the lights of a toy piano.
import 'package:flutter/painting.dart';

class PixArt {
  const PixArt(this.rows, this.colors);
  final List<String> rows;
  final Map<String, Color> colors;
}

const _k = Color(0xFF3A3328); // eyes, nose
const _w = Color(0xFFFFFDF7);

const Map<String, PixArt> pixArt = {
  'fox': PixArt([
    '.O........O.',
    '.OO......OO.',
    '.OOO....OOO.',
    '.OOOOOOOOOO.',
    'OOOOOOOOOOOO',
    'OOKOOOOOOKOO',
    'OOOOOOOOOOOO',
    'WWOOOOOOOOWW',
    '.WWWOOOOWWW.',
    '..WWWKKWWW..',
    '...WWWWWW...',
  ], {'O': Color(0xFFF08A3E), 'W': _w, 'K': _k}),
  'owl': PixArt([
    '.B........B.',
    '.BBBBBBBBBB.',
    'BBWWWBBWWWBB',
    'BWWKWWWWKWWB',
    'BBWWWBBWWWBB',
    'BBBBBYYBBBBB',
    'BBTTBBBBTTBB',
    'BBBTTTTTTBBB',
    'BBBTTTTTTBBB',
    '.BBBTTTTBBB.',
    '..YY....YY..',
  ], {'B': Color(0xFF9C6B43), 'W': _w, 'K': _k, 'Y': Color(0xFFF6C344), 'T': Color(0xFFE8C9A0)}),
  'mouse': PixArt([
    'GG........GG',
    'GPG......GPG',
    'GPPG....GPPG',
    '.GGGGGGGGGG.',
    '.GGGGGGGGGG.',
    '.GKGGGGGGKG.',
    '.GGGGGGGGGG.',
    '..GGGGGGGG..',
    '...GGPPGG...',
    '....GGGG....',
    '.....GG.....',
  ], {'G': Color(0xFFA9A9B3), 'P': Color(0xFFF2A7B8), 'K': _k}),
  'cow': PixArt([
    'KK........KK',
    '.KWWWWWWWWK.',
    '..WWKKWWWW..',
    '..WKKWWWWW..',
    '..WWWWWKKW..',
    '..WKWWWWKW..',
    '..WWWWWWWW..',
    '.PPPPPPPPPP.',
    '.PKPPPPPPKP.',
    '.PPPPPPPPPP.',
    '..PPPPPPPP..',
  ], {'W': _w, 'K': _k, 'P': Color(0xFFF2A7B8)}),
  'pig': PixArt([
    '.PP......PP.',
    '.PPP....PPP.',
    '.PPPPPPPPPP.',
    'PPPPPPPPPPPP',
    'PPKPPPPPPKPP',
    'PPPPPPPPPPPP',
    'PPPPRRRRPPPP',
    'PPPRKRRKRPPP',
    'PPPRRRRRRPPP',
    '.PPPPPPPPPP.',
    '..PPPPPPPP..',
  ], {'P': Color(0xFFF7B6C2), 'R': Color(0xFFEC8FA3), 'K': _k}),
  'horse': PixArt([
    '.B........B.',
    '.BB.DDDD.BB.',
    '..BBDDDDBB..',
    '..BBBDDBBB..',
    '..BKBBBBKB..',
    '..BBBBBBBB..',
    '...BBBBBB...',
    '...BBBBBB...',
    '...TTTTTT...',
    '..TTKTTKTT..',
    '...TTTTTT...',
  ], {'B': Color(0xFFB9784A), 'D': Color(0xFF6B4630), 'T': Color(0xFFE8C9A0), 'K': _k}),
  'rooster': PixArt([
    '....RR......',
    '...RRR......',
    '..YYYYY.....',
    '.YYYYYYY....',
    '.YYKYYYYO...',
    '.YYYYYYYOO..',
    '..YYYYYYY...',
    '.YYYYYYYYY..',
    'YYYYYYYYYYY.',
    '.YYYYYYYYY..',
    '...O...O....',
  ], {'Y': Color(0xFFF6CF4A), 'R': Color(0xFFE5574F), 'O': Color(0xFFF08A3E), 'K': _k}),
  'whale': PixArt([
    '..L...L.....',
    '...L.L......',
    '....L.......',
    '..BBBBBB....',
    '.BBBBBBBB..B',
    'BBKBBBBBBBBB',
    'BBBBBBBBBBB.',
    'BWWWWWWBBBB.',
    '.BWWWWWBBB..',
    '..BBBBBB....',
    '............',
  ], {'B': Color(0xFF4A9FDB), 'W': Color(0xFFCFE6F6), 'L': Color(0xFF9CCFF0), 'K': _k}),
};
