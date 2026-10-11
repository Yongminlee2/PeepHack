# HackQuest 2부 구현 계획 — 챕터 2~5 콘텐츠 · 번역 · 소리 · 출시 준비


**Goal:** 1부에서 만든 엔진 위에 임무 24개(챕터 2~5)를 데이터로 얹고, 14개 언어·효과음·아이콘·서명 빌드까지 끝내 플레이 스토어에 올릴 수 있는 상태로 만든다.

**Architecture:** 코드 변경은 효과음 배선 한 곳뿐이다. 나머지는 전부 `assets/missions/*.json` 과 `i18n/*.json` 데이터이고, `flutter test` 의 `missions_test` 가 임무를 실제로 풀어 보고 `i18n_test` 가 번역 열쇠를 대조한다. 임무가 빨간불이면 임무 데이터를 고치지 엔진을 고치지 않는다(엔진 버그면 1부 테스트에 재현 테스트부터).

**Tech Stack:** 1부와 같다 + `audioplayers`(효과음), `common/i18n/TRANSLATION_PROMPT.md`·`audit.py`, `common/android/`·`common/checklists/play-release.md`.

**Spec:** `docs/specs/2026-10-11-hackquest-design.md`. 1부 계획: `2026-10-11-hackquest-part1-engine-ui-ch1.md` (엔진 API·JSON 형식·검사 규칙은 거기 있다. 이 문서는 1부가 끝났다고 가정한다).

## Global Constraints

- 임무 JSON 규칙(설계 3절): 챕터 2 는 `input: "chips"` 이고 정답 줄이 전부 칩으로 만들어져야 한다(검사 3번). 챕터 3+ 는 `keyboard`, 힌트는 2개(셋째는 정답 줄 자동).
- 새 명령은 그 챕터부터만(검사 4번): 챕터2 `ls cd pwd cat grep`, 챕터3 `find ssh head tail | history`, 챕터4 `git env crontab fix run`.
- 열쇠 접두어는 임무 id (`m2_03_…`). 문장은 `i18n/ko.json` 에만 손으로 쓰고, 나머지 13개 언어는 `TRANSLATION_PROMPT.md` 로 뽑아 `audit.py` 확정 0 이어야 한다.
- 비밀번호·호스트 이름·파일 이름·코드·로그는 영문·숫자. 번역 문장 안에 비밀번호 조각이 들어갈 때는 영문 그대로(예: "고양이 이름은 momo").
- 스토어 문구에 "광고 없음·무료·인앱결제 없음·개인정보 수집 안 함" 금지. 폰 설치는 사용자가 요청할 때만.
- 실제 공격 기법 없음. 전부 복구·점검·버그 수리 이야기.

## Review Focus

1. `grep`·`find` 정답 줄의 낱말이 **번역된 파일 안에** 있으면 언어에 따라 못 찾는다 → 정답 경로의 `grep`/`find` 대상은 반드시 영문 원문 파일(로그·코드)만. Task 1~4 의 임무마다 검사: `solution` 에 `grep X f` 가 있으면 `f` 의 내용이 `@` 가 아니어야 한다(`missions_test` 에 9번 검사로 추가, Task 1).
2. 챕터 2 칩 임무에서 `cd a/b` 처럼 두 단계 경로는 칩으로 못 만든다 → 정답은 `cd a`, `cd b` 두 줄로. 검사 3번이 잡는다.
3. 러시아어·태국어에서 칩·상단 바·퍼즐 카드가 넘침 → Task 7 스크린샷.
4. 효과음을 켠 채 칩을 연타해도 화면이 멈추지 않아야 한다(`LowLatencySfx`) → Task 5 실기기.
5. 릴리스 빌드에서만 안 나는 소리(assets 누락) → Task 5 에서 `pubspec` assets 확인 + Task 8 릴리스 APK 로 소리 확인.

---

### Task 1: 검사 9번 추가 + 챕터 2 임무 6개 (칩, 진짜 명령 입문)

**Files:**
- Modify: `test/missions_test.dart`(검사 9번), `i18n/ko.json`
- Create: `assets/missions/m2_01.json` … `m2_06.json`

- [ ] **Step 1: 검사 9번 — grep/find 대상은 원문 파일**

`missions_test.dart` 의 group 안에 추가:
```dart
      test('9. grep 정답 줄의 대상 파일은 번역되지 않은 원문이다', () {
        for (final step in m.solution.whereType<String>()) {
          final t = step.split(RegExp(r'\s+'));
          final gi = t.indexOf('grep');
          if (gi < 0) continue;
          // "grep W F" 또는 "cat F | grep W"
          final file = t.first == 'cat' ? t[1] : (t.length > gi + 2 ? t[gi + 2] : null);
          if (file == null) continue;
          for (final h in m.hosts.values) {
            final node = lookup(h.fs, file.startsWith('/') ? file : '/$file');
            if (node is FsFile) expect(node.text.startsWith('@'), isFalse, reason: '$step 의 대상이 번역 파일');
          }
        }
      });
```
(상대 경로는 루트 기준으로만 찾는다 — 못 찾으면 검사하지 않는다. 정답 줄의 grep 은 cwd 가 루트가 아닐 수 있으므로, 못 찾는 경우는 아래 임무 설계에서 대상 파일을 영문으로 두는 것으로 지킨다.)

- [ ] **Step 2: 임무 JSON**

`m2_01.json` — ls·cat 입문
```json
{"id":"m2_01","chapter":2,"title":"@m2_01_title","brief":["@m2_01_brief_1","@m2_01_brief_2"],"done":["@m2_01_done_1"],
 "input":"chips","commands":["scan","connect","ls","cat"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m2_01_f_readme"}},
  "shop":{"name":"shop-server","fs":{"menu.txt":"@m2_01_f_menu","prices.txt":"Americano 3000\nLatte 4000\nMocha 4500"}}},
 "start":"home","puzzles":[],
 "goal":{"read":"shop:/menu.txt"},
 "hints":["@m2_01_hint_1","@m2_01_hint_2","@m2_01_hint_3"],
 "solution":["scan","connect shop-server","ls","cat menu.txt"]}
```

`m2_02.json` — cd 로 깊은 폴더
```json
{"id":"m2_02","chapter":2,"title":"@m2_02_title","brief":["@m2_02_brief_1","@m2_02_brief_2"],"done":["@m2_02_done_1"],
 "input":"chips","commands":["scan","connect","ls","cd","pwd","cat"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m2_02_f_readme"}},
  "shop":{"name":"shop-server","fs":{
    "var/":{"log/":{"app.log":"2024-05-01 boot ok\n2024-05-02 boot ok"}},
    "home/":{"owner/":{"memo.txt":"@m2_02_f_memo"},"staff/":{"shift.txt":"Mon: Kim\nTue: Lee"}}}}},
 "start":"home","puzzles":[],
 "goal":{"read":"shop:/home/owner/memo.txt"},
 "hints":["@m2_02_hint_1","@m2_02_hint_2","@m2_02_hint_3"],
 "solution":["scan","connect shop-server","ls","cd home","ls","cd owner","cat memo.txt"]}
```

`m2_03.json` — grep 으로 로그에서 비밀번호
```json
{"id":"m2_03","chapter":2,"title":"@m2_03_title","brief":["@m2_03_brief_1","@m2_03_brief_2"],"done":["@m2_03_done_1"],
 "input":"chips","commands":["scan","connect","ls","cd","cat","grep"],"words":["ERROR","admin"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m2_03_f_readme"}},
  "shop":{"name":"shop-server","fs":{"var/":{"log/":{"app.log":"2024-05-01 10:00 INFO boot\n2024-05-01 10:05 INFO order #1\n2024-05-01 11:20 ERROR login failed user=admin pw=latte2024 (typed on wrong screen)\n2024-05-01 11:21 INFO login ok user=admin\n2024-05-01 12:00 INFO order #2\n2024-05-01 13:00 INFO order #3"}}}},
  "pos":{"name":"pos-terminal","lock":{"type":"password","answer":"latte2024"},"fs":{"report.txt":"@m2_03_f_report"}}},
 "start":"home","puzzles":[],
 "goal":{"read":"pos:/report.txt"},
 "hints":["@m2_03_hint_1","@m2_03_hint_2","@m2_03_hint_3"],
 "solution":["scan","connect shop-server","cd var","cd log","grep ERROR app.log","connect pos-terminal","latte2024","cat report.txt"]}
```

`m2_04.json` — 숨은 파일
```json
{"id":"m2_04","chapter":2,"title":"@m2_04_title","brief":["@m2_04_brief_1","@m2_04_brief_2"],"done":["@m2_04_done_1"],
 "input":"chips","commands":["scan","connect","ls","cat"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m2_04_f_readme"}},
  "shop":{"name":"shop-server","fs":{"public.txt":"@m2_04_f_public",".secret.txt":"@m2_04_f_secret","menu.txt":"Americano 3000"}}},
 "start":"home","puzzles":[],
 "goal":{"read":"shop:/.secret.txt"},
 "hints":["@m2_04_hint_1","@m2_04_hint_2","@m2_04_hint_3"],
 "solution":["scan","connect shop-server","ls","ls -a","cat .secret.txt"]}
```

`m2_05.json` — 직원 메모 → 조립 비밀번호
```json
{"id":"m2_05","chapter":2,"title":"@m2_05_title","brief":["@m2_05_brief_1","@m2_05_brief_2"],"done":["@m2_05_done_1"],
 "input":"chips","commands":["scan","connect","ls","cd","cat"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m2_05_f_readme"}},
  "shop":{"name":"shop-server","fs":{"staff/":{"notes.txt":"@m2_05_f_notes","shift.txt":"Mon: Kim"},"old/":{"junk.txt":"nothing here"}}},
  "nas":{"name":"backup-nas","lock":{"type":"puzzle","puzzle":"p1"},"fs":{"photos.txt":"@m2_05_f_photos"}}},
 "start":"home",
 "puzzles":[{"id":"p1","type":"password","data":{"clues":["@m2_05_p1_c1","@m2_05_p1_c2"],"fragments":["bori","2021","choco","2020","7"]},"answer":"bori2021"}],
 "goal":{"read":"nas:/photos.txt"},
 "hints":["@m2_05_hint_1","@m2_05_hint_2","@m2_05_hint_3"],
 "solution":["scan","connect shop-server","cd staff","cat notes.txt","connect backup-nas",{"puzzle":"p1"},"cat photos.txt"]}
```

`m2_06.json` — 보스: 서버 세 대
```json
{"id":"m2_06","chapter":2,"title":"@m2_06_title","brief":["@m2_06_brief_1","@m2_06_brief_2","@m2_06_brief_3"],"done":["@m2_06_done_1","@m2_06_done_2"],
 "input":"chips","commands":["scan","connect","ls","cd","cat","grep","back"],"words":["owner","ERROR"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m2_06_f_readme"}},
  "shop":{"name":"shop-server","fs":{"var/":{"log/":{"access.log":"GET / from 10.0.0.4\nGET /menu from 10.0.0.5\nPOST /login from 10.0.0.9 user=owner pw=mocha99\nGET /admin from 10.0.0.9 user=owner\nGET / from 10.0.0.6"}}}},
  "office":{"name":"office-pc","lock":{"type":"password","answer":"mocha99"},"fs":{"desk/":{"keys.txt":"@m2_06_f_keys"},"photos/":{"cat.txt":"meow"}}},
  "archive":{"name":"archive-box","lock":{"type":"puzzle","puzzle":"p1"},"fs":{"ledger.txt":"@m2_06_f_ledger"}}},
 "start":"home",
 "puzzles":[{"id":"p1","type":"match","data":{"left":["USB","HDMI","LAN","PWR"],"right":["monitor","12V","keyboard","switch"]},"answer":[[0,2],[1,0],[2,3],[3,1]]}],
 "goal":{"all":[{"read":"archive:/ledger.txt"},{"puzzle":"p1"}]},
 "hints":["@m2_06_hint_1","@m2_06_hint_2","@m2_06_hint_3"],
 "solution":["scan","connect shop-server","cd var","cd log","grep owner access.log","connect office-pc","mocha99","cd desk","cat keys.txt","connect archive-box",{"puzzle":"p1"},"cat ledger.txt"]}
```

- [ ] **Step 3: 문장 (ko.json)**

```json
  "m2_01_title": "진짜 명령어",
  "m2_01_brief_1": "장난감은 끝. 이제부터는 진짜 서버에서 쓰는 명령이다. ls 는 폴더 안을 보여 주고 cat 은 파일을 읽는다.",
  "m2_01_brief_2": "동네 카페 서버에서 메뉴 파일을 읽어 와. open 대신 cat 이다.",
  "m2_01_done_1": "ls 와 cat, 이 둘이면 세상 파일의 절반은 읽는다.",
  "m2_01_f_readme": "카페 사장님 의뢰. 서버 점검 전에 메뉴 파일부터 확인.",
  "m2_01_f_menu": "오늘의 메뉴: 아메리카노, 라떼, 모카. 점검 끝나면 라떼 한 잔 쏜대요.",
  "m2_01_hint_1": "connect 로 들어간 뒤 ls 를 눌러 파일 이름을 보세요.",
  "m2_01_hint_2": "cat 을 누르고 파일 이름 칩을 이어서 누르세요.",
  "m2_01_hint_3": "cat menu.txt",
  "m2_02_title": "깊은 폴더",
  "m2_02_brief_1": "사장님 메모가 서버 어딘가 깊은 폴더에 있어. cd 로 폴더에 들어가고, 길을 잃으면 pwd 로 지금 어디인지 봐.",
  "m2_02_brief_2": "사람 이름 폴더는 보통 home 아래에 있지.",
  "m2_02_done_1": "폴더는 상자 속 상자다. cd 로 들어가고 cd .. 로 나온다. 몸에 익혀 둬.",
  "m2_02_f_readme": "메모 위치: 사장님 개인 폴더 어딘가.",
  "m2_02_f_memo": "사장님 메모: 다음 달 원두 거래처 바꾸기. 비밀번호 수첩은 금고에.",
  "m2_02_hint_1": "ls 로 폴더 목록을 보고 cd 로 home 에 들어가세요.",
  "m2_02_hint_2": "home 안에 owner 폴더가 있습니다. 거기서 ls.",
  "m2_02_hint_3": "cd home → cd owner → cat memo.txt",
  "m2_03_title": "로그에서 찾기",
  "m2_03_brief_1": "포스기가 잠겼는데 비밀번호를 아무도 몰라. 그런데 누가 로그인 화면이 아니라 엉뚱한 칸에 비밀번호를 친 적이 있대.",
  "m2_03_brief_2": "그런 실수는 로그에 ERROR 로 남아. grep 은 파일에서 그 낱말이 있는 줄만 골라 보여 준다. 로그는 var/log 아래.",
  "m2_03_done_1": "로그는 거짓말을 안 한다. grep 하나로 수천 줄에서 한 줄을 뽑았군.",
  "m2_03_f_readme": "포스기 비밀번호는 shop-server 로그 어딘가에 남아 있을 것.",
  "m2_03_f_report": "일일 매출 보고: 정상. 포스기 비밀번호는 오늘 바꿀 것.",
  "m2_03_hint_1": "shop-server 에서 cd var, cd log 로 들어가세요.",
  "m2_03_hint_2": "grep ERROR app.log 를 치면 실수한 줄이 보입니다.",
  "m2_03_hint_3": "pw= 뒤의 글자가 pos-terminal 비밀번호입니다.",
  "m2_04_title": "숨은 파일",
  "m2_04_brief_1": "사장님이 서버에 중요한 메모를 숨겨 뒀는데, 어디 숨겼는지 본인도 잊었대.",
  "m2_04_brief_2": "이름이 점(.)으로 시작하는 파일은 ls 에 안 나온다. ls -a 를 쓰면 전부 보인다.",
  "m2_04_done_1": "숨긴 파일도 결국 파일이다. -a 하나면 다 보인다.",
  "m2_04_f_readme": "숨긴 메모 찾기. 점으로 시작하는 파일을 찾아볼 것.",
  "m2_04_f_public": "공개 안내: 영업시간 9시~21시.",
  "m2_04_f_secret": "숨긴 메모: 금고 비밀번호 수첩은 두 번째 서랍. 아무한테도 말하지 말 것.",
  "m2_04_hint_1": "ls 로는 안 보입니다. ls 에 -a 칩을 붙여 보세요.",
  "m2_04_hint_2": "점으로 시작하는 파일 이름이 나타납니다.",
  "m2_04_hint_3": "cat .secret.txt",
  "m2_05_title": "직원 메모",
  "m2_05_brief_1": "백업 NAS 가 잠겼어. 점장이 비밀번호를 만들었는데 퇴사했대. 다행히 직원 폴더에 메모를 남겼다는군.",
  "m2_05_brief_2": "사람은 늘 같은 방식으로 비밀번호를 만든다. 메모를 읽고 조립해 봐.",
  "m2_05_done_1": "강아지 이름에 태어난 해. 전국의 비밀번호 절반이 이렇다.",
  "m2_05_f_readme": "backup-nas 비밀번호 단서: shop-server 의 직원 폴더.",
  "m2_05_f_notes": "점장 메모: NAS 비밀번호는 우리 강아지 보리(bori) 이름에 보리가 태어난 해 2021 을 붙였음.",
  "m2_05_f_photos": "백업 사진 2,300장 복구 완료.",
  "m2_05_p1_c1": "강아지 이름은 소문자 영어로.",
  "m2_05_p1_c2": "그 뒤에 태어난 해 네 자리.",
  "m2_05_hint_1": "shop-server 의 staff 폴더에 notes.txt 가 있습니다.",
  "m2_05_hint_2": "connect backup-nas 를 하면 조립 퍼즐이 뜹니다.",
  "m2_05_hint_3": "bori 다음 2021.",
  "m2_06_title": "서버 세 대",
  "m2_06_brief_1": "챕터 마지막 의뢰다. 사장님이 장부 서버 비밀번호도, 사무실 PC 비밀번호도 전부 잊었어.",
  "m2_06_brief_2": "사무실 PC 비밀번호는 서버 접속 로그에 남아 있을 거고, 장부 서버는 사무실 PC 의 배선 메모로 연다.",
  "m2_06_brief_3": "서버 세 대를 오가야 해. 배운 것 전부다.",
  "m2_06_done_1": "장부 복구 완료. 사장님이 라떼 평생 무료권을 주겠대.",
  "m2_06_done_2": "다음 챕터부터 키보드가 열린다. 진짜 터미널처럼 직접 친다.",
  "m2_06_f_readme": "순서: shop-server 로그 → office-pc → archive-box.",
  "m2_06_f_keys": "장부 서버 배선: USB 에 keyboard, HDMI 에 monitor, LAN 에 switch, PWR 에 12V.",
  "m2_06_f_ledger": "장부: 5월 매출 정상. 전부 무사.",
  "m2_06_hint_1": "shop-server 의 var/log/access.log 에서 grep owner.",
  "m2_06_hint_2": "office-pc 에 들어가면 desk/keys.txt 에 배선 짝이 있습니다.",
  "m2_06_hint_3": "USB→keyboard, HDMI→monitor, LAN→switch, PWR→12V. 그 다음 cat ledger.txt.",
```

- [ ] **Step 4: 확인 · 커밋**

`python ..\common\i18n\gen.py i18n --to flutter --out lib\l10n` 후 `flutter test`. `i18n_test` 는 en 에 열쇠가 없어 빨간불이 난다 — **이 Task 에서는 en.json 에 같은 열쇠를 영어로 넣어 통과시킨다**(다른 12개 언어는 Task 6). `git add -A; git commit -m "챕터2 임무 6개: 진짜 명령 입문"`.

---

### Task 2: 챕터 3 임무 6개 (키보드 열림: find · ssh · 파이프 · history)

**Files:**
- Create: `assets/missions/m3_01.json` … `m3_06.json`
- Modify: `i18n/ko.json`, `i18n/en.json`

챕터 3부터 `input: "keyboard"`, 힌트 2개. 칩은 여전히 나오지만 정답 줄이 칩만으로 만들어질 필요는 없다.

- [ ] **Step 1: 임무 JSON**

`m3_01.json` — 키보드 튜토리얼: 절대 경로로 cat
```json
{"id":"m3_01","chapter":3,"title":"@m3_01_title","brief":["@m3_01_brief_1","@m3_01_brief_2"],"done":["@m3_01_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cd","cat","find"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m3_01_f_readme"}},
  "corp":{"name":"corp-fs","fs":{"projects/":{"alpha/":{"spec.md":"alpha spec v1"},"beta/":{"notes.md":"@m3_01_f_notes"}},"hr/":{"list.csv":"id,name\n1,Kim\n2,Lee"}}}},
 "start":"home","puzzles":[],
 "goal":{"read":"corp:/projects/beta/notes.md"},
 "hints":["@m3_01_hint_1","@m3_01_hint_2"],
 "solution":["scan","connect corp-fs","find notes","cat /projects/beta/notes.md"]}
```

`m3_02.json` — find 로 이름 일부 검색
```json
{"id":"m3_02","chapter":3,"title":"@m3_02_title","brief":["@m3_02_brief_1","@m3_02_brief_2"],"done":["@m3_02_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cd","cat","find"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m3_02_f_readme"}},
  "corp":{"name":"corp-fs","fs":{
    "finance/":{"q1/":{"report.txt":"Q1 ok"},"q2/":{"report.txt":"Q2 ok"},"q3/":{"budget_final.txt":"@m3_02_f_budget","draft.txt":"old draft"}},
    "legal/":{"nda.txt":"confidential"},"tmp/":{"x.txt":"x"}}}},
 "start":"home","puzzles":[],
 "goal":{"read":"corp:/finance/q3/budget_final.txt"},
 "hints":["@m3_02_hint_1","@m3_02_hint_2"],
 "solution":["scan","connect corp-fs","find budget","cat /finance/q3/budget_final.txt"]}
```

`m3_03.json` — 파이프로 로그에서 토큰
```json
{"id":"m3_03","chapter":3,"title":"@m3_03_title","brief":["@m3_03_brief_1","@m3_03_brief_2"],"done":["@m3_03_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cd","cat","grep","|","head","tail"],"words":["token","FAILED"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m3_03_f_readme"}},
  "corp":{"name":"corp-fs","fs":{"logs/":{"auth.log":"09:00 login ok user=kim\n09:02 FAILED login user=jkim from 203.0.113.7\n09:03 FAILED login user=jkim from 203.0.113.7\n09:05 password reset token=river77 for user=jkim\n09:06 login ok user=jkim\n09:10 login ok user=lee\n09:20 FAILED login user=park\n09:30 login ok user=park"}}},
  "jkim":{"name":"jkim-laptop","lock":{"type":"password","answer":"river77"},"fs":{"findings.txt":"@m3_03_f_findings"}}},
 "start":"home","puzzles":[],
 "goal":{"read":"jkim:/findings.txt"},
 "hints":["@m3_03_hint_1","@m3_03_hint_2"],
 "solution":["scan","connect corp-fs","cat logs/auth.log | grep token","connect jkim-laptop","river77","cat findings.txt"]}
```

`m3_04.json` — ssh 계정 맞추기
```json
{"id":"m3_04","chapter":3,"title":"@m3_04_title","brief":["@m3_04_brief_1","@m3_04_brief_2"],"done":["@m3_04_done_1"],
 "input":"keyboard","commands":["scan","connect","ssh","ls","cat","find"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m3_04_f_readme"}},
  "corp":{"name":"corp-fs","fs":{"staff.txt":"db-server admin account: dba\nweb-server admin account: www\nmail-server admin account: postmaster"}},
  "db":{"name":"db-server","user":"dba","fs":{"dump.txt":"@m3_04_f_dump"}}},
 "start":"home","puzzles":[],
 "goal":{"read":"db:/dump.txt"},
 "hints":["@m3_04_hint_1","@m3_04_hint_2"],
 "solution":["scan","connect corp-fs","cat staff.txt","ssh dba@db-server","cat dump.txt"]}
```

`m3_05.json` — history 에 남은 길
```json
{"id":"m3_05","chapter":3,"title":"@m3_05_title","brief":["@m3_05_brief_1","@m3_05_brief_2"],"done":["@m3_05_done_1"],
 "input":"keyboard","commands":["scan","connect","ssh","ls","cd","cat","history"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m3_05_f_readme"}},
  "corp":{"name":"corp-fs","fs":{".bash_history":"ls\ncat /etc/motd\nssh ops@backup-01\nscp secret.tar ops@backup-01:/tmp/","notes.txt":"nothing here"}},
  "backup":{"name":"backup-01","user":"ops","fs":{"tmp/":{"secret.tar.txt":"@m3_05_f_secret"},"etc/":{"motd":"welcome"}}}},
 "start":"home","puzzles":[],
 "goal":{"read":"backup:/tmp/secret.tar.txt"},
 "hints":["@m3_05_hint_1","@m3_05_hint_2"],
 "solution":["scan","connect corp-fs","history","ssh ops@backup-01","cat /tmp/secret.tar.txt"]}
```

`m3_06.json` — 보스: 서버 네 대
```json
{"id":"m3_06","chapter":3,"title":"@m3_06_title","brief":["@m3_06_brief_1","@m3_06_brief_2","@m3_06_brief_3"],"done":["@m3_06_done_1","@m3_06_done_2"],
 "input":"keyboard","commands":["scan","connect","ssh","ls","cd","cat","grep","|","history","find"],"words":["ceo","hint"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m3_06_f_readme"}},
  "corp":{"name":"corp-fs","fs":{".bash_history":"ssh audit@hr-box\nexit","readme.txt":"corp file server"}},
  "hr":{"name":"hr-box","user":"audit","fs":{"payroll/":{"notes.txt":"@m3_06_f_notes","orders.log":"order#10 user=kim item=americano\norder#11 user=lee item=latte\norder#12 user=ceo item=caramel-macchiato\norder#13 user=park item=mocha\norder#14 user=ceo item=caramel-macchiato"}}},
  "vault":{"name":"vault-01","lock":{"type":"puzzle","puzzle":"p1"},"fs":{"evidence.txt":"@m3_06_f_evidence","map.txt":"@m3_06_f_map"}},
  "archive":{"name":"archive-02","lock":{"type":"puzzle","puzzle":"p2"},"fs":{"final.txt":"@m3_06_f_final"}}},
 "start":"home",
 "puzzles":[
  {"id":"p1","type":"password","data":{"clues":["@m3_06_p1_c1","@m3_06_p1_c2"],"fragments":["caramel","macchiato","12","latte","7"]},"answer":"caramelmacchiato12"},
  {"id":"p2","type":"match","data":{"left":["north","east","south","west"],"right":["sea","mountain","city","forest"]},"answer":[[0,1],[1,0],[2,2],[3,3]]}],
 "goal":{"all":[{"read":"archive:/final.txt"},{"puzzle":"p1"},{"puzzle":"p2"}]},
 "hints":["@m3_06_hint_1","@m3_06_hint_2"],
 "solution":["scan","connect corp-fs","history","ssh audit@hr-box","cd payroll","cat notes.txt","cat orders.log | grep ceo","connect vault-01",{"puzzle":"p1"},"cat map.txt","connect archive-02",{"puzzle":"p2"},"cat final.txt"]}
```

- [ ] **Step 2: 문장 (ko.json)**

```json
  "m3_01_title": "키보드가 열렸다",
  "m3_01_brief_1": "이제부터 직접 친다. 칩은 그대로 쓸 수 있지만, 경로를 통째로 쳐 넣는 게 훨씬 빠르다.",
  "m3_01_brief_2": "find 는 이름 일부로 파일을 찾아 전체 경로를 알려 준다. 그 경로를 cat 뒤에 그대로 치면 된다.",
  "m3_01_done_1": "경로를 손으로 친 순간부터 넌 터미널 사용자다.",
  "m3_01_f_readme": "회사 파일 서버 감사 시작. beta 프로젝트 노트부터.",
  "m3_01_f_notes": "beta 프로젝트 노트: 일정 2주 지연. 사유는 감사 보고서에.",
  "m3_01_hint_1": "find notes 를 치면 전체 경로가 나옵니다.",
  "m3_01_hint_2": "cat 뒤에 그 경로를 /부터 전부 치세요.",
  "m3_02_title": "이름 일부로 찾기",
  "m3_02_brief_1": "예산 파일이 어딘가 있는데 폴더가 수십 개야. 하나씩 열 시간은 없다.",
  "m3_02_brief_2": "파일 이름에 budget 이 들어간다는 것만 안다. find 에 그 조각만 주면 된다.",
  "m3_02_done_1": "폴더 열 개를 뒤지는 대신 명령 한 줄. 이게 터미널을 쓰는 이유다.",
  "m3_02_f_readme": "예산 최종본 찾기. 이름에 budget 포함.",
  "m3_02_f_budget": "3분기 예산 최종본: 승인됨.",
  "m3_02_hint_1": "find budget",
  "m3_02_hint_2": "나온 경로를 cat 으로 읽으세요.",
  "m3_03_title": "파이프",
  "m3_03_brief_1": "직원 노트북이 잠겼는데 그 직원은 휴가 중. 비밀번호 초기화 토큰이 인증 로그에 남아 있을 거다.",
  "m3_03_brief_2": "로그가 길다. cat 으로 읽은 걸 | 로 grep 에 넘기면 원하는 줄만 남는다: cat 파일 | grep 낱말",
  "m3_03_done_1": "파이프는 명령을 잇는 관이다. 왼쪽 결과가 오른쪽으로 흘러간다.",
  "m3_03_f_readme": "jkim-laptop 비밀번호: corp-fs 의 logs/auth.log 에 token 으로 남아 있음.",
  "m3_03_f_findings": "감사 메모: 외부 IP 에서 로그인 시도 2회. 계정 잠금 정책 권고.",
  "m3_03_hint_1": "cat logs/auth.log | grep token",
  "m3_03_hint_2": "token= 뒤의 글자가 jkim-laptop 비밀번호입니다.",
  "m3_04_title": "ssh 계정",
  "m3_04_brief_1": "ssh 는 계정@서버 로 접속한다. 계정이 틀리면 서버가 문을 안 열어 준다.",
  "m3_04_brief_2": "어느 서버에 어떤 관리자 계정이 있는지 파일 서버의 staff.txt 에 적혀 있다.",
  "m3_04_done_1": "계정 이름 하나 틀리면 아무것도 안 된다. 적힌 대로 쳐라.",
  "m3_04_f_readme": "db-server 덤프 확인. 계정은 corp-fs 의 staff.txt.",
  "m3_04_f_dump": "DB 덤프: 테이블 12개, 이상 없음.",
  "m3_04_hint_1": "corp-fs 의 staff.txt 에 db-server 계정 이름이 있습니다.",
  "m3_04_hint_2": "ssh dba@db-server",
  "m3_05_title": "남은 발자국",
  "m3_05_brief_1": "퇴사한 관리자가 어디에 뭘 옮겼는지 아무도 몰라. 하지만 터미널은 친 명령을 기억한다.",
  "m3_05_brief_2": "history 를 치면 그 서버에서 친 명령이 나온다. 그대로 따라가 봐.",
  "m3_05_done_1": "사람은 잊어도 history 는 안 잊는다.",
  "m3_05_f_readme": "옮겨진 파일 찾기. corp-fs 에서 history 부터.",
  "m3_05_f_secret": "이전 관리자의 인수인계 문서. 전부 복구됨.",
  "m3_05_hint_1": "corp-fs 에서 history 를 치면 ssh 명령이 보입니다.",
  "m3_05_hint_2": "그 ssh 명령을 그대로 치고, scp 가 보낸 경로를 cat 하세요.",
  "m3_06_title": "서버 네 대",
  "m3_06_brief_1": "내부 감사 마지막 건. 증거 파일이 금고 서버에 있고, 금고 비밀번호는 CEO 의 커피 주문과 관련 있다는군.",
  "m3_06_brief_2": "인사 서버 계정은 파일 서버 history 에, 주문 기록은 인사 서버 급여 폴더에. 금고 안에는 다음 서버로 가는 지도가 있다.",
  "m3_06_brief_3": "서버 네 대. 배운 것 전부를 쓴다.",
  "m3_06_done_1": "증거 확보. 감사 보고서는 네 이름으로 나간다.",
  "m3_06_done_2": "다음 챕터는 코드다. 읽고, 고치고, 돌린다.",
  "m3_06_f_readme": "순서: corp-fs history → hr-box → vault-01 → archive-02.",
  "m3_06_f_notes": "금고 비밀번호 힌트: CEO 가 늘 시키는 음료 이름(소문자, 빈칸·하이픈 없이) 뒤에 그 첫 주문 번호.",
  "m3_06_f_evidence": "증거: 급여 이중 지급 3건.",
  "m3_06_f_map": "archive-02 자물쇠: north 는 mountain, east 는 sea, south 는 city, west 는 forest.",
  "m3_06_f_final": "최종 보고서. 감사 완료.",
  "m3_06_p1_c1": "음료 이름을 소문자로, 빈칸과 하이픈 없이 이어 쓴다.",
  "m3_06_p1_c2": "그 뒤에 CEO 의 첫 주문 번호(숫자만).",
  "m3_06_hint_1": "hr-box 의 payroll/orders.log 를 grep ceo 로 보세요. 첫 주문 번호가 비밀번호 끝입니다.",
  "m3_06_hint_2": "vault-01 의 map.txt 가 archive-02 짝 잇기 정답입니다.",
```

- [ ] **Step 3: 확인 · 커밋** — en.json 도 채우고 `gen.py` 재생성 → `flutter test` 전부 PASS. `git add -A; git commit -m "챕터3 임무 6개: 키보드·find·ssh·파이프·history"`

---

### Task 3: 챕터 4 임무 6개 (코드 속으로: git · env · crontab · fix · run)

**Files:**
- Create: `assets/missions/m4_01.json` … `m4_06.json`
- Modify: `i18n/ko.json`, `i18n/en.json`

codefix 의 `answer` 는 문자열 `"bugs"` 로 두고 정답은 `data.bugs[].answer` 에 있다(1부 검사 테스트가 그렇게 읽는다). `lines` 의 버그 줄에는 **틀린 조각이 실제로 들어 있어야** 플레이어가 코드를 읽고 찾는다.

- [ ] **Step 1: 임무 JSON**

`m4_01.json` — 비교 연산자
```json
{"id":"m4_01","chapter":4,"title":"@m4_01_title","brief":["@m4_01_brief_1","@m4_01_brief_2"],"done":["@m4_01_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cat","fix","run"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m4_01_f_readme"}},
  "svc":{"name":"api-box","fs":{"check.py":"def can_enter(age):\n    if age > 18:\n        return True\n    return False\n\nassert can_enter(18), '18 should enter'\nprint('OK: 18 enters')"}}},
 "start":"home",
 "puzzles":[{"id":"c1","type":"codefix","file":"svc:/check.py",
   "data":{"lang":"python","lines":["def can_enter(age):","    if age > 18:","        return True","    return False","","assert can_enter(18), '18 should enter'","print('OK: 18 enters')"],
           "bugs":[{"line":1,"choices":[">",">=","=="],"answer":">="}],
           "failOutput":"AssertionError: 18 should enter","okOutput":"OK: 18 enters"},
   "answer":"bugs"}],
 "goal":{"run":"svc:/check.py"},
 "hints":["@m4_01_hint_1","@m4_01_hint_2"],
 "solution":["scan","connect api-box","run check.py","cat check.py","fix check.py",{"puzzle":"c1"},"run check.py"]}
```

`m4_02.json` — 루프 범위
```json
{"id":"m4_02","chapter":4,"title":"@m4_02_title","brief":["@m4_02_brief_1","@m4_02_brief_2"],"done":["@m4_02_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cat","fix","run"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m4_02_f_readme"}},
  "svc":{"name":"api-box","fs":{"total.py":"total = 0\nfor i in range(1, 10):\n    total += i\nassert total == 55, total\nprint('sum ok:', total)"}}},
 "start":"home",
 "puzzles":[{"id":"c1","type":"codefix","file":"svc:/total.py",
   "data":{"lang":"python","lines":["total = 0","for i in range(1, 10):","    total += i","assert total == 55, total","print('sum ok:', total)"],
           "bugs":[{"line":1,"choices":["range(1, 10)","range(1, 11)","range(0, 10)"],"answer":"range(1, 11)"}],
           "failOutput":"AssertionError: 45","okOutput":"sum ok: 55"},
   "answer":"bugs"}],
 "goal":{"run":"svc:/total.py"},
 "hints":["@m4_02_hint_1","@m4_02_hint_2"],
 "solution":["scan","connect api-box","run total.py","fix total.py",{"puzzle":"c1"},"run total.py"]}
```

`m4_03.json` — 범인 커밋
```json
{"id":"m4_03","chapter":4,"title":"@m4_03_title","brief":["@m4_03_brief_1","@m4_03_brief_2"],"done":["@m4_03_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cat","git","fix","run"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m4_03_f_readme"}},
  "repo":{"name":"repo-box",
    "git":[{"hash":"c3d4","message":"add retry","diff":"+retries = 3"},{"hash":"a1b2","message":"tune timeout","diff":"-timeout = 30\n+timeout = 3"},{"hash":"9f8e","message":"initial","diff":"+connect(timeout, retries)"}],
    "fs":{"client.py":"timeout = 3\nretries = 3\nconnect(timeout, retries)"}}},
 "start":"home",
 "puzzles":[{"id":"c1","type":"codefix","file":"repo:/client.py",
   "data":{"lang":"python","lines":["timeout = 3","retries = 3","connect(timeout, retries)"],
           "bugs":[{"line":0,"choices":["3","30","300"],"answer":"30"}],
           "failOutput":"TimeoutError: no response in 3s","okOutput":"connected"},
   "answer":"bugs"}],
 "goal":{"run":"repo:/client.py"},
 "hints":["@m4_03_hint_1","@m4_03_hint_2"],
 "solution":["scan","connect repo-box","git log","git diff a1b2","fix client.py",{"puzzle":"c1"},"run client.py"]}
```

`m4_04.json` — env 와 설정 오타
```json
{"id":"m4_04","chapter":4,"title":"@m4_04_title","brief":["@m4_04_brief_1","@m4_04_brief_2"],"done":["@m4_04_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cat","env","fix","run"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m4_04_f_readme"}},
  "web":{"name":"web-box","env":{"DB_HOST":"db.internal","DB_PORT":"5432","MODE":"prod"},
    "fs":{"config.py":"DB_HOST = 'db.internal'\nDB_PORT = 5342\nconnect(DB_HOST, DB_PORT)"}}},
 "start":"home",
 "puzzles":[{"id":"c1","type":"codefix","file":"web:/config.py",
   "data":{"lang":"python","lines":["DB_HOST = 'db.internal'","DB_PORT = 5342","connect(DB_HOST, DB_PORT)"],
           "bugs":[{"line":1,"choices":["5342","5432","3306"],"answer":"5432"}],
           "failOutput":"ConnectionRefused: db.internal:5342","okOutput":"db connected"},
   "answer":"bugs"}],
 "goal":{"run":"web:/config.py"},
 "hints":["@m4_04_hint_1","@m4_04_hint_2"],
 "solution":["scan","connect web-box","run config.py","env","fix config.py",{"puzzle":"c1"},"run config.py"]}
```

`m4_05.json` — crontab 과 스크립트
```json
{"id":"m4_05","chapter":4,"title":"@m4_05_title","brief":["@m4_05_brief_1","@m4_05_brief_2"],"done":["@m4_05_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cd","cat","crontab","fix","run"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m4_05_f_readme"}},
  "cron":{"name":"cron-box","cron":["0 3 * * * /opt/backup.sh","0 9 * * 1 /opt/report.sh"],
    "fs":{"opt/":{"backup.sh":"#!/bin/sh\ntar -czf /backup/today.tgz /dat\necho done","report.sh":"#!/bin/sh\necho weekly"},"data/":{"db.sqlite":"(binary)"}}}},
 "start":"home",
 "puzzles":[{"id":"c1","type":"codefix","file":"cron:/opt/backup.sh",
   "data":{"lang":"sh","lines":["#!/bin/sh","tar -czf /backup/today.tgz /dat","echo done"],
           "bugs":[{"line":1,"choices":["/dat","/data","/date"],"answer":"/data"}],
           "failOutput":"tar: /dat: No such file or directory","okOutput":"done"},
   "answer":"bugs"}],
 "goal":{"run":"cron:/opt/backup.sh"},
 "hints":["@m4_05_hint_1","@m4_05_hint_2"],
 "solution":["scan","connect cron-box","crontab -l","cd opt","run backup.sh","fix backup.sh",{"puzzle":"c1"},"run backup.sh"]}
```

`m4_06.json` — 보스: 로그 → 코드 → 수정 → 실행
```json
{"id":"m4_06","chapter":4,"title":"@m4_06_title","brief":["@m4_06_brief_1","@m4_06_brief_2","@m4_06_brief_3"],"done":["@m4_06_done_1","@m4_06_done_2"],
 "input":"keyboard","commands":["scan","connect","ls","cd","cat","grep","|","git","env","fix","run"],"words":["ERROR"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m4_06_f_readme"}},
  "prod":{"name":"prod-box",
    "git":[{"hash":"e5f6","message":"remove empty-list check","diff":"-    if not xs:\n-        return 0"},{"hash":"d4c3","message":"add avg","diff":"+def avg(xs):"}],
    "env":{"MODE":"prod"},
    "fs":{"var/":{"log/":{"app.log":"10:00 INFO start\n10:01 INFO request /stats\n10:01 ERROR ZeroDivisionError in app/stats.py line 3\n10:02 INFO request /\n10:03 ERROR ZeroDivisionError in app/stats.py line 3"}},
          "app/":{"stats.py":"def avg(xs):\n    total = sum(xs)\n    return total / len(xs)\n\nprint(avg([]))","main.py":"from stats import avg"}}}},
 "start":"home",
 "puzzles":[{"id":"c1","type":"codefix","file":"prod:/app/stats.py",
   "data":{"lang":"python","lines":["def avg(xs):","    total = sum(xs)","    return total / len(xs)","","print(avg([]))"],
           "bugs":[{"line":2,"choices":["total / len(xs)","total / max(len(xs), 1)","total * len(xs)"],"answer":"total / max(len(xs), 1)"}],
           "failOutput":"ZeroDivisionError: division by zero","okOutput":"0.0"},
   "answer":"bugs"}],
 "goal":{"run":"prod:/app/stats.py"},
 "hints":["@m4_06_hint_1","@m4_06_hint_2"],
 "solution":["scan","connect prod-box","cat var/log/app.log | grep ERROR","git log","git diff e5f6","cd app","fix stats.py",{"puzzle":"c1"},"run stats.py"]}
```

- [ ] **Step 2: 문장 (ko.json)**

```json
  "m4_01_title": "비교 연산자",
  "m4_01_brief_1": "멈춘 서비스를 살리는 일이다. 이번엔 코드를 읽는다. 겁먹지 마, 열 줄이다.",
  "m4_01_brief_2": "run 으로 돌려 보면 왜 죽는지 나온다. cat 으로 읽고, fix 로 틀린 줄을 고른 뒤, 다시 run.",
  "m4_01_done_1": "> 와 >= 의 차이로 18살이 문 앞에서 쫓겨났었군. 코드는 글자 하나로 뒤집힌다.",
  "m4_01_f_readme": "api-box 의 check.py 가 실패함. 18세가 입장 못 함.",
  "m4_01_hint_1": "run check.py 로 오류 메시지를 보고, cat check.py 로 조건문을 찾으세요.",
  "m4_01_hint_2": "'18이 들어가야 한다' 면 '크거나 같다' 입니다.",
  "m4_02_title": "루프 범위",
  "m4_02_brief_1": "1부터 10까지 더하면 55 인데 코드는 45 를 낸다. 하나가 빠진 거지.",
  "m4_02_brief_2": "파이썬의 range(a, b) 는 b 를 포함하지 않는다. 그게 함정이다.",
  "m4_02_done_1": "끝 숫자가 빠지는 실수는 모든 개발자가 한 번은 한다. 이제 너도 했다.",
  "m4_02_f_readme": "api-box 의 total.py 합계가 틀림.",
  "m4_02_hint_1": "range(1, 10) 은 1부터 9까지입니다.",
  "m4_02_hint_2": "10 까지 더하려면 range(1, 11).",
  "m4_03_title": "범인 커밋",
  "m4_03_brief_1": "어제까지 잘 되던 접속이 오늘 자꾸 끊긴대. 코드를 누가 바꿨는지 git log 로 보자.",
  "m4_03_brief_2": "git log 는 바뀐 기록 목록, git diff 해시 는 그 기록이 무엇을 바꿨는지다. 범인을 찾아 되돌려.",
  "m4_03_done_1": "30초를 3초로 줄인 커밋이 범인이었다. 기록이 있으면 범인은 늘 잡힌다.",
  "m4_03_f_readme": "repo-box 의 client.py 접속 타임아웃. 최근 변경 확인.",
  "m4_03_hint_1": "git log 로 목록을 보고, 수상한 커밋을 git diff 해시 로 보세요.",
  "m4_03_hint_2": "timeout 을 원래 값 30 으로 되돌리세요.",
  "m4_04_title": "설정 오타",
  "m4_04_brief_1": "웹 서버가 DB 에 못 붙는대. 서버의 환경 변수(env)에는 진짜 값이 있고, 설정 파일에는 누가 손으로 옮겨 적은 값이 있다.",
  "m4_04_brief_2": "env 로 진짜 값을 보고 config.py 와 비교해 봐. 숫자 하나가 다를 거다.",
  "m4_04_done_1": "5432 를 5342 로 적었군. 손으로 옮겨 적는 순간 오타는 생긴다.",
  "m4_04_f_readme": "web-box 가 DB 연결 실패. env 와 config.py 비교.",
  "m4_04_hint_1": "env 를 치면 DB_PORT 의 진짜 값이 나옵니다.",
  "m4_04_hint_2": "config.py 의 DB_PORT 를 env 값과 같게.",
  "m4_05_title": "새벽 3시의 백업",
  "m4_05_brief_1": "백업이 매일 새벽 3시에 돌아야 하는데 한 달째 비어 있대. crontab -l 로 예약 목록을 보고 그 스크립트를 열어 봐.",
  "m4_05_brief_2": "스크립트는 opt 폴더에. run 으로 직접 돌려 보면 왜 실패하는지 나온다.",
  "m4_05_done_1": "/data 를 /dat 로 적어서 한 달 동안 빈 백업을 만들었군. 백업은 돌아가는지가 아니라 복구되는지 봐야 한다.",
  "m4_05_f_readme": "cron-box 백업이 비어 있음. crontab 부터.",
  "m4_05_hint_1": "crontab -l 로 스크립트 경로를 보고 cd opt 에서 run backup.sh.",
  "m4_05_hint_2": "tar 가 찾는 폴더 이름이 틀렸습니다. /data 로.",
  "m4_06_title": "로그에서 코드까지",
  "m4_06_brief_1": "통계 페이지가 죽는다. 로그 → 범인 코드 → 왜 그런지 git → 고치고 → 돌린다. 지금까지 배운 전부다.",
  "m4_06_brief_2": "로그에서 ERROR 줄을 찾으면 파일과 줄 번호가 나온다. git log 에 누가 뭘 지웠는지 있을 거다.",
  "m4_06_brief_3": "빈 목록의 평균을 구하면 0으로 나누게 된다. 그걸 막아야 한다.",
  "m4_06_done_1": "빈 목록 검사를 지운 커밋이 범인. 네가 다시 막았다.",
  "m4_06_done_2": "마지막 챕터다. 지금까지 배운 걸 전부 섞는다.",
  "m4_06_f_readme": "prod-box /stats 500 오류. 로그 → git → fix.",
  "m4_06_hint_1": "cat var/log/app.log | grep ERROR 로 파일과 줄 번호를, git diff e5f6 로 지워진 검사를 보세요.",
  "m4_06_hint_2": "len(xs) 가 0 이면 안 되니 max(len(xs), 1) 로.",
```

- [ ] **Step 3: 확인 · 커밋** — en.json 채우고 `gen.py` → `flutter test` PASS. `git add -A; git commit -m "챕터4 임무 6개: 코드 읽기·git·env·crontab·fix·run"`

---

### Task 4: 챕터 5 임무 6개 (최종 작전: 전부 섞기)

**Files:**
- Create: `assets/missions/m5_01.json` … `m5_06.json`
- Modify: `i18n/ko.json`, `i18n/en.json`, `test/missions_test.dart`(30개 전수 확인)

- [ ] **Step 1: 검사 8번을 30개 전수로 강화**

`missions_test.dart` 8번 테스트 끝에 추가:
```dart
    expect(missions.length, 30, reason: '챕터 5 × 임무 6');
```

- [ ] **Step 2: 임무 JSON**

`m5_01.json` — decode + 파이프 + 비밀번호 두 번
```json
{"id":"m5_01","chapter":5,"title":"@m5_01_title","brief":["@m5_01_brief_1","@m5_01_brief_2"],"done":["@m5_01_done_1"],
 "input":"keyboard","commands":["scan","connect","open","decode","ls","cd","cat","grep","|"],"words":["token"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m5_01_f_readme","key.txt":{"text":"mfwgtw9","encode":"caesar:5"}}},
  "relay":{"name":"relay-box","lock":{"type":"password","answer":"harbor9"},"fs":{"logs/":{"net.log":"00:01 link up\n00:02 handshake gate-01\n00:03 token=north42 for gate-01\n00:04 link idle"}}},
  "gate":{"name":"gate-01","lock":{"type":"password","answer":"north42"},"fs":{"report.txt":"@m5_01_f_report"}}},
 "start":"home","puzzles":[],
 "goal":{"read":"gate:/report.txt"},
 "hints":["@m5_01_hint_1","@m5_01_hint_2"],
 "solution":["decode key.txt","scan","connect relay-box","harbor9","cat logs/net.log | grep token","connect gate-01","north42","cat report.txt"]}
```

`m5_02.json` — history + ssh + 순서 퍼즐
```json
{"id":"m5_02","chapter":5,"title":"@m5_02_title","brief":["@m5_02_brief_1","@m5_02_brief_2"],"done":["@m5_02_done_1"],
 "input":"keyboard","commands":["scan","connect","ssh","ls","cat","history"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m5_02_f_readme"}},
  "corp":{"name":"corp-fs","fs":{".bash_history":"cat runbook.md\nssh deploy@build-01","runbook.md":"@m5_02_f_runbook"}},
  "build":{"name":"build-01","user":"deploy","lock":{"type":"puzzle","puzzle":"p1"},"fs":{"release.txt":"@m5_02_f_release"}}},
 "start":"home",
 "puzzles":[{"id":"p1","type":"order","data":{"items":["Push image","Run tests","Restart service","Build image"]},"answer":[1,3,0,2]}],
 "goal":{"read":"build:/release.txt"},
 "hints":["@m5_02_hint_1","@m5_02_hint_2"],
 "solution":["scan","connect corp-fs","cat runbook.md","history","ssh deploy@build-01",{"puzzle":"p1"},"cat release.txt"]}
```

`m5_03.json` — git diff 가 짝 잇기 정답
```json
{"id":"m5_03","chapter":5,"title":"@m5_03_title","brief":["@m5_03_brief_1","@m5_03_brief_2"],"done":["@m5_03_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cat","git"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m5_03_f_readme"}},
  "repo":{"name":"repo-box","git":[{"hash":"b7c8","message":"rotate wiring","diff":"-PWR->3V3, SIG->GPIO2, GND->GND, VCC->5V\n+PWR->5V, SIG->GPIO4, GND->GND, VCC->3V3"},{"hash":"a0a0","message":"initial","diff":"+wiring.txt"}],
    "fs":{"wiring.txt":"PWR->3V3, SIG->GPIO2, GND->GND, VCC->5V (OUTDATED, see git)"}},
  "iot":{"name":"iot-node","lock":{"type":"puzzle","puzzle":"p1"},"fs":{"sensor.txt":"@m5_03_f_sensor"}}},
 "start":"home",
 "puzzles":[{"id":"p1","type":"match","data":{"left":["PWR","SIG","GND","VCC"],"right":["GPIO4","3V3","5V","GND"]},"answer":[[0,2],[1,0],[2,3],[3,1]]}],
 "goal":{"all":[{"read":"iot:/sensor.txt"},{"puzzle":"p1"}]},
 "hints":["@m5_03_hint_1","@m5_03_hint_2"],
 "solution":["scan","connect repo-box","cat wiring.txt","git log","git diff b7c8","connect iot-node",{"puzzle":"p1"},"cat sensor.txt"]}
```

`m5_04.json` — env + find + codefix + run
```json
{"id":"m5_04","chapter":5,"title":"@m5_04_title","brief":["@m5_04_brief_1","@m5_04_brief_2"],"done":["@m5_04_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cd","cat","env","find","fix","run"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m5_04_f_readme"}},
  "web":{"name":"web-box","env":{"API_URL":"https://api.internal/v2","MODE":"prod"},
    "fs":{"app/":{"client.py":"API_URL = 'https://api.internal/v1'\nresp = get(API_URL + '/status')\nassert resp == 200, resp\nprint('status ok')","util.py":"def get(url): ..."},"docs/":{"api.md":"v1 was retired last month"}}}},
 "start":"home",
 "puzzles":[{"id":"c1","type":"codefix","file":"web:/app/client.py",
   "data":{"lang":"python","lines":["API_URL = 'https://api.internal/v1'","resp = get(API_URL + '/status')","assert resp == 200, resp","print('status ok')"],
           "bugs":[{"line":0,"choices":["v1","v2","v3"],"answer":"v2"}],
           "failOutput":"AssertionError: 410","okOutput":"status ok"},
   "answer":"bugs"}],
 "goal":{"run":"web:/app/client.py"},
 "hints":["@m5_04_hint_1","@m5_04_hint_2"],
 "solution":["scan","connect web-box","env","find client","cd app","fix client.py",{"puzzle":"c1"},"run client.py"]}
```

`m5_05.json` — find 가 숨은 파일을 찾는다 + 조립 비밀번호
```json
{"id":"m5_05","chapter":5,"title":"@m5_05_title","brief":["@m5_05_brief_1","@m5_05_brief_2"],"done":["@m5_05_done_1"],
 "input":"keyboard","commands":["scan","connect","ls","cd","cat","find"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m5_05_f_readme"}},
  "corp":{"name":"corp-fs","fs":{"archive/":{".backup-note.txt":"@m5_05_f_note","2023.txt":"old"},"public/":{"index.html":"<html>"}}},
  "vault":{"name":"vault-02","lock":{"type":"puzzle","puzzle":"p1"},"fs":{"secrets.txt":"@m5_05_f_secrets"}}},
 "start":"home",
 "puzzles":[{"id":"p1","type":"password","data":{"clues":["@m5_05_p1_c1","@m5_05_p1_c2"],"fragments":["nova","2023","pixel","2022","9"]},"answer":"nova2023"}],
 "goal":{"read":"vault:/secrets.txt"},
 "hints":["@m5_05_hint_1","@m5_05_hint_2"],
 "solution":["scan","connect corp-fs","find backup","cat /archive/.backup-note.txt","connect vault-02",{"puzzle":"p1"},"cat secrets.txt"]}
```

`m5_06.json` — 최종: 조각 네 개를 모아 연다 (decode · ssh · codefix/run · 조립)
```json
{"id":"m5_06","chapter":5,"title":"@m5_06_title","brief":["@m5_06_brief_1","@m5_06_brief_2","@m5_06_brief_3"],"done":["@m5_06_done_1","@m5_06_done_2","@m5_06_done_3"],
 "input":"keyboard","commands":["scan","connect","ssh","open","decode","ls","cd","cat","fix","run"],
 "hosts":{
  "home":{"name":"my-laptop","fs":{"readme.txt":"@m5_06_f_readme"}},
  "alpha":{"name":"alpha-01","fs":{"clue1.txt":"@m5_06_f_clue1","key.txt":{"text":"oqqp","encode":"caesar:2"}}},
  "beta":{"name":"beta-01","lock":{"type":"password","answer":"moon"},"fs":{"clue2.txt":"@m5_06_f_clue2"}},
  "gamma":{"name":"gamma-01","user":"ghost","fs":{"clue3.txt":"@m5_06_f_clue3","unlock.py":"code = 41\nprint('fourth fragment:', code)"}},
  "delta":{"name":"delta-final","lock":{"type":"puzzle","puzzle":"p1"},"fs":{"final.txt":"@m5_06_f_final"}}},
 "start":"home",
 "puzzles":[
  {"id":"c1","type":"codefix","file":"gamma:/unlock.py",
   "data":{"lang":"python","lines":["code = 41","print('fourth fragment:', code)"],
           "bugs":[{"line":0,"choices":["41","42","43"],"answer":"42"}],
           "failOutput":"CheckError: 41 is not the answer","okOutput":"fourth fragment: 42"},
   "answer":"bugs"},
  {"id":"p1","type":"password","data":{"clues":["@m5_06_p1_c1"],"fragments":["ghost","1999","river","42","moon","2024"]},"answer":"ghost1999river42"}],
 "goal":{"all":[{"read":"delta:/final.txt"},{"run":"gamma:/unlock.py"},{"puzzle":"p1"}]},
 "hints":["@m5_06_hint_1","@m5_06_hint_2"],
 "solution":["scan","connect alpha-01","cat clue1.txt","decode key.txt","connect beta-01","moon","cat clue2.txt","ssh ghost@gamma-01","cat clue3.txt","run unlock.py","fix unlock.py",{"puzzle":"c1"},"run unlock.py","connect delta-final",{"puzzle":"p1"},"cat final.txt"]}
```

- [ ] **Step 3: 문장 (ko.json)**

```json
  "m5_01_title": "두 개의 문",
  "m5_01_brief_1": "최종 작전 시작. 중계 서버 비밀번호는 노트북에 암호로, 게이트 서버 토큰은 중계 서버 로그에.",
  "m5_01_brief_2": "decode 와 파이프, 둘 다 쓴다.",
  "m5_01_done_1": "문 두 개를 열었다. 앞으로 다섯 개.",
  "m5_01_f_readme": "key.txt 는 다섯 칸 밀린 암호. 풀면 relay-box 비밀번호.",
  "m5_01_f_report": "게이트 보고서: 외부 접근 없음.",
  "m5_01_hint_1": "decode key.txt → relay-box 비밀번호. 로그는 cat logs/net.log | grep token.",
  "m5_01_hint_2": "token= 뒤가 gate-01 비밀번호.",
  "m5_02_title": "배포 순서",
  "m5_02_brief_1": "빌드 서버가 배포 순서 퍼즐로 잠겼다. 순서는 파일 서버의 runbook 에 있고, 계정은 history 에.",
  "m5_02_brief_2": "테스트 없이 배포하는 사람은 없다. 순서를 잘 봐.",
  "m5_02_done_1": "테스트 → 빌드 → 푸시 → 재시작. 이 순서를 어기면 새벽에 전화가 온다.",
  "m5_02_f_readme": "build-01 잠김. corp-fs 의 runbook.md 와 history.",
  "m5_02_f_runbook": "배포 순서: 먼저 테스트를 돌리고, 이미지를 빌드하고, 이미지를 푸시하고, 마지막에 서비스를 재시작한다.",
  "m5_02_f_release": "릴리스 노트 v2.0: 배포 완료.",
  "m5_02_hint_1": "runbook.md 가 순서, history 가 ssh 계정.",
  "m5_02_hint_2": "Run tests → Build image → Push image → Restart service.",
  "m5_03_title": "바뀐 배선",
  "m5_03_brief_1": "센서 장치가 잠겼는데 배선표 파일이 낡았대. 누가 배선을 바꿨는지 git 이 안다.",
  "m5_03_brief_2": "git log 에서 커밋을 찾고 git diff 로 새 배선을 읽어. + 로 시작하는 줄이 지금 값이다.",
  "m5_03_done_1": "파일은 낡아도 git 은 최신이다. 늘 기록을 믿어라.",
  "m5_03_f_readme": "iot-node 잠김. repo-box 의 배선 기록 확인.",
  "m5_03_f_sensor": "센서 값 정상. 온도 23도.",
  "m5_03_hint_1": "git diff b7c8 의 + 줄이 현재 배선입니다.",
  "m5_03_hint_2": "PWR→5V, SIG→GPIO4, GND→GND, VCC→3V3.",
  "m5_04_title": "은퇴한 주소",
  "m5_04_brief_1": "클라이언트가 API 에 붙지 못한다. env 에는 새 주소, 코드에는 옛 주소.",
  "m5_04_brief_2": "코드 파일 위치는 find 로. 고치고 run.",
  "m5_04_done_1": "v1 은 지난달에 은퇴했다. 코드만 몰랐군.",
  "m5_04_f_readme": "web-box 클라이언트 410 오류. env 와 코드 비교.",
  "m5_04_hint_1": "env 의 API_URL 끝이 v2 입니다. find client 로 파일을 찾으세요.",
  "m5_04_hint_2": "cd app 에서 fix client.py, v1 을 v2 로.",
  "m5_05_title": "숨은 메모",
  "m5_05_brief_1": "금고 서버 비밀번호 메모를 누가 숨겨 뒀다. 이름이 점으로 시작하면 ls 엔 안 보이지만 find 는 찾는다.",
  "m5_05_brief_2": "메모를 읽고 비밀번호를 조립해.",
  "m5_05_done_1": "숨겨도 find 는 본다. 이제 넌 찾는 쪽이다.",
  "m5_05_f_readme": "vault-02 잠김. corp-fs 어딘가 backup 메모.",
  "m5_05_f_note": "금고 비밀번호: 우리 회사 첫 제품 이름 nova 뒤에 출시한 해 2023.",
  "m5_05_f_secrets": "회사 기밀: 차기 제품명 pixel-2, 출시 미정.",
  "m5_05_p1_c1": "첫 제품 이름을 소문자로.",
  "m5_05_p1_c2": "그 뒤에 출시한 해 네 자리.",
  "m5_05_hint_1": "find backup 이 숨은 파일 경로를 알려 줍니다.",
  "m5_05_hint_2": "nova 다음 2023.",
  "m5_06_title": "최종 작전",
  "m5_06_brief_1": "마지막 의뢰. 최종 서버는 조각 네 개를 이어 붙인 비밀번호로 열린다. 조각은 서버 네 대에 하나씩.",
  "m5_06_brief_2": "alpha 는 열려 있고, beta 비밀번호는 alpha 에 암호로, gamma 는 내 계정 ghost 로 ssh, 넷째 조각은 gamma 의 스크립트가 고쳐지면 출력한다.",
  "m5_06_brief_3": "지금까지 배운 전부다. 가자.",
  "m5_06_done_1": "넷을 모아 하나를 열었다. 축하한다, 더 이상 신입이 아니다.",
  "m5_06_done_2": "여기까지가 1부다. 이 뒤로도 의뢰는 계속 온다.",
  "m5_06_done_3": "— 고스트",
  "m5_06_f_readme": "순서: alpha-01 → beta-01 → gamma-01 → delta-final. 조각 넷을 이어서.",
  "m5_06_f_clue1": "첫째 조각: ghost",
  "m5_06_f_clue2": "둘째 조각: 1999",
  "m5_06_f_clue3": "셋째 조각: river. 넷째 조각은 unlock.py 를 고쳐서 돌리면 나온다.",
  "m5_06_f_final": "최종 파일: 당신은 모든 임무를 완수했습니다.",
  "m5_06_p1_c1": "조각 네 개를 첫째부터 넷째까지 빈칸 없이 이어 붙인다.",
  "m5_06_hint_1": "beta-01 비밀번호는 alpha-01 의 key.txt 를 decode. gamma-01 은 ssh ghost@gamma-01.",
  "m5_06_hint_2": "unlock.py 의 41 을 42 로 고치고 run. 비밀번호는 ghost 1999 river 42 를 이어서.",
```

- [ ] **Step 4: 확인 · 커밋** — en.json 채우고 `gen.py` → `flutter test` 30개 전부 PASS. `git add -A; git commit -m "챕터5 임무 6개: 최종 작전"`

---

### Task 5: 효과음 5개

**Files:**
- Create: `tool/gen_sfx.py`(삐약푸시 것 복사 후 소리 5개로 줄임), `assets/sfx/key.wav tap.wav run.wav ok.wav fail.wav`, `lib/sfx.dart`
- Modify: `pubspec.yaml`(`audioplayers: ^6.8.1`, assets `assets/sfx/`), `lib/ui/mission_screen.dart`, `lib/ui/input_bar.dart`, `lib/main.dart`

- [ ] **Step 1: 소리 만들기**

`C:\workAndroid\PiyakPush\tool\gen_sfx.py` 를 복사해 `OUT` 을 `assets/sfx` 로, 소리는 다섯 개만 남긴다: `key`(짧은 틱 1200Hz 20ms), `tap`(칩, 800Hz 40ms), `run`(실행, 600→900Hz 스윕 80ms), `ok`(성공, 660·880·1320Hz 세 음 각 70ms), `fail`(실패, 300→200Hz 스윕 150ms). `python tool/gen_sfx.py` → 5개 wav.

- [ ] **Step 2: 배선**

`lib/sfx.dart`:
```dart
import 'package:audioplayers/audioplayers.dart';

import 'engine/progress.dart';
import 'sfx_low_latency.dart'; // common/flutter/sfx_low_latency.dart 복사

/// 효과음 다섯 개. 설정에서 끄면 전부 조용.
class Sfx {
  static final Sfx _i = Sfx._();
  factory Sfx() => _i;
  Sfx._();
  final Map<String, LowLatencySfx> _s = {};
  Progress? progress;

  Future<void> load(Progress p) async {
    progress = p;
    for (final n in ['key', 'tap', 'run', 'ok', 'fail']) {
      _s[n] = await LowLatencySfx.fromAsset('sfx/$n.wav');
    }
  }

  void play(String name) {
    if (progress?.soundOn == false) return;
    _s[name]?.start();
  }
}
```
`main.dart` 에서 `await Sfx().load(progress);`. `InputBar` 칩 탭 → `Sfx().play('tap')`, 실행 → `'run'`. `MissionScreen._onRun` 결과가 오류면 `'fail'`, `_onPuzzle` 맞으면 `'ok'` 틀리면 `'fail'`, `_finish` 에서 `'ok'`. `TextField.onChanged` → `'key'`.
`AudioPlayer` 는 테스트에서 플랫폼 채널이 없어 던진다 — `Sfx.load` 는 try/catch 로 감싸 실패해도 앱이 뜨게 한다. 위젯 테스트는 `Sfx()` 를 부르지 않는 경로라 영향 없다(InputBar 는 `Sfx().play` 를 부르지만 `_s` 가 비어 있으면 아무것도 안 한다).

- [ ] **Step 3: 확인** — `flutter test` PASS. 실기기에서 칩을 빠르게 연타해도 화면이 안 멈추는지(메모리: audioplayers MediaPlayer 모드가 메인스레드를 0.12초 잡던 사례). `pubspec.yaml` assets 에 `assets/sfx/` 가 있는지 — 없으면 릴리스에서만 소리가 안 난다.
- [ ] **Step 4: 커밋** — `git add -A; git commit -m "효과음 5개(저지연 재생)"`

---

### Task 6: 12개 언어 번역

**Files:**
- Create: `i18n/ja.json zh.json zh_Hant.json es.json pt.json de.json fr.json it.json ru.json id.json vi.json th.json`
- Modify: `lib/l10n/*`(재생성)

- [ ] **Step 1: 번역 지시문** — `common/i18n/TRANSLATION_PROMPT.md` 를 그대로 쓴다. 꼭 덧붙일 것: "명령 이름(scan, cat, grep …)·호스트 이름·파일 이름·비밀번호 조각(momo, 2019, bori …)·코드는 번역하지 않는다. `{n}`·`{cmd}`·`{host}` 같은 자리는 그대로 둔다. 힌트의 `cat menu.txt` 같은 명령 줄은 그대로."
- [ ] **Step 2: 언어마다 한 파일씩** 만들고, 하나 만들 때마다:
  ```powershell
  python ..\common\i18n\audit.py i18n
  ```
  확정(`slotcount missing hangul glue`) 0 이어야 다음 언어로 간다. `seg` 단서는 es·fr·pt·id·vi·th 만 본다.
- [ ] **Step 3:** `gen.py` 재생성 → `flutter test`(`i18n_test` 가 열쇠·이름 자리를 대조). 설정 화면에서 14개 언어가 그 언어 글자로 나오고 골라서 바뀌는지 한 번 실행해 본다.
- [ ] **Step 4: 커밋** — `git add -A; git commit -m "12개 언어 번역 추가(14개 언어)"`

---

### Task 7: 아이콘 · 전체 화면 스크린샷 · 실기기 일괄 플레이

**Files:**
- Create: `assets/icon/icon.png`(1024×1024), `tool/apply_icon.py`(삐약푸시 복사), `store/screenshots/<lang>/…`
- Modify: `android/app/src/main/res/mipmap-*`

- [ ] **Step 1: 아이콘** — 어두운 바탕에 초록 `>_` 프롬프트와 자물쇠. `tool/apply_icon.py` 로 mipmap 전부 교체. 적응형 아이콘(`mipmap-anydpi-v26`)도 같이.
- [ ] **Step 2: 실기기 일괄 플레이** — 사용자에게 폰 연결을 요청한 뒤 디버그 APK 설치. **챕터마다 임무 하나 이상을 힌트 없이 끝까지**(m1_06·m2_06·m3_06·m4_06·m5_06 보스 다섯). 발견한 결함은 재현 테스트 → 수정 → 커밋.
- [ ] **Step 3: 스크린샷** — ko·en·ru·th 로 모든 화면(메시지함·상세·터미널·파일·퍼즐 4종·힌트·완료·설정). 칩·상단 바·퍼즐 카드가 넘치면 글자 크기나 줄바꿈을 고친다(스크린샷으로 판단, UI 덤프 아님). 스토어용 7장은 `store/screenshots/<lang>/` 에.
- [ ] **Step 4: 커밋** — `git add -A; git commit -m "아이콘과 스토어 스크린샷"`

---

### Task 8: 서명 빌드 · 스토어 준비

**Files:**
- Create: `android/keystore.properties`(gitignore), `store/listing-ko.md`, `store/listing-en.md`, `store/release-notes/`
- Modify: `pubspec.yaml`(`version: 1.0.0+1`), `README.md`

- [ ] **Step 1: 서명** — `C:\workAndroid\_서명키_백업` 의 기존 키를 쓴다(앱마다 새 키를 만들지 않는다). `keystore.properties` 를 다른 Flutter 앱(삐약푸시)에서 복사해 경로만 맞춘다. `android/app/build.gradle.kts` 는 1부 Task 1 에서 삐약푸시와 같은 서명 블록을 넣어 뒀는지 확인(없으면 삐약푸시 것을 그대로).
- [ ] **Step 2: 릴리스 빌드**
  ```powershell
  flutter build appbundle --release
  flutter build apk --release
  ```
  릴리스 APK 를 폰에 깔아 **켜지는지·소리 나는지·임무 하나 끝까지 되는지** 본다(릴리스에서만 죽는 사례가 있었다). `apksigner verify --print-certs` 로 지문이 다른 앱과 같은지.
- [ ] **Step 3: 스토어 문구** — `common/checklists/play-release.md`·`store/README.md` 대로. 간단한 설명·자세한 설명을 ko·en 으로 쓰되 **"광고 없음·무료·인앱결제 없음·개인정보 수집 안 함" 을 쓰지 않는다.** 데이터 보안 신고는 "수집 없음" 으로 사실대로. 콘텐츠 등급은 `common/checklists/content-rating.md`(폭력·도박 없음, 해킹 소재는 "교육용 시뮬레이션").
- [ ] **Step 4: 출시노트** — `common/store/release-notes.py` 로 14개 언어.
- [ ] **Step 5: README 갱신** — 2부가 끝났다는 것, 남은 일(광고·「개발자의 다른 게임」 은 인터넷 권한과 함께 v1.1, 챕터 6+ 추가법).
- [ ] **Step 6: 커밋 · 원격**
  ```powershell
  git add -A
  git commit -m "v1.0.0: 30임무·14개 언어·서명 빌드"
  ```
  GitHub 원격(`Yongminlee2/HackQuest`)은 **사용자에게 이름을 확인한 뒤** 만든다. 비공개 테스트 등록과 프로덕션 신청은 사람이 한다(`common/store/프로덕션-신청-답변.md`).

---

## 2부 끝

여기까지 끝나면 스토어에 올릴 AAB 와 등록정보가 준비된다. 그 뒤(v1.1): 광고 자리에 SDK + 「개발자의 다른 게임」 + `legal/apps.json` 에 이 앱 한 줄(`common/promo/README.md`).
