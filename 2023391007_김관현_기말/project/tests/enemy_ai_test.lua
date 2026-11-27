-- enemy_ai_test.lua
-- R4 적 AI 4상태(enter -> formation -> dive -> return) 전이와 주입 rng 기반 결정성을 검사한다.
-- 실행: cd project/tests && lua enemy_ai_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
h.setup(app)

local EnemyFactory = require("EnemyFactory")
local EnemyAI = require("EnemyAI")
local GameModel = require("GameModel")

local DT = 1 / 60
local IDLE = { move = 0, fire = false, missile = false }

local function fixedRng(val)
  return {
    range = function(_, n)
      if val > n then
        return n
      end
      return val
    end,
    next = function()
      return val
    end,
  }
end

print("[enemy_ai_test] " .. app .. "/")

-- 1. enter -> formation 전이
h.test("스폰 직후 enter 상태에서 진입 시간 경과 후 formation 으로 전이한다", function()
  local e = EnemyFactory.create("basic", 120, 80)
  if e.aiState ~= "enter" then
    error("초기 상태가 enter 가 아님: " .. tostring(e.aiState))
  end
  local ctx = { rng = fixedRng(999), playerX = 300, playerY = 740, width = 600, height = 800 }
  for _ = 1, 30 do -- 0.5초
    e:update(DT, ctx)
  end
  return e.aiState == "formation" and e.x == 120 and e.y == 80
end)

-- 2. formation -> dive 전이 (주입 rng) 및 하강 이동
h.test("formation 상태에서 주입된 rng 조건 충족 시 dive 로 전이해 하강한다", function()
  local e = EnemyFactory.create("scout", 200, 100)
  e.aiState = "formation"
  e.stateTimer = 0
  local ctx = { rng = fixedRng(1), playerX = 300, playerY = 740, width = 600, height = 800 }
  e:update(DT, ctx)
  if e.aiState ~= "dive" then
    error("dive 로 전이하지 않음: " .. tostring(e.aiState))
  end
  local y0 = e.y
  for _ = 1, 10 do
    e:update(DT, ctx)
  end
  return e.aiState == "dive" and e.y > y0
end)

-- 3. dive -> return -> formation 전체 순환
h.test("dive 중 화면 하단 통과 시 return 으로 전이하고 편대 자리 도달 시 formation 복귀", function()
  local e = EnemyFactory.create("basic", 200, 100)
  e.aiState = "dive"
  e.diveVx = 0
  e.diveVy = 300
  e.y = 795
  local ctx = { rng = fixedRng(999), playerX = 300, playerY = 740, width = 600, height = 800 }

  -- 하단 통과 → return
  e:update(0.1, ctx)
  if e.aiState ~= "return" then
    error("return 으로 전이하지 않음: " .. tostring(e.aiState))
  end

  -- 편대 자리(homeX=200, homeY=100) 도달할 때까지 진행
  for _ = 1, 120 do
    e:update(DT, ctx)
    if e.aiState == "formation" then
      break
    end
  end
  return e.aiState == "formation" and e.x == e.homeX and e.y == e.homeY
end)

-- 4. 적마다 독립적인 AI 상태 + Scout 가 Basic 보다 빠르게 돌격
h.test("적마다 독립된 AI 상태를 가지며 Scout 가 Basic 보다 빠르게 돌격한다", function()
  local b = EnemyFactory.create("basic", 100, 100)
  local s = EnemyFactory.create("scout", 200, 100)
  local stay = EnemyFactory.create("tank", 300, 100)

  b.aiState = "formation"
  b.stateTimer = 0
  s.aiState = "formation"
  s.stateTimer = 0
  stay.aiState = "formation"
  stay.stateTimer = 10

  local diveCtx = { rng = fixedRng(1), playerX = 200, playerY = 740, width = 600, height = 800 }
  b:update(DT, diveCtx)
  s:update(DT, diveCtx)
  stay:update(DT, diveCtx)

  for _ = 1, 15 do
    b:update(DT, diveCtx)
    s:update(DT, diveCtx)
    stay:update(DT, diveCtx)
  end

  return b.aiState == "dive"
    and s.aiState == "dive"
    and stay.aiState == "formation"
    and s.y > b.y
end)

-- 5. 결정성: 같은 seed 로 두 GameModel 을 300스텝 실행하면 모든 적 상태·좌표 완전 일치
h.test("결정성: 같은 seed 로 300스텝 실행 시 모든 적의 위치와 aiState 가 완전 동일", function()
  local waves = {
    {
      id = 1,
      spawns = {
        { kind = "basic", x = 100, y = 80 },
        { kind = "scout", x = 220, y = 80 },
        { kind = "tank", x = 340, y = 80 },
      },
    },
  }
  local g1 = GameModel({ width = 600, height = 800, seed = 42, waves = waves })
  local g2 = GameModel({ width = 600, height = 800, seed = 42, waves = waves })

  local sawDive = false
  for _ = 1, 300 do
    g1:update(DT, IDLE)
    g2:update(DT, IDLE)
    for i = 1, #g1.enemies do
      if g1.enemies[i].aiState == "dive" then
        sawDive = true
      end
    end
  end

  if #g1.enemies ~= #g2.enemies then
    error("적 수 불일치")
  end
  for i = 1, #g1.enemies do
    local a, b = g1.enemies[i], g2.enemies[i]
    if a.x ~= b.x or a.y ~= b.y or a.aiState ~= b.aiState then
      error("결정성 깨짐: enemy #" .. tostring(i))
    end
  end
  return sawDive and EnemyAI.STATES.enter ~= nil and EnemyAI.STATES["return"] ~= nil
end)

-- 6. 경계: 죽은 적과 ctx 가 nil 일 때 안전하게 무시
h.test("경계: 죽은 적(alive=false)과 ctx=nil 입력에서도 오류 없이 안전 동작", function()
  local dead = EnemyFactory.create("basic", 100, 80)
  dead.alive = false
  dead:update(1.0, nil)
  if dead.aiState ~= "enter" then
    error("죽은 적의 상태가 바뀜")
  end

  local live = EnemyFactory.create("basic", 100, 80)
  live.aiState = "formation"
  live.stateTimer = 0
  live:update(DT, nil)
  return live.aiState == "formation"
end)

h.finish()
