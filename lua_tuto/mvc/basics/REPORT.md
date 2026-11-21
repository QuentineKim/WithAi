# MVC 퀴즈 과제 보고서 (`06_dungeon`)

- **학번 / 이름**: 2023391007 / 김관현
- **대상**: `lua_tuto/mvc/basics/06_dungeon`

---

## ① 파일 변경표

| 구분 | 파일 경로 | 변경 내용 요약 | 기존 메서드 수정 여부 |
|---|---|---|---|
| 신규 | `06_dungeon/models/kill_list_model.lua` | `EventBus`의 `enemy_killed`를 구독해 처치한 적 이름 목록(`kills`) 저장 | 해당 없음 (신규) |
| 신규 | `06_dungeon/views/kill_list_view.lua` | 처치 목록 패널 출력 (`(없음)` 또는 `목록 (총 N마리)`) | 해당 없음 (신규) |
| 신규 | `06_dungeon/models/achievement_model.lua` | `EventBus`만 구독해 처치 골드 누적 및 기준(`goldGoal`) 도달 시 `achievement_unlocked` 1회 발행 | 해당 없음 (신규) |
| 신규 | `06_dungeon/controllers/shop_controller.lua` | 상점 모드(`shop`) 입력 해석 (`b`: 구매, `l`: 나가기) | 해당 없음 (신규) |
| 수정 | `06_dungeon/data/dungeon_data.lua` | `goldAchievementGoal = 15` 추가, 출구 직전 `shop` 방 추가, `"아이템 2번 사용"` 퀘스트 추가 (기존 `explorer` 퀘스트는 `needed = 7` 유지) | 없음 (데이터 테이블만 수정) |
| 수정 | `06_dungeon/models/player_model.lua` | 골드 차감용 새 메서드 `PlayerModel:spendGold(amount)` 추가 | **없음** (새 메서드만 추가) |
| 수정 | `06_dungeon/models/game_model.lua` | `GameModel.new()` 생성자에 `killList`/`achievements` 생성 및 `room_entered` 상점 전환 구독 추가, 새 메서드 `buyPotion()`·`leaveShop()` 추가 | **없음** (생성자 확장 + 새 메서드 추가) |
| 수정 | `06_dungeon/views/log_view.lua` | `FORMAT` 테이블에 `achievement_unlocked`, `shop_entered`, `item_bought`, `shop_left` 문구 추가 | **없음** (`FORMAT` 테이블만 확장) |
| 수정 | `06_dungeon/views/command_view.lua` | `COMMANDS` 테이블에 `shop` 안내 문구 추가 | **없음** (`COMMANDS` 테이블만 확장) |
| 수정 | `06_dungeon/main.lua` | `KillListView`·`ShopController` 조립, `layouts.explore`/`shop`/`default` 등록, 자동 시연 `script`에 상점 입력(`"n", "b", "l"`) 추가 | **없음** (조립 설정 및 시연 스크립트만 확장) |
| 수정 | `tests/dungeon_test.lua` | 디커플링·전역 오염(`_G`) 검사 강화 및 문제 1~4 단위·통합·라우팅 테스트 추가 | 기존 테스트 유지 + `[5]` 섹션 추가 |

---

## ② 핵심 프롬프트

1. **초기 요구사항 및 규칙 제약 프롬프트**
   - `mvc/basics/06_dungeon` 대상으로 ① 데이터 기반 "아이템 2번 사용" 퀘스트, ② `KillListModel`+`KillListView`, ③ `GameModel`·`PlayerModel` 비의존 골드 15 누적 업적, ④ 출구 앞 상점 방 + `ShopController`(`b`/`l`, 실패 이유 표시) 구현.
   - 전역 변수 금지, 기존 메서드 수정 금지(새 메서드·생성자만 허용), 테스트·자동 시연 통과, diff 검증 조건 부여.
2. **설계 검증 및 리스크 점검 프롬프트**
   - 계획 검토 중 기존 `explorer` 퀘스트(`needed = 7`) 변경 시 불필요한 수정/위반 여지가 없는지 재확인하고, 잠재적 위험요소(기존 테스트 최소 데이터 호환성, 구매 실패 시 골드 차감 원자성, 상점 데이터 생략 시 기본값 등)를 사전 분석.
3. **구현·검증 실행 프롬프트**
   - 신규 파일 생성과 기존 파일 최소 변경 후 `dungeon_test.lua`, `main.lua` 자동 시연, `git diff`를 한 번에 확인하여 규칙 위반 여부 검증.

---

## ③ AI 실수 사례 (계획 점검 및 `git diff` 확인)

1. **불필요한 기존 데이터 수정 시도 (계획 단계에서 사용자 피드백으로 수정)**
   - **문제**: 초기 계획에서 출구 앞에 상점 방이 추가되어 총 방 수가 7개 → 8개가 되므로, `dungeon_data.lua`의 기존 `explorer` 퀘스트(`"방 7개 탐험"`, `needed = 7`)도 `8`로 바꿀지 검토했습니다.
   - **원인 및 교정**: 사용자가 기존 규칙/퀘스트를 불필요하게 건드리지 않는 편이 맞는지 지적했고, 다시 확인한 결과 `needed = 7`을 유지해도 7번째 방(상점 방) 진입 시 정상 완료되므로 기존 `explorer` 퀘스트는 수정하지 않고 그대로 두도록 계획을 수정했습니다.
2. **상점 방 진입 처리 시 `GameModel:explore()` 수정 유혹 회피**
   - **주의점**: 일반적인 구현이라면 `GameModel:explore()` 내부의 `if room.kind == "enemy" ... elseif room.kind == "item" ...` 분기에 `elseif room.kind == "shop"`을 추가하기 쉽습니다.
   - **해결 (`git diff`로 검증)**: "기존 메서드 수정 금지" 규칙을 지키기 위해 `explore()` 본문은 한 줄도 수정하지 않고, 허용된 생성자 `GameModel.new()` 안에서 `room_entered` 이벤트를 구독해 `room.kind == "shop"`일 때 `self.mode = "shop"` 전환 및 `shop_entered` 발행을 처리했습니다.
3. **사전 방어한 잠재 오류**
   - **기존 테스트 호환성**: 기존 `dungeon_test.lua`의 `newGame()`은 `goldAchievementGoal`이나 상점 방의 `price`/`item` 필드를 넘기지 않으므로 `AchievementModel.new()`와 `GameModel:buyPotion()`에 기본값(`15`, `5`, 회복 물약)을 두어 기존 56개 테스트가 깨지지 않게 처리했습니다.
   - **구매 원자성**: `buyPotion()`에서 `spendGold()`를 먼저 호출한 뒤 `inventory:add()`가 실패하면 골드만 빠져나갈 수 있으므로, 골드 부족·가방 가득 여부를 먼저 검사하고 추가 실패 시 골드를 복구하도록 구현했습니다.

---

## ④ 테스트 전/후 결과

### 1) 작업 전 (기준선)
- **`lua lua_tuto/mvc/basics/tests/dungeon_test.lua`**
  - 결과: **`56 통과, 0 실패`** (exit code `0`)
- **`lua lua_tuto/mvc/basics/06_dungeon/main.lua`**
  - 결과: 7/7번 방 도달, 골드 18, 3개 퀘스트 완료, `VICTORY — 아무 키나 입력하면 종료`

### 2) 작업 후
- **`lua lua_tuto/mvc/basics/tests/dungeon_test.lua`**
  - 결과: **`85 통과, 0 실패`** (exit code `0`)
  - 추가 검증 항목(29개):
    - `[0]` 신규 파일(`kill_list_model.lua`, `achievement_model.lua`, `shop_controller.lua`) `print`/`io`/`love` 미사용 검사, `AchievementModel`의 `GameModel`·`PlayerModel` 비의존 검사, 로드 시점 및 실행 종료 시점 `_G` 전역 변수 오염 없음 검사
    - `[5]` 문제 1(`dungeon_data.lua` `item_used` 2회 퀘스트 완료), 문제 2(`KillListModel` 단독 및 `KillListView` 빈 상태/처치 후 출력), 문제 3(`AchievementModel` 단독 14→15→35 1회 달성 및 로그 업적 출력), 문제 4(상점 진입, 골드 부족/가방 가득 실패 이유 및 골드 미차감, 구매 성공, `ShopController` `b`/`l`/오입력 라우팅, 상점 퇴장 후 출구 승리)
- **`lua lua_tuto/mvc/basics/06_dungeon/main.lua` 자동 시연**
  - 처치 목록 변화: `(없음)` → `슬라임 (총 1마리)` → `슬라임, 고블린 (총 2마리)` → `슬라임, 고블린, 오크 (총 3마리)`
  - 오크 처치 시(누적 처치 골드 18 >= 15): `★ 업적 달성: 처치 골드 15 이상 달성` 로그 1회 출력
  - 7/8번 방 상점 진입 → `b` 입력 시 `회복 물약 을(를) 5골드에 구매했다.` (골드 18 → 13, 가방 `회복 물약  1/4`) → `l` 입력 시 `상점을 나왔다.` → `n` 입력 시 8/8번 방 출구 `출구를 찾았다! 총 골드 13` 및 `VICTORY — 아무 키나 입력하면 종료` (exit code `0`)
  - 4개 퀘스트 모두 `[v]` 완료 (`몬스터 3마리 처치`, `아이템 2개 줍기`, `방 7개 탐험`, `아이템 2번 사용`)
- **`git diff -- lua_tuto/mvc/basics/06_dungeon/` 확인**
  - 기존 메서드(`explore`, `attack`, `flee`, `useItem`, `lines` 등) 본문 수정 0건, 전역 변수 선언 0건 확인.

---

## ⑤ 설명

### Q1. 퀘스트 진행도가 오르는 원리
`dungeon_data.lua`의 `quests` 테이블에는 각 퀘스트가 반응해야 할 이벤트 이름(`event`)과 목표 횟수(`needed`)가 정의되어 있습니다. `QuestModel.new()`가 실행될 때 `bus:on(def.event, ...)`를 통해 각 퀘스트의 이벤트에 `advance()` 함수를 미리 등록해 둡니다. 이후 게임 중 아이템을 사용하면 `GameModel:useItem()`이 `bus:emit("item_used", ...)`로 사건을 발행하고, `EventBus`가 해당 이벤트를 구독 중인 퀘스트의 `advance()`를 호출해 `progress`를 1씩 증가시킵니다. 진행도가 `needed`에 도달하면 완료(`done = true`)로 표시하고 `quest_completed` 이벤트까지 발행하므로, 코드를 한 줄도 고치지 않고 `dungeon_data.lua`에 데이터만 추가해도 퀘스트가 정상 동작합니다.

### Q2. `attack()`을 안 고쳐도 되는 이유
`GameModel:attack()`은 적을 처치했을 때 이미 `self.bus:emit("enemy_killed", { name = enemy.name, gold = enemy.gold })` 이벤트를 발행하며 처치한 적의 이름과 골드를 함께 전달하고 있습니다. 새로 만든 `KillListModel`과 `AchievementModel`은 `GameModel`이나 `PlayerModel`을 직접 호출하지 않고 `EventBus`에서 `enemy_killed` 이벤트만 구독해 각각 적 이름 저장과 처치 골드 누적을 처리합니다. 이처럼 `attack()`은 사건을 발행하는 역할만 맡고 후속 처리는 구독 모델들이 각자 담당하는 구조이기 때문에, 새 기능을 붙여도 기존 `attack()` 메서드를 수정할 필요가 없습니다.

### Q3. 업적 기준 30 변경 시 고칠 파일
**`06_dungeon/data/dungeon_data.lua`** 파일 1개만 수정하면 됩니다(`goldAchievementGoal = 15`를 `30`으로 변경). `AchievementModel.new()`는 기준값을 내부에 고정해 두지 않고 생성자 인자(`goldGoal`)로 주입받도록 만들었고, `GameModel.new()`가 `data.goldAchievementGoal` 값을 그대로 전달하기 때문입니다. 또한 업적 달성 시 출력되는 문구도 `AchievementModel`이 `self.goal` 값을 이용해 생성한 `text`를 `LogView`가 그대로 출력하므로, Model·View·Controller 코드는 전혀 손대지 않고 데이터 파일만 수정해 기준을 바꿀 수 있습니다.
