# My Pong - 사이버 하이롤러 카지노 & AI 퀀트 베팅 아레나

> **소재:** Pong (Week 01 실습 4번 확장 프로젝트)
> **핵심 키워드:** `자율 AI 에이전트(Strategy 패턴)`, `ELO 레이팅 & 동적 배당률`, `켈리 기준(Kelly Criterion) 퀀트 베팅`, `무제한 구속 가속 & 서브스텝 터널링 방지`, `Passive View 렌더러 분리`

---

## 📌 프로젝트 개요

단순한 2인용 아케이드 게임 Pong을 소프트웨어 엔지니어링 및 게임 알고리즘 기법을 적용하여 **자율 AI 간의 물리 대전 시뮬레이션**과 **금융 통계 기반의 실시간 퀀트 베팅 마켓** 시스템으로 고도화한 프로젝트입니다.

---

## 🏛️ 아키텍처 및 모듈 구성 (SRP 원칙 준수)

| 모듈 파일 | 역할 및 책임 |
| :--- | :--- |
| **[`class.lua`](class.lua)** | 메타테이블 기반 클래스/상속 생성 유틸리티 (`__index`, `__call`) |
| **[`constants.lua`](constants.lua)** | 아레나 및 HUD 규격, 트론/카지노 색상 팔레트, 물리 가속 상수 정의 |
| **[`Paddle.lua`](Paddle.lua)** | 패들 엔티티 클래스 (상하 이동 및 화면 클램핑) |
| **[`Ball.lua`](Ball.lua)** | 공 엔티티 클래스 및 트론 라이트 잔상 큐 관리 |
| **[`AIControllers.lua`](AIControllers.lua)** | `PredictiveAI`(광선 추적 물리 예측) vs `ReactiveAI`(PD 제어 추적) |
| **[`AnalyticsEngine.lua`](AnalyticsEngine.lua)** | 체스/바둑 공식 기반 ELO 레이팅(K=32), 기대 승률, 동적 배당률 산출 |
| **[`BettingMarket.lua`](BettingMarket.lua)** | 켈리 기준 퀀트 봇, 도박꾼 AI 4인방, 관전자 올인(ALL-IN) 자산 정산 |
| **[`ParticleSystem.lua`](ParticleSystem.lua)** | 충돌 시 방향성 네온 스파크 파티클 물리 갱신 |
| **[`Renderer.lua`](Renderer.lua)** | **순수 View:** 한글 TTF 네온 HUD, 스파크라인 차트, 게임 상태 렌더링 (상태 변경 0건) |
| **[`conf.lua`](conf.lua)** | 1000x640 와이드 스크린 창 설정 |
| **[`main.lua`](main.lua)** | 게임 루프 오케스트레이션, 서브스텝 터널링 방지 충돌 검사, 배속 제어 |

---

## 🧠 핵심 수학 및 알고리즘 구현

### 1. 무제한 가속 & 서브스텝(Sub-stepping) 터널링 방지
- 패들에 부딪힐 때마다 구속이 **8%씩 무제한 가속**됩니다. (`BALL_ACCEL = 1.08`)
- 공의 속도가 1,000 ~ 3,000+ px/s로 폭증해도 패들을 뚫고 지나가는 **터널링(Tunneling)**을 방지하기 위해, 1스텝당 최대 이동 거리를 10px로 제한하여 서브스텝을 분할 실행합니다.
  ```lua
  local subSteps = math.max(1, math.ceil((speed * dt) / maxStepDist))
  local subDt = dt / subSteps
  for _ = 1, subSteps do
    ball:update(subDt)
    -- 충돌 및 벽 반사 검사
  end
  ```

### 2. ELO 레이팅 및 기대 승률 공식
- 매 경기(5점 선취) 승패마다 두 AI의 ELO 레이팅($R_A, R_B$)을 갱신합니다.
- 기대 승률 공식:
  $$E_A = \frac{1}{1 + 10^{(R_B - R_A)/400}}$$
- 배당률 공식 (북메이커 마진 8% 적용):
  $$Odds_A = \max\left(1.05, \frac{1 - 0.08}{E_A}\right)$$

### 3. 켈리 기준 (Kelly Criterion) 투자 공식
- 켈리 퀀트 봇은 자산 파산 확률을 0으로 통제하면서 장기 복리 수익을 극대화하는 켈리 비율을 계산하여 최적 분산 투자(Half-Kelly)를 집행합니다.
  $$f^* = \frac{b \cdot p - q}{b}$$
  *(여기서 $b = Odds - 1$, $p = E$, $q = 1 - p$)*

---

## 🎲 도박꾼 AI 4인방 라인업

1. **켈리 퀀트 (The Quant):** 켈리 공식에 따라 기댓값이 양수일 때만 최적 분산 투자.
2. **역배 사냥꾼 (The Underdog):** "인생은 한 방!" 배당률 2.0배 이상의 고배당 역배에 전격 투자.
3. **정배 올인러 (The Bull):** 승률 우세 쪽에 자산의 40% 이상을 공격적으로 몰빵.
4. **마틴게일 (The Martingale):** 패배할 때마다 베팅액을 2배씩 늘려 배수 베팅 (파산 시 `[파산]` 처리).

---

## 🕹️ 조작 및 실행 방법

### VS Code Task로 실행
- `Ctrl + Shift + P` ➔ **Tasks: Run Task** ➔ **`Love2D: Run My Pong`**

### 단축키
- **`1`** : 알파(시안)에 베팅 ($50 / $100 / $250)
- **`2`** : 베타(마젠타)에 베팅 ($50 / $100 / $250)
- **`A`** : **전재산 올인 (ALL-IN)!**
- **`C`** : 베팅 단위 변경 ($50 ➔ $100 ➔ $250)
- **`Tab`** : 시뮬레이션 배속 전환 (1x ➔ 5x ➔ 20x)
- **`Space`** : 일시정지 / 재개
- **`R`** : 전적 및 자산 초기화
- **`Esc`** : 종료

