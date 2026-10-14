import 'package:flutter/material.dart';

import '../strings.dart';

const hqBg = Color(0xFF0B0F0C);
const hqPanel = Color(0xFF121A14);
const hqGreen = Color(0xFFB8F5C0);
const hqDim = Color(0xFF6E9A75);
/// 사람이 읽는 글(안내·편지). 형광 초록은 긴 한글에 눈이 아파서 흰빛에 가까운 연초록.
const hqText = Color(0xFFE4F1E7);
const hqOrange = Color(0xFFFFB454);
const hqRed = Color(0xFFFF6B6B);

final ThemeData hqTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: hqBg,
  colorScheme: const ColorScheme.dark(primary: hqGreen, secondary: hqOrange, surface: hqPanel, error: hqRed),
  appBarTheme: const AppBarTheme(backgroundColor: hqPanel, foregroundColor: hqGreen),
  chipTheme: const ChipThemeData(
    backgroundColor: hqPanel,
    labelStyle: TextStyle(color: hqGreen, fontFamily: kMono),
    // 고른 칩: 주황 바탕에 검은 글씨(주황 위 주황 글씨는 안 읽혔다)
    selectedColor: hqOrange,
    secondaryLabelStyle: TextStyle(color: Colors.black, fontFamily: kMono),
    checkmarkColor: Colors.black,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(backgroundColor: hqGreen, foregroundColor: hqBg),
  ),
);

/// 영문 명령·코드·로그만 고정폭. 한글·가나·한자·태국어가 섞이면 고정폭 글꼴이
/// 글자 칸을 벌려 「첫  접속」처럼 보인다(실기기에서 확인).
/// 앱 안 고정폭 글꼴(나눔고딕코딩의 영문·기호만 잘라 낸 것, OFL — tool/subset_font.py).
/// 한글 등 글꼴에 없는 글자는 기기 기본 글꼴이 그린다.
const kMono = 'HackMono';

/// 안드로이드 기본 글꼴. null 로 두면 칩처럼 부모가 고정폭이면 그걸 물려받아 한글 띄어쓰기가 벌어진다.
const kSans = 'Roboto';

/// 한글·가나·한자·태국어·키릴이 섞인 줄은 통째로 기본 글꼴 — 고정폭 칸에 넣으면 글자 사이가 벌어진다.
String monoFor(String s) => _foreign.hasMatch(s) ? kSans : kMono;
final _foreign = RegExp(r'[^\u0000-ɏ -⯿]');

/// 임무 JSON 문자열: '@열쇠' 면 번역, 아니면 원문(로그·코드) 그대로.
String tr(String s) => s.startsWith('@') ? S.t(s.substring(1)) : s;
