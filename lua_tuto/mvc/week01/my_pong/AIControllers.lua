-- AIControllers.lua
-- 역할 특화 AI 2종 (창과 방패 밸런스)
-- 1. PredictiveAI (알파): [수비 특화] 정밀 궤적 예측 + 중앙 타격으로 안정적 철벽 방어
-- 2. ReactiveAI   (베타): [공격 특화] 고속 대시 + 상대 위치 기반 모서리 스매시 공격

local constants = require("constants")

local AIControllers = {}

-- ── 1. PredictiveAI (에이전트 알파 - 수비 특화) ────────────────────────────
local PredictiveAI = {}
PredictiveAI.__index = PredictiveAI

function PredictiveAI.new(isLeft)
  local self = setmetatable({}, PredictiveAI)
  self.isLeft = isLeft
  self.cachedTargetY = constants.ARENA_Y + constants.ARENA_H * 0.5
  return self
end

function PredictiveAI:predictLandingY(ball, targetX)
  if (self.isLeft and ball.vx >= 0) or ((not self.isLeft) and ball.vx <= 0) then
    return constants.ARENA_Y + constants.ARENA_H * 0.5
  end

  local dtToTarget = (targetX - ball.x) / ball.vx
  if dtToTarget <= 0 then
    return ball.y + ball.h * 0.5
  end

  local arenaTop = constants.ARENA_Y
  local arenaBottom = constants.ARENA_Y + constants.ARENA_H - ball.h
  local wallSpan = arenaBottom - arenaTop

  local virtualY = (ball.y - arenaTop) + ball.vy * dtToTarget
  local doubleSpan = 2 * wallSpan
  local modY = virtualY % doubleSpan
  if modY < 0 then modY = modY + doubleSpan end

  local finalY
  if modY <= wallSpan then
    finalY = arenaTop + modY
  else
    finalY = arenaTop + (doubleSpan - modY)
  end

  return finalY + ball.h * 0.5
end

function PredictiveAI:getDirection(paddle, ball, opponentPaddle, dt)
  local targetX = self.isLeft and (paddle.x + paddle.w) or paddle.x
  local landingY

  local isApproaching = (self.isLeft and ball.vx < 0) or ((not self.isLeft) and ball.vx > 0)
  if isApproaching then
    landingY = self:predictLandingY(ball, targetX)
  else
    landingY = constants.ARENA_Y + constants.ARENA_H * 0.5
  end

  -- [수비 특화 전략]: 패들의 정중앙으로 공을 받아내어 반사각을 완만하고 안정적으로 제어
  local paddleCenter = paddle.y + paddle.h * 0.5
  local diff = landingY - paddleCenter
  local deadZone = 6

  if diff > deadZone then
    return 1
  elseif diff < -deadZone then
    return -1
  else
    return 0
  end
end

-- ── 2. ReactiveAI (에이전트 베타 - 공격 특화) ──────────────────────────────
local ReactiveAI = {}
ReactiveAI.__index = ReactiveAI

function ReactiveAI.new(isLeft)
  local self = setmetatable({}, ReactiveAI)
  self.isLeft = isLeft
  self.targetY = constants.ARENA_Y + constants.ARENA_H * 0.5
  return self
end

function ReactiveAI:getDirection(paddle, ball, opponentPaddle, dt)
  local isApproaching = (self.isLeft and ball.vx < 0) or ((not self.isLeft) and ball.vx > 0)
  local desiredCenterY

  if isApproaching then
    local ballCenterY = ball.y + ball.h * 0.5
    local oppCenterY = opponentPaddle and (opponentPaddle.y + opponentPaddle.h * 0.5) or (constants.ARENA_Y + constants.ARENA_H * 0.5)

    -- [공격 특화 전략]: 상대방의 빈틈을 향해 패들 모서리로 각도 스매시를 꽂아 넣음!
    -- 상대가 위쪽에 있으면 공의 상단을 쳐서 아래로 내리꽂고, 아래에 있으면 위로 꺾음
    local attackOffset = 0
    if oppCenterY < constants.ARENA_Y + constants.ARENA_H * 0.5 then
      -- 상대가 상단에 치우침 ➔ 패들의 상단 모서리로 맞춰서 아래 대각선 스매시
      attackOffset = -paddle.h * 0.38
    else
      -- 상대가 하단에 치우침 ➔ 패들의 하단 모서리로 맞춰서 위 대각선 스매시
      attackOffset = paddle.h * 0.38
    end

    desiredCenterY = ballCenterY + attackOffset + (ball.vy * 0.04)
  else
    -- 상대 공격 중일 때는 빠르게 중앙에 대기
    desiredCenterY = constants.ARENA_Y + constants.ARENA_H * 0.5
  end

  -- 고속 반응 추종 (날렵한 기동)
  self.targetY = self.targetY + (desiredCenterY - self.targetY) * math.min(1.0, 24 * dt)

  local paddleCenter = paddle.y + paddle.h * 0.5
  local diff = self.targetY - paddleCenter
  local deadZone = 7

  if diff > deadZone then
    return 1
  elseif diff < -deadZone then
    return -1
  else
    return 0
  end
end

AIControllers.PredictiveAI = PredictiveAI
AIControllers.ReactiveAI = ReactiveAI

return AIControllers
