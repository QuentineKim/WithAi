■ 대상 파일
lua_tuto/mvc/basics/tests/dungeon_test.lua
(관련 예제: lua_tuto/mvc/basics/06_dungeon/)

■ 진행 방법
1. 테스트를 실행한다.
- VS Code: dungeon_test.lua 를 열고 task Lua: Run current file 실행
- 터미널(저장소 루트): lua lua_tuto/mvc/basics/tests/dungeon_test.lua
2. dungeon_test.lua 를 읽고 아래 10문항에 짧게 답한다. (숫자, 단어, 또는 한 줄)
3. 코드는 수정하지 않는다.
4. AI 사용은 허용한다. 사용했다면 답안 맨 아래에 도구와 질문을 한 줄로 적는다.

■ 작성자 정보
- 학과: 게임제작과
- 학년: 3학년
- 학번 / 이름: 2023391007 김관현

■ 문항 (각 10점, 총 100점)

1. 테스트 실행 결과 마지막 줄에 나오는 통과 수는?
답: 56

2. [0]~[4] 각 구역은 무엇을 검사하는가?
보기에서 고르시오: 구조 / Model / View / Controller
답:
- [0]: 구조
- [1]: Model
- [2]: Model
- [3]: View
- [4]: Controller

3. [0] 디커플링 검사에서 Model·Controller 파일에 있으면 안 되는 것 3가지는?
답: print, io, love

4. newGame 함수는 실제 데이터 파일(data/dungeon_data.lua) 대신
작은 던전을 직접 만든다. 그 이유를 한 줄로 쓰시오.
답: 실제 데이터 파일과 독립적이어서 기획 수치(데이터)가 바뀌어도 테스트가 깨지지 않게 하기 위해.

5. 적이 살아 있으면 반격 테스트에서 플레이어 HP 가 10 → 6 이 된다.
줄어든 4는 누구의 어떤 값인가?
답: 적(골렘)의 공격력(attack)

6. 전투 중 물약 테스트에서 물약의 power 는 5인데 실제로는 4만 회복된다.
그 이유는?
답: 플레이어의 최대 체력(maxHp=10)까지만 회복되기 때문에 (현재 체력 6에서 최대치 10까지 4만 회복 가능).

7. [4] 구역의 fakeView 는 진짜 화면 대신 무엇 두 가지를 기록하는가?
답: 알림 메시지(notices), 렌더링 호출 횟수(renders)

8. 승리 후 router:handle(x) 의 반환값은 true 인가 false 인가?
그리고 이 입력을 처리하는 Controller 의 이름은?
답: false, EndController

9. router:handle( n ) 처럼 앞뒤에 공백이 있어도 n 으로 처리된다.
공백을 지우는 코드는 어느 파일에 있는가?
답: controllers/input_router.lua (또는 input_router.lua)

10. 이 테스트 파일이 검사하지 않는 것을 하나 찾아 한 줄로 쓰시오.
(파일, 기능, 상황 무엇이든 좋다)
답: 실제 게임 기획 데이터 파일(data/dungeon_data.lua)의 내용 유효성 검사 (또는 게임 실행 진입점인 main.lua의 사용자 표준 입력 대화형 루프)

---

■ AI 사용 기록
- 사용 도구: Antigravity (Gemini 3.8)
- 세부 탐구 활동 내역:
  1. [검증 구역 분석] `dungeon_test.lua`의 [0]~[4] 각 섹션이 MVC의 어떤 책임(디커플링 구조, Leaf Model 단위, 통합 FSM 규칙, Passive View 무상태성, Controller 라우팅)을 검사하는지 테스트 대상 파일 및 어설션 코드 기반으로 단계별 역할 질의
  2. [테스트 독립성 분석] `newGame()` 함수가 실제 기획 파일(`data/dungeon_data.lua`) 대신 테스트용 작은 방과 플레이어 데이터를 직접 주입하는 이유와, 이것이 단위 테스트의 Flaky Test(불안정성) 방지에 미치는 영향 분석 요청
  3. [규칙 역추적] 전투 중 물약 회복량(power 5 → 실제 회복 4)과 골렘 반격 피해(HP 10 → 6) 발생 시 `PlayerModel:heal()` 및 `GameModel:attack()`의 내부 수치 감쇠 공식과 FSM 턴 처리 메커니즘 소스코드 대조 질의
  4. [Mock 객체 원리] [4]번 구역의 `fakeView`가 실제 화면 출력 대신 `notices` 배열과 `renders` 카운터만 수집하는 Mocking 목적 및 `controllers/input_router.lua`의 입력 공백 정규식(`^%s*(.-)%s*$`) 위치 추적 질의
- 질문 내용(한 줄 요약): "dungeon_test.lua의 5단계 검증 프로세스(디커플링, Leaf Model, 통합 FSM, Passive View, FakeView Mocking)를 실제 소스코드와 대조 분석하고, 56개 테스트 케이스의 통과 메커니즘과 MVC 아키텍처 설계 의도를 단계별로 질의·교차 검증함"
