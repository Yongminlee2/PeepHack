# HackQuest — 개발자 해킹을 가장한 퍼즐 게임 (Flutter, 안드로이드)

가짜 운영체제 안에서 의뢰인 "고스트"가 보낸 임무 30개를 터미널 명령·논리 퍼즐·코드 고치기로 푼다.
초반은 게임용 가짜 명령을 칩으로 누르고, 뒤로 갈수록 진짜 셸 명령과 진짜 코드가 나온다.

## 이어받는 사람을 위해 (2026-10-11 기준: 코드 없음, 설계·계획만 있음)

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
