# 3주차 발표 자료 — `BulletModel.lua` & `PlayerModel.lua` TODO 정답 및 해설

> **대상 파일:**
> - [`starter/BulletModel.lua`](BulletModel.lua) (TODO 2개)
> - [`starter/PlayerModel.lua`](PlayerModel.lua) (TODO 5개)

---

## 🎯 발표 도입: 두 스크립트의 공통 설계 원칙

> **발표 멘트 포인트:**  
> *"이 두 파일은 2주차 모놀리식 코드에서 **순수 게임 규칙(Model)**만 떼어낸 모듈입니다. 가장 큰 특징은 `love.graphics`나 `love.keyboard` 같은 엔진 의존 코드가 **단 한 줄도 없다**는 점입니다."*

1. **LÖVE2D 완전 비의존 (`print` / `io` / `love` 금지):** 창을 띄우지 않고 CLI(`lua` / `luajit`)에서 0.01초 만에 단위 테스트가 가능합니다.
2. **메타테이블 기반 OOP (`require("class")`):** 1주차에 만든 `class` 유틸로 상태(필드)와 행위(메서드)를 객체 하나로 캡슐화했습니다.
3. **Docstring 계약 (`@field` 주석):** 동적 타입 언어인 Lua에서 필드 타입과 의미를 머리 주석으로 명시해 다른 계층과의 약속(계약)을 문서화했습니다.
4. **프레임 독립성 (`* dt`):** 모든 이동과 쿨타임 차감에 `dt`를 곱해 프레임률과 무관하게 결정적으로 동작합니다.

---

## 1. [`BulletModel.lua`](BulletModel.lua) TODO 정답 & 해설 (2개)

### ① `BulletModel:update(dt)` (24~26행)
> `-- TODO: 속도 × dt 만큼 이동`

- **정답 코드:**
  ```lua
  function BulletModel:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
  end
  ```
- **발표 해설:**
  - 현재 좌표에 `속도 × dt`를 더해 **프레임률과 무관하게 일정한 속력**으로 등속 이동합니다.
  - 수직 속도(`vy`)뿐 아니라 수평 속도(`vx`)도 함께 갱신하므로, 플레이어/일반 적의 직선 탄환뿐만 아니라 추후 보스의 원형 방사 탄막이나 유도 미사일까지 **이 클래스 하나로 전부 재사용**할 수 있습니다.

### ② `BulletModel:isOffscreen(width, height, margin)` (29~33행)
> `-- TODO: 네 방향 모두 검사 (모놀리식은 위/아래만 봤다 — 왜 부족한가?)`

- **정답 코드:**
  ```lua
  function BulletModel:isOffscreen(width, height, margin)
    margin = margin or 24
    return self.y + self.h < -margin
        or self.y > height + margin
        or self.x + self.w < -margin
        or self.x > width + margin
  end
  ```
- **발표 해설 (주석 질문에 대한 답변):**
  - **왜 4방향 모두 검사해야 하는가?**  
    2주차 모놀리식에서는 총알이 위/아래로만 날아가 `y`축만 검사했습니다. 하지만 대각선·방사형 탄막이나 유도 미사일이 추가되면 **좌우(`x`축)로 화면을 벗어나는 총알**이 생깁니다. 위/아래만 검사하면 좌우로 나간 총알이 영원히 제거되지 않아 메모리 누수 및 불필요한 연산이 누적됩니다.
  - **좌표 보정 (`+ self.w`, `+ self.h`)과 `margin`:**  
    `(x, y)`는 좌상단 기준 좌표이므로 왼쪽/위쪽 이탈 시 너비·높이를 더해(`x + w < -margin`, `y + h < -margin`) 몸체가 완전히 화면을 벗어났는지 판별합니다. 화면 크기(`width, height`)는 하드코딩하지 않고 인자로 주입받습니다.

---

## 2. [`PlayerModel.lua`](PlayerModel.lua) TODO 정답 & 해설 (5개)

### ① `PlayerModel:move(dt, dir, speed)` (22~24행)
> `-- TODO: love.keyboard 를 읽지 말 것. dir 은 바깥(Controller)이 준다.`

- **정답 코드:**
  ```lua
  function PlayerModel:move(dt, dir, speed)
    self.x = self.x + dir * speed * dt
  end
  ```
- **발표 해설:**
  - 2주차 모놀리식에서는 `love.keyboard.isDown("left")`를 직접 읽었지만, Model은 입력 장치를 몰라야 하므로 외부(Controller → GameModel)가 해석해 넘겨주는 방향 값 `dir`(`-1`, `0`, `1`)만 받습니다.
  - `dir`이 `0`이면 이동량이 `0`이 되어 별도 `if` 분기가 필요 없고, 테스트 시 키보드 없이 숫자만 넘겨 이동을 검증할 수 있습니다.

### ② `PlayerModel:clamp(minX, maxX)` (27~30행)
> `-- TODO: 모놀리식의 "if player.x < 0 ... elseif player.x > 600 - player.w" 를 옮긴다. 600 같은 매직 넘버 대신 인자를 쓴다.`

- **정답 코드:**
  ```lua
  function PlayerModel:clamp(minX, maxX)
    if self.x < minX then
      self.x = minX
    elseif self.x > maxX - self.w then
      self.x = maxX - self.w
    end
  end
  ```
- **발표 해설:**
  - `0`이나 `600` 같은 화면 크기 **매직 넘버를 Model 내부에 박지 않고** 인자(`minX`, `maxX`)로 주입받아 해상도 변화와 테스트 환경에 유연하게 대응합니다.
  - 오른쪽 경계에서 `maxX - self.w`를 계산하는 이유는 `self.x`가 기체의 좌상단 기준이기 때문에 너비(`w = 40`)만큼 빼주어야 기체가 화면 밖으로 삐져나가지 않기 때문입니다.

### ③ `PlayerModel:tickCooldown(dt)` (32~34행)
- **정답 코드:**
  ```lua
  function PlayerModel:tickCooldown(dt)
    if self.cooldown > 0 then
      self.cooldown = self.cooldown - dt
    end
  end
  ```
- **발표 해설:**
  - 매 고정 스텝마다 다음 발사까지의 남은 대기 시간(`cooldown`)을 `dt`만큼 차감합니다. `cooldown > 0` 조건으로 불필요하게 음수 무한대로 감소하는 것을 막습니다.

### ④ `PlayerModel:canFire()` (36~39행)
- **정답 코드:**
  ```lua
  function PlayerModel:canFire()
    return self.cooldown <= 0
  end
  ```
- **발표 해설:**
  - `dt` 감산 시 부동소수점 오차로 `cooldown`이 미세한 음수(예: `-0.001`)가 될 수 있으므로 `== 0` 대신 `<= 0`으로 안전하게 발사 가능 여부를 판정합니다.

### ⑤ `PlayerModel:resetCooldown(seconds)` (41~43행)
- **정답 코드:**
  ```lua
  function PlayerModel:resetCooldown(seconds)
    self.cooldown = seconds
  end
  ```
- **발표 해설:**
  - 발사 성공 직후 쿨타임(`seconds`, 예: `0.25`)을 외부에서 전달받아 재설정합니다. 쿨타임 수치를 Model 내부에 고정하지 않아 밸런스 조정이 쉽습니다.

---

## 🎤 발표 마무리 & 예상 Q&A

> **마무리 한 줄 요약:**  
> *"발사 쿨타임을 `tickCooldown`, `canFire`, `resetCooldown` 3개로 쪼개 둔 이유는 `PlayerModel`이 총알 배열이나 생성 규칙을 직접 알지 않게 하기 위해서입니다. 덕분에 `GameModel`이 `canFire()`를 확인하고 총알을 만든 뒤 `resetCooldown()`을 호출하는 깔끔한 책임 분리가 완성됩니다."*

- **Q. 왜 `BulletModel`에 `kind`를 두고 `vx, vy`를 모두 넣었나요?**
  - **A.** 플레이어 총알과 적 총알의 등속 이동 원리는 동일하므로 클래스를 나눌 필요 없이 `kind`로 소유자만 구분하고, `vx, vy`로 일반화해 두면 추후 보스 원형 탄막 등 모든 방향의 투사체를 코드 수정 없이 확장할 수 있기 때문입니다.
- **Q. 왜 `PlayerModel`에 화면 너비 `600`이나 속도 `340`을 상수로 넣지 않았나요?**
  - **A.** Model이 특정 화면 해상도나 상수에 종속되지 않게 하여 재사용성과 헤드리스 단위 테스트 용이성을 높이기 위함입니다.

