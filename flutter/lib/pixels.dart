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
  'dog': PixArt([
    '.DD......DD.',
    'DDDBBBBBBDDD',
    'DDBBBBBBBBDD',
    'DDBKBBBBKBDD',
    'DDBBBBBBBBDD',
    'DDBBCCCCBBDD',
    '.D.BCKKCB.D.',
    '...BCCCCB...',
    '...BCPPCB...',
    '....BCCB....',
    '............',
  ], {'B': Color(0xFFD9A066), 'D': Color(0xFF8A5A3B), 'C': Color(0xFFF6E3C4), 'P': Color(0xFFF2A7B8), 'K': _k}),
  'cat': PixArt([
    'G..........G',
    'GG........GG',
    'GPG......GPG',
    'GGGGGGGGGGGG',
    'GGGGGGGGGGGG',
    'GGKGGGGGGKGG',
    'GGGGGGGGGGGG',
    'GGGWWPPWWGGG',
    '.GWWWWWWWWG.',
    '..GWWWWWWG..',
    '...GGGGGG...',
  ], {'G': Color(0xFF9C9CA8), 'W': _w, 'P': Color(0xFFF2A7B8), 'K': _k}),
  'turtle': PixArt([
    '....GGGG....',
    '...GGGGGG...',
    '...GKGGKG...',
    '...GGGGGG...',
    '..OOOOOOOO..',
    '.OOLOOOOLOO.',
    'GOOOOLLOOOOG',
    'GOOOOOOOOOOG',
    '.OOLOOOOLOO.',
    '..OOOOOOOO..',
    '..GG....GG..',
  ], {'G': Color(0xFF7CC576), 'O': Color(0xFFF2A64A), 'L': Color(0xFFF8CF86), 'K': _k}),
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
};
