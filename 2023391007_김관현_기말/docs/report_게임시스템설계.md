# [게임시스템설계(2A)] 기말과제 보고서 (초안: 기준선 + R1)

- **출발 코드**: 선택 B — `lua_tuto/mvc/week05/examples/galaga_states`
- **현재 진행 상태**: 기준선 세팅 및 R1(`HelpScene`) 완료 (R2~R7 구현 후 보완 예정)

---

## 3-1. 출처 표

| 파일 / 기능 | 출처 | 수정 정도 |
|---|---|---|
| `project/src/` 기본 MVC 겔러그 코드 (`models/`, `views/`, `controllers/`, `scenes/`, `main.lua`, `conf.lua`) | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/galaga_states`) | `main.lua`, `TitleScene.lua`, `TitleView.lua`에 R1 연결부 추가, 나머지 무수정 |
| `project/tests/helper.lua`, `layer_check.lua`, `phase_test.lua`, `scene_test.lua` | 수업 공개 예제 (`lua_tuto/mvc/week05/examples/tests`) | `helper.lua`·`scene_test.lua`에 R1 검증 테스트 3건 추가 (`equivalence_test.lua` 제외) |
| `project/src/scenes/HelpScene.lua`, `project/src/views/HelpView.lua` | AI 협업 작성 (R1 신규) | 신규 작성 |

---

## 3-2. Lua 문법 매핑표 (현재 기준선 + R1 기준 9행, R2~R6 구현 시 추가 예정)

| Lua 문법 요소 | 위치 (`파일:줄`) | 왜 이 문법을 썼나 (대안과 비교) |
|---|---|---|
| 메타테이블 `__index` + `__call` 클래스 | `project/src/models/class.lua:4-23` | `cls.__index = cls`로 메서드 조회를 위임하고 `__call`로 `HelpScene(ctx)`처럼 생성자 문법을 통일. 매 인스턴스에 메서드를 복사하는 방식보다 메모리 할당이 적고 일관됨 |
| 가변 인자 `...` 전달 | `project/src/models/class.lua:9-13` | 클래스마다 다른 생성자 인자 개수(`PlayScene:init(ctx)` vs `ResultScene:init(ctx, game)`)를 공통 팩토리 `__call` 한 곳에서 그대로 전달하기 위해 사용 |
| `:` 메서드 정의와 `self` | `project/src/scenes/HelpScene.lua:12-24` | `self.ctx`, `self.stack`처럼 인스턴스 상태를 첫 번째 인자 `self`로 명시적으로 바인딩. 점(`.`) 호출로 `self`를 누락하는 실수를 막기 위해 인스턴스 동작은 콜론 문법으로 통일 |
| 모듈 반환 테이블 (`return M`) | `project/src/views/HelpView.lua:4-23` | 지역 테이블 `HelpView`만 만들어 반환해 전역 네임스페이스(`_G`) 오염을 원천 차단. 파일 전체에서 전역 변수 대입(`SETGLOBAL`) 0건 유지 |
| 클로저 + 업밸류 상태 캡처 | `project/src/main.lua:12-18` | `games` 카운터를 전역 변수로 노출하지 않고 `newSeed` 함수 내부에 캡슐화해 1초 이내 재도전 시에도 시드가 중복되지 않게 유지 |
| `table.concat` 문자열 결합 | `project/src/views/HelpView.lua:6-12` | 여러 줄 안내 문구를 `..` 연산자로 반복 연결하는 대신 배열에 담아 `table.concat`으로 한 번에 결합해 중간 문자열 생성 비용과 가독성 저하를 방지 |
| 역순 `for i = #t, 1, -1` + `table.remove` | `project/src/models/GameModel.lua:129-135` | 순회 중 `table.remove`로 원소를 지울 때 정방향 루프(`1..#t`)를 쓰면 다음 원소 인덱스가 밀려 건너뛰는 버그가 발생하므로 역순 순회를 사용 |
| `ipairs` vs `pairs` 선택 | `project/src/models/GameModel.lua:157`, `project/tests/layer_check.lua:61` | 배열(`enemies`, `bullets`)은 순서 보장을 위해 `ipairs`, 문자열 키 딕셔너리(`RULES`)는 모든 키 순회를 위해 `pairs`를 구분해 사용 |
| `pcall` 보호 호출 | `project/tests/helper.lua:27` | 테스트 함수 내부에서 `error()`가 발생해도 전체 테스트 러너가 중간에 멈추지 않고 실패 사유를 포착해 나머지 테스트를 계속 집계하기 위해 사용 |

---

## 3-3. 설명 문항 (R2~R6 구현 후 작성 예정)

1. *(R3/R4 구현 후 작성 예정)* 내 적 클래스 하나를 골라, `enemy:update(dt)`를 호출했을 때 `update`를 어떤 순서로 찾는지 `__index` 탐색 경로로 설명하세요.
2. *(R2 구현 후 작성 예정)* 내 웨이브 파서가 잘못된 줄을 어떻게 잡아내는지 설명하세요. `gmatch`만 썼다면 어떤 입력을 놓치는지, 그것을 막는 테스트가 어디 있는지 적으세요.
3. *(R6 구현 후 작성 예정)* 깨진 하이스코어 문자열이 들어왔을 때 어디서 오류가 생기고 어디서 막히는지(`pcall`/기본값 처리) 흐름을 설명하세요.

---

## 3-4. 알려진 문제와 한계
- 현재까지 **기준선 + R1(`HelpScene`)**만 완료된 상태이며, R2(웨이브 파서), R3/R4(적 3종·FSM), R5(업적), R6(저장/불러오기), R7(번짐 실측)은 후속 작업에서 구현 및 보고서 보완 예정입니다.
- 현재 PC 환경에 `luajit` 단독 실행 파일이 없어 Lua 5.1.5(`lua`, `luac`) 기준으로 테스트 및 `SETGLOBAL` 정적 검사를 수행했습니다.
