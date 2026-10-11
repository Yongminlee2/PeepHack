import 'package:flutter/material.dart';

import '../strings.dart';

const hqBg = Color(0xFF0B0F0C);
const hqPanel = Color(0xFF121A14);
const hqGreen = Color(0xFFB8F5C0);
const hqDim = Color(0xFF6E9A75);
const hqOrange = Color(0xFFFFB454);
const hqRed = Color(0xFFFF6B6B);

final ThemeData hqTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: hqBg,
  colorScheme: const ColorScheme.dark(primary: hqGreen, secondary: hqOrange, surface: hqPanel, error: hqRed),
  appBarTheme: const AppBarTheme(backgroundColor: hqPanel, foregroundColor: hqGreen),
  chipTheme: const ChipThemeData(backgroundColor: hqPanel, labelStyle: TextStyle(color: hqGreen, fontFamily: 'monospace')),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(backgroundColor: hqGreen, foregroundColor: hqBg),
  ),
);

/// 영문 명령·코드·로그만 고정폭. 한글·가나·한자·태국어가 섞이면 고정폭 글꼴이
/// 글자 칸을 벌려 「첫  접속」처럼 보인다(실기기에서 확인).
String? monoFor(String s) => _wide.hasMatch(s) ? null : 'monospace';
final _wide = RegExp(r'[฀-๿ᄀ-ᇿ぀-ヿ㄰-㆏㐀-鿿가-힯]');

/// 임무 JSON 문자열: '@열쇠' 면 번역, 아니면 원문(로그·코드) 그대로.
String tr(String s) => s.startsWith('@') ? S.t(s.substring(1)) : s;
