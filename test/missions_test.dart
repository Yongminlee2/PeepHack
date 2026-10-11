import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/puzzles.dart';
import 'package:hack_quest/engine/shell.dart';

/// 설계 문서 8절. 임무를 추가·수정하는 사람은 이것만 돌리면 된다.
void main() {
  final dir = Directory('assets/missions');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final ko = jsonDecode(File('i18n/ko.json').readAsStringSync()) as Map<String, dynamic>;

  test('임무 파일이 있다', () => expect(files, isNotEmpty));

  final missions = <Mission>[];
  for (final f in files) {
    final name = f.uri.pathSegments.last.replaceAll('.json', '');
    group(name, () {
      late Mission m;
      test('1. JSON 이 읽히고 id 가 파일 이름과 같다', () {
        m = Mission.parse(f.readAsStringSync());
        expect(m.id, name);
        missions.add(m);
      });
      test('2. 정답 경로로 목표에 닿는다 / 3. 칩 임무는 칩만으로 친다', () {
        final sh = Shell(m);
        for (final step in m.solution) {
          if (step is PuzzleStep) {
            final p = m.puzzleById(step.puzzle);
            expect(p, isNotNull, reason: '퍼즐 없음 ${step.puzzle}');
            final r = sh.submitPuzzle(p!.id, p.answer == 'bugs' ? _codefixAnswer(p) : p.answer);
            expect(r.key, isNot('puzzle_wrong'), reason: '퍼즐 정답이 안 맞음 ${p.id}');
            continue;
          }
          final line = step as String;
          if (m.input == 'chips' && !sh.awaitingPassword) {
            final s = sh.suggestions();
            final tokens = line.split(' ');
            expect(s.commands, contains(tokens.first), reason: '칩에 없는 명령: $line');
            for (final t in tokens.skip(1)) {
              expect(s.args, contains(t), reason: '칩에 없는 인자 "$t" in "$line"');
            }
          }
          final r = sh.run(line);
          expect(r.isError, isFalse, reason: '정답 줄이 실패: "$line" → ${r.key} ${r.args}');
        }
        expect(sh.goalDone, isTrue, reason: '정답을 다 쳤는데 목표 미달성');
      });
      test('4. 명령이 그 챕터까지 등장한 것뿐이다', () {
        for (final c in m.commands) {
          expect(kCommandChapter.containsKey(c), isTrue, reason: '모르는 명령 $c');
          expect(kCommandChapter[c]! <= m.chapter, isTrue, reason: '$c 는 챕터 ${kCommandChapter[c]} 부터');
        }
        expect(m.input, m.chapter <= 2 ? 'chips' : 'keyboard');
      });
      test('5. 퍼즐 정답이 data 로 만들어진다', () {
        for (final p in m.puzzles) {
          expect(answerBuildable(p), isTrue, reason: '퍼즐 ${p.id}');
          if (p.file != null) {
            final i = p.file!.indexOf(':');
            final h = m.hosts[p.file!.substring(0, i)];
            expect(h, isNotNull, reason: '퍼즐 ${p.id} 의 호스트');
            expect(lookup(h!.fs, p.file!.substring(i + 1)), isA<FsFile>(), reason: '퍼즐 ${p.id} 의 파일');
          }
        }
        for (final h in m.hosts.values) {
          if (h.lock?.type == 'puzzle') expect(m.puzzleById(h.lock!.puzzle!), isNotNull);
        }
      });
      test('6. @열쇠가 전부 ko.json 에 있다', () {
        final raw = jsonDecode(f.readAsStringSync());
        final keys = <String>{};
        void walk(Object? v) {
          if (v is String && v.startsWith('@')) keys.add(v.substring(1));
          if (v is List) v.forEach(walk);
          if (v is Map) v.values.forEach(walk);
        }
        walk(raw);
        expect(keys, isNotEmpty);
        for (final k in keys) {
          expect(ko.containsKey(k), isTrue, reason: 'ko.json 에 없는 열쇠 $k');
          expect(k.startsWith('${m.id}_'), isTrue, reason: '열쇠 접두어가 임무 id 와 다름: $k');
        }
      });
      test('9. grep 정답 줄의 대상 파일은 번역되지 않은 원문이다', () {
        for (final step in m.solution.whereType<String>()) {
          final t = step.split(RegExp(r'\s+'));
          final gi = t.indexOf('grep');
          if (gi < 0) continue;
          // "grep W F" 또는 "cat F | grep W"
          final file = t.first == 'cat' ? t[1] : (t.length > gi + 2 ? t[gi + 2] : null);
          if (file == null) continue;
          // cd 로 들어간 뒤 상대 경로로 grep 하므로, 어느 폴더든 같은 이름의 파일을 전부 본다.
          final base = file.split('/').last;
          var found = 0;
          void walk(FsDir d) => d.children.forEach((n, node) {
                if (node is FsDir) walk(node);
                if (node is FsFile && n == base) {
                  found++;
                  expect(node.text.startsWith('@'), isFalse, reason: '$step 의 대상이 번역 파일');
                }
              });
          for (final h in m.hosts.values) {
            walk(h.fs);
          }
          expect(found, greaterThan(0), reason: '$step 의 대상 파일을 못 찾음');
        }
      });
      test('7. 힌트 개수: 챕터1·2 는 3개, 챕터3+ 는 2개(셋째는 정답 줄)', () {
        expect(m.hints.length, m.chapter <= 2 ? 3 : 2);
        expect(m.title, startsWith('@'));
        expect(m.brief, isNotEmpty);
        expect(m.done, isNotEmpty);
      });
    });
  }

  test('8. 각 챕터에 임무 6개가 빠짐없이', () {
    final byChapter = <int, List<String>>{};
    for (final m in missions) {
      byChapter.putIfAbsent(m.chapter, () => []).add(m.id);
    }
    byChapter.forEach((c, ids) {
      expect(ids.toSet(), {for (var n = 1; n <= 6; n++) 'm${c}_0$n'}, reason: '챕터 $c');
    });
  });
}

Map<int, String> _codefixAnswer(Puzzle p) =>
    {for (final b in p.data['bugs'] as List) (b as Map)['line'] as int: b['answer'] as String};
