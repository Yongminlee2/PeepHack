/// 실행·기기마다 같은 값이 나오는 문자열 해시(FNV-1a 32비트). 퍼즐 씨앗용.
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h;
}
