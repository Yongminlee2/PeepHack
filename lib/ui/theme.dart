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
  fontFamily: 'monospace',
  appBarTheme: const AppBarTheme(backgroundColor: hqPanel, foregroundColor: hqGreen),
  chipTheme: const ChipThemeData(backgroundColor: hqPanel, labelStyle: TextStyle(color: hqGreen, fontFamily: 'monospace')),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(backgroundColor: hqGreen, foregroundColor: hqBg),
  ),
);

/// 임무 JSON 문자열: '@열쇠' 면 번역, 아니면 원문(로그·코드) 그대로.
String tr(String s) => s.startsWith('@') ? S.t(s.substring(1)) : s;
