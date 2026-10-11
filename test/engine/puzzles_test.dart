import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/puzzles.dart';

Puzzle p(String type, Map<String, dynamic> data, Object answer) =>
    Puzzle(id: 'x', type: type, data: data, answer: answer);

void main() {
  test('match: 순서 무관, 전부 맞아야', () {
    final q = p('match', {'left': ['A', 'B'], 'right': ['1', '2']}, [[0, 1], [1, 0]]);
    expect(checkAnswer(q, [[1, 0], [0, 1]]), isTrue);
    expect(checkAnswer(q, [[0, 0], [1, 1]]), isFalse);
    expect(checkAnswer(q, [[0, 1]]), isFalse);
    expect(answerBuildable(q), isTrue);
    expect(answerBuildable(p('match', {'left': ['A'], 'right': ['1']}, [[0, 5]])), isFalse);
  });
  test('password: 대소문자 구분, 앞뒤 공백 무시', () {
    final q = p('password', {'clues': [], 'fragments': ['mo', 'mo', '2019', 'x']}, 'momo2019');
    expect(checkAnswer(q, 'momo2019'), isTrue);
    expect(checkAnswer(q, ' momo2019 '), isTrue);
    expect(checkAnswer(q, 'Momo2019'), isFalse);
    expect(answerBuildable(q), isTrue);
    expect(answerBuildable(p('password', {'fragments': ['mo', '2019']}, 'momo2019')), isFalse);
  });
  test('order: 순열 일치', () {
    final q = p('order', {'items': ['c', 'a', 'b']}, [1, 2, 0]);
    expect(checkAnswer(q, [1, 2, 0]), isTrue);
    expect(checkAnswer(q, [0, 1, 2]), isFalse);
    expect(answerBuildable(q), isTrue);
    expect(answerBuildable(p('order', {'items': ['a', 'b']}, [0, 0])), isFalse);
  });
  test('codefix: 버그 줄 전부', () {
    final q = p('codefix', {
      'lang': 'python',
      'lines': ['x = 1', 'if x <= 1:', '  print(x)'],
      'bugs': [{'line': 1, 'choices': ['<', '<=', '>'], 'answer': '<'}],
    }, 'bugs');
    expect(checkAnswer(q, {1: '<'}), isTrue);
    expect(checkAnswer(q, {1: '<='}), isFalse);
    expect(checkAnswer(q, <int, String>{}), isFalse);
    expect(answerBuildable(q), isTrue);
    expect(answerBuildable(p('codefix', {'lines': ['a'], 'bugs': [{'line': 3, 'choices': ['x'], 'answer': 'x'}]}, 'bugs')), isFalse);
  });
  test('decode', () {
    expect(decodeText('rshqvhvdph', 'caesar:3'), 'opensesame');
    expect(decodeText('Khoor 123', 'caesar:3'), 'Hello 123');
    expect(decodeText('cba', 'reverse'), 'abc');
  });
}
