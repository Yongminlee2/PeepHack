# HackQuest — 개발자 해킹을 가장한 퍼즐 게임 (Flutter, 안드로이드)

가짜 운영체제 안에서 의뢰인 "고스트"가 보낸 임무 30개를 터미널 명령·논리 퍼즐·코드 고치기로 푼다.
초반은 게임용 가짜 명령을 칩으로 누르고, 뒤로 갈수록 진짜 셸 명령과 진짜 코드가 나온다.

## 지금 상태 (2026-10-11)

세 가지 모드가 있는 해킹 퍼즐 게임이다. 타이틀 → 모드 선택.

- **작전**: 고스트의 의뢰 30개(5장). 터미널 + 네트워크 지도. 잠긴 서버는 단서(비밀번호·퍼즐·ssh)로 열거나, 포트 크랙(브리치 판·단어 추리)으로 뚫는다. 시작 서버 밖에 있으면 추적 게이지가 오르고 100% 면 실패. 보상 크레딧으로 장비(버퍼 확장·오버클럭·추적 교란기)를 산다.
- **브리치**: 사이버펑크 브리치 프로토콜식 격자 퍼즐 60스테이지 + 오늘의 퍼즐.
- **사건 파일**: 자료(로그·메일)를 읽고 결론 질문에 답하는 추리 사건 6개. 잠긴 자료는 폴아웃식 단어 추리로 연다.
- 한국어·영어만 켜져 있다. 12개 언어 번역은 `i18n/pending/` 에 빼 두었다(게임 완성 뒤 한 번에).
- 패키지 `com.peep.hack`. 실기기(갤럭시 A16)로 세 모드 모두 직접 플레이 확인.

설계: `docs/specs/` (1차 설계, 브리치, 작전 개편, 단어 추리·사건 파일).

## 테스트

```powershell
flutter test      # 엔진·화면·임무 검사·번역 열쇠 전부
flutter analyze   # 경고 0 을 유지한다
```

`test/missions_test.dart` 가 `assets/missions/*.json` 을 엔진으로 **실제로 풀어 본다**.
정답 경로로 목표에 닿는지, 칩 임무가 칩만으로 쳐지는지, 퍼즐 정답이 조각으로 만들어지는지,
번역 열쇠가 다 있는지. 임무를 고치면 이것만 돌리면 된다.

## 임무 추가법

1. `assets/missions/m{챕터}_0{번호}.json` — 형식은 설계 문서 3절, 예시는 챕터 1 파일들.
2. 사람이 읽는 글은 `@m{챕터}_0{번호}_...` 열쇠로 쓰고 `i18n/ko.json`·`en.json` 에 넣는다.
   로그·코드·비밀번호·파일 이름은 영어 원문 그대로 둔다(언어마다 grep 결과가 달라지면 안 된다).
3. `python ../common/i18n/gen.py i18n --to flutter --out lib/l10n`
4. `flutter test` — 빨간불이면 엔진이 아니라 임무 데이터를 고친다.

## 아이폰 (같은 Dart 코드, `ios/`)

맥에서 빌드한다. 번들 ID `com.peep.hack`(안드로이드 패키지와 같음), 팀 3276G27R59, 아이폰 전용·세로 전용, 최소 iOS 15.
버전·빌드 번호는 `pubspec.yaml` 의 `version` 이 그대로 들어간다. Flutter 는 `~/flutter`(3.44.x, 윈도우와 같은 줄)를 쓴다.

```bash
flutter build ios --simulator          # 시뮬레이터 빌드 확인
flutter test test/ios                  # 아이폰 설정이 안드로이드와 맞는지(번들 ID·이름·언어·아이콘·매니페스트)
tool/ios_store_shots.sh                # 앱스토어 스크린샷 1320×2868, 한국어·영어 → store/ios/screenshots/
tool/ios_archive.sh upload             # 보관 + App Store Connect 업로드
```

- 앱스토어 문구·설문·심사 메모: `store/ios/앱스토어-작성내용.md`. 개인정보처리방침은 legal 저장소 `hackquest/`.
- 아이폰에서만 다른 것: 명령 입력칸의 둥근 따옴표·긴 줄표 자동 바꾸기를 끈다(`input_bar.dart`), 소리는 ambient 세션
  (듣던 음악과 섞이고 무음 스위치를 따른다), 「다른 게임」 단추는 아직 "준비 중" 이라 아이폰에서 숨긴다(심사 2.1·2.3.10).
- 아이콘을 바꾸면 `tool/apply_icon.py` 가 아이폰 1024 아이콘도 같이 만든다.
- 이 맥의 시뮬레이터는 바깥 탭을 앱이 못 받는다 — 스크린샷은 `integration_test/store_shots_test.dart` 가 앱 안에서 눌러 찍는다.

## 함정

- `lib/engine/` 에는 Flutter 를 import 하지 않는다(순수 Dart, 테스트·도구용).
- 위젯 테스트에서 `rootBundle` 로 자산을 읽는 테스트가 여럿이면 `setUp` 에서 `rootBundle.clear()`.
  앞 테스트의 가짜 시간 영역에서 만든 캐시를 기다리다 10분 동안 멈춘다.
- `pumpAndSettle` 은 타임아웃을 짧게 준다(`play_chapter1_test.dart` 의 `settle`). 기본값은 10분이다.

## 이어받는 사람을 위해

읽는 순서:

1. `docs/specs/2026-10-11-hackquest-design.md` — 승인된 설계. 화면·임무 JSON 형식·명령 표·퍼즐 4종·검사 규칙.
2. `docs/plans/2026-10-11-hackquest-part1-engine-ui-ch1.md` — 1부: 엔진·화면·챕터 1. 테스트 코드와 구현 코드가 전부 들어 있다. 순서대로 하면 된다.
3. `docs/plans/2026-10-11-hackquest-part2-content-release.md` — 2부: 챕터 2~5 임무 24개·14개 언어·효과음·아이콘·서명 빌드.

규칙(공통 저장소 `../common/AGENTS.md` 와 같다):

- 빌드가 통과했다고 동작한다고 보고하지 않는다. 폰에서 한 임무를 끝까지 플레이한다.
- 폰 설치는 사용자가 요청할 때만.
- 스토어 문구에 "광고 없음·무료·인앱결제 없음" 을 쓰지 않는다.

빌드 환경(한글 홈 경로 함정, 매 셸 세션):

```powershell
$env:Path = "C:\flutter\bin;$env:Path"
$env:PUB_CACHE = "C:\flutter\.pub-cache"
$env:GRADLE_USER_HOME = "C:\workAndroid\gradle-home-ascii"
$env:TEMP = "C:\workAndroid\tmp-ascii"; $env:TMP = "C:\workAndroid\tmp-ascii"
```

## 아트·소리 출처

- 고스트 얼굴·앱 아이콘: 어나니머스 문양 — [Wikimedia Commons: Anonymous_Flag.svg](https://commons.wikimedia.org/wiki/File:Anonymous_Flag.svg), 퍼블릭 도메인. 깃발 바탕을 떼고 초록으로 다시 칠함(`assets/images/`).
- 매트릭스 비·스캔라인·글리치 글자: 코드로 그림(`lib/ui/fx/`).
- 효과음: `tool/gen_sfx.py` 로 합성.
- 배경음악: `tool/gen_music.py` 로 합성한 곡(직접 만든 것, 저작권 문제 없음).
- 글꼴: HackMono = 나눔고딕코딩(SIL Open Font License 1.1)의 영문·기호만 잘라 이름을 바꾼 것(`tool/subset_font.py`, 라이선스 `assets/fonts/OFL-Nanum.txt`).
