# [게임시스템설계(2A)] 기말과제 보고서 (최종: 기준선 + R1~R7 + 연출·전투 업그레이드)

- **출발 코드**: 선택 B — `lua_tuto/mvc/week05/examples/galaga_states`
- **현재 진행 상태**: 기준선 및 **필수 요건 R1~R7 전체 완료** (`HelpScene`, `WaveParser`, 적 4종·`EnemyFactory`, `EnemyAI` 4상태, 업적 3종 `AchievementModel`, `HighScoreModel` 저장/복원, R7 `SniperEnemy` 번짐 실측) + 패럴랙스 우주·감쇠 사인파 트윈 유도탄·Graze/Overdrive/파워업(`WeaponDecorator`)·보스 광폭화/레이저 완료

---

## 3-1. 출처 표

| 파일 / 기능 | 출처 | 수정 정도 |
|---|---|---|
| `project/src/` 기본 MVC 겔러그 코드 (`models/`, `views/`, `controllers/`, `scenes/`, `main.lua`, `conf.lua`) | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/galaga_states`) | R1(`HelpScene`), R2(`WaveParser`), R3(`EnemyFactory`), R4(`EnemyAI`), R5(`AchievementModel`·`EffectsView`), R6(`HighScoreModel`·`ResultScene`·`ResultView`), R7(`EnemyView` 색상 1줄), 유도탄·Graze/파워업·보스 광폭화/레이저 확장 |
| `project/tests/helper.lua`, `layer_check.lua`, `phase_test.lua`, `scene_test.lua` | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/tests`) | `helper.lua`·`scene_test.lua`에 R1 검증 테스트 3건 추가 (`equivalence_test.lua` 제외) |
| `project/src/scenes/HelpScene.lua`, `project/src/views/HelpView.lua` | AI 협업 작성 (R1 신규) | 신규 작성 |
| `docs/waves_format.md`, `project/src/waves.txt`, `project/src/models/WaveParser.lua`, `project/tests/wave_parser_test.lua` | AI 협업 작성 (R2 신규) | 신규 작성 |
| `project/src/models/{BasicEnemy,ScoutEnemy,TankEnemy,EnemyFactory}.lua`, `project/tests/enemy_factory_test.lua` | AI 협업 작성 (R3 신규) | 신규 작성 |
| `project/src/models/EnemyAI.lua`, `project/tests/enemy_ai_test.lua` | AI 협업 작성 (R4 신규) | 신규 작성 |
| `project/src/models/AchievementModel.lua`, `project/tests/achievement_test.lua` | AI 협업 작성 (R5 신규) | 신규 작성 |
| `project/src/models/HighScoreModel.lua`, `project/src/models/WeaponDecorator.lua`, `project/src/views/StarfieldView.lua`, `project/tests/{highscore,homing,powerup_graze,boss_enrage}_test.lua` | AI 협업 작성 (R6 + 게임플레이 업그레이드 신규) | 신규 작성 |
| `project/src/models/SniperEnemy.lua` | AI 협업 작성 (R7 신규) | 신규 작성 |

---

## 3-2. Lua 문법 매핑표 (14행)

| Lua 문법 요소 | 위치 (`파일:줄`) | 왜 이 문법을 썼나 (대안과 비교) |
|---|---|---|
| 메타테이블 `__index` + `__call` 클래스 | `project/src/models/class.lua:4-23` | `cls.__index = cls`로 메서드 조회를 위임하고 `__call`로 `HelpScene(ctx)`처럼 생성자 문법을 통일. 매 인스턴스에 메서드를 복사하는 방식보다 메모리 할당이 적고 일관됨 |
| 가변 인자 `...` 전달 | `project/src/models/class.lua:9-13` | 클래스마다 다른 생성자 인자 개수(`PlayScene:init(ctx)` vs `ResultScene:init(ctx, game)`)를 공통 팩토리 `__call` 한 곳에서 그대로 전달하기 위해 사용 |
| `:` 메서드 정의와 `self` | `project/src/scenes/HelpScene.lua:12-24` | `self.ctx`, `self.stack`처럼 인스턴스 상태를 첫 번째 인자 `self`로 명시적으로 바인딩. 점(`.`) 호출로 `self`를 누락하는 실수를 막기 위해 인스턴스 동작은 콜론 문법으로 통일 |
| 모듈 반환 테이블 (`return M`) | `project/src/views/HelpView.lua:4-23` | 지역 테이블 `HelpView`만 만들어 반환해 전역 네임스페이스(`_G`) 오염을 원천 차단. 파일 전체에서 전역 변수 대입(`SETGLOBAL`) 0건 유지 |
| 클로저 + 업밸류 상태 캡처 | `project/src/main.lua:16,31-34` | `games` 카운터를 전역 변수로 노출하지 않고 `newSeed` 함수 내부에 캡슐화해 1초 이내 재도전 시에도 시드가 중복되지 않게 유지 |
| `table.concat` 문자열 결합 | `project/src/views/HelpView.lua:6-12` | 여러 줄 안내 문구를 `..` 연산자로 반복 연결하는 대신 배열에 담아 `table.concat`으로 한 번에 결합해 중간 문자열 생성 비용과 가독성 저하를 방지 |
| 역순 `for i = #t, 1, -1` + `table.remove` | `project/src/models/GameModel.lua:190-198` | 순회 중 `table.remove`로 원소를 지울 때 정방향 루프(`1..#t`)를 쓰면 다음 원소 인덱스가 밀려 건너뛰는 버그가 발생하므로 역순 순회를 사용 |
| `ipairs` vs `pairs` 선택 | `project/src/models/GameModel.lua:99,222`, `project/tests/layer_check.lua:63` | 배열(`enemies`, `spawns`)은 순서 보장을 위해 `ipairs`, 문자열 키 딕셔너리(`RULES`)는 모든 키 순회를 위해 `pairs`를 구분해 사용 |
| `pcall` 보호 호출 | `project/tests/helper.lua:27`, `project/tests/wave_parser_test.lua:17` | 테스트 함수와 파서 오류 검증에서 `error()`가 발생해도 러너가 중단되지 않고 에러 메시지(줄 번호 포함 여부)를 포착해 검증하기 위해 사용 |
| 패턴 매칭(`string.find`/`match`/`gsub`/`gmatch`) + 줄 번호 추적 | `project/src/models/WaveParser.lua:51-116` | 전체 문자열에 `gmatch`만 쓰면 규칙에 어긋난 줄을 조용히 건너뛰므로, `find("\n")`로 줄 단위 분리·줄 번호를 세고 각 줄을 엄격하게 토큰화·검증해 `waves:<줄번호>:` 에러를 보고 |
| 메타테이블 단일 상속 (`class(EnemyModel)`) | `project/src/models/class.lua:18-22`, `project/src/models/TankEnemy.lua:7`, `project/src/models/SniperEnemy.lua:7` | `TankEnemy`/`SniperEnemy`의 메타테이블 `mt.__index = EnemyModel`로 연결해 `hit`, `update`, `centerX` 같은 공통 메서드를 중복 작성하지 않고 공유 |
| 함수 테이블 디스패치 (Factory / State 테이블) | `project/src/models/EnemyFactory.lua:16-29`, `project/src/models/EnemyAI.lua:85-90` | 긴 `if/elseif` 분기 대신 문자열 키 → 함수 테이블(`REGISTRY[kind]`, `STATES[aiState]`)로 O(1) 조회·확장(예약어 키는 `["return"]`으로 안전하게 표기) |
| `pcall` 기반 안전 역직렬화 + 기본값 복구 | `project/src/models/HighScoreModel.lua:23-83`, `project/src/main.lua:18-28` | `parseStrict`가 형식 위반·음수·`nan`/`inf`·누락 필드에 대해 `error()`를 던지고, `HighScoreModel.deserialize`가 `pcall(parseStrict, text)`로 포착해 크래시 없이 `{ bestScore = 0, plays = 0 }`으로 복구 |
| 삼각·지수 함수(`math.atan2`/`sin`/`exp`) + 모듈로 각도 정규화 | `project/src/models/homing.lua:43-71` | 직선 보간(`steer`) 대신 `wrapPi`로 `(-π, π]` 최단 회전각을 구하고 `amp * sin(freq * age + phase) * exp(-damp * age)` 감쇠 사인파를 더해 초반 S자 사행 후 목표에 수렴하는 트윈 유도탄을 구현 |

---

## 3-3. 설명 문항

1. **내 적 클래스 하나를 골라, `enemy:update(dt)`를 호출했을 때 `update`를 어떤 순서로 찾는지 `__index` 탐색 경로로 설명하세요.**
   - `TankEnemy` 인스턴스 `e = EnemyFactory.create("tank", x, y)`에서 `e:update(dt, ctx)`를 호출하면 Lua는 다음 순서로 `update` 키를 탐색합니다.
   - ① **인스턴스 테이블 `e` 자체**: `TankEnemy:init`(`project/src/models/TankEnemy.lua:9-17`)은 데이터 필드(`x`, `y`, `hp`, `aiState` 등)만 넣으므로 `rawget(e, "update")`는 `nil`입니다.
   - ② **`e`의 메타테이블 `TankEnemy` (`TankEnemy.__index == TankEnemy`)**: `class.lua:6,10`에 의해 `e`의 메타테이블은 `TankEnemy` 테이블입니다. `TankEnemy`에도 `update`가 없으므로 `nil`입니다.
   - ③ **`TankEnemy`의 메타테이블 `mt.__index == EnemyModel`**: `TankEnemy = class(EnemyModel)`(`TankEnemy.lua:7`, `class.lua:18-20`)에서 `TankEnemy`의 메타테이블 `__index`가 부모 클래스 `EnemyModel`을 가리킵니다. 여기서 `EnemyModel.update`(`project/src/models/EnemyModel.lua:41-43`)를 찾아 `e`를 첫 인자(`self`)로 바인딩해 호출하고, 내부에서 `EnemyAI.update(self, dt, ctx)`로 위임합니다.
2. **내 웨이브 파서가 잘못된 줄을 어떻게 잡아내는지 설명하세요. `gmatch`만 썼다면 어떤 입력을 놓치는지, 그것을 막는 테스트가 어디 있는지 적으세요.**
   - `project/src/models/WaveParser.lua:51-116`은 전체 문자열에 `gmatch`를 돌리지 않고 `text:find("\n", pos, true)`로 한 줄씩 분리하며 `lineNo`를 1씩 증가시킵니다. 각 줄에서 `\r`와 앞뒤 공백을 제거한 뒤 빈 줄과 `#` 주석만 건너뛰고, 나머지 모든 줄은 공백 기준으로 토큰화(`splitTokens`)해 첫 토큰이 `"wave"` 또는 `"spawn"`인지, 토큰 개수·정수 번호·중복 번호·적 종류 패턴(`[A-Za-z0-9_]+`)·0 이상 유한 숫자인지를 검사합니다. 하나라도 어긋나면 `parseError(lineNo, reason)`(`WaveParser.lua:14-16`)이 `waves:<줄번호>: <사유>` 형식으로 즉시 `error()`를 던집니다.
   - 만약 전체 텍스트에 `text:gmatch("spawn%s+(%w+)%s+(%d+)%s+(%d+)")`처럼 `gmatch`만 썼다면, 명령어 오타(`spwn basic 120 60`), 인자 초과(`spawn basic 60 60 extra`), 비숫자·음수 좌표(`spawn basic abc 60`, `spawn basic -5 60`), `wave` 헤더 전 `spawn` 같은 잘못된 줄이 패턴에 매치되지 않아 **아무 오류 없이 조용히 무시**됩니다.
   - 이를 막는 테스트는 `project/tests/wave_parser_test.lua:106-163`(5~10번 테스트: 오타 명령어 3번 줄, 인자 부족/초과/비숫자 좌표, 헤더 전 `spawn`·음수 좌표·중복/비정수/무한대 `wave` 번호, 빈 파일·빈 웨이브, `nan`/`inf`·잘못된 적 종류)에 있습니다.
3. **깨진 하이스코어 문자열이 들어왔을 때 어디서 오류가 생기고 어디서 막히는지(`pcall`/기본값 처리) 흐름을 설명하세요.**
   - ① **파일 읽기 방어 (`project/src/main.lua:18-24`)**: 게임 시작 시 `loadHighScore()`가 `pcall(love.filesystem.read, "highscore.txt")`로 파일을 읽습니다. 파일이 없거나 읽기 오류가 나면 `nil`을 반환해 `HighScoreModel(nil)`로 넘깁니다.
   - ② **엄격 파서에서 오류 발생 (`project/src/models/HighScoreModel.lua:23-66`)**: `parseStrict(text)`는 비문자열/빈 문자열(`35-37줄`), 알 수 없는 키(`58줄`), 필수 필드(`best`/`plays`) 누락(`62-64줄`)을 검사하고, `parseNonNegInt`(`23-32줄`)가 숫자 패턴(`^%d+$`) 위반·음수·`nan`/`inf`·비정수일 때 `error(...)`를 즉시 던집니다.
   - ③ **`pcall` 포착 및 기본값 복구 (`HighScoreModel.lua:77-83, 85-90`)**: `HighScoreModel.deserialize(text)`가 `pcall(parseStrict, text)`로 호출을 감싸 오류를 포착합니다. `ok == false`이면 예외를 전파하지 않고 `defaultCopy()`(`{ bestScore = 0, plays = 0 }`)와 `false`를 반환하며, `HighScoreModel:init`은 이를 그대로 받아 `loadedOk = false` 상태로 안전하게 게임을 시작합니다.
   - ④ **검증 테스트**: `project/tests/highscore_test.lua:30-51`에서 `nil`, 빈 문자열, 임의 문자열, 음수, `inf`, `nan`, 필드 누락, 숫자 타입 등 8종의 손상 입력을 검증합니다.

---

## 3-4. 알려진 문제와 한계
- 현재 PC 환경에 `luajit` 단독 CLI가 없어 Lua 5.1.5(`lua`/`luac`) 기준으로 10개 단위 테스트(80건 통과/0건 실패), `layer_check.lua`(39개 파일 위반 0건), `luac -l -p`(`SETGLOBAL` 0건)를 검증했습니다.
- LÖVE 11.5 기본 비트맵 폰트가 한글을 지원하지 않으므로 모든 화면 렌더링 문구는 영문 ASCII로 통일했습니다.
- 사운드(`love.audio`)는 별도 에셋 없이 순수 그래픽 연출(파티클·플래시·셰이크·워프·레이저) 중심으로 구현했으며, 추후 `EffectsView:onEvent`에 효과음을 바로 연결할 수 있는 구조입니다.
