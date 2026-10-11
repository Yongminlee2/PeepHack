/// 셸 경로 처리. Flutter 의존 없음.
String normalizePath(String cwd, String arg) {
  final raw = arg.startsWith('/') ? arg : (cwd == '/' ? '/$arg' : '$cwd/$arg');
  final parts = <String>[];
  for (final seg in raw.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(seg);
  }
  return '/${parts.join('/')}';
}

String joinHostPath(String hostKey, String absPath) => '$hostKey:$absPath';

String dirOf(String absPath) {
  final i = absPath.lastIndexOf('/');
  return i <= 0 ? '/' : absPath.substring(0, i);
}

String baseOf(String absPath) => absPath.substring(absPath.lastIndexOf('/') + 1);
