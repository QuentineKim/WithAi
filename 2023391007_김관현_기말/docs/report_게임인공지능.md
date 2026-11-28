# [게임인공지능(3A)] 기말과제 보고서 (최종: 기준선 + R1~R7 + 연출·전투 업그레이드)

- **출발 코드**: 선택 B — `lua_tuto/mvc/week05/examples/galaga_states`
- **현재 진행 상태**: 기준선 및 **필수 요건 R1~R7 전체 완료** (`HelpScene`, `WaveParser`, 적 4종·`EnemyFactory`, `EnemyAI` 4상태, 업적 3종 `AchievementModel`, `HighScoreModel`, R7 `SniperEnemy` 번짐 실측) + Decorator(`WeaponDecorator`)/Graze·Overdrive/감쇠 사인파 유도탄/보스 광폭화·레이저 완료

---

## 3-1. 출처 표

| 파일 / 기능 | 출처 | 수정 정도 |
|---|---|---|
| `project/src/` 기본 프레임워크 (`GameModel`, `FormationPhase`, `BossPhase`, `SceneStack`, `Title/Play/Pause/ResultScene`, Views, `InputController`, `main.lua`, `conf.lua`) | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/galaga_states`) | R1(`HelpScene`), R2(`WaveParser`), R3(`EnemyFactory`), R4(`EnemyAI`), R5(`AchievementModel`·`EffectsView`), R6(`HighScoreModel`·`ResultScene`·`ResultView`), R7(`EnemyView` 색상 1줄), 유도탄·Graze/파워업·보스 광폭화/레이저 연결부 추가 |
| `project/tests/helper.lua`, `layer_check.lua`, `phase_test.lua`, `scene_test.lua` | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/tests`) | `helper.lua`·`scene_test.lua`에 R1(`HelpScene`) 테스트 3건 추가 (`equivalence_test.lua` 제외) |
| `project/src/scenes/HelpScene.lua`, `project/src/views/HelpView.lua` | AI 협업 작성 (R1 신규) | 신규 작성 |
| `docs/waves_format.md`, `project/src/waves.txt`, `project/src/models/WaveParser.lua`, `project/tests/wave_parser_test.lua` | AI 협업 작성 (R2 신규) | 신규 작성 |
| `project/src/models/{BasicEnemy,ScoutEnemy,TankEnemy,EnemyFactory}.lua`, `project/tests/enemy_factory_test.lua` | AI 협업 작성 (R3 신규) | 신규 작성 |
| `project/src/models/EnemyAI.lua`, `project/tests/enemy_ai_test.lua` | AI 협업 작성 (R4 신규) | 신규 작성 |
| `project/src/models/AchievementModel.lua`, `project/tests/achievement_test.lua` | AI 협업 작성 (R5 신규) | 신규 작성 |
| `project/src/models/HighScoreModel.lua`, `project/src/models/WeaponDecorator.lua`, `project/src/views/StarfieldView.lua`, `project/tests/{highscore,homing,powerup_graze,boss_enrage}_test.lua` | AI 협업 작성 (R6 + 게임플레이 업그레이드 신규) | 신규 작성 |
| `project/src/models/SniperEnemy.lua` | AI 협업 작성 (R7 신규) | 신규 작성 |

---

## 3-2. 적 AI 상태 설계

### 진행 단계 FSM (`GameModel.phase`)
| 현재 상태 | 조건 | 다음 상태 | 구현 위치 (`파일:줄`) |
|---|---|---|---|
| `formation` | `game.score >= 1000` | `boss` | `project/src/models/FormationPhase.lua:23-27` |
| `boss` | `boss:takeDamage(1)` 결과 격파 | `game.state = "won"` | `project/src/models/BossPhase.lua:42-46` |

### 적 개별 AI FSM (`EnemyModel.aiState` → `EnemyAI`)
| 현재 상태 | 조건 | 다음 상태 | 구현 위치 (`파일:줄`) |
|---|---|---|---|
| `enter` | `e.stateTimer <= 0` (`ENTER_DURATION = 0.35s` 경과) | `formation` | `project/src/models/EnemyAI.lua:14-22` |
| `formation` | `stateTimer <= 0` (`0.8s` 주기) 및 주입 `ctx.rng:range(4) == 1` | `dive` | `project/src/models/EnemyAI.lua:24-52` |
| `dive` | `e.y > ctx.height` (화면 하단 통과) | `return` | `project/src/models/EnemyAI.lua:54-65` |
| `return` | `dist(e, home) <= RETURN_SPEED * dt` (편대 자리 도달) | `formation` | `project/src/models/EnemyAI.lua:67-81` |

- **상태 기계 공유 방식**: `BasicEnemy`/`ScoutEnemy`/`TankEnemy`/`SniperEnemy`는 모두 `EnemyAI.STATES` 테이블을 공유하고, 각 적 인스턴스가 독립적인 `aiState`·`stateTimer`·`homeX`/`homeY`·`diveVx`/`diveVy`와 종별 `diveSpeed`(`basic` 190 / `scout` 270 / `tank` 140 / `sniper` 340)만 보관합니다.
- **결정성 검증 테스트**: `project/tests/enemy_ai_test.lua` — `"결정성: 같은 seed 로 300스텝 실행 시 모든 적의 위치와 aiState 가 완전 동일"`

---

## 3-3. 패턴 적용표

| 패턴 | 이 패턴이 없었다면 생기는 증상 | 참여 객체 (`파일:줄`) | 대안 패턴과 고르지 않은 이유 |
|---|---|---|---|
| **State (스택 FSM — 앱 씬)** | 타이틀/플레이/도움말/일시정지/결과 화면 분기가 `main.lua`와 `InputController` 전체에 `if state == ...`로 퍼지고, 일시정지 복귀 시 게임 상태를 수동 백업해야 함 | `SceneStack` (`project/src/scenes/SceneStack.lua:11-103`), `TitleScene`, `HelpScene`, `PlayScene`, `PauseScene`, `ResultScene` | 단일 `switch` 기반 단순 FSM: 일시정지나 도움말 진입 시 아래 씬이 `exit`되어 상태를 보존하기 어렵고 복귀할 때마다 씬을 다시 생성해야 하므로 스택 FSM(`push`/`pop`)을 사용 |
| **State (진행 단계 FSM)** | 편대 유지 조건과 보스전 등장·이동·피격 규칙이 `GameModel:update` 내부 4~5곳에 흩어져 새 웨이브/단계 추가가 어려움 | `GameModel` (`project/src/models/GameModel.lua:90-92,202`), `FormationPhase`, `BossPhase` | 플래그 기반 조건 분기(`if bossSpawned ...`): 단계가 늘수록 조건문이 기하급수적으로 증가하고 단계별 테스트가 불가능해 State 객체로 분리 |
| **Factory Method (등록표)** | `GameModel:spawnFormation`에 `if kind == "basic" ... elseif kind == "scout" ...` 분기가 늘어 새 적 추가 시 `GameModel`을 매번 수정해야 함 | `EnemyFactory` (`project/src/models/EnemyFactory.lua:16-61`), `BasicEnemy`, `ScoutEnemy`, `TankEnemy`, `SniperEnemy`, `GameModel:spawnFormation` (`project/src/models/GameModel.lua:95-110`) | 직접 생성 분기(`if/elseif`): R7에서 새 적 1종 추가 시 `GameModel`까지 번짐이 발생하므로 등록표 기반 Factory로 분리 |
| **State (적 개별 AI FSM)** | 적 1기마다 진입·편대·돌격·복귀 플래그(`isDiving`, `isReturning`, `entered`)가 얽혀 잘못된 조합 상태가 생기고 전이 추적이 어려움 | `EnemyAI` (`project/src/models/EnemyAI.lua:14-103`), `EnemyModel:update` (`project/src/models/EnemyModel.lua:41-43`), `GameModel:_updateEnemies` (`project/src/models/GameModel.lua:244-253`) | 적마다 별도 상태 객체 인스턴스 생성(new State per enemy): 60Hz 루프에서 전이마다 테이블을 생성하면 GC 부담이 커지므로 상태 함수 테이블(`STATES`)은 공유하고 상태 값만 인스턴스에 저장 |
| **Observer (이벤트 구독)** | `GameModel`의 발사·피격·보스 처치 코드 안에 업적 조건 검사와 View 알림 호출이 직접 섞여 `GameModel`이 비대해지고 업적 추가 시마다 게임 규칙 코드를 고쳐야 함 | `AchievementModel` (`project/src/models/AchievementModel.lua:19-95`), `PlayScene` (`project/src/scenes/PlayScene.lua:27-30,45-50`), `EffectsView` (`project/src/views/EffectsView.lua:150-157,240-264`) | `GameModel` 직접 폴링/직접 호출: `GameModel`이 업적 모델·알림 뷰에 직접 의존하게 되므로 `drainEvents()`와 `subscribe()` 기반 단방향 Observer로 분리 |
| **Decorator (무기 강화 조합, 가산점)** | 기본 단발·3갈래 산탄(`Spread`)·오버드라이브 연사 2배(`Rapid`) 조합마다 `if spread and overdrive ... elseif spread ...` 분기와 중복 탄환 생성 코드가 기하급수적으로 늘어남 | `WeaponDecorator` (`project/src/models/WeaponDecorator.lua:12-78`: `BaseWeapon`, `SpreadDecorator`, `RapidDecorator`), `GameModel` (`project/src/models/GameModel.lua:51-53,160-165`) | 상속 서브클래스 조합(`SpreadRapidWeapon` 등): 효과가 하나 늘 때마다 클래스가 2^n개로 폭증하므로 동일 인터페이스(`cooldown()`, `fire()`)를 감싸는 Decorator로 합성 |
| **의존성 주입(`ctx`) + MVC 경계** | 씬끼리 서로 `require`해 순환 참조로 로드 실패가 나고, `love` 전역 의존 때문에 창 없이 헤드리스 테스트를 돌릴 수 없음 | `main.lua` (`project/src/main.lua:46-62`), `PlayScene`, `InputController` | 전역 싱글톤/직접 `require`: 순환 `require` 및 `love` 결합으로 `layer_check` 위반과 테스트 불가 문제를 유발하므로 `ctx` 테이블로 한 번에 주입 |

- **과잉 패턴 회피 사례**: `EnemyView`의 적 종류별 색상 매핑(`project/src/views/EnemyView.lua:7-12`)은 별도 View 서브클래스나 Abstract Factory로 쪼개지 않고 `COLORS[e.kind]` 단순 룩업 테이블로 유지해 불필요한 파일 증가를 피했습니다.

---

## 3-4. 설명 문항

### Q1. 일시정지는 왜 `switch`가 아니라 `push`인가요? R1에서 추가한 씬은 `push` / `switch` 중 무엇이고 왜인가요?
일시정지(`PauseScene`)를 `switch`로 전환하면 아래에 있던 `PlayScene`이 스택에서 제거(`exit`)되어 진행 중이던 적 위치·총알·점수 상태가 사라집니다. 반면 `PlayScene:keypressed`(`project/src/scenes/PlayScene.lua:53`)에서 `push`로 쌓으면 `SceneStack:update`(`project/src/scenes/SceneStack.lua:75-80`)가 맨 위 씬만 갱신하므로 아래 `PlayScene`은 상태가 살아있는 채 정지하고, `PauseScene.transparent = true`(`project/src/scenes/PauseScene.lua:10`) 덕분에 멈춘 게임 화면 위에 오버레이가 그려진 뒤 `pop()`(`project/src/scenes/PauseScene.lua:18`)만으로 즉시 재개됩니다. R1에서 추가한 `HelpScene` 역시 `TitleScene:keypressed`(`project/src/scenes/TitleScene.lua:18-19`)에서 **`push`**를 선택해 타이틀 씬을 파괴하지 않고 스택 아래에 유지한 채 `HelpScene:keypressed`(`project/src/scenes/HelpScene.lua:16-19`)의 `pop()`으로 원래 타이틀 인스턴스로 복귀하도록 했으며, `HelpScene.transparent = false`(`project/src/scenes/HelpScene.lua:10`)로 지정해 아래 타이틀 문구와 겹쳐 그려지지 않게 했습니다.

### Q2. 씬 상태와 적 AI 상태는 서로 다른 층의 상태입니다. 내 코드에서 두 층이 섞이지 않도록 어떻게 나눴는지 설명하세요.
앱 흐름 상태(타이틀·도움말·플레이·일시정지·결과)는 `project/src/scenes/` 아래 `SceneStack`(`project/src/scenes/SceneStack.lua:11-103`)과 각 `*Scene`이 담당해 화면 전환과 키 입력(`H`, `P`, `Esc`, `R`)만 처리하고, 게임 규칙·적 AI 상태는 `project/src/models/GameModel.lua`(`244-253줄`)와 `EnemyAI.lua`(`14-103줄`)가 담당해 고정 스텝 `dt`와 주입된 `rng` 위에서 결정적으로 동작합니다. 일시정지나 도움말 화면 중에는 `SceneStack:update`가 아래 `PlayScene`의 `update`를 아예 호출하지 않으므로(`project/src/scenes/PlayScene.lua:23-33`), `EnemyAI`와 `models/` 코드는 일시정지·도움말 씬의 존재를 전혀 알 필요가 없으며 `layer_check.lua`가 `models/`에서 `scenes/`를 `require`하는 것을 정적으로 차단합니다.

### Q3. R7에서 새 적 1종을 추가할 때 바뀐 파일 목록을 보고, Factory와 MVC가 없었다면 어디가 더 바뀌었을지 설명하세요.
R7(`SniperEnemy` 추가, 커밋 `26563b9`)에서 `project/src/` 아래 바뀐 코드 파일은 `models/SniperEnemy.lua`(신규), `models/EnemyFactory.lua`(4줄), `views/EnemyView.lua`(1줄), 그리고 데이터 파일 `waves.txt`(12줄 변경)뿐이며 `GameModel.lua`·`EnemyAI.lua`·`controllers/`·`scenes/`는 **단 한 줄도 바뀌지 않았습니다.** 만약 `EnemyFactory`가 없었다면 `GameModel:spawnFormation`(`project/src/models/GameModel.lua:95-110`)의 `if kind == ...` 분기와 `require` 목록을 수정해야 했고, `EnemyModel` 상속·공유 `EnemyAI`가 없었다면 `GameModel:_updateEnemies`(`244-253줄`)와 `_resolveCollisions`(`297-327줄`)의 점수·체력·돌격 분기까지 모두 번졌을 것입니다. 또한 MVC 분리가 없었다면 `main.lua`의 `love.update`와 `love.draw`에 `sniper` 전용 이동·렌더링 분기가 함께 섞여 수정 범위가 2주차 모놀리식 수준으로 커졌을 것입니다.

---

## 3-5. 번짐 실측 (R7: `before-r7`(`7f11e8b`) → `26563b9`)

| 계층 (`project/src/...`) | 변경 덩어리 (hunk 수) | 바뀐 파일 (`git diff --stat`) |
|---|---:|---|
| `models` | **3** | `SniperEnemy.lua` (신규 +19), `EnemyFactory.lua` (+4) |
| `views` | **1** | `EnemyView.lua` (+1) |
| `controllers` | **0** | 없음 |
| `scenes` | **0** | 없음 |
| **계층 합계** | **4** | *(별도 데이터/테스트: `waves.txt` 12줄, `tests/enemy_factory_test.lua` 43줄)* |

- **해석**: 새 적 `SniperEnemy` 추가 시 변경이 `models`(3 hunk)와 `views`(1 hunk)에만 국한되었고, `controllers`·`scenes`·`GameModel.lua`는 **0 hunk**로 유지되었습니다(4주차 MVC 25 hunk, 2주차 모놀리식 41 hunk 대비 극소 번짐). 이는 적 생성 책임을 `EnemyFactory`에, 공통 AI·피격 규칙을 `EnemyModel`+`EnemyAI`에, 색상 매핑을 `EnemyView.COLORS` 테이블에 격리했기 때문이며, 바뀌지 말았어야 할 제어·씬·핵심 게임 루프가 전혀 오염되지 않았습니다.

---

## 3-6. 알려진 문제와 한계
- 현재 PC 환경에 `luajit` CLI가 설치되어 있지 않아 헤드리스 테스트(80건)와 계층 검사(39개 파일)는 Lua 5.1.5(`lua`/`luac`)로 검증했습니다.
- `SniperEnemy`는 `GameModel.lua` 무수정(번짐 0)을 우선해 `EnemyModel`의 `diveSpeed = 340` 고속 돌격 차별화로 구현했으며, 추후 적 종별 특수 탄막(예: 조준 스나이퍼 탄)이 필요할 경우 `EnemyModel:fire(ctx)` 훅을 도입하면 `GameModel` 분기 없이 확장할 수 있습니다.
