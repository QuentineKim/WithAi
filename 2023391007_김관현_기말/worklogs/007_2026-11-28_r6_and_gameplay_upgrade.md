# 작업 로그 007 — R6 하이스코어 저장/복원 + 게임플레이·연출 업그레이드 (Steps A~E)

- **날짜**: 2026-11-28
- **사용 도구**: Antigravity (Gemini + `test-runner` / `lua-reviewer` 서브에이전트)
- **연관 커밋**: `(커밋 전)`

---

## 1. 이번 세션의 목표
- **R6 (하이스코어 저장/불러오기)**: 순수 Lua 직렬화/역직렬화(`HighScoreModel`) + `main.lua` 파일 I/O 격리 + 깨진 문자열 `pcall` 복구 + `ResultScene`/`ResultView` 표시.
- **게임 재미·차별점 업그레이드 (Steps B~E)**:
  - **Step B**: 3층 패럴랙스 우주 배경 + 보스/오버드라이브 워프(`StarfieldView`).
  - **Step C**: 감쇠 사인파 사행 + 각속도 제한 트윈 유도 미사일(`homing.wrapPi`, `homing.steerWave`, 8점 네온 궤적).
  - **Step D**: 스침(Graze) 피버 & 5초 오버드라이브 + 돌격 격추 2배 점수/파워업 드롭(`spread`/`shield`/`slow`) + **Decorator 패턴**(`WeaponDecorator`).
  - **Step E**: 보스 2페이즈 광폭화(HP ≤ 50%) + 경고선(`DANGER`)→레이저 빔(`BossModel`, `BossPhase`, `BossView`).
- **제외 범위**: Step F(R7 새 적 추가 및 `before-r7` 번짐 실측)는 커밋·태그 후 다음 세션에서 진행.

---

## 2. 사용한 프롬프트 (원문 그대로)

1.
> 내 게임이 너무 정석적이고 지루하고 현학적이야 좀 더 재미요소나 차별점을 추가할 만한게 있을까?

2.
> 다 넣어보고 싶고 추가적으로 유도탄을 좀 더 수학적으로 재밌는 움직임을 줄 수 있지 않을까? 이거 포함해서 설계해봐

3.
> f 빼고 나머지 진행해봐

---

## 3. TDD 및 리뷰에서 잡은 오류 (Before → After)

### ① TDD 실패 먼저 확인 (Red → Green)
- 구현 전 4개 테스트 파일(`highscore_test.lua`, `homing_test.lua`, `powerup_graze_test.lua`, `boss_enrage_test.lua`)을 먼저 작성해 실행했을 때 `module 'HighScoreModel' not found`, `attempt to call field 'wrapPi' (a nil value)` 등으로 실패(`EXIT:1`)함을 확인한 뒤 구현을 진행했다.

### ② `lua-reviewer` 리뷰 지적 수정 (높음 1건 + 중간 3건 + 낮음 1건)
- **Before (높음 — Lua 5.1 구멍 테이블 `#` 함정)**: `tests/highscore_test.lua:31-41`의 `badInputs` 배열 1번 인덱스에 `nil`을 넣어 배열에 구멍이 생겼고, Lua 5.1/LuaJIT에서 `#badInputs` 길이가 불확정해질 수 있는 위험이 지적됐다.
  - **After**: `nil` 입력은 별도 검증(`HighScoreModel.deserialize(nil)`)으로 분리하고 나머지 비-`nil` 입력만 배열로 순회하도록 수정.
- **Before (중간 — 동일 프레임 상태 덮어쓰기/중복 피격)**:
  - `BossPhase:resolveCollisions` 진입부에 `game.state ~= "playing"` 가드가 없어 같은 스텝에 `gameover` 후 `won` 덮어쓰기나 레이저 추가 피격 가능성이 있었고, `GameModel:_resolveCollisions`의 적 탄환 충돌 루프도 `lives <= 0` 직후 `break`가 없었다.
  - **After**: `BossPhase:resolveCollisions` 진입부 및 레이저 판정부에 `game.state == "playing"` 가드 추가 + `beam` 임시 테이블 할당 제거(직접 좌표 비교), `GameModel.lua` 적 탄환 사망 직후 `break` 추가.
- **Before (중간 — `BossView` 높이 하드코딩 및 폭 폴백 불일치)**: `BossView.lua`가 `800`을 하드코딩하고 `laserW` 폴백이 `36`(`BossModel`은 `28`)이었다.
  - **After**: `BossView.draw(gfx, boss, width, height)`로 `height`(기본 `800`)를 받아 사용하고 `GameView.lua`에서 `self.height` 전달, 폴백 폭을 `28`로 통일.
- **Before (낮음 — 60Hz GC 핫스팟)**: `homing.steerWave`에서 `opts = opts or {}`가 매 스텝 빈 테이블을 할당했다.
  - **After**: 모듈 상단에 `local DEFAULT_OPTS = {}`를 캐싱해 재사용.

---

## 4. 변경·신규 파일 요약
- **신규 Model/View**: `project/src/models/HighScoreModel.lua`, `project/src/models/WeaponDecorator.lua`, `project/src/views/StarfieldView.lua`
- **수정 Model**: `project/src/models/homing.lua`, `project/src/models/BulletModel.lua`, `project/src/models/BossModel.lua`, `project/src/models/BossPhase.lua`, `project/src/models/GameModel.lua`
- **수정 Scene/View/Root**: `project/src/main.lua`, `project/src/scenes/ResultScene.lua`, `project/src/views/{ResultView,GameView,BulletView,PlayerView,HudView,BossView,EffectsView}.lua`
- **신규 테스트**: `project/tests/{highscore_test,homing_test,powerup_graze_test,boss_enrage_test}.lua`
- **문서 갱신**: `docs/report_게임시스템설계.md`(Q3 및 매핑표), `docs/report_게임인공지능.md`(3-3 Decorator 행), `README.md`, `TODO.md`

---

## 5. 검증 결과
- `luac -l -p` (`project/src/**/*.lua` 전체): `SETGLOBAL: 0`
- `lua tests/layer_check.lua src`: **38개 파일 검사, 계층 규칙 위반 0건**
- 단위 테스트 10개 스크립트 전체 통과 (**79건 통과 / 0건 실패**, `FAILED_SCRIPTS: 0`):
  - `phase_test.lua` (9/9), `scene_test.lua` (19/19), `wave_parser_test.lua` (10/10), `enemy_factory_test.lua` (6/6), `enemy_ai_test.lua` (6/6), `achievement_test.lua` (8/8)
  - `highscore_test.lua` (6/6), `homing_test.lua` (4/4), `powerup_graze_test.lua` (6/6), `boss_enrage_test.lua` (5/5)
- LÖVE 11.5 창 실행 시각 확인: `(사용자 직접 LÖVE 실행 확인 필요)` — `run.bat` 또는 `Love2D: Run project` 태스크로 패럴랙스 우주·트윈 유도탄 궤적·Graze/Overdrive·보스 레이저·결과 화면 `BEST / NEW!` 확인 필요.

---

## 6. 다음 세션용 인계 메모
1. LÖVE 11.5로 직접 실행해 R5~R6 + 게임플레이 업그레이드 연출을 확인한 뒤, 현재 변경분을 커밋한다.
2. 커밋 직후 `git tag before-r7` 태그를 생성한다.
3. 다음 세션에서 **R7 (새 기믹 적 1종 추가 + 계층별 hunk 번짐 실측)** 및 `layer_check` 경계 위반 거절 기록 1건, 최종 회고(`worklogs/999_retrospective.md`), `docs/git_log.txt` 생성을 진행한다.
