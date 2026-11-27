# 004 - 2026-11-27 - R3 적 3종 상속 및 EnemyFactory 구현

## 세션 목표
- `class.lua` 상속으로 적 3종(`BasicEnemy`, `ScoutEnemy`, `TankEnemy`)과 등록표 기반 `EnemyFactory`를 구현하고 `GameModel`·`EnemyView`·`waves.txt`에 연동한다.

## 프롬프트 기록 #1
- 시각 / 커밋: 17:46 / `2eb0aef`
- 도구: Antigravity
- 목적: 3회차(R3)·4회차(R4) 구현 계획 및 TODO 문서 계획 수립 요청
- 프롬프트 원문:
  > 4회차까지 하고 일단 todo문서도 만들어
- AI 결과 요약: `class.lua`·`EnemyView.lua`·`GameView.lua`를 읽고 R3(적 3종 + Factory), R4(적 AI 4상태 + 결정성), TODO 문서의 단계별 계획(수정/읽기 전용 파일, 먼저 쓸 테스트, 기존 `wave_parser_test`/`phase_test` 호환성 위험 대응)을 제시해 승인을 요청함.
- 판정: 채택
- 문제점: 없음
- 다음 프롬프트에서 바꾼 점: 승인 후 1 태스크 = 1 커밋 원칙에 따라 R3를 먼저 TDD로 완료·커밋한 뒤 R4로 이어감.

## 프롬프트 기록 #2
- 시각 / 커밋: 17:48 / (커밋 전)
- 도구: Antigravity (에이전트 `test-runner`, `lua-reviewer`)
- 목적: 승인된 계획대로 R3 TDD 구현, 검증 및 리뷰 지적 보완
- 프롬프트 원문:
  > ㄱㄱ
- AI 결과 요약:
  - [Before] `enemy_factory_test.lua`(4건)를 먼저 작성해 `module 'EnemyFactory' not found`(EXIT:1) 실패를 확인함.
  - [Mid] `BasicEnemy`·`ScoutEnemy`·`TankEnemy`·`EnemyFactory`를 구현하고 `GameModel`에서 `e:takeDamage(1)`을 호출했더니, `test-runner` 실행 시 읽기 전용 `phase_test.lua:141`의 정적 검사(`남아 있는 보스 규칙: takeDamage`)가 1건 실패함.
  - [After] `EnemyModel:takeDamage`를 `EnemyModel:hit(dmg)`로 변경해 보스 규칙 식별자 충돌을 해소하고, `lua-reviewer`가 제안한 `GameModel` 이벤트 계약 주석(`enemy_hit`) 및 `enemy_factory_test.lua` 보강 테스트 2건(`waves.txt` 전 `kind` 등록 검증, `EnemyView` 색상 분기/폴백)을 추가해 전체 테스트를 통과시킴.
- 판정: 수정 후 채택
- 문제점:
  - `GameModel.lua`에 `takeDamage` 이름을 써서 `phase_test.lua`의 보스 규칙 잔존 정적 검사를 깨뜨렸고, `enemy_hit` 이벤트 주석 및 View/`waves.txt` 연동 테스트가 초기에 누락됨.
- 다음 프롬프트에서 바꾼 점: 읽기 전용 테스트의 정적 검사 키워드와 겹치지 않도록 `EnemyModel:hit(dmg)`로 명명하고, 리뷰에서 지적된 계약 주석·테스트를 커밋 전 즉시 보강함.

## 검증
- TDD 수정 전 실패 확인:
  - `lua project\tests\enemy_factory_test.lua src`: `module 'EnemyFactory' not found` (exit 1)
- 중간 실패(Before) → 수정(After):
  - Before: `phase_test.lua` 통과 8 / 실패 1 (`남아 있는 보스 규칙: takeDamage`)
  - After: `EnemyModel:hit(dmg)`로 변경 후 전체 통과
- 최종 테스트 결과 (`lua` / `luac`):
  - `lua layer_check.lua src`: 파일 33개 검사, 위반 0건
  - `lua phase_test.lua src`: 통과 9 / 실패 0
  - `lua scene_test.lua src`: 통과 19 / 실패 0
  - `lua wave_parser_test.lua src`: 통과 10 / 실패 0
  - `lua enemy_factory_test.lua src`: 통과 6 / 실패 0
  - `luac -l -p` (`project/src/**/*.lua` 35개 파일): 컴파일 에러 0건, `SETGLOBAL`/`SETTABUP` 0건
- `lua-reviewer` 리뷰: `커밋 가능` (높음 0건, 중간 1건·낮음 1건 보강 완료)
- LÖVE 실행 확인(3종 적 색상 및 Tank 2발 격파 시각 확인): (사용자 직접 LÖVE 실행 확인 필요)

## 회고
- AI 에 맡긴 것 / 내가 직접 한 것: R3 클래스 계층·Factory 구현, `test-runner`/`lua-reviewer` 검증 및 `takeDamage` 충돌 수정은 AI가 수행했고, 회차 범위 결정과 계획 승인은 내가 결정함.
- 다음에 프롬프트를 다르게 쓸 점: R4에서도 기존 읽기 전용 테스트(`phase_test.lua`, `wave_parser_test.lua`)의 스폰 좌표·보스 규칙 정적 검사를 깨지 않도록 테스트 통과를 바로 확인할 것.

## 인계 메모 (다음 세션 첫 프롬프트에 붙여넣기)
1) 완료: R3 완료 — `BasicEnemy`/`ScoutEnemy`/`TankEnemy`(`class(EnemyModel)` 상속), `EnemyFactory`(등록표 + `register`/`create`/`has`, 미등록 종류 에러), `EnemyModel:hit(dmg)`, `GameModel`·`EnemyView`·`waves.txt` 연동, `enemy_factory_test.lua` 6건 통과.
2) 바뀐 파일: `project/src/models/{EnemyModel,BasicEnemy,ScoutEnemy,TankEnemy,EnemyFactory,GameModel}.lua`, `project/src/views/EnemyView.lua`, `project/src/waves.txt`, `project/tests/enemy_factory_test.lua`, `worklogs/004_2026-11-27_r3_enemy_factory.md`.
3) 정한 규칙: `GameModel.lua`에는 `phase_test.lua` 정적 검사 금지어(`takeDamage` 등)를 쓰지 않으며, 적 피격은 `e:hit(1)`로 처리.
4) 남은 문제: LÖVE 창 시각 확인 필요, R4~R7 미구현.
5) 다음 태스크: R3 커밋 후 **R4(적 AI 4상태 `enter` → `formation` → `dive` → `return`, Model 내부 전이 + 주입된 `rng` 결정성)** 진행.
