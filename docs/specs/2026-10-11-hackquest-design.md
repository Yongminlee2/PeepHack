# HackQuest 설계 문서 — 개발자 해킹을 가장한 퍼즐 게임

작성 2026-10-11. 승인된 설계. 구현 계획은 `docs/plans/` 에 따로 둔다.

## 0. 한 줄 요약

폰에서 가짜 운영체제를 열고, 의뢰인이 보낸 임무 30개를 터미널 명령·논리 퍼즐·코드 고치기로
푸는 Flutter 게임. 초반은 게임용 가짜 명령을 칩으로 누르고, 후반으로 갈수록 진짜 셸 명령과
진짜 코드가 나온다. 임무는 전부 JSON 데이터이고 앱은 엔진 하나만 가진다.

## 1. 확정 사항 (질문·답)

| 항목 | 결정 |
|---|---|
| 핵심 손맛 | 터미널 명령 + 탭·드래그 논리 퍼즐 + 코드 읽고 고치기 + 셋을 섞은 임무. 전부 |
| 플랫폼 | 안드로이드 폰, Flutter. 플레이 스토어 출시 |
| 대상 | 개발 모르는 일반인으로 시작해 개발자용 진짜 명령·코드로 (챕터가 올라갈수록) |
| 진행 구조 | 의뢰인 메시지 → 임무. 스토리형. 별도 연습 모드 없음 |
| v1 분량 | 챕터 5 × 임무 6 = 30임무 |
| 언어 | 14개 (`common/i18n/languages.json`): ko en ja zh zh_Hant es pt de fr it ru id vi th |
| 만드는 방식 | 임무 = JSON 파일. 엔진·퍼즐 위젯은 공용. 검사 테스트가 모든 임무를 실제로 풀어 본다 |
| 폴더 | `C:\workAndroid\HackQuest` (임시 이름, 스토어 이름은 나중에) |

### 하지 않는 것 (v1)

- 연습 모드, 랭킹, 계정, 서버 통신 (인터넷 권한은 광고를 붙일 때만 생긴다)
- 게임 안에 진짜 인터프리터(Lua·JS) 심기
- 실제 공격 기법 교육. 셸 사용법과 논리 추론만 가르친다 (콘텐츠 등급·스토어 정책)
- iOS (코드는 막지 않되 v1 에서 빌드·검증하지 않는다)

## 2. 화면 흐름

```
메시지함(inbox) ─▶ 임무 상세(brief) ─▶ 가짜 OS(mission) ─▶ 완료(result) ─▶ 메시지함
   │ 메뉴: 설정(언어·소리) · 개발자의 다른 게임
```

- **메시지함**: 챕터별 묶음. 완료한 임무는 별(0~3), 다음 임무 하나만 열림. 챕터는 앞 챕터의 임무 6개를 다 깨야 열린다.
- **임무 상세**: 의뢰인 "고스트"의 대사 2~4줄, 목표 한 줄, 「접속」 버튼.
- **가짜 OS**: 세로 화면. 위 70% 가 "창", 아래 30% 가 입력 영역.
  - 창은 한 번에 하나: 터미널(기본) / 파일 보기 / 퍼즐. 퍼즐·파일 창은 「닫기」로 터미널로 돌아온다.
  - 입력 영역: 명령 칩 한 줄 + 인자 칩 한 줄 + (챕터3부터) 키보드 입력칸. 칩을 누르면 입력칸에 글자가 들어가고 「실행」으로 보낸다. 칩만 있는 챕터에서는 입력칸을 보여 주되 편집 불가.
  - 상단 바: 현재 서버 이름·현재 폴더, 힌트 버튼(남은 별 표시), 나가기.
- **완료**: 별, 걸린 시간, 힌트 사용 수, 의뢰인 마무리 대사, 광고 자리(비워 둠), 「다음 임무」.

## 3. 임무 데이터 (`assets/missions/m{챕터}_{번호}.json`)

```json
{
  "id": "m2_03",
  "chapter": 2,
  "input": "chips",
  "commands": ["ls", "cd", "cat", "grep", "pwd", "connect", "scan"],
  "words": ["admin", "error", "backup"],
  "hosts": {
    "home":   { "name": "my-laptop", "fs": { "notes.txt": "@m2_03_f_notes", "work/": { "todo.md": "- check logs" } } },
    "shop":   { "name": "shop-server", "lock": { "type": "password", "answer": "latte2024" },
                "fs": { "var/": { "log/": { "app.log": "2024-05-01 ERROR login admin latte2024\n..." } }, "root/": { "flag.txt": "@m2_03_f_flag" } } }
  },
  "start": "home",
  "puzzles": [
    { "id": "p1", "type": "password", "file": "shop:/root/.safe",
      "data": { "clues": ["@m2_03_p1_c1", "@m2_03_p1_c2"], "fragments": ["lat", "te", "2024", "mocha", "99"] },
      "answer": "latte2024" }
  ],
  "goal": { "all": [ { "read": "shop:/root/flag.txt" }, { "puzzle": "p1" } ] },
  "hints": ["@m2_03_hint_1", "@m2_03_hint_2", "@m2_03_hint_3"],
  "solution": ["scan", "connect shop-server", "latte2024", "cd var/log", "grep admin app.log", "cat /root/flag.txt", { "puzzle": "p1" }]
}
```

규칙:

- 문자열이 `@` 로 시작하면 번역 키다. 그 외는 영어 원문 그대로 보여 준다(로그·코드·명령 출력). 번역하는 것은 의뢰 대사·힌트·단서 카드·사람이 읽는 메모 파일뿐이다.
- 폴더는 이름 끝 `/`. 파일 값은 문자열. 숨김 파일은 이름이 `.` 로 시작하고 `ls -a` 에만 나온다.
- `lock` 은 호스트와 파일 둘 다에 붙을 수 있다. `{"type":"password","answer":"…"}` 또는 `{"type":"puzzle","puzzle":"p1"}`. 잠긴 파일을 열면 퍼즐 창이 뜨고, 풀면 내용이 보인다.
- `goal` 은 `read`(파일 열기), `puzzle`(해결), `connect`(접속), `run`(코드 실행 성공) 과 `all`/`any` 묶음.
- `solution` 은 검사 테스트가 그대로 입력하는 정답 경로다. 문자열은 명령 한 줄(잠금 비밀번호 입력 포함), `{"puzzle":"p1"}` 은 그 퍼즐의 `answer` 를 제출한다는 뜻.
- 파일 값이 객체면 `{"text": "…", "encode": "caesar:3" | "reverse"}` — `decode` 가 풀어 주는 파일. `open`/`cat` 은 암호문 그대로 보여 준다.
- 호스트 추가 필드(필요한 임무만): `user`(ssh 계정 이름), `git: [{hash, message, diff}]`, `env: {KEY: value}`, `cron: ["* * * * * /opt/backup.sh"]`.
- `input` 은 `chips`(챕터 1~2) 또는 `keyboard`(챕터 3~5, 칩도 같이 나온다).
- `words` 는 `grep`·`find` 인자 칩으로 쓸 낱말. 없으면 파일 이름만 칩으로 나온다.

## 4. 터미널 엔진 (`lib/engine/shell.dart`, 순수 Dart, Flutter 의존 없음)

상태: 현재 호스트, 현재 폴더, 열린 잠금 집합, 읽은 파일 집합, 푼 퍼즐 집합, 실행 성공 집합, 명령 기록.
입력 `run(String line)` → 출력 `ShellResult(text, open: 파일|퍼즐|null, goalDone)`.
`suggestions()` → 명령 칩 목록, 인자 칩 목록(현재 폴더 항목 + 알려진 호스트 + `words`).
잠금 입력 대기 상태에서는 다음 한 줄을 비밀번호로 받는다.

명령 표. 챕터는 "처음 등장하는 챕터"이고 이후 챕터는 전부 쓸 수 있다. 임무의 `commands` 에 있는 것만 받는다.

| 명령 | 챕터 | 동작 |
|---|---|---|
| `scan` | 1 | 이 임무의 호스트 목록(이름·잠김 여부) |
| `connect <host>` | 1 | 호스트로 이동. 잠겨 있으면 비밀번호 대기 또는 퍼즐 창 |
| `open <file>` | 1 | 파일 창(챕터1 전용 쉬운 이름, `cat` 과 같다) |
| `decode <file>` | 1 | 카이사르 시프트·역순 등 파일에 붙은 `encode` 규칙을 풀어 보여 준다 |
| `back` | 1 | 홈 호스트로 |
| `ls [-a]` | 2 | 현재 폴더 항목 |
| `cd <dir>` | 2 | `..`·절대·상대 경로 |
| `pwd` | 2 | 현재 경로 |
| `cat <file>` | 2 | 파일 창 |
| `grep <word> <file>` | 2 | 포함하는 줄만 |
| `find <name>` | 3 | 현재 호스트 전체에서 이름 부분 일치 경로 목록 |
| `ssh <user>@<host>` | 3 | `connect` 와 같되 계정 이름이 맞아야 한다(호스트 `user` 필드) |
| `head/tail -n <k> <file>` | 3 | 앞/뒤 k줄 |
| `… \| grep <word>` | 3 | 파이프 한 단계. 앞 명령 출력에 grep |
| `history` | 3 | 이 호스트에 미리 심어 둔 가짜 기록(`fs` 의 `.bash_history`) |
| `git log` / `git diff <hash>` | 4 | 호스트 `git` 필드의 커밋 목록·변경 내용 |
| `env`, `crontab -l` | 4 | 호스트 `env`·`cron` 필드 |
| `fix <file>` | 4 | 그 파일에 붙은 `codefix` 퍼즐 창 |
| `run <file>` | 4 | 그 파일의 codefix 퍼즐이 풀렸으면 성공 출력, 아니면 오류 출력(퍼즐 `data.failOutput`) |

출력 글(오류·안내)은 전부 번역 키다. 명령 이름·경로·로그는 영어 원문.
알 수 없는 명령 → `shell_unknown` 키. 잘못된 비밀번호 → `shell_wrong_password`, 횟수 제한 없음.

## 5. 퍼즐 4종 (`lib/ui/puzzles/`, 정답 판정은 `lib/engine/puzzles.dart` 의 순수 함수)

| type | 화면 | data | answer | 등장 |
|---|---|---|---|---|
| `match` | 왼쪽 점과 오른쪽 점을 드래그로 잇기(회로·포트 짝) | `left[]`, `right[]`, 오답 선 섞기 | `pairs: [[l,r],…]` | 1 |
| `password` | 단서 카드 2~4장 + 조각 칩, 칩을 눌러 비밀번호 조립 | `clues[]`, `fragments[]` | 문자열 | 1 |
| `order` | 항목을 드래그로 순서 맞추기(부팅 순서·로그 순서) | `items[]` | `[인덱스…]` | 1 |
| `codefix` | 코드 10~20줄, 틀린 줄을 탭 → 그 줄에서 바꿀 조각을 칩으로 선택 | `lang`, `lines[]`, `bugs: [{line, choices[], answer}]`, `failOutput` | bugs 전부 맞추기 | 4 |

"단서 찾기(터미널)" 는 퍼즐 종류가 아니라 잠금·목표로 표현한다. "섞기" 는 한 임무에 퍼즐·잠금·목표를 여러 개 두는 것이다.
퍼즐 창은 「확인」 을 누르면 판정하고, 틀리면 흔들림 + `puzzle_wrong` 글, 맞으면 잠금 해제 후 터미널로 돌아간다. 틀린 횟수 제한 없음.

## 6. 진행·저장 (`lib/engine/progress.dart`, shared_preferences)

- 키: `done.<id>`(bool), `stars.<id>`(0~3), `hints.<id>`(쓴 힌트 수), `lang`, `sound`.
- 별 = 3 − 쓴 힌트 수(최소 1). 재도전하면 더 좋은 값만 남긴다.
- 힌트 3개는 순서대로만 열린다. 챕터 3 이상에서 힌트 3 은 다음 정답 명령 한 줄을 그대로 보여 준다(`solution` 에서 아직 안 한 첫 줄).
- 힌트를 여는 경로는 `Rewards.unlockHint(missionId)` 함수 하나. 나중에 보상형 광고를 여기에만 붙인다.
- `android:allowBackup="false"`. 되살아나는 세이브 충돌을 설계하지 않는다.

## 7. 다국어

- `i18n/ko.json` 원본, `common/i18n/gen.py --to flutter --out lib/l10n`. `lib/strings.dart` 는 `common/flutter/strings.dart` 복사.
- 열쇠 규칙: 화면 공통 `btn_`·`inbox_`·`shell_`·`puzzle_`, 임무 글은 `m{c}_{n}_` 접두어 + `title`·`brief_k`·`hint_k`·`done_k`·`f_<파일>`·`p<k>_c<j>`(단서).
- 코드·명령·로그·비밀번호·파일 이름은 번역하지 않는다. 비밀번호는 모든 언어에서 영문·숫자만.
- `test/i18n_test.dart`: 모든 언어가 같은 열쇠를 가진다 + 임무 JSON 의 `@키` 가 전부 ko.json 에 있다.
- 릴리스 전 `python ../common/i18n/audit.py i18n/` 확정 0.

## 8. 검사 테스트 (기능을 만들기 전에 먼저)

`test/missions_test.dart` 가 `assets/missions/*.json` 전부에 대해:

1. JSON 이 모델로 읽힌다. `id` 가 파일 이름과 같다.
2. `solution` 을 엔진에 한 줄씩 넣으면 마지막에 `goal` 이 달성된다.
3. `input: chips` 임무의 `solution` 모든 줄이 그 시점의 `suggestions()` 칩만으로 만들어진다(한 줄 = 명령 칩 하나 + 인자 칩 0~2개, 비밀번호 줄은 제외).
4. `commands` 가 그 챕터까지 등장한 명령만 포함한다(4절 표).
5. 퍼즐 `answer` 가 `data` 로 만들 수 있다(`password` 는 조각으로 조립 가능, `match` 는 인덱스 범위, `order` 는 순열, `codefix` 는 `choices` 안).
6. 힌트·대사·단서의 `@키` 가 ko.json 에 있다.
7. 힌트 3(챕터3+)이 가리키는 `solution` 줄이 존재한다.
8. 챕터 n 의 임무 수가 6이고 1~30 이 빠짐없이 있다.

이 테스트가 빨간불이면 릴리스하지 않는다. 임무를 추가·수정하는 사람은 이것만 돌리면 된다.

## 9. 광고·홍보·설정

- 완료 화면에 `common/flutter/ads/ad_banner.dart` 자리만. SDK 는 v1 에서 붙이지 않는다(인터넷 권한 0개 유지). 등록정보에 "광고 없음·무료" 를 쓰지 않는다.
- 「개발자의 다른 게임」: `common/promo/README.md` 대로 `legal/apps.json` 을 읽는 화면. 이것도 인터넷이 필요하므로 **광고와 같은 시점에** 붙인다. v1 에서는 메뉴 자리만.
- 설정: 언어(14개, 그 언어 글자로), 효과음 켜기/끄기. 효과음은 `common/flutter/sfx_low_latency.dart`.

## 10. 보기·소리

- 어두운 터미널 테마 하나. 글꼴은 고정폭(JetBrains Mono, OFL, `assets/fonts/`). 강조색 초록·경고 주황.
- 러시아어(가장 김)·태국어(줄바꿈) 로 칩·상단 바가 넘치지 않는지 스크린샷으로 확인한다.
- 효과음: 키 입력, 실행, 성공, 실패, 잠금 해제 — 5개. `tool/gen_sfx.py`(삐약푸시 것 복사) 로 합성.

## 11. 스토리와 30임무

플레이어는 복구·보안 점검 프리랜서. 의뢰인 **고스트** 가 메시지로 일을 준다. 실제 공격은 없고, 잃어버린 접근 권한 되찾기·점검·버그 수리가 전부다.

| 챕터 | 제목 | 입력 | 새 명령 | 임무 1~6 핵심 |
|---|---|---|---|---|
| 1 | 첫 접속 (분실 계정 복구) | 칩 | scan connect open decode back | ① scan→connect→open ② decode 암호 메모 ③ match 로 잠금 ④ password 단서 카드 ⑤ order 부팅 순서 ⑥ 서버 2대, ③④⑤ 섞기 |
| 2 | 진짜 명령 (소상공인 서버 점검) | 칩 | ls cd pwd cat grep | ① ls/cat ② cd 깊은 폴더 ③ grep 로그 ④ ls -a 숨김 파일 ⑤ grep + password ⑥ 서버 3대, 찾은 비밀번호로 connect |
| 3 | 키보드 열림 (기업 내부 감사) | 키보드 | find ssh head tail pipe history | ① 자동완성 튜토리얼 ② find ③ cat \| grep ④ ssh 계정 맞추기 ⑤ history 단서 ⑥ 서버 4대 전부 섞기 |
| 4 | 코드 속으로 (멈춘 서비스 살리기) | 키보드 | git log git diff env crontab fix run | ① codefix 비교 연산자 ② 루프 범위 ③ git log 로 범인 커밋 → diff ④ env 오타 ⑤ crontab 스크립트 ⑥ 로그→코드→fix→run |
| 5 | 최종 작전 | 키보드 | (없음, 전부) | ①~⑤ 앞 챕터 기법 둘씩 섞은 긴 임무 ⑥ 앞 챕터 단서 파일 네 개를 모아야 열리는 최종 서버 |

임무 길이 목표: 챕터1 2~3분, 챕터5 8~10분. 전체 2~3시간.

## 12. 코드 배치

```
lib/
  main.dart                 앱 시작, 언어 로드, 테마
  strings.dart              common 복사
  l10n/                     gen.py 생성물. 손대지 않는다
  engine/
    mission.dart            JSON → 모델
    shell.dart              4절
    puzzles.dart            5절 판정 함수
    progress.dart           6절
    rewards.dart            unlockHint 하나
  ui/
    inbox_screen.dart  brief_screen.dart  mission_screen.dart  result_screen.dart
    terminal_view.dart  file_view.dart  input_bar.dart(칩+입력칸)
    puzzles/ match_puzzle.dart  password_puzzle.dart  order_puzzle.dart  codefix_puzzle.dart
    settings_screen.dart  promo_screen.dart(자리)
assets/missions/m1_01.json … m5_06.json
assets/fonts/  assets/sfx/
i18n/ko.json … th.json
test/ shell_test.dart  puzzles_test.dart  missions_test.dart  i18n_test.dart  progress_test.dart
tool/ gen_sfx.py  (삐약푸시 복사)
```

상태 관리는 `ValueNotifier`/`setState`. 패키지: `shared_preferences`, `audioplayers` 만. 내비게이션 라이브러리 없음.

## 13. 오류 처리

- 임무 JSON 깨짐 → 테스트에서 잡힌다. 런타임에서는 메시지함에서 그 임무를 비활성 표시(앱이 죽지 않는다).
- 세이브 읽기 실패 → 빈 진행으로 시작, 덮어쓰지 않고 다음 저장 때 쓴다.
- 언어 파일 열쇠 누락 → `S.t` 가 영어 → 열쇠 이름 순으로 폴백(common strings.dart 동작).

## 14. 테스트 전략

- 엔진(셸·퍼즐 판정·진행)은 전부 순수 Dart 단위 테스트. 각 명령의 정상·오류 경로 하나씩.
- `missions_test.dart` = 콘텐츠 검사(8절). 임무가 늘 때마다 자동으로 포함.
- 위젯 테스트는 입력 바(칩 누르면 입력칸에 들어가는지, `chips` 모드에서 편집 불가)만.
- 실기기: 챕터마다 임무 1개를 끝까지 플레이 + 모든 화면 스크린샷(ko·ru·th). "빌드 통과 ≠ 동작" 규칙.

## 15. 빌드·환경

- Windows 한글 경로 함정: `common/traps/04-windows-build.md` 대로 `android-sdk-ascii`·`gradle-home-ascii` 사용.
- 릴리스: `common/traps/02-android-release.md`, 서명은 `_서명키_백업` 의 기존 키 체계.
