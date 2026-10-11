# HackQuest — 개발자 해킹을 가장한 퍼즐 게임 (Flutter, 안드로이드)

가짜 운영체제 안에서 의뢰인 "고스트"가 보낸 임무 30개를 터미널 명령·논리 퍼즐·코드 고치기로 푼다.
초반은 게임용 가짜 명령을 칩으로 누르고, 뒤로 갈수록 진짜 셸 명령과 진짜 코드가 나온다.

## 지금 상태 (2026-10-11)

- **1부 완료**: 터미널 엔진(명령 21개), 퍼즐 4종, 화면 전부, 챕터 1 임무 6개, 한국어·영어.
- **남은 것**: 2부 계획서 — 챕터 2~5 임무 24개, 12개 언어, 효과음, 아이콘, 서명 빌드, 스토어 준비.
- 실기기 플레이 확인은 아직 안 했다(디버그 APK 는 빌드됨). 화면 배선은 `test/play_chapter1_test.dart` 가 챕터 1 을 실제 화면으로 끝까지 눌러 확인한다.

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
