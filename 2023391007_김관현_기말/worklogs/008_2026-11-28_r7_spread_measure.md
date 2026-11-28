# 008 - 2026-11-28 - R7 새 적(SniperEnemy) 추가 및 계층별 번짐 실측

## 세션 목표
- `before-r7`(`7f11e8b`) 태그를 기준으로 새 적 종류 1종 `SniperEnemy`("sniper")를 `GameModel`·`controllers`·`scenes` 무수정으로 TDD 구현하고, 커밋 후 계층별 hunk 번짐을 실측해 보고서에 반영한다.

## 프롬프트 기록 #1
- 시각 / 커밋: 14:22 / `7f11e8b` (`before-r7`) → `26563b9`
- 도구: Antigravity (에이전트 `lua-reviewer`, 상시 규칙 `.agents/rules/student-guide-workflow.md` · `project-core.md` · `AGENTS.md` 자동 적용)
- 목적: 6요소 명세 프롬프트로 R7(`SniperEnemy`) 계획 수립 → 승인 → TDD 구현 → 번짐 실측
- 프롬프트 원문:
  > [맥락]
  > LÖVE 11.5 / Lua 5.1 MVC 겔러그 기말 프로젝트(`2023391007_김관현_기말/project/src/`)에서 R1~R6 완료 후 `before-r7` 태그를 찍은 상태다.
  >
  > [목표]
  > R7 번짐 실측을 위해 새 적 종류 1종 `SniperEnemy`("sniper": 편대 대기 중 조준 사격 또는 빠른 직선 돌격, HP 1, 점수 200)를 추가하고, `git diff -U0 before-r7 HEAD`로 계층별 hunk 수를 실측할 수 있게 최소 번짐으로 구현해라.
  >
  > [참조 파일 (읽기 전용)]
  > - `project/src/models/class.lua`, `EnemyModel.lua`, `EnemyAI.lua`
  > - `project/src/models/GameModel.lua` (수정 금지 — Factory·MVC 덕분에 무수정 유지)
  > - `project/src/controllers/`, `project/src/scenes/` (수정 금지)
  > - `project/tests/layer_check.lua`, `enemy_factory_test.lua`
  >
  > [수정 허용 파일]
  > - 신규: `project/src/models/SniperEnemy.lua`
  > - 수정: `project/src/models/EnemyFactory.lua`, `project/src/views/EnemyView.lua`, `project/src/waves.txt`, `project/tests/enemy_factory_test.lua`
  >
  > [제약 사항]
  > - Lua 5.1 / LuaJIT 호환 문법만 사용 (`//`, `!=`, `goto`, `table.unpack`, 전역 `utf8` 금지).
  > - 모든 변수·함수는 `local`만 사용 (`luac -l -p` 기준 `SETGLOBAL` 0건).
  > - Model에는 `love`·`io`·`print`·시드 없는 `math.random` 금지, View에서는 Model 상태 수정 금지.
  > - 구현 전 계획(수정 파일·먼저 쓸 테스트·위험 요소)을 먼저 제시하고 승인 후 TDD(테스트 실패 확인 → 구현 → 통과) 순서로 진행할 것.
  >
  > [검증]
  > - `lua tests/layer_check.lua src` (위반 0건)
  > - 전체 `*_test.lua` 통과 및 `luac -l -p` `SETGLOBAL` 0건
  > - 커밋 후 계층별 hunk 수(`models`, `views`, `controllers`, `scenes`) 실측
- AI 결과 요약:
  - [Plan] `git tag` 확인 결과 `before-r7` 태그 미생성을 선제 포착하고, `SniperEnemy` 5개 파일 경계·TDD 테스트 3건·위험 요소를 제시해 승인을 요청함.
  - [Before] `before-r7` 태그를 `7f11e8b`에 생성한 뒤 `enemy_factory_test.lua`에 `sniper` 검증 테스트를 먼저 추가해 `통과 4 / 실패 3` (`EnemyFactory.create: 알 수 없는 적 종류입니다: sniper`, `EXIT:1`) 실패를 확인함.
  - [After] `SniperEnemy.lua` 신규 작성 및 `EnemyFactory.lua`·`EnemyView.lua`·`waves.txt` 최소 수정으로 전체 80개 테스트 + `layer_check.lua`(39개 파일 0건) + `SETGLOBAL: 0` + `lua-reviewer` `커밋 가능` 판정을 받고 커밋(`26563b9`)함.
- 판정: 채택
- 문제점: 없음 (`lua-reviewer` 지적 0건)
- 다음 프롬프트에서 바꾼 점: R7 번짐 실측 결과를 `report_게임인공지능.md`에 반영하고 보고서 2종 줄 번호 동기화·`999_retrospective.md`·`docs/git_log.txt`로 최종 마감.

## 프롬프트 기록 #2
- 시각 / 커밋: 14:22 / `7f11e8b` → `26563b9` (이후 보고서·회고 마감 커밋)
- 도구: Antigravity
- 목적: 해시 정비 → `before-r7` 태그 → R7 TDD → 보고서 줄 번호 동기화 & 최종 회고 일괄 승인
- 프롬프트 원문:
  > ① 미커밋 파일 정리 + 커밋 해시 정비 → ② R7(실제 6요소 프롬프트로 진행) → ③ 보고서 줄 번호 동기화 & 999_retrospective.md 작성 순서로 깔끔하게 진행해봐
- AI 결과 요약: 승인된 순서대로 해시 정비 커밋(`7f11e8b`) + `before-r7` 태그 생성, R7 TDD 구현·커밋(`26563b9`), 계층별 hunk 실측, 보고서 2종 줄 번호 전수 동기화 및 최종 회고(`999_retrospective.md`) 작성을 완료함.
- 판정: 채택

## R7 번짐 실측 결과 (`before-r7`..`26563b9`)
- `models`: **3 hunk** (`SniperEnemy.lua` +19, `EnemyFactory.lua` +4)
- `views`: **1 hunk** (`EnemyView.lua` +1)
- `controllers`: **0 hunk**
- `scenes`: **0 hunk**
- `GameModel.lua`: **0줄 수정**

## 검증
- TDD 수정 전 실패 확인:
  - `lua tests/enemy_factory_test.lua src`: `통과 4 / 실패 3` (`EXIT:1`)
- R7 구현 후 최종 검증 (`lua` 5.1.5 / `luac`):
  - `luac -l -p` (`project/src/**/*.lua`): `SETGLOBAL: 0`
  - `lua tests/layer_check.lua src`: 파일 39개 검사, 위반 0건
  - 전체 단위 테스트 10개 파일: **80건 통과 / 0건 실패** (`FAILED_SCRIPTS: 0`)
- `lua-reviewer` 리뷰: `커밋 가능` (높음/중간/낮음 0건)
- LÖVE 실행 확인(웨이브 2·3 보라색 `SniperEnemy` 고속 돌격 시각 확인): `(사용자 직접 LÖVE 실행 확인 필요)`

## 회고
- AI 에 맡긴 것 / 내가 직접 한 것: 6요소 명세 프롬프트로 수정 허용/금지 파일과 Lua 5.1·MVC 제약을 직접 지정해 지시했고, TDD 구현·리뷰·실측·문서 동기화는 AI가 수행함.
- 다음에 프롬프트를 다르게 쓸 점: 처음부터 6요소 프롬프트로 수정 허용 파일과 읽기 전용 파일을 명시하니 `lua-reviewer` 지적 0건, `controllers`/`scenes` 0 hunk로 가장 깔끔한 결과가 나왔음.
