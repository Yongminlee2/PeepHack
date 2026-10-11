import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/paths.dart';

void main() {
  test('상대·절대·.. 경로', () {
    expect(normalizePath('/', 'a'), '/a');
    expect(normalizePath('/a', 'b/c'), '/a/b/c');
    expect(normalizePath('/a/b', '..'), '/a');
    expect(normalizePath('/a', '../../..'), '/');
    expect(normalizePath('/a', '/x/y/'), '/x/y');
    expect(normalizePath('/a', './b'), '/a/b');
    expect(normalizePath('/', ''), '/');
  });
  test('호스트 경로 조합', () {
    expect(joinHostPath('shop', '/root/flag.txt'), 'shop:/root/flag.txt');
    expect(dirOf('/a/b/c.txt'), '/a/b');
    expect(dirOf('/c.txt'), '/');
    expect(baseOf('/a/b/c.txt'), 'c.txt');
  });
}
