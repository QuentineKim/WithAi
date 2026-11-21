# [게임인공지능(3A)] 기말과제 보고서 (초안: 기준선 + R1)

- **출발 코드**: 선택 B — `lua_tuto/mvc/week05/examples/galaga_states`
- **현재 진행 상태**: 기준선 세팅 및 R1(`HelpScene`) 완료 (R2~R7 구현 후 보완 예정)

---

## 3-1. 출처 표

| 파일 / 기능 | 출처 | 수정 정도 |
|---|---|---|
| `project/src/` 기본 프레임워크 (`GameModel`, `FormationPhase`, `BossPhase`, `SceneStack`, `Title/Play/Pause/ResultScene`, Views, `InputController`, `main.lua`, `conf.lua`) | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/galaga_states`) | `main.lua`, `TitleScene.lua`, `TitleView.lua`에 R1 연결부만 최소 추가, 나머지 무수정 |
| `project/tests/helper.lua`, `layer_check.lua`, `phase_test.lua`, `scene_test.lua` | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/tests`) | `helper.lua`·`scene_test.lua`에 R1(`HelpScene`) 테스트 3건 추가 (`equivalence_test.lua` 제외) |
| `project/src/scenes/HelpScene.lua`, `project/src/views/HelpView.lua` | AI 협업 작성 (R1 신규) | 신규 작성 |

---

## 3-2. 적 AI 상태 설계 (R4 구현 후 보완 예정)

현재 출발 코드에서는 게임 진행 단계를 `FormationPhase`와 `BossPhase` 두 상태로 분리해 `GameModel.phase`에 위임하고 있습니다.

| 현재 상태 | 조건 | 다음 상태 | 구현 위치 (`파일:줄`) |
|---|---|---|---|
| `formation` | `game.score >= 1000` | `boss` | `project/src/models/FormationPhase.lua:23-27` |
| `boss` | `boss:takeDamage(1)` 결과 격파 | `game.state = "won"` | `project/src/models/BossPhase.lua:42-46` |

- **추후 R3/R4 보완 예정**: 적 종류별 3개 이상 AI 상태(예: 진입/편대/돌격/복귀), 적 클래스 간 상태 기계 공유 여부 및 `rng` 주입 기반 결정성 테스트 이름 기록.

---

## 3-3. 패턴 적용표 (현재 3행 + R3~R6 구현 시 추가 예정)

| 패턴 | 이 패턴이 없었다면 생기는 증상 | 참여 객체 (`파일:줄`) | 대안 패턴과 고르지 않은 이유 |
|---|---|---|---|
| **State (스택 FSM — 앱 씬)** | 타이틀/플레이/도움말/일시정지/결과 화면 분기가 `main.lua`와 `InputController` 전체에 `if state == ...`로 퍼지고, 일시정지 복귀 시 게임 상태를 수동 백업해야 함 | `SceneStack` (`project/src/scenes/SceneStack.lua:11-103`), `TitleScene` (`project/src/scenes/TitleScene.lua:8-29`), `HelpScene` (`project/src/scenes/HelpScene.lua:8-26`), `PlayScene`, `PauseScene`, `ResultScene` | 단일 `switch` 기반 단순 FSM: 일시정지나 도움말 진입 시 아래 씬이 `exit`되어 상태를 보존하기 어렵고 복귀할 때마다 씬을 다시 생성해야 하므로 스택 FSM(`push`/`pop`)을 사용 |
| **State (진행 단계 FSM)** | 편대 유지 조건과 보스전 등장·이동·피격 규칙이 `GameModel:update` 내부 4~5곳에 흩어져 새 웨이브/단계 추가가 어려움 | `GameModel` (`project/src/models/GameModel.lua:56-64,139,151-152`), `FormationPhase` (`project/src/models/FormationPhase.lua:14-41`), `BossPhase` (`project/src/models/BossPhase.lua:8-52`) | 플래그 기반 조건 분기(`if bossSpawned ...`): 단계가 늘수록 조건문이 기하급수적으로 증가하고 단계별 테스트가 불가능해 State 객체로 분리 |
| **의존성 주입(`ctx`) + MVC 경계** | 씬끼리 서로 `require`해 순환 참조로 로드 실패가 나고, `love` 전역 의존 때문에 창 없이 헤드리스 테스트를 돌릴 수 없음 | `main.lua` (`project/src/main.lua:24-37`), `PlayScene` (`project/src/scenes/PlayScene.lua:15-21`), `InputController` (`project/src/controllers/InputController.lua:19-24`) | 전역 싱글톤/직접 `require`: 순환 `require` 및 `love` 결합으로 `layer_check` 위반과 테스트 불가 문제를 유발하므로 `ctx` 테이블로 한 번에 주입 |

*(추후 R3 Factory Method, R4 적 AI State, R5 Observer/이벤트 구독 및 과잉 패턴 회피 사례 1곳 추가 예정)*

---

## 3-4. 설명 문항

### Q1. 일시정지는 왜 `switch`가 아니라 `push`인가요? R1에서 추가한 씬은 `push` / `switch` 중 무엇이고 왜인가요?
일시정지(`PauseScene`)를 `switch`로 전환하면 아래에 있던 `PlayScene`이 스택에서 제거(`exit`)되어 진행 중이던 적 위치·총알·점수 상태가 사라집니다. 반면 `PlayScene:keypressed`(`project/src/scenes/PlayScene.lua:53`)에서 `push`로 쌓으면 `SceneStack:update`(`project/src/scenes/SceneStack.lua:75-80`)가 맨 위 씬만 갱신하므로 아래 `PlayScene`은 상태가 살아있는 채 정지하고, `PauseScene.transparent = true`(`project/src/scenes/PauseScene.lua:10`) 덕분에 멈춘 게임 화면 위에 오버레이가 그려진 뒤 `pop()`(`project/src/scenes/PauseScene.lua:18`)만으로 즉시 재개됩니다. R1에서 추가한 `HelpScene` 역시 `TitleScene:keypressed`(`project/src/scenes/TitleScene.lua:18-19`)에서 **`push`**를 선택해 타이틀 씬을 파괴하지 않고 스택 아래에 유지한 채 `HelpScene:keypressed`(`project/src/scenes/HelpScene.lua:16-19`)의 `pop()`으로 원래 타이틀 인스턴스로 복귀하도록 했으며, `HelpScene.transparent = false`(`project/src/scenes/HelpScene.lua:10`)로 지정해 아래 타이틀 문구와 겹쳐 그려지지 않게 했습니다.

### Q2. 씬 상태와 적 AI 상태는 서로 다른 층의 상태입니다. 내 코드에서 두 층이 섞이지 않도록 어떻게 나눴는지 설명하세요.
앱 흐름 상태(타이틀·도움말·플레이·일시정지·결과)는 `project/src/scenes/` 아래 `SceneStack`(`project/src/scenes/SceneStack.lua:11-103`)과 각 `*Scene`이 담당해 화면 전환과 키 흐름(`H`, `P`, `Esc`, `R`)만 처리하고, 게임 규칙 상태는 `project/src/models/GameModel.lua`(`56-64,139,151-152줄`)와 `*Phase`가 담당해 고정 스텝 `dt` 위에서 결정적으로 동작합니다. 일시정지나 도움말 화면 중에는 `SceneStack:update`가 아래 `PlayScene`의 `update`를 아예 호출하지 않으므로(`project/src/scenes/PlayScene.lua:23-33`), `models/` 안의 코드는 일시정지·도움말 씬의 존재를 전혀 알 필요가 없습니다. *(R4 적 AI 상태 구현 후 해당 모델 줄 번호 보완 예정)*

### Q3. R7에서 새 적 1종을 추가할 때 바뀐 파일 목록을 보고, Factory와 MVC가 없었다면 어디가 더 바뀌었을지 설명하세요.
*(R7 번짐 실측 완료 후 작성 예정)*

---

## 3-5. 번짐 실측 (R7 완료 후 작성 예정)

*(R1~R6 완료 후 `git tag before-r7` → 새 적 1종 추가 후 계층별 hunk 수 실측 기록 예정)*

---

## 3-6. 알려진 문제와 한계
- 현재까지 **기준선 + R1(`HelpScene`)**만 구현되었으며, R2~R7 기능 및 신규 테스트(10개 이상 중 3개 완료)는 후속 세션에서 진행 예정입니다.
- 현재 PC 환경에 `luajit` CLI가 설치되어 있지 않아 헤드리스 테스트와 계층 검사는 Lua 5.1.5(`lua`)로 검증했습니다.
