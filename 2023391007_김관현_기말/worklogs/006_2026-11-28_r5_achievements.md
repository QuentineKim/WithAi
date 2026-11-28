# 006 - 2026-11-28 - R5 특이 업적 3종(Observer) 및 통합 배너·폭죽 연출

## 세션 목표
- `GameModel`을 전혀 수정하지 않고 `drainEvents()` 이벤트만 구독해 특이한 업적 3종(`trigger_happy`, `last_stand`, `clean_boss`)을 판정하는 `AchievementModel`과, `EffectsView` 배너 영역에 통합된 요란한 알림·연출을 TDD로 구현한다.

## 프롬프트 기록 #1
- 시각 / 커밋: 10:15 / `deef986`
- 도구: Antigravity
- 목적: 5회차 R5 구현 전 계획 수립 및 승인 요청
- 프롬프트 원문:
  > 5회차 진행하기 전에 계획 세워봐
- AI 결과 요약: `GameModel.lua`, `PlayScene.lua`, `GameView.lua`, `EffectsView.lua`, `HudView.lua`, `FormationPhase.lua`, `BossPhase.lua`를 읽고 수정/읽기 전용 파일 경계(`GameModel.lua` 수정 금지), TDD 테스트 7건 목록, 배너 위치·동시 달성 큐·LÖVE 폰트 위험 대응, 확인 질문 2가지를 제시하고 승인을 요청함.
- 판정: 채택 (질문에 따른 업적·연출 방향 변경으로 이어짐)
- 문제점: 없음
- 다음 프롬프트에서 바꾼 점: 기본 업적 3종 대신 특이한 조건의 업적과 요란한 게임 연출을 추가하고 알림 UI는 `EffectsView` 배너 영역에 통합하도록 확정함.

## 프롬프트 기록 #2
- 시각 / 커밋: 10:21 / `deef986` → `a723406`
- 도구: Antigravity (에이전트 `test-runner`, `lua-reviewer`, 상시 규칙 `.agents/rules/student-guide-workflow.md` · `project-core.md` · `AGENTS.md` 자동 적용)
- 목적: 특이 업적 3종 + 보스 경보·폭죽·네온 배너 연출 TDD 구현 및 리뷰 보완
- 프롬프트 원문:
  > 추천 업적 좀 특이한걸로 변경해서 하고 게임 요소도 좀 요란한거 하나 추가해보자 그런 다음 알림 ui는 베너 영역에 통합하는게 좋을거 같긴해 좋아 이대로 진행시켜
- AI 결과 요약:
  - [Before] `project/tests/achievement_test.lua`(8건)를 먼저 작성·실행해 `module 'AchievementModel' not found` (`EXIT:1`) 실패를 확인함.
  - [Mid] `AchievementModel.lua`(Observer: `trigger_happy` 발사 20회, `last_stand` 2피격 후 3기 격추, `clean_boss` 보스전 무피격 격파)와 `EffectsView.lua`(보스 등장 붉은 경보+플래시+셰이크, 업적 달성 3지점 36발 다색 폭죽+네온 점멸 배너 큐, 보스 격파 대폭발), `PlayScene.lua` 구독 연결을 구현해 `test-runner` 7개 스크립트 전체 통과 및 `SETGLOBAL` 0건을 확인함.
  - [After] `lua-reviewer`가 `EffectsView.lua:101-103, 219`의 `onEvent` 테이블 가드 누락 및 `title` nil 폴백 부재, `achievement_test.lua:39-40`의 `title` 단언 누락(낮음 2건)을 지적해 즉시 보강한 뒤 `test-runner`와 `luac` 검사를 재통과시킴.
- 판정: 수정 후 채택
- 문제점:
  - `EffectsView:onEvent`에 `AchievementModel:onEvent`와 같은 입력 타입 가드(`type(ev) ~= "table"`)와 `title` 폴백이 빠져 있었고, `trigger_happy` 테스트에서 이벤트 `title` 필드 검증이 누락되어 있었음.
- 다음 프롬프트에서 바꾼 점: 리뷰에서 지적된 방어 가드와 payload 계약 단언을 반영하고 재검증까지 완료함.

## 검증
- TDD 수정 전 실패 확인:
  - `lua project\tests\achievement_test.lua src`: `module 'AchievementModel' not found` (exit 1)
- 리뷰 보강 후 최종 `test-runner` 결과 (`lua` 5.1.5):
  - `lua layer_check.lua src`: 파일 35개 검사, 위반 0건
  - `lua phase_test.lua src`: 통과 9 / 실패 0
  - `lua scene_test.lua src`: 통과 19 / 실패 0
  - `lua wave_parser_test.lua src`: 통과 10 / 실패 0
  - `lua enemy_factory_test.lua src`: 통과 6 / 실패 0
  - `lua enemy_ai_test.lua src`: 통과 6 / 실패 0
  - `lua achievement_test.lua src`: 통과 8 / 실패 0
- `luac -l -p` (`project/src/**/*.lua`): `SETGLOBAL 0건`
- `lua-reviewer` 리뷰: `커밋 가능` (높음 0건, 낮음 2건 보강 완료)
- LÖVE 실행 확인(보스 경보, 업적 폭죽·네온 배너 점멸, 보스 격파 연출 시각 확인): (사용자 직접 LÖVE 실행 확인 필요)

## 회고
- AI 에 맡긴 것 / 내가 직접 한 것: 특이 업적 3종·요란한 폭죽/경보 연출과 배너 영역 통합 방향은 내가 결정했고, `AchievementModel`·`EffectsView` 구현, TDD 테스트, `test-runner`/`lua-reviewer` 검증 및 문서 갱신은 AI가 수행함.
- 다음에 프롬프트를 다르게 쓸 점: 6회차(R6 하이스코어)에서는 깨진 입력 방어와 `layer_check` 경계 위반 거절 사례를 로그에 남길 수 있도록 설계 단계에서 `io`/직렬화 분리 계약을 더욱 명확히 짚을 것.

## 인계 메모 (다음 세션 첫 프롬프트에 붙여넣기)
1) 완료: R5 완료 — `AchievementModel.lua`(Observer: `trigger_happy`, `last_stand`, `clean_boss`), `EffectsView.lua`(보스 경보·36발 폭죽·네온 점멸 업적 배너 큐), `PlayScene.lua` 구독 연결, `achievement_test.lua` 8/8 및 전체 58테스트+`layer_check`(35개 0건) 통과, `report_게임인공지능.md` Observer 행 추가.
2) 바뀐 파일: `models/AchievementModel.lua`, `views/EffectsView.lua`, `scenes/PlayScene.lua`, `tests/achievement_test.lua`, `README.md`, `TODO.md`, `docs/report_*.md`, `worklogs/006_2026-11-28_r5_achievements.md`.
3) 정한 규칙: `GameModel.lua`는 업적을 전혀 모름(`drainEvents()`만 소비), `EffectsView`는 `love` 없이 `gfx`와 주입 `rand`만 사용, 화면 문구는 영문 ASCII 유지.
4) 남은 문제: 커밋 `a723406`(R5+R6+업그레이드 통합 반영) 완료, LÖVE 창 시각 확인 필요, R7(번짐 실측)·최종 회고·`docs/git_log.txt` 미완료.
5) 다음 태스크: R5 커밋 후 6회차에서 **R6(하이스코어 저장/불러오기 — Model은 순수 직렬화/역직렬화+손상 복구, 파일 I/O는 `main.lua`에서만)** 계획 수립부터 시작.
