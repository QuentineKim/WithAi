-- EnemyAI.lua
-- 적 AI 상태 기계 (State 패턴): enter -> formation -> dive -> return -> formation.
-- Model 계층 규칙 준수: love/io/print/math.random 금지, 주입된 ctx.rng 만 사용한다(결정성).

local math_sqrt = math.sqrt

local M = {}

M.ENTER_DURATION = 0.35
M.DIVE_CHECK_INTERVAL = 0.8
M.DIVE_CHANCE_DENOM = 4
M.RETURN_SPEED = 240

local function updateEnter(e, dt)
  e.x = e.homeX
  e.y = e.homeY
  e.stateTimer = e.stateTimer - dt
  if e.stateTimer <= 0 then
    e.aiState = "formation"
    e.stateTimer = M.DIVE_CHECK_INTERVAL
  end
end

local function updateFormation(e, dt, ctx)
  e.x = e.homeX
  e.y = e.homeY
  e.stateTimer = e.stateTimer - dt
  if e.stateTimer > 0 then
    return
  end
  e.stateTimer = M.DIVE_CHECK_INTERVAL

  if ctx and ctx.rng and ctx.rng:range(M.DIVE_CHANCE_DENOM) == 1 then
    local px = ctx.playerX or e:centerX()
    local py = ctx.playerY or (e.y + 400)
    local dx = px - e:centerX()
    local dy = py - e:centerY()
    if dy < 120 then
      dy = 120
    end
    local dist = math_sqrt(dx * dx + dy * dy)
    local speed = e.diveSpeed or 190
    if dist > 0 then
      e.diveVx = (dx / dist) * speed
      e.diveVy = (dy / dist) * speed
    else
      e.diveVx = 0
      e.diveVy = speed
    end
    e.aiState = "dive"
  end
end

local function updateDive(e, dt, ctx)
  e.x = e.x + e.diveVx * dt
  e.y = e.y + e.diveVy * dt

  local height = (ctx and ctx.height) or 800
  if e.y > height then
    e.aiState = "return"
    e.x = e.homeX
    e.y = -e.h
    e.diveVx = 0
    e.diveVy = 0
  end
end

local function updateReturn(e, dt)
  local dx = e.homeX - e.x
  local dy = e.homeY - e.y
  local dist = math_sqrt(dx * dx + dy * dy)
  local step = M.RETURN_SPEED * dt

  if dist <= step or dist == 0 then
    e.x = e.homeX
    e.y = e.homeY
    e.aiState = "formation"
    e.stateTimer = M.DIVE_CHECK_INTERVAL
  else
    e.x = e.x + (dx / dist) * step
    e.y = e.y + (dy / dist) * step
  end
end

local STATES = {
  enter = updateEnter,
  formation = updateFormation,
  dive = updateDive,
  ["return"] = updateReturn,
}

M.STATES = STATES

--- 적 1기의 AI 상태를 고정 스텝 dt 만큼 갱신한다.
function M.update(enemy, dt, ctx)
  if not enemy.alive then
    return
  end
  local handler = STATES[enemy.aiState]
  if handler then
    handler(enemy, dt, ctx)
  end
end

return M
