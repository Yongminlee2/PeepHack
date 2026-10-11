# 브리치 모드 구현 계획

**Goal:** 브리치 프로토콜 미니게임 부품 + 브리치 모드(60 스테이지·매일 퍼즐) + 모드 선택 화면.
**Spec:** `docs/specs/2026-10-11-breach-mode-design.md`
**Tech:** 기존 Flutter 앱. 새 패키지 없음.

## Global Constraints

- `lib/engine/` 는 Flutter import 금지. 모든 규칙·생성은 순수 Dart, 테스트 먼저.
- 문장은 `i18n/ko.json`·`en.json` 열쇠로만(다른 언어는 `i18n/pending/`, 손대지 않음).
- 움직이는 위젯(제한 시간 막대)은 테스트에서 pumpAndSettle 이 끝나도록 `Ticker` 대신 `Timer.periodic` 1초 + 테스트에서 시간 주입.
- 커밋 메시지에 AI 언급 금지.

## Review Focus

1. 첫 선택은 맨 윗줄만, 두 번째는 그 세로줄만 — 뒤집혀 구현되기 쉽다.
2. 같은 칸 두 번 고르기, 버퍼 넘침.
3. 목표가 버퍼 안에서 겹치며 달성되는 경우(예: `55 1C` 와 `1C BD` 를 `55 1C BD` 로 둘 다).
4. 시간이 끝난 뒤의 탭은 무시.
5. 매일 퍼즐: 같은 날 같은 퍼즐, 다른 날 다른 퍼즐.

## Tasks

1. **규칙 엔진** `breach.dart` + `test/engine/breach_test.dart`: `BreachPuzzle(grid, buffer, daemons, timeLimit)`, `BreachGame.legalCells()`, `pick(r,c)`, `done`, `daemonDone(i)`, `stars`, `timeUp()`.
2. **생성기** `breach_gen.dart` + 테스트: `stageParams(n)`, `generateStage(n)`, `generateDaily(DateTime)`, 심은 경로(`solution`)가 규칙에 맞고 전부 달성하는지 60개 + 날짜 30개 검사.
3. **저장** `Progress.breachStars/setBreachStars/dailyStars/setDailyStars/isBreachUnlocked` + 테스트.
4. **판 부품** `BreachBoard` + 위젯 테스트(정답 경로를 눌러 별 3, 줄 강조, 잘못된 칸 무시).
5. **화면**: 모드 선택(타이틀 → 모드), 브리치 목록, 플레이(결과·다음·다시) + 위젯 테스트, ko/en 문장.
6. **실기기**: 설치해 스테이지 몇 개와 매일 퍼즐을 직접 풀어 보고 스크린샷.
