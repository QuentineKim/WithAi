-- main.lua
-- 트론 퐁 - 사이버 하이롤러 카지노 & AI 배팅 아레나
-- 밸런스: 수비 특화 예측형 알파 (방패) vs 공격 특화 반응형 베타 (창)

local constants        = require("constants")
local Paddle           = require("Paddle")
local Ball             = require("Ball")
local AIControllers    = require("AIControllers")
local AnalyticsEngine  = require("AnalyticsEngine")
local BettingMarket    = require("BettingMarket")
local ParticleSystem   = require("ParticleSystem")
local Renderer         = require("Renderer")

local lg = love.graphics

-- ── 1. 충돌 판정 및 타격 반응 (역할별 물리 차별화) ────────────────────────
local function overlaps(a, b)
  return a.x < b.x + b.w
    and b.x < a.x + a.w
    and a.y < b.y + b.h
    and b.y < a.y + a.h
end

local function handlePaddleHit(game, isLeft)
  local paddle = isLeft and game.left or game.right
  local ball = game.ball

  local paddleCenter = paddle.y + paddle.h * 0.5
  local ballCenter = ball.y + ball.h * 0.5
  local offset = (ballCenter - paddleCenter) / (paddle.h * 0.5)
  if offset < -1 then offset = -1 end
  if offset > 1 then offset = 1 end

  -- x 위치 보정
  if isLeft then
    ball.x = paddle.x + paddle.w
  else
    ball.x = paddle.x - ball.w
  end

  local speed = math.abs(ball.vx)

  if isLeft then
    -- 🛡️ [에이전트 알파 - 수비 특화]
    -- 공의 궤적을 흡수·안정화하여 차분하고 정확한 수평 리턴 (5% 완만 가속)
    speed = speed * constants.DEF_ACCEL
    ball.vx = speed
    ball.vy = speed * offset * 0.60 -- 완만한 반사각 (수비 안정성)
    game.lastHitAction = "🛡️ 알파의 완벽 방어 리턴!"
  else
    -- ⚡ [에이전트 베타 - 공격 특화]
    -- 모서리 타격을 활용한 강력한 스매시 & 폭발적 가속 (10% 강한 가속)
    speed = speed * constants.ATK_ACCEL
    ball.vx = -speed
    ball.vy = speed * offset * 1.15 -- 날카로운 각도의 맹공 스매시!
    game.lastHitAction = "⚡ 베타의 각도 스매시 공격!"
  end

  -- 통계 및 시각 효과 기록
  game.analytics:recordHit(speed)
  local hitX = isLeft and (paddle.x + paddle.w) or paddle.x
  local sparkCount = isLeft and 18 or 32
  ParticleSystem.emit(game.ps, hitX, ballCenter, sparkCount, paddle.color, ball.vx, ball.vy)
  game.flashTimer = isLeft and 0.08 or 0.14
  game.flashColor = paddle.color
end

-- ── 2. 게임 상태 초기화 및 매치 루프 ──────────────────────────────────────
local game

local function startNewMatch()
  game.scoreL = 0
  game.scoreR = 0
  game.ball:reset(math.random() > 0.5 and 1 or -1)
  game.analytics:resetRally()
  game.lastHitAction = ""

  -- 도박꾼 AI 4인방의 자동 베팅 실행
  local oddsA, oddsB, probA, probB = game.analytics:getOdds()
  game.market:placeAIBets(oddsA, oddsB, probA, probB)
end

local function newGame()
  local g = {
    -- 알파: 넓은 패들(96px), 안정적 속도(410)
    left = Paddle(constants.ARENA_X + 16, constants.COLOR_CYAN, "ALPHA", constants.DEF_PADDLE_H, constants.DEF_SPEED),
    -- 베타: 컴팩트한 패들(78px), 초고속 이동(470)
    right = Paddle(constants.ARENA_X + constants.ARENA_W - 16 - constants.PADDLE_W, constants.COLOR_MAGENTA, "BETA", constants.ATK_PADDLE_H, constants.ATK_SPEED),
    ball = Ball(),
    aiAlpha = AIControllers.PredictiveAI.new(true),
    aiBeta = AIControllers.ReactiveAI.new(false),
    analytics = AnalyticsEngine.new(),
    market = BettingMarket.new(),
    ps = ParticleSystem.new(),

    scoreL = 0,
    scoreR = 0,
    acc = 0,
    time = 0,
    isPaused = false,
    timeScale = 1, -- 1x, 5x, 20x
    lastHitAction = "",

    flashTimer = 0,
    flashColor = { 0, 0, 0 },
  }
  return g
end

-- 공 이동 및 충돌 서브스텝 (초고속 구속에서도 터널링 방지)
local function updateBallAndCollisions(dt)
  local ball = game.ball
  local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
  local maxStepDist = 10
  local subSteps = math.max(1, math.ceil((speed * dt) / maxStepDist))
  local subDt = dt / subSteps

  local arenaTop = constants.ARENA_Y
  local arenaBottom = constants.ARENA_Y + constants.ARENA_H - ball.h

  for _ = 1, subSteps do
    ball:update(subDt)

    -- 상/하 벽 반사
    if ball.y < arenaTop then
      ball.y = arenaTop
      ball.vy = -ball.vy
      ParticleSystem.emit(game.ps, ball.x + ball.w * 0.5, arenaTop, 8, constants.COLOR_YELLOW, ball.vx, 0)
    elseif ball.y > arenaBottom then
      ball.y = arenaBottom
      ball.vy = -ball.vy
      ParticleSystem.emit(game.ps, ball.x + ball.w * 0.5, arenaBottom, 8, constants.COLOR_YELLOW, ball.vx, 0)
    end

    -- 패들 충돌
    if ball.vx < 0 and overlaps(ball, game.left) then
      handlePaddleHit(game, true)
      break
    elseif ball.vx > 0 and overlaps(ball, game.right) then
      handlePaddleHit(game, false)
      break
    end
  end
end

-- 고정 타임스텝 물리 스텝
local function step(dt)
  game.time = game.time + dt
  game.market:update(dt)

  if game.flashTimer > 0 then
    game.flashTimer = game.flashTimer - dt
  end

  -- 파티클 물리
  ParticleSystem.update(game.ps, dt)

  -- AI 자율 제어 입력 및 패들 이동 (상대방 위치 전달)
  local dirAlpha = game.aiAlpha:getDirection(game.left, game.ball, game.right, dt)
  local dirBeta = game.aiBeta:getDirection(game.right, game.ball, game.left, dt)
  game.left:update(dt, dirAlpha)
  game.right:update(dt, dirBeta)

  -- 공 물리 및 서브스텝 충돌
  updateBallAndCollisions(dt)

  -- 실시간 모멘텀 갱신
  game.analytics:updateMomentum(game.ball, constants.ARENA_X, constants.ARENA_W)

  -- 득점 판정
  local ball = game.ball
  local leftGoal = constants.ARENA_X
  local rightGoal = constants.ARENA_X + constants.ARENA_W

  if ball.x + ball.w < leftGoal then
    -- Beta (오른쪽 공격 성공!)
    game.scoreR = game.scoreR + 1
    game.analytics:resetRally()
    ParticleSystem.emit(game.ps, leftGoal, ball.y, 40, constants.COLOR_MAGENTA, 260, 0)

    if game.scoreR >= constants.WINNING_SCORE then
      game.analytics:recordMatchResult(false)
      game.market:settle(false)
      startNewMatch()
    else
      ball:reset(1)
    end

  elseif ball.x > rightGoal then
    -- Alpha (왼쪽 수비 후 카운터 성공!)
    game.scoreL = game.scoreL + 1
    game.analytics:resetRally()
    ParticleSystem.emit(game.ps, rightGoal, ball.y, 40, constants.COLOR_CYAN, -260, 0)

    if game.scoreL >= constants.WINNING_SCORE then
      game.analytics:recordMatchResult(true)
      game.market:settle(true)
      startNewMatch()
    else
      ball:reset(-1)
    end
  end
end

-- ── 3. LÖVE 콜백 ─────────────────────────────────────────────────────────
function love.load()
  local bg = constants.COLOR_BG
  lg.setBackgroundColor(bg[1], bg[2], bg[3])
  game = newGame()
  startNewMatch()
end

function love.update(dt)
  if game.isPaused then
    return
  end

  local scaledDt = math.min(dt, 0.1) * game.timeScale
  game.acc = game.acc + scaledDt
  local maxSteps = 50
  local stepCount = 0

  while game.acc >= constants.FIXED_DT and stepCount < maxSteps do
    step(constants.FIXED_DT)
    game.acc = game.acc - constants.FIXED_DT
    stepCount = stepCount + 1
  end
end

function love.draw()
  Renderer.draw(game)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "space" then
    game.isPaused = not game.isPaused
  elseif key == "tab" then
    if game.timeScale == 1 then
      game.timeScale = 5
    elseif game.timeScale == 5 then
      game.timeScale = 20
    else
      game.timeScale = 1
    end
  elseif key == "c" then
    game.market:cycleUserUnit()
  elseif key == "1" then
    local oddsA = game.analytics:getOdds()
    game.market:placeUserBet("ALPHA", oddsA)
  elseif key == "2" then
    local _, oddsB = game.analytics:getOdds()
    game.market:placeUserBet("BETA", oddsB)
  elseif key == "a" then
    local oddsA, oddsB = game.analytics:getOdds()
    local side = (game.analytics.liveMomentum >= 0.5) and "ALPHA" or "BETA"
    local odds = (side == "ALPHA") and oddsA or oddsB
    game.market:placeUserAllIn(side, odds)
  elseif key == "r" then
    game = newGame()
    startNewMatch()
  end
end
