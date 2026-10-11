# HackQuest 1부 구현 계획 — 엔진 · 화면 · 챕터 1


**Goal:** 가짜 터미널 엔진(명령 21개)·퍼즐 4종·화면 전부·챕터 1 임무 6개가 폰에서 끝까지 플레이되는 Flutter 앱.

**Architecture:** `lib/engine/` 은 Flutter 를 import 하지 않는 순수 Dart(셸·퍼즐 판정·임무 모델·저장). 임무는 `assets/missions/*.json` 데이터이고 `test/missions_test.dart` 가 모든 임무를 엔진으로 실제로 풀어 본다. 화면은 `ValueNotifier`/`setState` 만 쓴다.

**Tech Stack:** Flutter 3.44 / Dart 3.12, `shared_preferences`, `audioplayers`(2부에서 소리 넣을 때), `common/i18n/gen.py`, `common/flutter/strings.dart`.

**Spec:** `docs/specs/2026-10-11-hackquest-design.md` — 이 계획은 그 문서를 근거로 한다. 실행자는 둘 다 읽는다.

## Global Constraints

- 프로젝트 폴더 `C:\workAndroid\HackQuest`, applicationId `com.yongmin.hackquest`, Dart 패키지 이름 `hack_quest`.
- `lib/engine/` 에 `package:flutter` import 금지 (테스트·도구가 `dart run` 으로 돈다).
- 화면 문장은 전부 `S.t('열쇠')`. 코드에 한국어·영어 문장을 직접 쓰지 않는다. 숫자 자리는 `{n}` 같은 이름 자리 (`S.tn`).
- 번역하지 않는 것: 명령 이름, 파일·호스트 이름, 로그·코드 본문, 비밀번호(영문·숫자만).
- 임무 JSON 안의 문자열이 `@` 로 시작하면 번역 열쇠다.
- `android:allowBackup="false"`. 권한 0개(인터넷 포함). 패키지는 `shared_preferences` 만 추가(2부에서 `audioplayers`).
- 매 셸 세션 환경변수(PowerShell) — 한글 홈 경로 함정:
  ```powershell
  $env:Path = "C:\flutter\bin;$env:Path"
  $env:PUB_CACHE = "C:\flutter\.pub-cache"
  $env:GRADLE_USER_HOME = "C:\workAndroid\gradle-home-ascii"
  $env:TEMP = "C:\workAndroid\tmp-ascii"; $env:TMP = "C:\workAndroid\tmp-ascii"
  ```
  (`gradle-user-ascii` 는 한글 홈으로 가는 정션이라 쓰지 않는다.)
- 테스트 명령: `flutter test` (프로젝트 루트에서). 빌드 통과 ≠ 동작. 실기기 확인은 Task 14.

## Review Focus

1. 챕터 1~2(`chips`) 임무에서 비밀번호 입력 — 칩으로는 못 치므로 잠금 대기 중에는 입력칸이 편집 가능해야 한다 → Task 11 위젯 테스트.
2. 같은 퍼즐을 두 번 풀거나, 푼 뒤 다시 `open` 했을 때 퍼즐 창이 또 뜨면 안 된다 → Task 4 테스트.
3. `cd ../../..` 처럼 루트 위로 올라가는 경로, 끝에 `/` 붙은 경로 → Task 5 `normalizePath` 테스트.
4. 임무 JSON 하나가 깨졌을 때 앱이 죽지 않고 그 임무만 비활성 → Task 10 `Catalog.load` 테스트.
5. 세이브가 깨졌을 때(값이 이상한 형) 빈 진행으로 시작 → Task 8 테스트.

---

## 파일 구조

```
lib/
  main.dart                     앱 시작: 언어·진행·카탈로그 로드, 테마, 첫 화면
  strings.dart                  common/flutter/strings.dart 복사본
  l10n/                         gen.py 생성물 (손대지 않음)
  engine/
    paths.dart                  경로 정규화, 파일시스템 탐색
    mission.dart                JSON → Mission/Host/FsNode/Puzzle/Goal
    puzzles.dart                퍼즐 정답 판정 (순수 함수)
    shell.dart                  명령 실행기
    progress.dart               저장 (shared_preferences)
    rewards.dart                힌트 열기 경로 한 곳
  catalog.dart                  assets/missions 전부 로드 (Flutter rootBundle)
  ui/
    theme.dart                  색·글꼴
    inbox_screen.dart           챕터·임무 목록
    brief_screen.dart           의뢰 대사·접속 버튼
    mission_screen.dart         가짜 OS (창 전환, 힌트, 완료 판정)
    terminal_view.dart          출력 줄 목록
    file_view.dart              파일 내용 창
    input_bar.dart              칩 + 입력칸 + 실행
    result_screen.dart          별·시간·광고 자리·다음
    settings_screen.dart        언어·소리
    promo_screen.dart           「개발자의 다른 게임」 자리
    puzzles/
      match_puzzle.dart  password_puzzle.dart  order_puzzle.dart  codefix_puzzle.dart
assets/missions/m1_01.json … m1_06.json
i18n/ko.json  i18n/en.json  i18n/_ignore.json
test/
  engine/paths_test.dart  mission_test.dart  puzzles_test.dart  shell_test.dart  progress_test.dart
  missions_test.dart  i18n_test.dart  catalog_test.dart  input_bar_test.dart
```

---

### Task 1: 프로젝트 생성 · 다국어 틀 · 첫 테스트

**Files:**
- Create: 프로젝트 전체(`flutter create`), `i18n/ko.json`, `i18n/en.json`, `i18n/_ignore.json`, `lib/strings.dart`, `lib/l10n/*`, `test/i18n_test.dart`
- Modify: `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/local.properties`, `android/gradle.properties`, `.gitignore`

**Interfaces:**
- Produces: `S.t(key)`, `S.tn(key, {slots})`, `AppLang()`, `kLanguageOrder`, `kLanguageNames` (common strings.dart 그대로).

- [ ] **Step 1: 프로젝트 생성**

```powershell
cd C:\workAndroid\HackQuest
flutter create --org com.yongmin --project-name hack_quest --platforms android .
```
`docs/` 와 `.git` 이 이미 있으므로 덮어쓰지 않는지 확인(`git status` 에 docs 변경이 없어야 한다).

- [ ] **Step 2: 안드로이드 설정**

`android/local.properties` 를 아래로 교체:
```
sdk.dir=C:\\workAndroid\\android-sdk-ascii
flutter.sdk=C:\\flutter
```
`android/gradle.properties` 에 추가:
```
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G
org.gradle.java.home=C:/Program Files/Android/Android Studio/jbr
```
`android/app/build.gradle.kts` 의 `applicationId` 를 `"com.yongmin.hackquest"` 로. `namespace` 도 같은 값.
`android/app/src/main/AndroidManifest.xml` 의 `<application` 에 `android:allowBackup="false"` 추가. `<uses-permission>` 이 하나도 없어야 한다.
`.gitignore` 에 `local.properties`, `keystore.properties`, `*.jks` 가 있는지 확인(없으면 추가).

- [ ] **Step 3: pubspec**

`pubspec.yaml` 의 dependencies 에 `shared_preferences: ^2.5.5`. `flutter:` 아래에:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/missions/
```
`assets/missions/.gitkeep` 를 만들어 둔다(빈 폴더는 pub get 이 경고한다).

- [ ] **Step 4: 다국어 원본**

`i18n/_ignore.json`:
```json
["app_name"]
```
`i18n/ko.json` (화면 공통 열쇠. 임무 열쇠는 Task 9 에서 추가):
```json
{
  "app_name": "HackQuest",
  "inbox_title": "메시지함",
  "inbox_chapter_n": "챕터 {n}",
  "inbox_locked": "앞 임무를 먼저 끝내세요",
  "btn_connect": "접속",
  "btn_run": "실행",
  "btn_close": "닫기",
  "btn_check": "확인",
  "btn_next": "다음 임무",
  "btn_back_inbox": "메시지함으로",
  "btn_hint": "힌트",
  "btn_hint_next": "다음 힌트 보기",
  "btn_exit": "나가기",
  "btn_settings": "설정",
  "btn_promo": "개발자의 다른 게임",
  "btn_reset": "진행 초기화",
  "confirm_reset": "정말 처음부터 다시 할까요?",
  "brief_from": "보낸 사람: 고스트",
  "brief_goal": "목표",
  "hint_title": "힌트 (남은 별 {n})",
  "hint_none_left": "힌트를 다 썼습니다",
  "hint_next_cmd": "다음 명령: {cmd}",
  "shell_welcome": "접속 준비 완료. 명령을 고르세요.",
  "shell_connected": "{host} 에 접속했습니다",
  "shell_password_prompt": "비밀번호를 입력하세요",
  "shell_unlocked": "잠금이 풀렸습니다",
  "shell_run_ok": "실행 성공",
  "shell_empty": "(비어 있음)",
  "shell_err_unknown": "모르는 명령: {cmd}",
  "shell_err_usage": "사용법: {usage}",
  "shell_err_no_host": "그런 서버가 없습니다: {host}",
  "shell_err_no_file": "그런 파일이 없습니다: {path}",
  "shell_err_no_dir": "그런 폴더가 없습니다: {path}",
  "shell_err_is_dir": "폴더입니다: {path}",
  "shell_err_wrong_password": "비밀번호가 틀렸습니다",
  "shell_err_ssh_denied": "{user} 계정은 이 서버에 없습니다",
  "shell_err_not_encoded": "암호화된 파일이 아닙니다",
  "shell_err_no_commit": "그런 커밋이 없습니다: {hash}",
  "shell_err_nothing_to_fix": "고칠 코드가 없습니다: {path}",
  "shell_err_nothing_to_run": "실행할 수 없는 파일입니다: {path}",
  "shell_err_locked_cmd": "이 임무에서는 쓸 수 없는 명령입니다: {cmd}",
  "input_password_hint": "비밀번호",
  "input_command_hint": "명령",
  "puzzle_wrong": "틀렸습니다. 다시 해 보세요",
  "puzzle_solved": "해결!",
  "puzzle_match_title": "짝을 이으세요 (왼쪽 → 오른쪽 순서로 누르기)",
  "puzzle_password_title": "단서로 비밀번호를 조립하세요",
  "puzzle_order_title": "올바른 순서로 끌어다 놓으세요",
  "puzzle_codefix_title": "틀린 줄을 누르고 바꿀 조각을 고르세요",
  "puzzle_codefix_line_ok": "이 줄은 문제없어 보입니다",
  "result_title": "임무 완료",
  "result_time": "걸린 시간 {m}분 {s}초",
  "result_hints": "쓴 힌트 {n}개",
  "settings_title": "설정",
  "settings_language": "언어",
  "settings_follow_system": "기기 설정 따르기",
  "settings_sound": "효과음",
  "promo_title": "개발자의 다른 게임",
  "promo_coming": "곧 열립니다",
  "mission_broken": "이 임무는 지금 열 수 없습니다"
}
```
`i18n/en.json` 은 같은 열쇠를 영어로 (예: `"inbox_chapter_n": "Chapter {n}"`, `"shell_err_unknown": "Unknown command: {cmd}"`, `"result_time": "Time {m}m {s}s"`). 전 열쇠를 빠짐없이 옮긴다.

- [ ] **Step 5: strings.dart 복사 · l10n 생성**

```powershell
Copy-Item ..\common\flutter\strings.dart lib\strings.dart
python ..\common\i18n\gen.py i18n --to flutter --out lib\l10n
```
`lib/strings.dart` 의 `import 'l10n/l10n.dart'` 경로가 맞는지 확인. `gen.py` 는 `languages.json` 에 있는 언어 중 파일이 있는 것만 뽑는다(지금은 ko·en).

- [ ] **Step 6: 실패하는 테스트**

`test/i18n_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/strings.dart';

void main() {
  test('모든 언어가 영어와 같은 열쇠를 가진다', () {
    expect(S.missingKeys(), isEmpty);
  });
  test('열쇠를 못 찾으면 열쇠 자체를 돌려준다', () {
    expect(S.t('no_such_key_xyz'), 'no_such_key_xyz');
  });
  test('이름 자리({n} 등)가 언어마다 같다', () {
    // common/i18n/audit.py 의 slotcount 는 `{}`·`{1}` 만 세고 `{n}` 은 모른다. 그래서 여기서 본다.
    final slot = RegExp(r'\{[a-z]+\}');
    final base = S.strings['ko']!;
    S.strings.forEach((code, table) {
      table.forEach((k, v) {
        final want = slot.allMatches(base[k] ?? '').map((m) => m.group(0)).toSet();
        final got = slot.allMatches(v).map((m) => m.group(0)).toSet();
        expect(got, want, reason: '$code.$k');
      });
    });
  });
}
```
일부러 `en.json` 에서 열쇠 하나를 지우고 `gen.py` 를 다시 돌린 뒤 `flutter test test/i18n_test.dart` → **FAIL** 이어야 한다. 되돌리고 다시 생성.

- [ ] **Step 7: 통과 확인 · 커밋**

`flutter test test/i18n_test.dart` → PASS. `flutter analyze` → 경고 0.
```powershell
git add -A
git commit -m "프로젝트 생성, 다국어 틀(ko·en), 권한 0개·백업 끔"
```

---

### Task 2: 경로 유틸 (`lib/engine/paths.dart`)

**Files:**
- Create: `lib/engine/paths.dart`, `test/engine/paths_test.dart`

**Interfaces:**
- Produces: `String normalizePath(String cwd, String arg)`, `String joinHostPath(String hostKey, String absPath)` → `"host:/a/b"`, `String dirOf(String absPath)`, `String baseOf(String absPath)`.

- [ ] **Step 1: 실패하는 테스트**

`test/engine/paths_test.dart`:
```dart
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
```

- [ ] **Step 2: 실패 확인** — `flutter test test/engine/paths_test.dart` → FAIL (파일 없음)

- [ ] **Step 3: 구현**

```dart
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
```

- [ ] **Step 4: 통과 확인** — PASS
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "엔진: 경로 정규화"`

---

### Task 3: 임무 모델 (`lib/engine/mission.dart`)

**Files:**
- Create: `lib/engine/mission.dart`, `test/engine/mission_test.dart`

**Interfaces:**
- Produces:
  - `Mission.parse(String json)`, `Mission.fromJson(Map)`; 필드 `id chapter title brief done input commands words hosts start puzzles goal hints solution`
  - `Host(key name lock fs user git env cron)`, `Lock(type answer puzzle)`, `FsDir(children)`, `FsFile(text encode lock)`, `Commit(hash message diff)`
  - `Puzzle(id type file data answer)`, `PuzzleStep(puzzle)`
  - `Goal.check(GoalState)`, `GoalState(read solved connected ran)`
  - `Mission.hostByName(String)`, `Mission.puzzleById(String)`, `Mission.puzzleForFile(String hostKey, String absPath)`
  - `FsNode? lookup(FsDir root, String absPath)`

- [ ] **Step 1: 실패하는 테스트**

`test/engine/mission_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';

const sample = '''
{
  "id": "m9_01", "chapter": 9, "title": "@m9_01_title",
  "brief": ["@m9_01_brief_1"], "done": ["@m9_01_done_1"],
  "input": "chips",
  "commands": ["scan", "connect", "open"],
  "words": ["admin"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {"note.txt": "hello", "work/": {"a.txt": {"text": "x", "encode": "reverse"}}}},
    "shop": {"name": "shop-server", "user": "root", "lock": {"type": "password", "answer": "pw1"},
             "fs": {"flag.txt": {"text": "FLAG", "lock": {"type": "password", "answer": "pw2"}}},
             "git": [{"hash": "a1b2", "message": "fix", "diff": "-1\\n+2"}],
             "env": {"MODE": "prod"}, "cron": ["* * * * * /x.sh"]}
  },
  "start": "home",
  "puzzles": [{"id": "p1", "type": "password", "file": "shop:/flag.txt",
               "data": {"clues": ["@c1"], "fragments": ["pw", "2"]}, "answer": "pw2"}],
  "goal": {"all": [{"read": "shop:/flag.txt"}, {"puzzle": "p1"}, {"connect": "shop"}, {"run": "shop:/a.py"}]},
  "hints": ["@h1", "@h2", "@h3"],
  "solution": ["scan", "connect shop-server", "pw1", {"puzzle": "p1"}]
}
''';

void main() {
  final m = Mission.parse(sample);
  test('기본 필드', () {
    expect(m.id, 'm9_01');
    expect(m.chapter, 9);
    expect(m.commands, ['scan', 'connect', 'open']);
    expect(m.start, 'home');
    expect(m.solution.length, 4);
    expect(m.solution[3], isA<PuzzleStep>());
    expect((m.solution[3] as PuzzleStep).puzzle, 'p1');
  });
  test('파일시스템 파싱', () {
    final home = m.hosts['home']!;
    expect(lookup(home.fs, '/note.txt'), isA<FsFile>());
    expect((lookup(home.fs, '/note.txt') as FsFile).text, 'hello');
    expect(lookup(home.fs, '/work'), isA<FsDir>());
    expect((lookup(home.fs, '/work/a.txt') as FsFile).encode, 'reverse');
    expect(lookup(home.fs, '/nope'), isNull);
    expect(lookup(home.fs, '/'), same(home.fs));
  });
  test('호스트 부가 정보', () {
    final shop = m.hosts['shop']!;
    expect(shop.lock!.type, 'password');
    expect(shop.lock!.answer, 'pw1');
    expect(shop.user, 'root');
    expect(shop.git.single.hash, 'a1b2');
    expect(shop.env['MODE'], 'prod');
    expect(shop.cron.single, '* * * * * /x.sh');
    expect((lookup(shop.fs, '/flag.txt') as FsFile).lock!.answer, 'pw2');
    expect(m.hostByName('shop-server')!.key, 'shop');
    expect(m.hostByName('shop')!.key, 'shop');
    expect(m.hostByName('zzz'), isNull);
  });
  test('퍼즐 찾기', () {
    expect(m.puzzleById('p1')!.type, 'password');
    expect(m.puzzleForFile('shop', '/flag.txt')!.id, 'p1');
    expect(m.puzzleForFile('home', '/note.txt'), isNull);
  });
  test('목표 판정', () {
    final none = GoalState();
    expect(m.goal.check(none), isFalse);
    final all = GoalState(
      read: {'shop:/flag.txt'}, solved: {'p1'}, connected: {'home', 'shop'}, ran: {'shop:/a.py'});
    expect(m.goal.check(all), isTrue);
    final partial = GoalState(read: {'shop:/flag.txt'}, solved: {'p1'}, connected: {'shop'});
    expect(m.goal.check(partial), isFalse);
    final any = Goal.fromJson({'any': [{'puzzle': 'zz'}, {'connect': 'home'}]});
    expect(any.check(all), isTrue);
  });
}
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현**

```dart
import 'dart:convert';

/// 임무 JSON 모델. Flutter 의존 없음. 형식은 설계 문서 3절.
class Mission {
  final String id;
  final int chapter;
  final String title;
  final List<String> brief;
  final List<String> done;
  final String input; // 'chips' | 'keyboard'
  final List<String> commands;
  final List<String> words;
  final Map<String, Host> hosts;
  final String start;
  final List<Puzzle> puzzles;
  final Goal goal;
  final List<String> hints;
  final List<Object> solution; // String | PuzzleStep

  Mission({
    required this.id, required this.chapter, required this.title,
    required this.brief, required this.done, required this.input,
    required this.commands, required this.words, required this.hosts,
    required this.start, required this.puzzles, required this.goal,
    required this.hints, required this.solution,
  });

  static Mission parse(String jsonText) =>
      Mission.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        id: j['id'] as String,
        chapter: j['chapter'] as int,
        title: j['title'] as String? ?? '',
        brief: _strs(j['brief']),
        done: _strs(j['done']),
        input: j['input'] as String? ?? 'chips',
        commands: _strs(j['commands']),
        words: _strs(j['words']),
        hosts: (j['hosts'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, Host.fromJson(k, v as Map<String, dynamic>))),
        start: j['start'] as String? ?? 'home',
        puzzles: [
          for (final p in (j['puzzles'] as List?) ?? const [])
            Puzzle.fromJson(p as Map<String, dynamic>)
        ],
        goal: Goal.fromJson(j['goal'] as Map<String, dynamic>),
        hints: _strs(j['hints']),
        solution: [
          for (final s in j['solution'] as List)
            s is String ? s : PuzzleStep((s as Map)['puzzle'] as String)
        ],
      );

  Host? hostByName(String name) {
    for (final h in hosts.values) {
      if (h.key == name || h.name == name) return h;
    }
    return null;
  }

  Puzzle? puzzleById(String id) {
    for (final p in puzzles) {
      if (p.id == id) return p;
    }
    return null;
  }

  Puzzle? puzzleForFile(String hostKey, String absPath) {
    final want = '$hostKey:$absPath';
    for (final p in puzzles) {
      if (p.file == want) return p;
    }
    return null;
  }
}

List<String> _strs(Object? v) => v == null ? const [] : List<String>.from(v as List);

class PuzzleStep {
  final String puzzle;
  const PuzzleStep(this.puzzle);
}

class Host {
  final String key;
  final String name;
  final Lock? lock;
  final FsDir fs;
  final String? user;
  final List<Commit> git;
  final Map<String, String> env;
  final List<String> cron;

  Host({
    required this.key, required this.name, this.lock, required this.fs,
    this.user, this.git = const [], this.env = const {}, this.cron = const [],
  });

  factory Host.fromJson(String key, Map<String, dynamic> j) => Host(
        key: key,
        name: j['name'] as String? ?? key,
        lock: j['lock'] == null ? null : Lock.fromJson(j['lock'] as Map<String, dynamic>),
        fs: FsDir.fromJson((j['fs'] as Map<String, dynamic>?) ?? const {}),
        user: j['user'] as String?,
        git: [
          for (final c in (j['git'] as List?) ?? const [])
            Commit(
              hash: (c as Map)['hash'] as String,
              message: c['message'] as String,
              diff: c['diff'] as String? ?? '',
            )
        ],
        env: Map<String, String>.from((j['env'] as Map?) ?? const {}),
        cron: _strs(j['cron']),
      );
}

class Lock {
  final String type; // 'password' | 'puzzle'
  final String? answer;
  final String? puzzle;
  Lock({required this.type, this.answer, this.puzzle});
  factory Lock.fromJson(Map<String, dynamic> j) => Lock(
        type: j['type'] as String,
        answer: j['answer'] as String?,
        puzzle: j['puzzle'] as String?,
      );
}

class Commit {
  final String hash;
  final String message;
  final String diff;
  Commit({required this.hash, required this.message, required this.diff});
}

abstract class FsNode {}

class FsDir extends FsNode {
  final Map<String, FsNode> children;
  FsDir(this.children);

  /// 열쇠가 `/` 로 끝나면 폴더, 값이 문자열이면 파일, 객체면 옵션 있는 파일.
  factory FsDir.fromJson(Map<String, dynamic> j) {
    final out = <String, FsNode>{};
    j.forEach((name, v) {
      if (name.endsWith('/')) {
        out[name.substring(0, name.length - 1)] =
            FsDir.fromJson((v as Map<String, dynamic>?) ?? const {});
      } else if (v is String) {
        out[name] = FsFile(text: v);
      } else {
        final m = v as Map<String, dynamic>;
        out[name] = FsFile(
          text: m['text'] as String? ?? '',
          encode: m['encode'] as String?,
          lock: m['lock'] == null ? null : Lock.fromJson(m['lock'] as Map<String, dynamic>),
        );
      }
    });
    return FsDir(out);
  }
}

class FsFile extends FsNode {
  final String text;
  final String? encode; // 'caesar:3' | 'reverse'
  final Lock? lock; // password 만
  FsFile({required this.text, this.encode, this.lock});
}

/// 절대 경로로 노드를 찾는다. 없으면 null. '/' 는 root.
FsNode? lookup(FsDir root, String absPath) {
  FsNode cur = root;
  for (final seg in absPath.split('/')) {
    if (seg.isEmpty) continue;
    if (cur is! FsDir) return null;
    final next = cur.children[seg];
    if (next == null) return null;
    cur = next;
  }
  return cur;
}

class Puzzle {
  final String id;
  final String type; // match | password | order | codefix
  final String? file; // "host:/abs/path"
  final Map<String, dynamic> data;
  final Object answer;
  Puzzle({required this.id, required this.type, this.file, required this.data, required this.answer});
  factory Puzzle.fromJson(Map<String, dynamic> j) => Puzzle(
        id: j['id'] as String,
        type: j['type'] as String,
        file: j['file'] as String?,
        data: Map<String, dynamic>.from((j['data'] as Map?) ?? const {}),
        answer: j['answer'] as Object,
      );
}

/// 목표 판정에 필요한 셸 상태 스냅샷.
class GoalState {
  final Set<String> read; // "host:/path"
  final Set<String> solved; // puzzle id
  final Set<String> connected; // host key
  final Set<String> ran; // "host:/path"
  GoalState({
    this.read = const {}, this.solved = const {},
    this.connected = const {}, this.ran = const {},
  });
}

abstract class Goal {
  bool check(GoalState s);

  factory Goal.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('all')) return _Combo(_list(j['all']), all: true);
    if (j.containsKey('any')) return _Combo(_list(j['any']), all: false);
    if (j.containsKey('read')) return _Leaf('read', j['read'] as String);
    if (j.containsKey('puzzle')) return _Leaf('puzzle', j['puzzle'] as String);
    if (j.containsKey('connect')) return _Leaf('connect', j['connect'] as String);
    if (j.containsKey('run')) return _Leaf('run', j['run'] as String);
    throw FormatException('알 수 없는 goal: $j');
  }

  static List<Goal> _list(Object? v) =>
      [for (final g in v as List) Goal.fromJson(g as Map<String, dynamic>)];
}

class _Leaf implements Goal {
  final String kind;
  final String target;
  _Leaf(this.kind, this.target);
  @override
  bool check(GoalState s) => switch (kind) {
        'read' => s.read.contains(target),
        'puzzle' => s.solved.contains(target),
        'connect' => s.connected.contains(target),
        'run' => s.ran.contains(target),
        _ => false,
      };
}

class _Combo implements Goal {
  final List<Goal> parts;
  final bool all;
  _Combo(this.parts, {required this.all});
  @override
  bool check(GoalState s) => all ? parts.every((g) => g.check(s)) : parts.any((g) => g.check(s));
}
```

- [ ] **Step 4: 통과 확인** — `flutter test test/engine/mission_test.dart` → PASS
- [ ] **Step 5: 커밋** — `git commit -am "엔진: 임무 JSON 모델과 목표 판정"` (새 파일은 `git add -A`)

---

### Task 4: 퍼즐 판정 (`lib/engine/puzzles.dart`)

**Files:**
- Create: `lib/engine/puzzles.dart`, `test/engine/puzzles_test.dart`

**Interfaces:**
- Consumes: `Puzzle` (Task 3)
- Produces: `bool checkAnswer(Puzzle p, Object answer)`, `bool answerBuildable(Puzzle p)` (검사 테스트용: 정답이 data 로 만들어지는가), `String decodeText(String text, String encode)`.
- 답 형식: `match` → `List<List<int>>` 쌍, `password` → `String`, `order` → `List<int>`, `codefix` → `Map<int, String>` (줄 번호 → 고른 조각).

- [ ] **Step 1: 실패하는 테스트**

`test/engine/puzzles_test.dart`:
```dart
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
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현**

```dart
import 'mission.dart';

/// 퍼즐 정답 판정. 화면은 이 함수만 부른다.
bool checkAnswer(Puzzle p, Object answer) {
  switch (p.type) {
    case 'match':
      final want = _pairSet(p.answer);
      final got = _pairSet(answer);
      return want.length == got.length && want.containsAll(got);
    case 'password':
      return (answer as String).trim() == (p.answer as String);
    case 'order':
      final want = List<int>.from(p.answer as List);
      final got = List<int>.from(answer as List);
      if (want.length != got.length) return false;
      for (var i = 0; i < want.length; i++) {
        if (want[i] != got[i]) return false;
      }
      return true;
    case 'codefix':
      final got = answer as Map;
      for (final b in _bugs(p)) {
        if (got[b['line']] != b['answer']) return false;
      }
      return true;
  }
  return false;
}

Set<String> _pairSet(Object v) =>
    {for (final pair in v as List) '${(pair as List)[0]}-${pair[1]}'};

List<Map> _bugs(Puzzle p) => List<Map>.from(p.data['bugs'] as List);

/// 정답을 data 만으로 만들 수 있는가. `missions_test` 가 쓴다.
bool answerBuildable(Puzzle p) {
  switch (p.type) {
    case 'match':
      final l = (p.data['left'] as List).length;
      final r = (p.data['right'] as List).length;
      final usedL = <int>{};
      for (final pair in p.answer as List) {
        final a = (pair as List)[0] as int;
        final b = pair[1] as int;
        if (a < 0 || a >= l || b < 0 || b >= r || !usedL.add(a)) return false;
      }
      return usedL.length == l;
    case 'password':
      return _buildable(p.answer as String, List<String>.from(p.data['fragments'] as List));
    case 'order':
      final n = (p.data['items'] as List).length;
      final got = List<int>.from(p.answer as List);
      return got.length == n && got.toSet().length == n && got.every((i) => i >= 0 && i < n);
    case 'codefix':
      final n = (p.data['lines'] as List).length;
      return _bugs(p).every((b) =>
          (b['line'] as int) < n && List<String>.from(b['choices'] as List).contains(b['answer']));
  }
  return false;
}

/// 조각을 각각 한 번씩만 써서 answer 를 이어 만들 수 있는가.
bool _buildable(String rest, List<String> frags) {
  if (rest.isEmpty) return true;
  for (var i = 0; i < frags.length; i++) {
    if (rest.startsWith(frags[i])) {
      final left = [...frags]..removeAt(i);
      if (_buildable(rest.substring(frags[i].length), left)) return true;
    }
  }
  return false;
}

/// `decode` 명령. 모르는 방식이면 원문 그대로.
String decodeText(String text, String encode) {
  if (encode == 'reverse') return text.split('').reversed.join();
  if (encode.startsWith('caesar:')) {
    final k = int.parse(encode.substring(7));
    return String.fromCharCodes(text.runes.map((c) {
      if (c >= 97 && c <= 122) return 97 + (c - 97 - k + 26) % 26;
      if (c >= 65 && c <= 90) return 65 + (c - 65 - k + 26) % 26;
      return c;
    }));
  }
  return text;
}
```

- [ ] **Step 4: 통과 확인** — PASS
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "엔진: 퍼즐 4종 판정과 decode"`

---

### Task 5: 셸 엔진 — 챕터 1·2 명령 (`lib/engine/shell.dart`)

**Files:**
- Create: `lib/engine/shell.dart`, `test/engine/shell_test.dart`

**Interfaces:**
- Consumes: Task 2·3·4 전부
- Produces:
  ```dart
  class ShellResult { String text; String? key; Map<String,Object> args; String? openFile; String? fileText; String? openPuzzle; bool get isError; }
  class Suggestions { List<String> commands; List<String> args; }
  class Shell {
    Shell(Mission m);
    String hostKey; String cwd; List<String> history;
    bool get awaitingPassword; bool get goalDone; Host get host; GoalState get state;
    ShellResult run(String line);
    ShellResult submitPuzzle(String id, Object answer);   // 틀리면 key 'puzzle_wrong'
    Suggestions suggestions();
    String? nextSolutionLine();
  }
  const Map<String,int> kCommandChapter;   // 명령 → 처음 등장 챕터
  ```
- 오류 열쇠는 전부 `shell_err_` 로 시작한다(검사 테스트가 이 접두어로 실패를 잡는다).

- [ ] **Step 1: 실패하는 테스트 (챕터 1·2)**

`test/engine/shell_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/engine/shell.dart';

Mission mk({String input = 'chips', List<String>? commands}) => Mission.fromJson({
  'id': 'm9_01', 'chapter': 9, 'input': input,
  'commands': commands ?? ['scan', 'connect', 'open', 'decode', 'back', 'ls', 'cd', 'pwd', 'cat', 'grep'],
  'words': ['ERROR'],
  'hosts': {
    'home': {'name': 'my-laptop', 'fs': {
      'note.txt': 'go to shop', 'secret.txt': {'text': 'sz1', 'encode': 'caesar:1'},
      '.hidden': 'h', 'work/': {'log.txt': 'ok\nERROR bad\nok'}}},
    'shop': {'name': 'shop-server', 'lock': {'type': 'password', 'answer': 'ry1'},
      'fs': {'flag.txt': 'FLAG', 'safe.txt': {'text': 'S', 'lock': {'type': 'password', 'answer': 'zz'}},
             'box.txt': 'B'}},
    'vault': {'name': 'vault', 'lock': {'type': 'puzzle', 'puzzle': 'p1'}, 'fs': {'v.txt': 'V'}},
  },
  'puzzles': [
    {'id': 'p1', 'type': 'order', 'data': {'items': ['a', 'b']}, 'answer': [1, 0]},
    {'id': 'p2', 'type': 'password', 'file': 'shop:/box.txt', 'data': {'fragments': ['B', 'x']}, 'answer': 'Bx'},
  ],
  'goal': {'all': [{'read': 'shop:/flag.txt'}, {'puzzle': 'p1'}]},
  'solution': ['scan', 'connect shop-server', 'ry1', 'open flag.txt', 'connect vault', {'puzzle': 'p1'}],
});

void main() {
  test('scan·connect·비밀번호·open·goal', () {
    final sh = Shell(mk());
    expect(sh.run('scan').text, contains('shop-server'));
    expect(sh.run('scan').text, contains('LOCKED'));
    var r = sh.run('connect shop-server');
    expect(r.key, 'shell_password_prompt');
    expect(sh.awaitingPassword, isTrue);
    r = sh.run('wrong');
    expect(r.key, 'shell_err_wrong_password');
    expect(sh.awaitingPassword, isTrue);
    r = sh.run('ry1');
    expect(r.key, 'shell_connected');
    expect(sh.hostKey, 'shop');
    expect(sh.goalDone, isFalse);
    r = sh.run('open flag.txt');
    expect(r.openFile, '/flag.txt');
    expect(r.fileText, 'FLAG');
    expect(sh.state.read, contains('shop:/flag.txt'));
    r = sh.run('connect vault');
    expect(r.openPuzzle, 'p1');
    expect(sh.submitPuzzle('p1', [0, 1]).key, 'puzzle_wrong');
    r = sh.submitPuzzle('p1', [1, 0]);
    expect(r.key, 'shell_connected');
    expect(sh.hostKey, 'vault');
    expect(sh.goalDone, isTrue);
  });
  test('잠금 푼 호스트는 다시 묻지 않는다', () {
    final sh = Shell(mk());
    sh.run('connect shop-server'); sh.run('ry1'); sh.run('back');
    expect(sh.hostKey, 'home');
    expect(sh.run('connect shop-server').key, 'shell_connected');
  });
  test('오류 열쇠', () {
    final sh = Shell(mk());
    expect(sh.run('nope').key, 'shell_err_unknown');
    expect(sh.run('find x').key, 'shell_err_locked_cmd');
    expect(sh.run('connect zzz').key, 'shell_err_no_host');
    expect(sh.run('open zzz').key, 'shell_err_no_file');
    expect(sh.run('open work').key, 'shell_err_is_dir');
    expect(sh.run('cd nope').key, 'shell_err_no_dir');
    expect(sh.run('decode note.txt').key, 'shell_err_not_encoded');
    expect(sh.run('open').key, 'shell_err_usage');
    expect(sh.run('').key, isNull);
  });
  test('decode 는 풀어서 보여 주고 읽은 것으로 친다', () {
    final sh = Shell(mk());
    final r = sh.run('decode secret.txt');
    expect(r.fileText, 'ry1');
    expect(sh.state.read, contains('home:/secret.txt'));
  });
  test('ls·cd·pwd·cat·grep·숨김', () {
    final sh = Shell(mk());
    expect(sh.run('ls').text, 'note.txt\nsecret.txt\nwork/');
    expect(sh.run('ls -a').text, '.hidden\nnote.txt\nsecret.txt\nwork/');
    expect(sh.run('cd work').key, isNull);
    expect(sh.run('pwd').text, '/work');
    expect(sh.run('cat log.txt').fileText, 'ok\nERROR bad\nok');
    expect(sh.run('grep ERROR log.txt').text, 'ERROR bad');
    expect(sh.run('grep zzz log.txt').key, 'shell_empty');
    expect(sh.run('cd ..').key, isNull);
    expect(sh.cwd, '/');
    expect(sh.run('cat /work/log.txt').openFile, '/work/log.txt');
    expect(sh.run('cd').key, isNull);
  });
  test('파일 비밀번호 잠금과 파일 퍼즐', () {
    final sh = Shell(mk());
    sh.run('connect shop-server'); sh.run('ry1');
    expect(sh.run('cat safe.txt').key, 'shell_password_prompt');
    expect(sh.run('zz').fileText, 'S');
    expect(sh.run('cat safe.txt').fileText, 'S');
    expect(sh.run('cat box.txt').openPuzzle, 'p2');
    final r = sh.submitPuzzle('p2', 'Bx');
    expect(r.fileText, 'B');
    expect(sh.state.read, contains('shop:/box.txt'));
    expect(sh.run('cat box.txt').openPuzzle, isNull);
  });
  test('칩 제안', () {
    final sh = Shell(mk());
    final s = sh.suggestions();
    expect(s.commands, contains('ls'));
    expect(s.args, containsAll(['note.txt', 'work', 'shop-server', 'ERROR', '..', '-a']));
    expect(s.args, isNot(contains('.hidden')));
    sh.run('ls -a');
    expect(sh.suggestions().args, contains('.hidden'));
  });
  test('힌트 3: 다음 정답 줄', () {
    final sh = Shell(mk());
    expect(sh.nextSolutionLine(), 'scan');
    sh.run('scan');
    expect(sh.nextSolutionLine(), 'connect shop-server');
    sh.run('ls');
    expect(sh.nextSolutionLine(), 'connect shop-server');
    sh.run('connect shop-server'); sh.run('ry1');
    expect(sh.nextSolutionLine(), 'open flag.txt');
  });
  test('kCommandChapter 는 21개 명령을 전부 안다', () {
    expect(kCommandChapter.length, 21);
    expect(kCommandChapter['scan'], 1);
    expect(kCommandChapter['|'], 3);
    expect(kCommandChapter['run'], 4);
  });
}
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현 (챕터 3·4 명령은 Task 6 에서 채운다 — 여기서는 `_notYet`/`_piped` 를 자리만 둔다)**

```dart
import 'mission.dart';
import 'paths.dart';
import 'puzzles.dart';

/// 명령 → 처음 등장하는 챕터. 설계 문서 4절 표.
const Map<String, int> kCommandChapter = {
  'scan': 1, 'connect': 1, 'open': 1, 'decode': 1, 'back': 1,
  'ls': 2, 'cd': 2, 'pwd': 2, 'cat': 2, 'grep': 2,
  'find': 3, 'ssh': 3, 'head': 3, 'tail': 3, '|': 3, 'history': 3,
  'git': 4, 'env': 4, 'crontab': 4, 'fix': 4, 'run': 4,
};

class ShellResult {
  final String text; // 원문 출력 (번역 안 함)
  final String? key; // 번역 열쇠 (오류는 shell_err_ 로 시작)
  final Map<String, Object> args;
  final String? openFile; // 파일 창에 띄울 절대 경로
  final String? fileText; // 그 파일의 (풀린) 내용
  final String? openPuzzle; // 퍼즐 창에 띄울 퍼즐 id
  const ShellResult({
    this.text = '', this.key, this.args = const {},
    this.openFile, this.fileText, this.openPuzzle,
  });
  bool get isError => key?.startsWith('shell_err_') ?? false;
}

class Suggestions {
  final List<String> commands;
  final List<String> args;
  Suggestions(this.commands, this.args);
}

class Shell {
  final Mission mission;
  late String hostKey;
  String cwd = '/';
  final Set<String> _unlockedHosts = {};
  final Set<String> _unlockedFiles = {}; // "host:/path"
  final Set<String> _read = {};
  final Set<String> _solved = {};
  final Set<String> _connected = {};
  final Set<String> _ran = {};
  final Set<String> _revealed = {}; // ls -a 한 폴더 "host:/dir"
  final List<String> history = [];
  String? _pendingHost; // 비밀번호 대기 중인 호스트 key
  String? _pendingFile; // 비밀번호 대기 중인 파일 절대 경로
  String? _puzzleHost; // 퍼즐 창이 뜬 원인이 호스트 잠금이면 그 key
  int _solutionIdx = 0;

  Shell(this.mission) {
    hostKey = mission.start;
    _connected.add(hostKey);
  }

  Host get host => mission.hosts[hostKey]!;
  bool get awaitingPassword => _pendingHost != null || _pendingFile != null;
  GoalState get state => GoalState(read: _read, solved: _solved, connected: _connected, ran: _ran);
  bool get goalDone => mission.goal.check(state);

  /// 정답 경로에서 아직 안 한 첫 줄. 힌트 3 용.
  String? nextSolutionLine() {
    if (_solutionIdx >= mission.solution.length) return null;
    final s = mission.solution[_solutionIdx];
    return s is String ? s : 'puzzle ${(s as PuzzleStep).puzzle}';
  }

  // ponytail: 정답 경로 추적은 "다음 줄과 똑같으면 전진" 뿐이다. 다른 순서로 풀면
  // 힌트 3 이 이미 한 일을 가리킬 수 있다. 문제 되면 goal 상태로 건너뛰기 추가.
  void _advance(Object step) {
    if (_solutionIdx >= mission.solution.length) return;
    final want = mission.solution[_solutionIdx];
    final same = (want is String && step is String && want == step) ||
        (want is PuzzleStep && step is PuzzleStep && want.puzzle == step.puzzle);
    if (same) _solutionIdx++;
  }

  ShellResult run(String rawLine) {
    final line = rawLine.trim();
    final r = _run(line);
    if (!r.isError) _advance(line);
    return r;
  }

  ShellResult _run(String line) {
    if (_pendingHost != null || _pendingFile != null) return _password(line);
    if (line.isEmpty) return const ShellResult();
    history.add(line);
    final pipe = line.indexOf('|');
    if (pipe >= 0) return _piped(line.substring(0, pipe).trim(), line.substring(pipe + 1).trim());
    final parts = line.split(RegExp(r'\s+'));
    final cmd = parts.first;
    final a = parts.sublist(1);
    if (!kCommandChapter.containsKey(cmd)) return _err('shell_err_unknown', {'cmd': cmd});
    if (!mission.commands.contains(cmd)) return _err('shell_err_locked_cmd', {'cmd': cmd});
    switch (cmd) {
      case 'scan': return _scan();
      case 'connect': return a.isEmpty ? _usage('connect <host>') : _connect(a[0]);
      case 'back': return _switchHost(mission.start);
      case 'open':
      case 'cat': return a.isEmpty ? _usage('$cmd <file>') : _open(a[0]);
      case 'decode': return a.isEmpty ? _usage('decode <file>') : _open(a[0], decode: true);
      case 'ls': return _ls(a);
      case 'cd': return _cd(a.isEmpty ? '/' : a[0]);
      case 'pwd': return ShellResult(text: cwd);
      case 'grep': return a.length < 2 ? _usage('grep <word> <file>') : _grep(a[0], a[1]);
      default: return _notYet(cmd, a);
    }
  }

  // Task 6 에서 채운다.
  ShellResult _notYet(String cmd, List<String> a) => _err('shell_err_unknown', {'cmd': cmd});
  ShellResult _piped(String left, String right) => _err('shell_err_unknown', {'cmd': '|'});

  ShellResult _err(String key, [Map<String, Object> args = const {}]) => ShellResult(key: key, args: args);
  ShellResult _usage(String usage) => _err('shell_err_usage', {'usage': usage});

  ShellResult _scan() {
    final lines = mission.hosts.values.map((h) {
      final locked = h.lock != null && !_unlockedHosts.contains(h.key);
      return '${h.name}  ${locked ? 'LOCKED' : 'open'}';
    });
    return ShellResult(text: lines.join('\n'));
  }

  ShellResult _connect(String name) {
    final h = mission.hostByName(name);
    if (h == null) return _err('shell_err_no_host', {'host': name});
    if (h.lock != null && !_unlockedHosts.contains(h.key)) {
      if (h.lock!.type == 'password') {
        _pendingHost = h.key;
        return const ShellResult(key: 'shell_password_prompt');
      }
      _puzzleHost = h.key;
      return ShellResult(openPuzzle: h.lock!.puzzle);
    }
    return _switchHost(h.key);
  }

  ShellResult _switchHost(String key) {
    hostKey = key;
    cwd = '/';
    _connected.add(key);
    return ShellResult(key: 'shell_connected', args: {'host': host.name});
  }

  ShellResult _password(String line) {
    if (_pendingHost != null) {
      final h = mission.hosts[_pendingHost]!;
      if (line != h.lock!.answer) return _err('shell_err_wrong_password');
      _unlockedHosts.add(h.key);
      _pendingHost = null;
      return _switchHost(h.key);
    }
    final path = _pendingFile!;
    final f = lookup(host.fs, path) as FsFile;
    if (line != f.lock!.answer) return _err('shell_err_wrong_password');
    _unlockedFiles.add(joinHostPath(hostKey, path));
    _pendingFile = null;
    return _open(path);
  }

  /// 파일을 연다. 잠금·퍼즐이 있으면 그쪽으로 보내고, 아니면 내용을 돌려준다.
  ShellResult _open(String arg, {bool decode = false}) {
    final path = normalizePath(cwd, arg);
    final node = lookup(host.fs, path);
    if (node == null) return _err('shell_err_no_file', {'path': arg});
    if (node is FsDir) return _err('shell_err_is_dir', {'path': arg});
    final f = node as FsFile;
    final hp = joinHostPath(hostKey, path);
    if (f.lock != null && !_unlockedFiles.contains(hp)) {
      _pendingFile = path;
      return const ShellResult(key: 'shell_password_prompt');
    }
    final pz = mission.puzzleForFile(hostKey, path);
    if (pz != null && pz.type != 'codefix' && !_solved.contains(pz.id)) {
      return ShellResult(openPuzzle: pz.id);
    }
    if (decode && f.encode == null) return _err('shell_err_not_encoded');
    final text = decode ? decodeText(f.text, f.encode!) : f.text;
    _read.add(hp);
    return ShellResult(text: text, openFile: path, fileText: text);
  }

  ShellResult _ls(List<String> a) {
    final all = a.contains('-a');
    final target = a.where((x) => !x.startsWith('-')).toList();
    final path = target.isEmpty ? cwd : normalizePath(cwd, target[0]);
    final node = lookup(host.fs, path);
    if (node is! FsDir) return _err('shell_err_no_dir', {'path': target.isEmpty ? cwd : target[0]});
    if (all) _revealed.add(joinHostPath(hostKey, path));
    final names = node.children.keys.where((n) => all || !n.startsWith('.')).toList()..sort();
    final lines = names.map((n) => node.children[n] is FsDir ? '$n/' : n);
    return lines.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: lines.join('\n'));
  }

  ShellResult _cd(String arg) {
    final path = normalizePath(cwd, arg);
    if (lookup(host.fs, path) is! FsDir) return _err('shell_err_no_dir', {'path': arg});
    cwd = path;
    return const ShellResult();
  }

  ShellResult _grep(String word, String file) {
    final r = _open(file);
    if (r.fileText == null) return r; // 오류·잠금·퍼즐 그대로
    final lines = r.fileText!.split('\n').where((l) => l.contains(word)).toList();
    return lines.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: lines.join('\n'));
  }

  /// 퍼즐 창에서 「확인」. 맞으면 잠금 해제 → 호스트 접속 또는 파일 열기.
  ShellResult submitPuzzle(String id, Object answer) {
    final p = mission.puzzleById(id)!;
    if (!checkAnswer(p, answer)) return const ShellResult(key: 'puzzle_wrong');
    _solved.add(id);
    _advance(PuzzleStep(id));
    for (final h in mission.hosts.values) {
      if (h.lock?.puzzle == id) _unlockedHosts.add(h.key);
    }
    if (_puzzleHost != null) {
      final k = _puzzleHost!;
      _puzzleHost = null;
      return _switchHost(k);
    }
    if (p.file != null && p.type != 'codefix') {
      final i = p.file!.indexOf(':');
      final hk = p.file!.substring(0, i);
      final path = p.file!.substring(i + 1);
      if (hk == hostKey) return _open(path);
    }
    return const ShellResult(key: 'puzzle_solved');
  }

  Suggestions suggestions() {
    final dir = lookup(host.fs, cwd) as FsDir;
    final showHidden = _revealed.contains(joinHostPath(hostKey, cwd));
    final args = <String>[
      ...dir.children.keys.where((n) => showHidden || !n.startsWith('.')),
      '..',
      ...mission.hosts.values.map((h) => h.name),
      ...mission.words,
      if (mission.commands.contains('ls')) '-a',
    ];
    return Suggestions(List.of(mission.commands), args);
  }
}
```

- [ ] **Step 4: 통과 확인** — `flutter test test/engine/shell_test.dart` → PASS
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "엔진: 셸 챕터1·2 명령, 잠금, 퍼즐 제출, 칩 제안"`

---

### Task 6: 셸 엔진 — 챕터 3·4 명령

**Files:**
- Modify: `lib/engine/shell.dart` (`_notYet`·`_piped` 를 실제 구현으로 교체), `test/engine/shell_test.dart` (테스트 추가)

**Interfaces:**
- Consumes: Task 5 의 `Shell`
- Produces: `find ssh head tail | history git env crontab fix run` 동작. `submitPuzzle` 가 codefix 면 `key: 'puzzle_solved'` 를 돌려주고 `run` 이 그 파일을 성공시킨다.

- [ ] **Step 1: 실패하는 테스트 추가**

`test/engine/shell_test.dart` 의 `main()` 안에 추가:
```dart
  Mission mk34() => Mission.fromJson({
    'id': 'm9_02', 'chapter': 9, 'input': 'keyboard',
    'commands': ['ls', 'cd', 'cat', 'find', 'ssh', 'head', 'tail', '|', 'grep', 'history',
                 'git', 'env', 'crontab', 'fix', 'run', 'connect'],
    'hosts': {
      'home': {'name': 'my-laptop', 'fs': {
        '.bash_history': 'ssh dev@api-box\ncat notes.txt',
        'notes.txt': 'l1\nl2\nl3\nl4',
        'src/': {'deep/': {'app.py': 'x = 1\nif x <= 1:\n  print(x)'}}}},
      'api': {'name': 'api-box', 'user': 'dev',
        'git': [{'hash': 'a1b2', 'message': 'tweak limit', 'diff': '-limit = 10\n+limit = 1'}],
        'env': {'MODE': 'prod', 'LIMIT': '1'}, 'cron': ['0 3 * * * /opt/backup.sh'],
        'fs': {'server.py': 'limit = 1\nfor i in range(limit):\n  work(i)'}},
    },
    'puzzles': [
      {'id': 'c1', 'type': 'codefix', 'file': 'api:/server.py',
       'data': {'lang': 'python', 'lines': ['limit = 1', 'for i in range(limit):', '  work(i)'],
                'bugs': [{'line': 0, 'choices': ['1', '10', '100'], 'answer': '10'}],
                'failOutput': 'Traceback: limit too small', 'okOutput': 'served 10 requests'},
       'answer': 'bugs'},
    ],
    'goal': {'run': 'api:/server.py'},
    'solution': ['ssh dev@api-box', 'fix server.py', {'puzzle': 'c1'}, 'run server.py'],
  });

  test('find·head·tail·pipe·history', () {
    final sh = Shell(mk34());
    expect(sh.run('find app').text, '/src/deep/app.py');
    expect(sh.run('find zzz').key, 'shell_empty');
    expect(sh.run('head -n 2 notes.txt').text, 'l1\nl2');
    expect(sh.run('tail -n 1 notes.txt').text, 'l4');
    expect(sh.run('head notes.txt').text, 'l1\nl2\nl3\nl4');
    expect(sh.run('cat notes.txt | grep l3').text, 'l3');
    expect(sh.run('cat notes.txt | grep zz').key, 'shell_empty');
    expect(sh.run('cat notes.txt | wc').key, 'shell_err_usage');
    expect(sh.run('history').text, 'ssh dev@api-box\ncat notes.txt');
  });
  test('ssh 는 계정이 맞아야', () {
    final sh = Shell(mk34());
    expect(sh.run('ssh root@api-box').key, 'shell_err_ssh_denied');
    expect(sh.run('ssh dev@zzz').key, 'shell_err_no_host');
    expect(sh.run('ssh dev').key, 'shell_err_usage');
    expect(sh.run('ssh dev@api-box').key, 'shell_connected');
    expect(sh.hostKey, 'api');
  });
  test('git·env·crontab', () {
    final sh = Shell(mk34());
    sh.run('ssh dev@api-box');
    expect(sh.run('git log').text, 'a1b2  tweak limit');
    expect(sh.run('git diff a1b2').text, '-limit = 10\n+limit = 1');
    expect(sh.run('git diff zz').key, 'shell_err_no_commit');
    expect(sh.run('git').key, 'shell_err_usage');
    expect(sh.run('env').text, 'MODE=prod\nLIMIT=1');
    expect(sh.run('crontab -l').text, '0 3 * * * /opt/backup.sh');
    expect(sh.run('crontab').key, 'shell_err_usage');
  });
  test('fix·run·codefix', () {
    final sh = Shell(mk34());
    sh.run('ssh dev@api-box');
    expect(sh.run('run server.py').text, 'Traceback: limit too small');
    expect(sh.goalDone, isFalse);
    expect(sh.run('fix notes.txt').key, 'shell_err_nothing_to_fix');
    expect(sh.run('cat server.py').fileText, isNotNull); // codefix 는 cat 을 막지 않는다
    expect(sh.run('fix server.py').openPuzzle, 'c1');
    expect(sh.submitPuzzle('c1', {0: '1'}).key, 'puzzle_wrong');
    expect(sh.submitPuzzle('c1', {0: '10'}).key, 'puzzle_solved');
    expect(sh.run('run server.py').text, 'served 10 requests');
    expect(sh.goalDone, isTrue);
    expect(sh.run('run notes.txt').key, 'shell_err_nothing_to_run');
  });
  test('키보드 임무의 칩에는 ssh 계정·커밋 해시가 들어간다', () {
    final sh = Shell(mk34());
    expect(sh.suggestions().args, contains('dev@api-box'));
    sh.run('ssh dev@api-box');
    expect(sh.suggestions().args, containsAll(['log', 'diff', 'a1b2', '-l', '-n']));
  });
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현 — `shell.dart` 에서 `_notYet`·`_piped` 두 줄을 지우고 아래로 교체**

`_run` 의 `default:` 분기를 다음으로:
```dart
      case 'find': return a.isEmpty ? _usage('find <name>') : _find(a[0]);
      case 'ssh': return _ssh(a);
      case 'head':
      case 'tail': return _headTail(cmd, a);
      case 'history': return _history();
      case 'git': return _git(a);
      case 'env': return _env();
      case 'crontab': return a.contains('-l') ? _cron() : _usage('crontab -l');
      case 'fix': return a.isEmpty ? _usage('fix <file>') : _fix(a[0]);
      case 'run': return a.isEmpty ? _usage('run <file>') : _runFile(a[0]);
      default: return _err('shell_err_unknown', {'cmd': cmd});
```

새 메서드:
```dart
  /// `왼쪽 | grep 낱말` 만 지원한다. 왼쪽은 파일 창을 열지 않고 글만 쓴다.
  ShellResult _piped(String left, String right) {
    if (!mission.commands.contains('|')) return _err('shell_err_locked_cmd', {'cmd': '|'});
    final r = right.split(RegExp(r'\s+'));
    if (r.length != 2 || r[0] != 'grep') return _usage('... | grep <word>');
    final l = _run(left);
    if (l.isError || l.key == 'shell_password_prompt' || l.openPuzzle != null) return l;
    final src = l.fileText ?? l.text;
    final lines = src.split('\n').where((x) => x.contains(r[1])).toList();
    return lines.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: lines.join('\n'));
  }

  ShellResult _find(String name) {
    final out = <String>[];
    void walk(FsDir d, String prefix) {
      d.children.forEach((n, node) {
        final p = prefix == '/' ? '/$n' : '$prefix/$n';
        if (n.contains(name)) out.add(p);
        if (node is FsDir) walk(node, p);
      });
    }
    walk(host.fs, '/');
    out.sort();
    return out.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: out.join('\n'));
  }

  ShellResult _ssh(List<String> a) {
    if (a.isEmpty || !a[0].contains('@')) return _usage('ssh <user>@<host>');
    final at = a[0].indexOf('@');
    final user = a[0].substring(0, at);
    final name = a[0].substring(at + 1);
    final h = mission.hostByName(name);
    if (h == null) return _err('shell_err_no_host', {'host': name});
    if (h.user != null && h.user != user) return _err('shell_err_ssh_denied', {'user': user});
    return _connect(name);
  }

  ShellResult _headTail(String cmd, List<String> a) {
    var n = 10;
    final rest = <String>[];
    for (var i = 0; i < a.length; i++) {
      if (a[i] == '-n' && i + 1 < a.length) {
        n = int.tryParse(a[++i]) ?? 10;
      } else {
        rest.add(a[i]);
      }
    }
    if (rest.isEmpty) return _usage('$cmd -n <k> <file>');
    final r = _open(rest[0]);
    if (r.fileText == null) return r;
    final lines = r.fileText!.split('\n');
    final pick = cmd == 'head' ? lines.take(n) : lines.skip(lines.length > n ? lines.length - n : 0);
    return ShellResult(text: pick.join('\n'));
  }

  ShellResult _history() {
    final f = lookup(host.fs, '/.bash_history');
    if (f is! FsFile) return const ShellResult(key: 'shell_empty');
    return ShellResult(text: f.text);
  }

  ShellResult _git(List<String> a) {
    if (a.isEmpty) return _usage('git log | git diff <hash>');
    if (a[0] == 'log') {
      if (host.git.isEmpty) return const ShellResult(key: 'shell_empty');
      return ShellResult(text: host.git.map((c) => '${c.hash}  ${c.message}').join('\n'));
    }
    if (a[0] == 'diff' && a.length >= 2) {
      for (final c in host.git) {
        if (c.hash == a[1]) return ShellResult(text: c.diff);
      }
      return _err('shell_err_no_commit', {'hash': a[1]});
    }
    return _usage('git log | git diff <hash>');
  }

  ShellResult _env() => host.env.isEmpty
      ? const ShellResult(key: 'shell_empty')
      : ShellResult(text: host.env.entries.map((e) => '${e.key}=${e.value}').join('\n'));

  ShellResult _cron() =>
      host.cron.isEmpty ? const ShellResult(key: 'shell_empty') : ShellResult(text: host.cron.join('\n'));

  Puzzle? _codefixFor(String arg) {
    final p = mission.puzzleForFile(hostKey, normalizePath(cwd, arg));
    return p?.type == 'codefix' ? p : null;
  }

  ShellResult _fix(String arg) {
    final p = _codefixFor(arg);
    if (p == null) return _err('shell_err_nothing_to_fix', {'path': arg});
    return ShellResult(openPuzzle: p.id);
  }

  ShellResult _runFile(String arg) {
    final p = _codefixFor(arg);
    if (p == null) return _err('shell_err_nothing_to_run', {'path': arg});
    if (!_solved.contains(p.id)) return ShellResult(text: p.data['failOutput'] as String? ?? 'error');
    _ran.add(joinHostPath(hostKey, normalizePath(cwd, arg)));
    return ShellResult(text: p.data['okOutput'] as String? ?? 'OK', key: 'shell_run_ok');
  }
```

`suggestions()` 의 `args` 에 추가:
```dart
      if (mission.commands.contains('ssh'))
        ...mission.hosts.values.where((h) => h.user != null).map((h) => '${h.user}@${h.name}'),
      if (mission.commands.contains('git')) ...['log', 'diff', ...host.git.map((c) => c.hash)],
      if (mission.commands.contains('crontab')) '-l',
      if (mission.commands.contains('head') || mission.commands.contains('tail')) '-n',
```

- [ ] **Step 4: 통과 확인** — `flutter test test/engine` → 전부 PASS
- [ ] **Step 5: 커밋** — `git commit -am "엔진: 챕터3·4 명령(find·ssh·pipe·git·env·crontab·fix·run)"`

---

### Task 7: 진행 저장 · 힌트 보상 경로

**Files:**
- Create: `lib/engine/progress.dart`, `lib/engine/rewards.dart`, `test/engine/progress_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class Progress {
    static Future<Progress> load();          // SharedPreferences 에서
    bool isDone(String id); int stars(String id); int hintsUsed(String id);
    Future<void> complete(String id, int hintsUsed);   // 별 = max(1, 3-힌트), 더 좋은 값만 남김
    bool isUnlocked(String id, List<String> orderedIds); // 앞 임무가 끝났으면
    Future<void> reset();
    bool soundOn; Future<void> setSound(bool v);
  }
  class Rewards { static Future<bool> unlockHint(String missionId); }
  ```
- `shared_preferences` 는 순수 Dart 패키지라 `lib/engine/` 에서 import 해도 된다(Flutter 위젯 의존 없음). 테스트는 `SharedPreferences.setMockInitialValues`.

- [ ] **Step 1: 실패하는 테스트**

`test/engine/progress_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/progress.dart';
import 'package:hack_quest/engine/rewards.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('완료·별·힌트', () async {
    final p = await Progress.load();
    expect(p.isDone('m1_01'), isFalse);
    expect(p.stars('m1_01'), 0);
    await p.complete('m1_01', 1);
    expect(p.isDone('m1_01'), isTrue);
    expect(p.stars('m1_01'), 2);
    expect(p.hintsUsed('m1_01'), 1);
    await p.complete('m1_01', 3);
    expect(p.stars('m1_01'), 2); // 더 나쁜 결과는 덮지 않는다
    await p.complete('m1_01', 0);
    expect(p.stars('m1_01'), 3);
    expect(p.hintsUsed('m1_01'), 0);
    await p.complete('m1_02', 5);
    expect(p.stars('m1_02'), 1); // 최소 1
    final again = await Progress.load();
    expect(again.stars('m1_01'), 3); // 저장됨
  });
  test('잠금 해제 순서', () async {
    final p = await Progress.load();
    const ids = ['m1_01', 'm1_02', 'm1_03'];
    expect(p.isUnlocked('m1_01', ids), isTrue);
    expect(p.isUnlocked('m1_02', ids), isFalse);
    await p.complete('m1_01', 0);
    expect(p.isUnlocked('m1_02', ids), isTrue);
    expect(p.isUnlocked('m1_03', ids), isFalse);
  });
  test('깨진 세이브는 빈 진행으로', () async {
    SharedPreferences.setMockInitialValues({'stars.m1_01': 'garbage', 'done.m1_01': 7});
    final p = await Progress.load();
    expect(p.stars('m1_01'), 0);
    expect(p.isDone('m1_01'), isFalse);
  });
  test('초기화·소리', () async {
    final p = await Progress.load();
    await p.complete('m1_01', 0);
    await p.setSound(false);
    await p.reset();
    expect(p.isDone('m1_01'), isFalse);
    expect(p.soundOn, isFalse); // 설정은 남긴다
  });
  test('힌트 보상 경로는 지금은 항상 허용', () async {
    expect(await Rewards.unlockHint('m1_01'), isTrue);
  });
}
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현**

`lib/engine/progress.dart`:
```dart
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// 임무 진행 저장. 열쇠: done.<id> stars.<id> hints.<id> sound
class Progress {
  final SharedPreferences _p;
  Progress._(this._p);

  static Future<Progress> load() async => Progress._(await SharedPreferences.getInstance());

  bool isDone(String id) => _bool('done.$id');
  int stars(String id) => _int('stars.$id');
  int hintsUsed(String id) => _int('hints.$id');
  bool get soundOn => _p.containsKey('sound') ? _bool('sound') : true;

  // 형이 다르면(깨진 세이브) 기본값. SharedPreferences 는 형이 다르면 던진다.
  bool _bool(String k) {
    try { return _p.getBool(k) ?? false; } catch (_) { return false; }
  }
  int _int(String k) {
    try { return _p.getInt(k) ?? 0; } catch (_) { return 0; }
  }

  Future<void> complete(String id, int hintsUsed) async {
    final newStars = max(1, 3 - hintsUsed);
    await _p.setBool('done.$id', true);
    if (newStars > stars(id)) {
      await _p.setInt('stars.$id', newStars);
      await _p.setInt('hints.$id', hintsUsed);
    }
  }

  bool isUnlocked(String id, List<String> orderedIds) {
    final i = orderedIds.indexOf(id);
    return i <= 0 || isDone(orderedIds[i - 1]);
  }

  Future<void> setSound(bool v) => _p.setBool('sound', v);

  Future<void> reset() async {
    for (final k in _p.getKeys().toList()) {
      if (k.startsWith('done.') || k.startsWith('stars.') || k.startsWith('hints.')) {
        await _p.remove(k);
      }
    }
  }
}
```

`lib/engine/rewards.dart`:
```dart
/// 보상이 걸리는 경로는 전부 여기를 지난다. 보상형 광고를 붙이면 이 함수 안에서
/// 광고를 보여 주고 결과를 돌려준다 — 게임 로직은 안 건드린다.
class Rewards {
  // ponytail: 지금은 무조건 허용. 광고 SDK 를 붙일 때 ad_service 호출로 교체.
  static Future<bool> unlockHint(String missionId) async => true;
}
```

- [ ] **Step 4: 통과 확인** — PASS
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "엔진: 진행 저장과 힌트 보상 경로"`

---

### Task 8: 검사 테스트 + 챕터 1 임무 6개

**Files:**
- Create: `test/missions_test.dart`, `assets/missions/m1_01.json` … `m1_06.json`
- Modify: `i18n/ko.json`, `i18n/en.json` (임무 문장 추가), `lib/l10n/*` 재생성

**Interfaces:**
- Consumes: `Mission`, `Shell`, `kCommandChapter`, `answerBuildable`
- Produces: 임무 파일 6개. 검사 테스트는 이후 임무가 늘 때마다 자동으로 포함한다.

- [ ] **Step 1: 검사 테스트 (먼저 쓴다 — 임무가 없으면 "챕터가 하나도 없다" 로 실패해야 한다)**

`test/missions_test.dart`:
```dart
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
```

`flutter test test/missions_test.dart` → '임무 파일이 있다' 가 FAIL.

- [ ] **Step 2: 임무 JSON 6개**

`assets/missions/m1_01.json`:
```json
{
  "id": "m1_01", "chapter": 1, "title": "@m1_01_title",
  "brief": ["@m1_01_brief_1", "@m1_01_brief_2"], "done": ["@m1_01_done_1"],
  "input": "chips",
  "commands": ["scan", "connect", "open"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {"readme.txt": "@m1_01_f_readme"}},
    "cafe": {"name": "cafe-pc", "fs": {"welcome.txt": "@m1_01_f_welcome"}}
  },
  "start": "home",
  "puzzles": [],
  "goal": {"read": "cafe:/welcome.txt"},
  "hints": ["@m1_01_hint_1", "@m1_01_hint_2", "@m1_01_hint_3"],
  "solution": ["scan", "connect cafe-pc", "open welcome.txt"]
}
```

`assets/missions/m1_02.json`:
```json
{
  "id": "m1_02", "chapter": 1, "title": "@m1_02_title",
  "brief": ["@m1_02_brief_1", "@m1_02_brief_2"], "done": ["@m1_02_done_1"],
  "input": "chips",
  "commands": ["scan", "connect", "open", "decode"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {
      "note.txt": "@m1_02_f_note",
      "secret.txt": {"text": "rshqvhvdph", "encode": "caesar:3"}}},
    "vault": {"name": "vault-box", "lock": {"type": "password", "answer": "opensesame"},
              "fs": {"key.txt": "@m1_02_f_key"}}
  },
  "start": "home",
  "puzzles": [],
  "goal": {"read": "vault:/key.txt"},
  "hints": ["@m1_02_hint_1", "@m1_02_hint_2", "@m1_02_hint_3"],
  "solution": ["open note.txt", "decode secret.txt", "scan", "connect vault-box", "opensesame", "open key.txt"]
}
```

`assets/missions/m1_03.json`:
```json
{
  "id": "m1_03", "chapter": 1, "title": "@m1_03_title",
  "brief": ["@m1_03_brief_1", "@m1_03_brief_2"], "done": ["@m1_03_done_1"],
  "input": "chips",
  "commands": ["scan", "connect", "open"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {"note.txt": "@m1_03_f_note"}},
    "router": {"name": "router", "lock": {"type": "puzzle", "puzzle": "p1"},
               "fs": {"admin.txt": "@m1_03_f_admin"}}
  },
  "start": "home",
  "puzzles": [
    {"id": "p1", "type": "match",
     "data": {"left": ["PWR", "LAN1", "WAN", "USB"], "right": ["ISP", "mouse", "5V", "192.168.0.2"]},
     "answer": [[0, 2], [1, 3], [2, 0], [3, 1]]}
  ],
  "goal": {"all": [{"puzzle": "p1"}, {"read": "router:/admin.txt"}]},
  "hints": ["@m1_03_hint_1", "@m1_03_hint_2", "@m1_03_hint_3"],
  "solution": ["open note.txt", "scan", "connect router", {"puzzle": "p1"}, "open admin.txt"]
}
```

`assets/missions/m1_04.json`:
```json
{
  "id": "m1_04", "chapter": 1, "title": "@m1_04_title",
  "brief": ["@m1_04_brief_1", "@m1_04_brief_2"], "done": ["@m1_04_done_1"],
  "input": "chips",
  "commands": ["scan", "connect", "open"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {"photo.txt": "@m1_04_f_photo"}},
    "cloud": {"name": "cloud-drive", "lock": {"type": "puzzle", "puzzle": "p1"},
              "fs": {"diary.txt": "@m1_04_f_diary"}}
  },
  "start": "home",
  "puzzles": [
    {"id": "p1", "type": "password",
     "data": {"clues": ["@m1_04_p1_c1", "@m1_04_p1_c2"],
              "fragments": ["momo", "2019", "lulu", "2020", "42"]},
     "answer": "momo2019"}
  ],
  "goal": {"read": "cloud:/diary.txt"},
  "hints": ["@m1_04_hint_1", "@m1_04_hint_2", "@m1_04_hint_3"],
  "solution": ["open photo.txt", "scan", "connect cloud-drive", {"puzzle": "p1"}, "open diary.txt"]
}
```

`assets/missions/m1_05.json`:
```json
{
  "id": "m1_05", "chapter": 1, "title": "@m1_05_title",
  "brief": ["@m1_05_brief_1", "@m1_05_brief_2"], "done": ["@m1_05_done_1"],
  "input": "chips",
  "commands": ["scan", "connect", "open"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {"manual.txt": "@m1_05_f_manual"}},
    "old": {"name": "old-server", "lock": {"type": "puzzle", "puzzle": "p1"},
            "fs": {"backup.txt": "@m1_05_f_backup"}}
  },
  "start": "home",
  "puzzles": [
    {"id": "p1", "type": "order",
     "data": {"items": ["Start OS", "Power on", "Login", "Load BIOS"]},
     "answer": [1, 3, 0, 2]}
  ],
  "goal": {"read": "old:/backup.txt"},
  "hints": ["@m1_05_hint_1", "@m1_05_hint_2", "@m1_05_hint_3"],
  "solution": ["open manual.txt", "scan", "connect old-server", {"puzzle": "p1"}, "open backup.txt"]
}
```

`assets/missions/m1_06.json`:
```json
{
  "id": "m1_06", "chapter": 1, "title": "@m1_06_title",
  "brief": ["@m1_06_brief_1", "@m1_06_brief_2", "@m1_06_brief_3"], "done": ["@m1_06_done_1", "@m1_06_done_2"],
  "input": "chips",
  "commands": ["scan", "connect", "open", "decode", "back"],
  "hosts": {
    "home": {"name": "my-laptop", "fs": {
      "note.txt": "@m1_06_f_note",
      "hint.txt": {"text": "dpggff7", "encode": "caesar:1"}}},
    "mail": {"name": "mail-box", "lock": {"type": "password", "answer": "coffee7"},
             "fs": {"letter.txt": "@m1_06_f_letter"}},
    "safe": {"name": "safe-box", "lock": {"type": "puzzle", "puzzle": "p1"},
             "fs": {"prize.txt": "@m1_06_f_prize"}}
  },
  "start": "home",
  "puzzles": [
    {"id": "p1", "type": "match",
     "data": {"left": ["red", "blue", "green"], "right": ["B", "C", "A"]},
     "answer": [[0, 2], [1, 1], [2, 0]]},
    {"id": "p2", "type": "order", "file": "safe:/prize.txt",
     "data": {"items": ["Open lid", "Turn key", "Take prize"]},
     "answer": [1, 0, 2]}
  ],
  "goal": {"all": [{"read": "safe:/prize.txt"}, {"puzzle": "p1"}, {"puzzle": "p2"}]},
  "hints": ["@m1_06_hint_1", "@m1_06_hint_2", "@m1_06_hint_3"],
  "solution": ["open note.txt", "decode hint.txt", "scan", "connect mail-box", "coffee7",
               "open letter.txt", "connect safe-box", {"puzzle": "p1"}, "open prize.txt", {"puzzle": "p2"}]
}
```

- [ ] **Step 3: 문장 (ko.json 에 추가)**

```json
  "m1_01_title": "첫 접속",
  "m1_01_brief_1": "안녕, 신입. 나는 고스트. 첫 일은 쉬운 거다.",
  "m1_01_brief_2": "동네 카페 PC에 환영 메모가 하나 있어. scan 으로 찾고, connect 로 들어가서, open 으로 읽어 봐.",
  "m1_01_done_1": "좋아. 명령 세 개면 어디든 갈 수 있지. 다음 건 조금 더 재미있을 거다.",
  "m1_01_f_readme": "내 노트북. 할 일: 카페 PC 접속해 보기.",
  "m1_01_f_welcome": "환영합니다! 당신은 방금 첫 서버에 접속했습니다.",
  "m1_01_hint_1": "먼저 scan 을 눌러 주변 서버를 찾아보세요.",
  "m1_01_hint_2": "connect 를 누르고 서버 이름 칩을 이어서 누르세요.",
  "m1_01_hint_3": "open 을 누르고 welcome.txt 를 고르세요.",

  "m1_02_title": "암호 메모",
  "m1_02_brief_1": "친구가 금고 서버 비밀번호를 잊어버렸대. 메모를 남겼는데 암호로 적어 뒀다는군.",
  "m1_02_brief_2": "내 노트북의 메모를 읽고, 암호 파일은 decode 로 풀어 봐. 그 비밀번호로 vault-box 에 들어가면 된다.",
  "m1_02_done_1": "decode 하나로 암호가 풀리다니, 친구가 보안에 약하군. 다음 일로 가자.",
  "m1_02_f_note": "비밀번호는 secret.txt 에 적어 뒀는데, 글자를 세 칸씩 밀어서 썼어. decode 명령이면 되돌릴 수 있을 거야.",
  "m1_02_f_key": "금고 열쇠 번호: 4417. 친구에게 전해 주세요.",
  "m1_02_hint_1": "note.txt 를 먼저 읽어 보세요. 어떤 파일을 풀어야 하는지 적혀 있어요.",
  "m1_02_hint_2": "decode 를 누르고 secret.txt 를 고르면 진짜 비밀번호가 나옵니다.",
  "m1_02_hint_3": "connect vault-box 를 한 뒤, 풀린 글자를 그대로 입력하세요.",

  "m1_03_title": "회로 잇기",
  "m1_03_brief_1": "공유기 관리 화면이 잠겼다. 뒷면 포트 배선을 맞춰야 열린다는군.",
  "m1_03_brief_2": "노트북 메모에 어느 포트에 뭐가 꽂히는지 적어 뒀어. 그대로 짝을 이어 봐.",
  "m1_03_done_1": "배선 정리 끝. 이제 관리자 메모도 네 것이다.",
  "m1_03_f_note": "공유기 뒷면: PWR 에는 5V 어댑터, LAN1 에는 192.168.0.2 데스크톱, WAN 은 ISP 회선, USB 에는 mouse.",
  "m1_03_f_admin": "관리자 메모: 공유기 비밀번호는 다음 주에 바꿀 것.",
  "m1_03_hint_1": "note.txt 에 포트마다 무엇이 연결되는지 적혀 있습니다.",
  "m1_03_hint_2": "connect router 를 하면 배선 퍼즐이 뜹니다. 왼쪽 포트를 누른 뒤 오른쪽 짝을 누르세요.",
  "m1_03_hint_3": "PWR→5V, LAN1→192.168.0.2, WAN→ISP, USB→mouse 를 이은 뒤 open admin.txt.",

  "m1_04_title": "단서로 비밀번호",
  "m1_04_brief_1": "클라우드 드라이브가 잠겼는데 주인은 비밀번호를 기억 못 해. 다행히 힌트가 있어.",
  "m1_04_brief_2": "사람들은 보통 반려동물 이름과 연도를 섞어 쓰지. 노트북의 사진 메모를 봐.",
  "m1_04_done_1": "역시 반려동물 이름이었군. 사람은 늘 같은 실수를 한다.",
  "m1_04_f_photo": "사진 뒷면 메모: 우리 고양이 모모(momo). 2019년 봄에 데려옴.",
  "m1_04_f_diary": "일기: 드디어 드라이브를 다시 열었다. 비밀번호는 이제 적어 두자.",
  "m1_04_p1_c1": "고양이 이름은 소문자 영어로 쓴다.",
  "m1_04_p1_c2": "그 뒤에 데려온 해를 네 자리로 붙인다.",
  "m1_04_hint_1": "photo.txt 에 고양이 이름과 연도가 있습니다.",
  "m1_04_hint_2": "connect cloud-drive 를 하면 조립 퍼즐이 뜹니다. 이름 조각 다음에 연도 조각을 누르세요.",
  "m1_04_hint_3": "momo 다음 2019. 그리고 open diary.txt.",

  "m1_05_title": "순서 맞추기",
  "m1_05_brief_1": "오래된 서버가 켜지지 않아. 부팅 순서를 손으로 잡아 줘야 하는 골동품이야.",
  "m1_05_brief_2": "노트북에 설명서를 넣어 뒀다. 순서대로 끌어다 놓으면 켜질 거야.",
  "m1_05_done_1": "골동품이 살아났군. 백업 파일 잘 챙겼다.",
  "m1_05_f_manual": "구형 서버 부팅 순서: 1) 전원을 켠다 2) BIOS 를 읽는다 3) 운영체제를 시작한다 4) 로그인한다.",
  "m1_05_f_backup": "백업 목록: 사진 1,204장, 문서 88개. 전부 무사함.",
  "m1_05_hint_1": "manual.txt 에 부팅 순서가 번호로 적혀 있습니다.",
  "m1_05_hint_2": "connect old-server 를 하면 순서 퍼즐이 뜹니다. 항목을 길게 눌러 끌어 옮기세요.",
  "m1_05_hint_3": "Power on → Load BIOS → Start OS → Login 순서로 놓고 open backup.txt.",

  "m1_06_title": "두 대의 서버",
  "m1_06_brief_1": "이번엔 진짜 의뢰다. 할머니가 돌아가시기 전 손자에게 남긴 선물이 금고 서버에 있어.",
  "m1_06_brief_2": "먼저 메일 서버에 들어가야 금고 여는 법을 알 수 있다. 메일 비밀번호는 노트북에 암호로 있고.",
  "m1_06_brief_3": "서버가 두 대니까 길을 잃으면 back 으로 돌아와. 배운 걸 전부 써 봐.",
  "m1_06_done_1": "손자가 선물을 받았대. 네 첫 챕터는 여기까지.",
  "m1_06_done_2": "다음부터는 장난감 명령 말고 진짜 명령어를 쓴다. 준비해.",
  "m1_06_f_note": "메일 서버 비밀번호는 hint.txt 에 한 칸씩 밀어서 적어 둠. 금고 여는 법은 메일 안에.",
  "m1_06_f_letter": "손자에게. 금고 색 자물쇠는 red 는 A, blue 는 C, green 은 B 에 맞춘다. 열 때는 열쇠를 먼저 돌리고, 뚜껑을 열고, 선물을 꺼내렴.",
  "m1_06_f_prize": "선물: 할머니가 손자 이름으로 심은 나무의 위치 지도.",
  "m1_06_hint_1": "note.txt 를 읽고 hint.txt 를 decode 하세요. 그게 mail-box 비밀번호입니다.",
  "m1_06_hint_2": "mail-box 의 letter.txt 에 색 자물쇠 짝과 금고 여는 순서가 있습니다.",
  "m1_06_hint_3": "red→A, blue→C, green→B. 그 다음 Turn key → Open lid → Take prize.",
```

`en.json` 에 같은 열쇠를 영어로. 예:
```json
  "m1_01_title": "First Connection",
  "m1_01_brief_1": "Hi, rookie. I'm Ghost. Your first job is an easy one.",
  "m1_01_brief_2": "There's a welcome note on the cafe PC down the street. Find it with scan, get in with connect, read it with open.",
  "m1_01_done_1": "Good. Three commands and you can go anywhere. The next one gets more interesting.",
  "m1_01_f_readme": "My laptop. To do: try connecting to the cafe PC.",
  "m1_01_f_welcome": "Welcome! You just connected to your first server.",
  "m1_01_hint_1": "Tap scan first to find nearby servers.",
  "m1_01_hint_2": "Tap connect, then tap the server name chip.",
  "m1_01_hint_3": "Tap open and pick welcome.txt.",
```
나머지 5개 임무도 같은 식으로 전부 옮긴다(단서·힌트 속 영문 조각·명령은 그대로). `python ..\common\i18n\gen.py i18n --to flutter --out lib\l10n` 재생성.

- [ ] **Step 4: 통과 확인**

`flutter test` → `missions_test`·`i18n_test` 포함 전부 PASS. 하나라도 빨간불이면 임무 JSON 또는 문장을 고친다(엔진을 고치지 않는다 — 엔진 버그면 Task 5·6 테스트에 먼저 재현 테스트를 넣는다).

- [ ] **Step 5: 커밋** — `git add -A; git commit -m "챕터1 임무 6개와 임무 검사 테스트"`

---

### Task 9: 카탈로그 · 테마 · 앱 시작 · 메시지함 · 임무 상세

**Files:**
- Create: `lib/catalog.dart`, `lib/ui/theme.dart`, `lib/ui/inbox_screen.dart`, `lib/ui/brief_screen.dart`, `test/catalog_test.dart`
- Modify: `lib/main.dart` (템플릿 전부 교체), `test/widget_test.dart` (삭제)

**Interfaces:**
- Produces:
  ```dart
  class Catalog { List<Mission> missions; Set<String> broken; static Catalog fromTexts(Map<String,String?>); static Future<Catalog> load();
                  List<int> get chapters; List<Mission> chapter(int c); Mission? byId(String); Mission? after(String id); List<String> get orderedIds; }
  ThemeData hqTheme; String tr(String s);   // '@키' 면 번역, 아니면 그대로
  class InboxScreen(progress, catalog); class BriefScreen(mission, progress, catalog)
  ```
- `MissionScreen`·`ResultScreen`·`SettingsScreen`·`PromoScreen` 은 Task 10·12 에서 만든다. 이 Task 에서는 `BriefScreen` 의 접속 버튼이 Task 10 의 `MissionScreen` 을 가리키므로, Task 10 전까지는 버튼 `onPressed` 를 `null` 로 두고 Task 10 에서 연결한다.

- [ ] **Step 1: 카탈로그 테스트**

`test/catalog_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/catalog.dart';

const good = '{"id":"m1_01","chapter":1,"title":"@t","brief":["@b"],"done":["@d"],"commands":["scan"],'
    '"hosts":{"home":{"name":"h","fs":{}}},"goal":{"connect":"home"},"hints":["@1","@2","@3"],"solution":[]}';

void main() {
  test('깨진 임무는 빼고 broken 에 남긴다', () {
    final c = Catalog.fromTexts({'m1_01': good, 'm1_02': '{not json', 'm1_03': null});
    expect(c.missions.map((m) => m.id), ['m1_01']);
    expect(c.broken, {'m1_02'});
    expect(c.chapters, [1]);
    expect(c.chapter(1).length, 1);
    expect(c.byId('m1_01'), isNotNull);
    expect(c.after('m1_01'), isNull);
    expect(c.orderedIds, ['m1_01']);
  });
  test('진짜 자산이 전부 읽힌다', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final c = await Catalog.load();
    expect(c.broken, isEmpty);
    expect(c.chapter(1).length, 6);
    expect(c.after('m1_01')!.id, 'm1_02');
  });
}
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현**

`lib/catalog.dart`:
```dart
import 'package:flutter/services.dart' show rootBundle;

import 'engine/mission.dart';

/// 임무 전부. 파일이 없거나 깨지면 그 임무만 빠진다(앱은 죽지 않는다).
class Catalog {
  final List<Mission> missions;
  final Set<String> broken;
  Catalog._(this.missions, this.broken);

  /// id → JSON 글. null 이면 파일 없음(조용히 건너뜀), 깨진 글이면 broken.
  static Catalog fromTexts(Map<String, String?> texts) {
    final out = <Mission>[];
    final broken = <String>{};
    texts.forEach((id, text) {
      if (text == null) return;
      try {
        out.add(Mission.parse(text));
      } catch (_) {
        broken.add(id);
      }
    });
    out.sort((a, b) => a.id.compareTo(b.id));
    return Catalog._(out, broken);
  }

  static Future<Catalog> load() async {
    final texts = <String, String?>{};
    for (var c = 1; c <= 5; c++) {
      for (var n = 1; n <= 6; n++) {
        final id = 'm${c}_0$n';
        try {
          texts[id] = await rootBundle.loadString('assets/missions/$id.json');
        } catch (_) {
          texts[id] = null;
        }
      }
    }
    return fromTexts(texts);
  }

  List<int> get chapters => missions.map((m) => m.chapter).toSet().toList()..sort();
  List<Mission> chapter(int c) => missions.where((m) => m.chapter == c).toList();
  List<String> get orderedIds => missions.map((m) => m.id).toList();
  Mission? byId(String id) {
    for (final m in missions) {
      if (m.id == id) return m;
    }
    return null;
  }
  Mission? after(String id) {
    final i = orderedIds.indexOf(id);
    return i < 0 || i + 1 >= missions.length ? null : missions[i + 1];
  }
}
```

`lib/ui/theme.dart`:
```dart
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
```

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';

import 'catalog.dart';
import 'engine/progress.dart';
import 'strings.dart';
import 'ui/inbox_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLang().load();
  final progress = await Progress.load();
  final catalog = await Catalog.load();
  runApp(HackQuestApp(progress: progress, catalog: catalog));
}

class HackQuestApp extends StatelessWidget {
  final Progress progress;
  final Catalog catalog;
  const HackQuestApp({super.key, required this.progress, required this.catalog});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: AppLang(),
        builder: (_, __, ___) => MaterialApp(
          title: 'HackQuest',
          theme: hqTheme,
          home: InboxScreen(progress: progress, catalog: catalog),
        ),
      );
}
```

`lib/ui/inbox_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'brief_screen.dart';
import 'promo_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

class InboxScreen extends StatefulWidget {
  final Progress progress;
  final Catalog catalog;
  const InboxScreen({super.key, required this.progress, required this.catalog});
  @override
  State<InboxScreen> createState() => _InboxState();
}

class _InboxState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final c = widget.catalog;
    final ids = c.orderedIds;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('inbox_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.videogame_asset),
            tooltip: S.t('btn_promo'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: S.t('btn_settings'),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(progress: p)));
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final ch in c.chapters) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(S.tn('inbox_chapter_n', {'n': ch}), style: const TextStyle(color: hqOrange, fontSize: 18)),
            ),
            for (final m in c.chapter(ch))
              ListTile(
                enabled: p.isUnlocked(m.id, ids),
                leading: Icon(p.isDone(m.id) ? Icons.check_circle : (p.isUnlocked(m.id, ids) ? Icons.mail : Icons.lock),
                    color: p.isDone(m.id) ? hqGreen : hqDim),
                title: Text(tr(m.title)),
                subtitle: p.isUnlocked(m.id, ids) ? null : Text(S.t('inbox_locked')),
                trailing: Text('★' * p.stars(m.id), style: const TextStyle(color: hqOrange)),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BriefScreen(mission: m, progress: p, catalog: c)));
                  setState(() {});
                },
              ),
          ],
          for (final id in c.broken)
            ListTile(enabled: false, leading: const Icon(Icons.error), title: Text(id), subtitle: Text(S.t('mission_broken'))),
        ],
      ),
    );
  }
}
```

`lib/ui/brief_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'mission_screen.dart';
import 'theme.dart';

class BriefScreen extends StatelessWidget {
  final Mission mission;
  final Progress progress;
  final Catalog catalog;
  const BriefScreen({super.key, required this.mission, required this.progress, required this.catalog});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(tr(mission.title))),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(S.t('brief_from'), style: const TextStyle(color: hqDim)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [for (final b in mission.brief) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(tr(b), style: const TextStyle(fontSize: 16)))],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => MissionScreen(mission: mission, progress: progress, catalog: catalog))),
                child: Text(S.t('btn_connect')),
              ),
            ],
          ),
        ),
      );
}
```

Task 10·12 전까지 컴파일되게, `lib/ui/mission_screen.dart`·`settings_screen.dart`·`promo_screen.dart` 는 아래 빈 화면으로 먼저 만든다(Task 10·12 에서 교체):
```dart
// mission_screen.dart (임시)
import 'package:flutter/material.dart';
import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
class MissionScreen extends StatelessWidget {
  final Mission mission; final Progress progress; final Catalog catalog;
  const MissionScreen({super.key, required this.mission, required this.progress, required this.catalog});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('mission')));
}
```
```dart
// settings_screen.dart (임시)
import 'package:flutter/material.dart';
import '../engine/progress.dart';
class SettingsScreen extends StatelessWidget {
  final Progress progress;
  const SettingsScreen({super.key, required this.progress});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('settings')));
}
```
```dart
// promo_screen.dart (임시)
import 'package:flutter/material.dart';
class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('promo')));
}
```
`test/widget_test.dart`(템플릿)는 지운다.

- [ ] **Step 4: 통과 확인** — `flutter test` 전부 PASS, `flutter analyze` 경고 0.
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "앱 뼈대: 카탈로그, 테마, 메시지함, 임무 상세"`

---

### Task 10: 가짜 OS 화면 — 터미널 · 파일 창 · 입력 바

**Files:**
- Create: `lib/ui/terminal_view.dart`, `lib/ui/file_view.dart`, `lib/ui/input_bar.dart`, `test/input_bar_test.dart`
- Modify: `lib/ui/mission_screen.dart` (임시 → 실제)

**Interfaces:**
- Consumes: `Shell`, `Suggestions`, `Progress`, `Rewards`, `Catalog`, `tr`
- Produces:
  ```dart
  class TermLine { String text; bool isCmd; bool isError; }
  class TerminalView(List<TermLine> lines)
  class FileView(String path, String text, VoidCallback onClose)
  class InputBar({Suggestions suggestions, bool editable, bool password, void Function(String) onRun})
  class MissionScreen(mission, progress, catalog)   // 퍼즐 창은 Task 11 에서 끼운다
  ```

- [ ] **Step 1: 입력 바 위젯 테스트**

`test/input_bar_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/shell.dart';
import 'package:hack_quest/ui/input_bar.dart';

Widget wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('칩만으로 한 줄을 만들고 실행하면 비워진다', (t) async {
    String? ran;
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['scan', 'open'], ['a.txt']),
      editable: false, password: false, onRun: (s) => ran = s,
    )));
    await t.tap(find.byKey(const Key('chip_open')));
    await t.pump();
    await t.tap(find.byKey(const Key('chip_a.txt')));
    await t.pump();
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).controller!.text, 'open a.txt ');
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).readOnly, isTrue);
    await t.tap(find.byKey(const Key('run_btn')));
    await t.pump();
    expect(ran, 'open a.txt');
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).controller!.text, '');
  });
  testWidgets('비밀번호 대기 중에는 칩이 없고 입력칸이 열린다', (t) async {
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['scan'], ['a.txt']),
      editable: false, password: true, onRun: (_) {},
    )));
    expect(find.byKey(const Key('chip_scan')), findsNothing);
    final f = t.widget<TextField>(find.byKey(const Key('input_field')));
    expect(f.readOnly, isFalse);
    expect(f.obscureText, isTrue);
  });
  testWidgets('키보드 임무는 입력칸이 열려 있고 칩도 있다', (t) async {
    await t.pumpWidget(wrap(InputBar(
      suggestions: Suggestions(['find'], ['x']),
      editable: true, password: false, onRun: (_) {},
    )));
    expect(find.byKey(const Key('chip_find')), findsOneWidget);
    expect(t.widget<TextField>(find.byKey(const Key('input_field'))).readOnly, isFalse);
  });
}
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현**

`lib/ui/terminal_view.dart`:
```dart
import 'package:flutter/material.dart';

import 'theme.dart';

class TermLine {
  final String text;
  final bool isCmd;
  final bool isError;
  const TermLine(this.text, {this.isCmd = false, this.isError = false});
}

/// 출력 줄 목록. 새 줄이 오면 맨 아래로.
class TerminalView extends StatefulWidget {
  final List<TermLine> lines;
  const TerminalView({super.key, required this.lines});
  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final _ctl = ScrollController();

  @override
  void didUpdateWidget(TerminalView old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ctl.hasClients) _ctl.jumpTo(_ctl.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
        controller: _ctl,
        padding: const EdgeInsets.all(12),
        itemCount: widget.lines.length,
        itemBuilder: (_, i) {
          final l = widget.lines[i];
          return Text(
            l.isCmd ? '\$ ${l.text}' : l.text,
            style: TextStyle(color: l.isError ? hqRed : (l.isCmd ? hqOrange : hqGreen), fontSize: 14),
          );
        },
      );
}
```

`lib/ui/file_view.dart`:
```dart
import 'package:flutter/material.dart';

import '../strings.dart';
import 'theme.dart';

class FileView extends StatelessWidget {
  final String path;
  final String text;
  final VoidCallback onClose;
  const FileView({super.key, required this.path, required this.text, required this.onClose});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: hqPanel,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(child: Text(path, style: const TextStyle(color: hqOrange))),
              TextButton(onPressed: onClose, child: Text(S.t('btn_close'))),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(text, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
          ),
        ],
      );
}
```

`lib/ui/input_bar.dart`:
```dart
import 'package:flutter/material.dart';

import '../engine/shell.dart';
import '../strings.dart';
import 'theme.dart';

/// 칩 두 줄(명령·인자) + 입력칸 + 실행. 칩을 누르면 입력칸에 낱말이 들어간다.
/// `editable=false` 면 입력칸은 읽기 전용(칩만). 비밀번호 대기 중엔 칩을 숨기고 입력칸을 연다.
class InputBar extends StatefulWidget {
  final Suggestions suggestions;
  final bool editable;
  final bool password;
  final void Function(String line) onRun;
  const InputBar({super.key, required this.suggestions, required this.editable, required this.password, required this.onRun});
  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _ctl = TextEditingController();

  void _append(String token) => setState(() => _ctl.text = '${_ctl.text}$token ');

  void _run() {
    final line = _ctl.text.trim();
    _ctl.clear();
    if (line.isNotEmpty) widget.onRun(line);
  }

  Widget _chips(List<String> items) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(key: Key('chip_$t'), label: Text(t), onPressed: () => _append(t)),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Container(
        color: hqPanel,
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!widget.password) ...[
            _chips(widget.suggestions.commands),
            const SizedBox(height: 6),
            _chips(widget.suggestions.args),
            const SizedBox(height: 6),
          ],
          Row(children: [
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('input_field'),
                controller: _ctl,
                readOnly: !(widget.editable || widget.password),
                obscureText: widget.password,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(color: hqGreen),
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: widget.password ? '' : '\$ ',
                  hintText: S.t(widget.password ? 'input_password_hint' : 'input_command_hint'),
                ),
                onSubmitted: (_) => _run(),
              ),
            ),
            IconButton(key: const Key('clear_btn'), icon: const Icon(Icons.backspace_outlined), onPressed: () => setState(_ctl.clear)),
            FilledButton(key: const Key('run_btn'), onPressed: _run, child: Text(S.t('btn_run'))),
            const SizedBox(width: 8),
          ]),
        ]),
      );
}
```

`lib/ui/mission_screen.dart` (임시 파일 교체):
```dart
import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../engine/rewards.dart';
import '../engine/shell.dart';
import '../strings.dart';
import 'file_view.dart';
import 'input_bar.dart';
import 'puzzles/puzzle_view.dart';
import 'result_screen.dart';
import 'terminal_view.dart';
import 'theme.dart';

enum _Win { terminal, file, puzzle }

class MissionScreen extends StatefulWidget {
  final Mission mission;
  final Progress progress;
  final Catalog catalog;
  const MissionScreen({super.key, required this.mission, required this.progress, required this.catalog});
  @override
  State<MissionScreen> createState() => _MissionState();
}

class _MissionState extends State<MissionScreen> {
  late final Shell shell = Shell(widget.mission);
  final List<TermLine> lines = [];
  _Win win = _Win.terminal;
  String filePath = '';
  String fileText = '';
  String puzzleId = '';
  int hintsUsed = 0;
  final startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    lines.add(TermLine(S.t('shell_welcome')));
  }

  void _show(ShellResult r) {
    if (r.key != null) lines.add(TermLine(S.tn(r.key!, r.args), isError: r.isError));
    if (r.text.isNotEmpty && r.openFile == null) lines.add(TermLine(r.text));
    if (r.openFile != null) {
      filePath = r.openFile!;
      fileText = r.fileText ?? '';
      win = _Win.file;
    } else if (r.openPuzzle != null) {
      puzzleId = r.openPuzzle!;
      win = _Win.puzzle;
    }
  }

  void _afterAction() {
    setState(() {});
    if (shell.goalDone) _finish();
  }

  void _onRun(String line) {
    lines.add(TermLine(shell.awaitingPassword ? '••••' : line, isCmd: true));
    _show(shell.run(line));
    _afterAction();
  }

  bool _onPuzzle(Object answer) {
    final r = shell.submitPuzzle(puzzleId, answer);
    if (r.key == 'puzzle_wrong') return false;
    win = _Win.terminal;
    _show(r);
    _afterAction();
    return true;
  }

  Future<void> _finish() async {
    await widget.progress.complete(widget.mission.id, hintsUsed);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(
      mission: widget.mission, progress: widget.progress, catalog: widget.catalog,
      hintsUsed: hintsUsed, elapsed: DateTime.now().difference(startedAt),
    )));
  }

  String _hintText(int i) {
    final h = widget.mission.hints;
    if (i < h.length) return tr(h[i]);
    return S.tn('hint_next_cmd', {'cmd': shell.nextSolutionLine() ?? '-'});
  }

  void _openHints() {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(S.tn('hint_title', {'n': 3 - hintsUsed}), style: const TextStyle(color: hqOrange, fontSize: 16)),
          const SizedBox(height: 8),
          for (var i = 0; i < hintsUsed; i++) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${i + 1}. ${_hintText(i)}')),
          if (hintsUsed < 3)
            FilledButton(
              onPressed: () async {
                if (!await Rewards.unlockHint(widget.mission.id)) return;
                setState(() => hintsUsed++);
                setSheet(() {});
              },
              child: Text(S.t('btn_hint_next')),
            )
          else
            Text(S.t('hint_none_left'), style: const TextStyle(color: hqDim)),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final Widget window = switch (win) {
      _Win.terminal => TerminalView(lines: lines),
      _Win.file => FileView(path: filePath, text: fileText, onClose: () => setState(() => win = _Win.terminal)),
      _Win.puzzle => PuzzleView(
          key: ValueKey(puzzleId),
          puzzle: m.puzzleById(puzzleId)!,
          onSubmit: _onPuzzle,
          onClose: () => setState(() => win = _Win.terminal),
        ),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('${shell.host.name}:${shell.cwd}', style: const TextStyle(fontSize: 14)),
        leading: IconButton(icon: const Icon(Icons.close), tooltip: S.t('btn_exit'), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton.icon(
            onPressed: _openHints,
            icon: const Icon(Icons.lightbulb_outline, color: hqOrange),
            label: Text('${S.t('btn_hint')} ${'★' * (3 - hintsUsed)}', style: const TextStyle(color: hqOrange)),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(child: window),
        InputBar(
          suggestions: shell.suggestions(),
          editable: m.input == 'keyboard',
          password: shell.awaitingPassword,
          onRun: _onRun,
        ),
      ]),
    );
  }
}
```

`PuzzleView` 와 `ResultScreen` 은 Task 11·12 에서 만든다. 이 Task 를 단독으로 컴파일하려면 둘을 임시로 만든다:
```dart
// lib/ui/puzzles/puzzle_view.dart (임시, Task 11 에서 교체)
import 'package:flutter/material.dart';
import '../../engine/mission.dart';
class PuzzleView extends StatelessWidget {
  final Puzzle puzzle; final bool Function(Object answer) onSubmit; final VoidCallback onClose;
  const PuzzleView({super.key, required this.puzzle, required this.onSubmit, required this.onClose});
  @override Widget build(BuildContext context) => Center(child: Text(puzzle.id));
}
```
```dart
// lib/ui/result_screen.dart (임시, Task 12 에서 교체)
import 'package:flutter/material.dart';
import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
class ResultScreen extends StatelessWidget {
  final Mission mission; final Progress progress; final Catalog catalog; final int hintsUsed; final Duration elapsed;
  const ResultScreen({super.key, required this.mission, required this.progress, required this.catalog, required this.hintsUsed, required this.elapsed});
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('result')));
}
```

- [ ] **Step 4: 통과 확인** — `flutter test` PASS, `flutter analyze` 0. 에뮬레이터나 폰이 있으면 `flutter run` 으로 m1_01 을 칩만으로 끝까지 가 본다(목표 달성 시 임시 result 화면이 떠야 한다).
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "가짜 OS 화면: 터미널·파일 창·칩 입력 바·힌트"`

---

### Task 11: 퍼즐 위젯 4종

**Files:**
- Create: `lib/ui/puzzles/match_puzzle.dart`, `password_puzzle.dart`, `order_puzzle.dart`, `codefix_puzzle.dart`, `test/puzzle_widgets_test.dart`
- Modify: `lib/ui/puzzles/puzzle_view.dart` (임시 → 종류별 분기)

**Interfaces:**
- Consumes: `Puzzle`, `tr`, `checkAnswer` 는 쓰지 않는다 — 판정은 `MissionScreen._onPuzzle` → `Shell.submitPuzzle` 이 한다.
- Produces: 각 위젯 `({Puzzle puzzle, bool Function(Object answer) onSubmit})`. `onSubmit` 이 false 면 위젯이 `puzzle_wrong` 스낵바를 띄우고 자기 상태를 비운다. `PuzzleView` 가 제목 줄(`puzzle_*_title`)·닫기 버튼·분기를 맡는다.
- 답 형식은 Task 4 와 같다: match `List<List<int>>`, password `String`, order `List<int>`, codefix `Map<int,String>`.

- [ ] **Step 1: 위젯 테스트**

`test/puzzle_widgets_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hack_quest/engine/mission.dart';
import 'package:hack_quest/ui/puzzles/puzzle_view.dart';

Widget wrap(Puzzle p, bool Function(Object) onSubmit) =>
    MaterialApp(home: Scaffold(body: PuzzleView(puzzle: p, onSubmit: onSubmit, onClose: () {})));

void main() {
  testWidgets('match: 왼쪽→오른쪽 탭으로 짝을 짓고 확인', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'match', data: {'left': ['A', 'B'], 'right': ['1', '2']}, answer: [[0, 1], [1, 0]]),
      (a) { got = a; return true; },
    ));
    await t.tap(find.byKey(const Key('left_0'))); await t.pump();
    await t.tap(find.byKey(const Key('right_1'))); await t.pump();
    await t.tap(find.byKey(const Key('left_1'))); await t.pump();
    await t.tap(find.byKey(const Key('right_0'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, [[0, 1], [1, 0]]);
  });
  testWidgets('password: 조각을 눌러 조립, 틀리면 비워진다', (t) async {
    final calls = <Object>[];
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'password', data: {'clues': ['c'], 'fragments': ['ab', 'cd']}, answer: 'abcd'),
      (a) { calls.add(a); return a == 'abcd'; },
    ));
    await t.tap(find.byKey(const Key('frag_1'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(calls, ['cd']);
    expect(find.text('cd'), findsNWidgets(1)); // 조립칸은 비워졌고 칩만 남음
    await t.tap(find.byKey(const Key('frag_0'))); await t.pump();
    await t.tap(find.byKey(const Key('frag_1'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(calls.last, 'abcd');
  });
  testWidgets('order: 현재 순서를 그대로 낸다', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'order', data: {'items': ['x', 'y', 'z']}, answer: [0, 1, 2]),
      (a) { got = a; return true; },
    ));
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, [0, 1, 2]);
  });
  testWidgets('codefix: 줄을 누르고 조각을 고른다', (t) async {
    Object? got;
    await t.pumpWidget(wrap(
      Puzzle(id: 'p', type: 'codefix', data: {
        'lang': 'python', 'lines': ['a = 1', 'if a <= 1:'],
        'bugs': [{'line': 1, 'choices': ['<', '<='], 'answer': '<'}],
      }, answer: 'bugs'),
      (a) { got = a; return true; },
    ));
    await t.tap(find.byKey(const Key('line_1'))); await t.pump();
    await t.tap(find.byKey(const Key('choice_<'))); await t.pump();
    await t.tap(find.byKey(const Key('puzzle_submit'))); await t.pump();
    expect(got, {1: '<'});
  });
}
```

- [ ] **Step 2: 실패 확인** — FAIL

- [ ] **Step 3: 구현**

`lib/ui/puzzles/puzzle_view.dart`:
```dart
import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../../strings.dart';
import '../theme.dart';
import 'codefix_puzzle.dart';
import 'match_puzzle.dart';
import 'order_puzzle.dart';
import 'password_puzzle.dart';

/// 퍼즐 창. 제목·닫기 + 종류별 위젯.
class PuzzleView extends StatelessWidget {
  final Puzzle puzzle;
  final bool Function(Object answer) onSubmit;
  final VoidCallback onClose;
  const PuzzleView({super.key, required this.puzzle, required this.onSubmit, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final body = switch (puzzle.type) {
      'match' => MatchPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      'password' => PasswordPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      'order' => OrderPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      'codefix' => CodefixPuzzle(puzzle: puzzle, onSubmit: onSubmit),
      _ => Center(child: Text(puzzle.type)),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        color: hqPanel,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Expanded(child: Text(S.t('puzzle_${puzzle.type}_title'), style: const TextStyle(color: hqOrange))),
          TextButton(onPressed: onClose, child: Text(S.t('btn_close'))),
        ]),
      ),
      Expanded(child: body),
    ]);
  }
}

/// 틀렸을 때 공통 반응.
void showWrong(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('puzzle_wrong')), duration: const Duration(seconds: 1)));

Widget submitButton(VoidCallback? onPressed) => Padding(
      padding: const EdgeInsets.all(12),
      child: FilledButton(key: const Key('puzzle_submit'), onPressed: onPressed, child: Text(S.t('btn_check'))),
    );
```

`lib/ui/puzzles/match_puzzle.dart`:
```dart
import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../theme.dart';
import 'puzzle_view.dart';

/// 왼쪽을 누르고 오른쪽을 누르면 짝. 같은 오른쪽을 다시 고르면 앞 짝은 풀린다.
class MatchPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const MatchPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<MatchPuzzle> createState() => _MatchState();
}

class _MatchState extends State<MatchPuzzle> {
  int? selectedLeft;
  final Map<int, int> pairs = {}; // left → right

  List<String> get left => List<String>.from(widget.puzzle.data['left'] as List);
  List<String> get right => List<String>.from(widget.puzzle.data['right'] as List);

  void _pickRight(int r) {
    final l = selectedLeft;
    if (l == null) return;
    setState(() {
      pairs.removeWhere((_, v) => v == r);
      pairs[l] = r;
      selectedLeft = null;
    });
  }

  void _submit() {
    final ok = widget.onSubmit([for (final e in pairs.entries) [e.key, e.value]]);
    if (!ok) {
      showWrong(context);
      setState(pairs.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = left, r = right;
    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(child: ListView(children: [
            for (var i = 0; i < l.length; i++)
              ListTile(
                key: Key('left_$i'),
                selected: selectedLeft == i,
                selectedTileColor: hqPanel,
                title: Text(tr(l[i])),
                trailing: pairs.containsKey(i) ? Text(tr(r[pairs[i]!]), style: const TextStyle(color: hqOrange)) : null,
                onTap: () => setState(() => selectedLeft = i),
              ),
          ])),
          Expanded(child: ListView(children: [
            for (var j = 0; j < r.length; j++)
              ListTile(
                key: Key('right_$j'),
                title: Text(tr(r[j])),
                tileColor: pairs.containsValue(j) ? hqPanel : null,
                onTap: () => _pickRight(j),
              ),
          ])),
        ]),
      ),
      submitButton(pairs.length == l.length ? _submit : null),
    ]);
  }
}
```

`lib/ui/puzzles/password_puzzle.dart`:
```dart
import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../theme.dart';
import 'puzzle_view.dart';

class PasswordPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const PasswordPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<PasswordPuzzle> createState() => _PasswordState();
}

class _PasswordState extends State<PasswordPuzzle> {
  final List<int> picked = []; // 조각 인덱스 순서

  List<String> get frags => List<String>.from(widget.puzzle.data['fragments'] as List);
  List<String> get clues => List<String>.from((widget.puzzle.data['clues'] as List?) ?? const []);
  String get assembled => picked.map((i) => frags[i]).join();

  void _submit() {
    if (!widget.onSubmit(assembled)) {
      showWrong(context);
      setState(picked.clear);
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
          for (final c in clues)
            Card(color: hqPanel, child: Padding(padding: const EdgeInsets.all(12), child: Text(tr(c)))),
          const SizedBox(height: 12),
          Container(
            key: const Key('assembled'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: hqDim)),
            child: Row(children: [
              Expanded(child: Text(assembled, style: const TextStyle(fontSize: 20, color: hqOrange))),
              IconButton(icon: const Icon(Icons.backspace_outlined), onPressed: picked.isEmpty ? null : () => setState(picked.removeLast)),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < frags.length; i++)
              ActionChip(key: Key('frag_$i'), label: Text(frags[i]), onPressed: picked.contains(i) ? null : () => setState(() => picked.add(i))),
          ]),
        ])),
        submitButton(picked.isEmpty ? null : _submit),
      ]);
}
```

`lib/ui/puzzles/order_puzzle.dart`:
```dart
import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../theme.dart';
import 'puzzle_view.dart';

class OrderPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const OrderPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<OrderPuzzle> createState() => _OrderState();
}

class _OrderState extends State<OrderPuzzle> {
  late List<int> order = List.generate((widget.puzzle.data['items'] as List).length, (i) => i);
  List<String> get items => List<String>.from(widget.puzzle.data['items'] as List);

  void _submit() {
    if (!widget.onSubmit(List<int>.from(order))) {
      showWrong(context);
      setState(() => order = List.generate(items.length, (i) => i));
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.all(12),
            onReorder: (from, to) => setState(() {
              if (to > from) to--;
              order.insert(to, order.removeAt(from));
            }),
            children: [
              for (final i in order)
                ListTile(key: ValueKey(i), tileColor: hqPanel, leading: const Icon(Icons.drag_handle), title: Text(tr(items[i]))),
            ],
          ),
        ),
        submitButton(_submit),
      ]);
}
```

`lib/ui/puzzles/codefix_puzzle.dart`:
```dart
import 'package:flutter/material.dart';

import '../../engine/mission.dart';
import '../../strings.dart';
import '../theme.dart';
import 'puzzle_view.dart';

/// 줄을 누르면 그 줄의 선택지가 아래 뜬다. 고르면 줄 끝에 표시.
// ponytail: 버그 아닌 줄을 누르면 "문제없어 보임" 이 떠서 찍어 보기로 버그 줄을 찾을 수 있다.
// 그래도 어느 조각이 답인지는 모른다. 모든 줄에 가짜 선택지를 주는 건 v1.1 에서.
class CodefixPuzzle extends StatefulWidget {
  final Puzzle puzzle;
  final bool Function(Object) onSubmit;
  const CodefixPuzzle({super.key, required this.puzzle, required this.onSubmit});
  @override
  State<CodefixPuzzle> createState() => _CodefixState();
}

class _CodefixState extends State<CodefixPuzzle> {
  int? selected;
  final Map<int, String> picks = {};

  List<String> get lines => List<String>.from(widget.puzzle.data['lines'] as List);
  List<Map> get bugs => List<Map>.from(widget.puzzle.data['bugs'] as List);
  Map? _bugAt(int i) {
    for (final b in bugs) {
      if (b['line'] == i) return b;
    }
    return null;
  }

  void _tapLine(int i) {
    if (_bugAt(i) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('puzzle_codefix_line_ok')), duration: const Duration(seconds: 1)));
      setState(() => selected = null);
      return;
    }
    setState(() => selected = i);
  }

  void _submit() {
    if (!widget.onSubmit(Map<int, String>.from(picks))) {
      showWrong(context);
      setState(() { picks.clear(); selected = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ls = lines;
    final bug = selected == null ? null : _bugAt(selected!);
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(8), children: [
        for (var i = 0; i < ls.length; i++)
          InkWell(
            key: Key('line_$i'),
            onTap: () => _tapLine(i),
            child: Container(
              color: selected == i ? hqPanel : null,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(children: [
                SizedBox(width: 28, child: Text('${i + 1}', style: const TextStyle(color: hqDim))),
                Expanded(child: Text(ls[i], style: const TextStyle(fontSize: 13))),
                if (picks.containsKey(i)) Text('→ ${picks[i]}', style: const TextStyle(color: hqOrange)),
              ]),
            ),
          ),
      ])),
      if (bug != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 8, children: [
            for (final c in List<String>.from(bug['choices'] as List))
              ChoiceChip(
                key: Key('choice_$c'),
                label: Text(c),
                selected: picks[selected] == c,
                onSelected: (_) => setState(() => picks[selected!] = c),
              ),
          ]),
        ),
      submitButton(picks.length == bugs.length ? _submit : null),
    ]);
  }
}
```

- [ ] **Step 4: 통과 확인** — `flutter test` PASS, `flutter analyze` 0.
- [ ] **Step 5: 커밋** — `git add -A; git commit -m "퍼즐 위젯 4종(짝 잇기·조립·순서·코드 고치기)"`

---

### Task 12: 완료 화면 · 설정 · 홍보 자리

**Files:**
- Modify: `lib/ui/result_screen.dart`, `lib/ui/settings_screen.dart`, `lib/ui/promo_screen.dart` (임시 → 실제)

**Interfaces:**
- Consumes: `Progress`, `Catalog.after`, `BriefScreen`, `kLanguageOrder`, `kLanguageNames`, `AppLang`

- [ ] **Step 1: 구현**

`lib/ui/result_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../catalog.dart';
import '../engine/mission.dart';
import '../engine/progress.dart';
import '../strings.dart';
import 'brief_screen.dart';
import 'theme.dart';

class ResultScreen extends StatelessWidget {
  final Mission mission;
  final Progress progress;
  final Catalog catalog;
  final int hintsUsed;
  final Duration elapsed;
  const ResultScreen({super.key, required this.mission, required this.progress, required this.catalog, required this.hintsUsed, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final next = catalog.after(mission.id);
    final stars = progress.stars(mission.id);
    return Scaffold(
      appBar: AppBar(title: Text(S.t('result_title')), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('★' * stars + '☆' * (3 - stars), textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, color: hqOrange)),
          const SizedBox(height: 8),
          Text(S.tn('result_time', {'m': elapsed.inMinutes, 's': elapsed.inSeconds % 60}), textAlign: TextAlign.center),
          Text(S.tn('result_hints', {'n': hintsUsed}), textAlign: TextAlign.center, style: const TextStyle(color: hqDim)),
          const SizedBox(height: 20),
          Expanded(child: ListView(children: [for (final d in mission.done) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(tr(d), style: const TextStyle(fontSize: 16)))])),
          // 광고 자리. SDK 는 2부 이후에 붙인다 — 자리를 먼저 잡아 두면 판이 안 밀린다.
          const SizedBox(height: 60),
          if (next != null)
            FilledButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => BriefScreen(mission: next, progress: progress, catalog: catalog))),
              child: Text(S.t('btn_next')),
            ),
          TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: Text(S.t('btn_back_inbox'))),
        ]),
      ),
    );
  }
}
```

`lib/ui/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../engine/progress.dart';
import '../strings.dart';

class SettingsScreen extends StatefulWidget {
  final Progress progress;
  const SettingsScreen({super.key, required this.progress});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = AppLang().value;
    return Scaffold(
      appBar: AppBar(title: Text(S.t('settings_title'))),
      body: ListView(children: [
        SwitchListTile(
          title: Text(S.t('settings_sound')),
          value: widget.progress.soundOn,
          onChanged: (v) async { await widget.progress.setSound(v); setState(() {}); },
        ),
        ListTile(title: Text(S.t('settings_language'))),
        for (final code in ['system', ...kLanguageOrder])
          ListTile(
            // 그 언어 글자로 적는다. 번역하지 않는다. (RadioListTile 은 3.3x 에서 deprecated 라 쓰지 않는다)
            title: Text(code == 'system' ? S.t('settings_follow_system') : kLanguageNames[code]!),
            trailing: lang == code ? const Icon(Icons.check) : null,
            onTap: () => AppLang().set(code),
          ),
        const Divider(),
        ListTile(
          title: Text(S.t('btn_reset')),
          onTap: () async {
            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
              content: Text(S.t('confirm_reset')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.t('btn_close'))),
                TextButton(onPressed: () => Navigator.pop(c, true), child: Text(S.t('btn_check'))),
              ],
            ));
            if (ok == true) await widget.progress.reset();
          },
        ),
      ]),
    );
  }
}
```
`AppLang` 은 `ValueNotifier` 라 `main.dart` 의 `ValueListenableBuilder` 가 앱 전체를 다시 그린다. 이 화면도 즉시 바뀌게 `initState` 에서 `AppLang().addListener(_rebuild)`, `dispose` 에서 제거(`_rebuild` = `() => setState(() {})`).

`lib/ui/promo_screen.dart`:
```dart
import 'package:flutter/material.dart';

import '../strings.dart';

/// 「개발자의 다른 게임」 자리. 목록은 legal/apps.json 에서 읽어야 하므로(인터넷)
/// 광고를 붙이는 시점에 common/promo/README.md 대로 채운다.
class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(S.t('promo_title'))),
        body: Center(child: Text(S.t('promo_coming'))),
      );
}
```

- [ ] **Step 2: 확인** — `flutter test` PASS, `flutter analyze` 0. `flutter run` 으로 m1_01 완료 → 완료 화면 → 「다음 임무」 → m1_02 상세가 뜨는지. 설정에서 English 로 바꾸면 메시지함 글이 바로 영어로 바뀌는지.
- [ ] **Step 3: 커밋** — `git add -A; git commit -m "완료 화면·설정·홍보 자리"`

---

### Task 13: 실기기 확인 · README

**Files:**
- Create: `README.md`
- Modify: 확인 중 발견한 결함(각각 재현 테스트 먼저)

- [ ] **Step 1: 디버그 APK 빌드**

```powershell
flutter build apk --debug
```
성공해도 동작 확인이 아니다. **폰 설치는 사용자에게 "폰을 연결해 주세요" 라고 요청한 뒤**에만 한다(백그라운드 대기 금지).

- [ ] **Step 2: 실기기에서 챕터 1 전부 플레이**

m1_01~m1_06 을 힌트 없이 끝까지. 확인 목록:
- 칩만으로 모든 정답 줄이 만들어지는가(키보드 없이)
- 비밀번호 대기에서 키보드가 뜨고, 틀리면 다시 묻는가
- 퍼즐 창에서 틀리면 흔들림 대신 스낵바가 뜨고 상태가 비워지는가
- 호스트 퍼즐을 풀면 바로 접속되는가(m1_03·04·05)
- 파일 퍼즐을 풀면 파일 창이 뜨고 목표가 달성되는가(m1_06 prize.txt)
- 완료 화면 별 개수, 「다음 임무」, 메시지함의 ★ 표시
- 임무 중 「나가기」 로 빠져나오면 진행이 저장되지 않는가(의도)

- [ ] **Step 3: 모든 화면 스크린샷 (ko·en)**

메시지함·임무 상세·터미널·파일 창·퍼즐 4종·힌트 시트·완료·설정·홍보 자리. 글자가 칩·상단 바에서 잘리는지 본다(UI 덤프 말고 스크린샷으로). 발견한 결함은 **재현 테스트 → 수정 → 커밋**.

- [ ] **Step 4: README**


- [ ] **Step 5: 커밋** — `git add -A; git commit -m "README: 빌드법·임무 추가법·남은 일"`

---

## 1부 끝 — 2부로

여기까지 끝나면 **엔진·화면·챕터 1** 이 폰에서 돈다. 다음은 `2026-10-11-hackquest-part2-content-release.md`(챕터 2~5 임무 24개, 12개 언어 번역, 효과음, 아이콘, 스토어 준비).
