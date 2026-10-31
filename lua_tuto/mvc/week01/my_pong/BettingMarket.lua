-- BettingMarket.lua
-- 사이버 카지노 도박 마켓 & 성향별 도박꾼 AI 4인방 모듈
-- 1. 켈리 퀀트 (The Quant)     : 켈리 기준 수학적 최적 분산 투자
-- 2. 역배 사냥꾼 (The Underdog): 고배당 역배에 전격 투자
-- 3. 정배 올인러 (The Bull)    : 승률 우세 쪽에 자산의 40% 이상 공격적 투자
-- 4. 마틴게일 (The Martingale) : 질 때마다 베팅액을 2배로 늘리는 파멸적 배수 베팅

local BettingMarket = {}
BettingMarket.__index = BettingMarket

function BettingMarket.new()
  local self = setmetatable({}, BettingMarket)

  -- 1) 사용자(관전자) 지갑
  self.userBalance = 1000
  self.userBetSide = nil     -- "ALPHA" | "BETA" | nil
  self.userBetAmount = 0
  self.userBetOdds = 0
  self.userUnit = 50         -- 1회 베팅 단위 ($50 / $100 / $250)
  self.lastResultToast = ""
  self.toastTimer = 0

  -- 2) 도박꾼 AI 4인방
  self.bettors = {
    -- 1. 켈리 퀀트
    {
      name = "켈리 퀀트",
      desc = "수학적 켈리 공식",
      balance = 1000,
      betSide = nil,
      betAmount = 0,
      betOdds = 0,
      isBankrupt = false,
      history = { 1000 },
      type = "kelly",
    },
    -- 2. 역배 사냥꾼
    {
      name = "역배 사냥꾼",
      desc = "고배당 역배 올인",
      balance = 1000,
      betSide = nil,
      betAmount = 0,
      betOdds = 0,
      isBankrupt = false,
      history = { 1000 },
      type = "underdog",
    },
    -- 3. 정배 올인러
    {
      name = "정배 올인러",
      desc = "승률 우세 공격형",
      balance = 1000,
      betSide = nil,
      betAmount = 0,
      betOdds = 0,
      isBankrupt = false,
      history = { 1000 },
      type = "favorite",
    },
    -- 4. 마틴게일
    {
      name = "마틴게일",
      desc = "패배 시 2배 베팅",
      balance = 1000,
      betSide = nil,
      betAmount = 0,
      betOdds = 0,
      isBankrupt = false,
      history = { 1000 },
      type = "martingale",
      currentStake = 40,
    },
  }

  return self
end

-- 켈리 공식 (Half-Kelly)
local function calcKelly(prob, odds)
  local b = odds - 1
  if b <= 0 then return 0 end
  local f = (b * prob - (1 - prob)) / b
  if f <= 0 then return 0 end
  return math.min(0.25, f * 0.5)
end

-- 새 매치 시작 시 도박꾼 AI들의 베팅 결정
function BettingMarket:placeAIBets(oddsA, oddsB, probA, probB)
  for _, b in ipairs(self.bettors) do
    b.betSide = nil
    b.betAmount = 0
    b.betOdds = 0

    if b.balance < 10 then
      b.isBankrupt = true
    else
      b.isBankrupt = false

      if b.type == "kelly" then
        local fA = calcKelly(probA, oddsA)
        local fB = calcKelly(probB, oddsB)
        if fA > fB and fA > 0.02 then
          b.betSide = "ALPHA"
          b.betAmount = math.floor(b.balance * fA)
          b.betOdds = oddsA
        elseif fB > fA and fB > 0.02 then
          b.betSide = "BETA"
          b.betAmount = math.floor(b.balance * fB)
          b.betOdds = oddsB
        end

      elseif b.type == "underdog" then
        -- 역배(배당률 높은 쪽) 선택
        if oddsA >= oddsB then
          b.betSide = "ALPHA"
          b.betOdds = oddsA
        else
          b.betSide = "BETA"
          b.betOdds = oddsB
        end
        -- 자산의 20% 과감히 투입 (최소 $30)
        b.betAmount = math.min(b.balance, math.max(30, math.floor(b.balance * 0.20)))

      elseif b.type == "favorite" then
        -- 정배(승률 높은 쪽)에 공격적 몰빵
        if probA >= probB then
          b.betSide = "ALPHA"
          b.betOdds = oddsA
        else
          b.betSide = "BETA"
          b.betOdds = oddsB
        end
        b.betAmount = math.min(b.balance, math.floor(b.balance * 0.40))

      elseif b.type == "martingale" then
        -- 매번 정배를 고르되, 베팅액은 마틴게일 룰
        local side = (probA >= probB) and "ALPHA" or "BETA"
        local odds = (side == "ALPHA") and oddsA or oddsB
        b.betSide = side
        b.betOdds = odds
        b.betAmount = math.min(b.balance, b.currentStake)
      end

      -- 자산 차감
      if b.betAmount > 0 then
        b.balance = b.balance - b.betAmount
      end
    end
  end
end

-- 관전자 일반 베팅 ($50, $100 등)
function BettingMarket:placeUserBet(side, odds)
  if self.userBetSide ~= nil then return false end
  local amount = math.min(self.userBalance, self.userUnit)
  if amount <= 0 then
    -- 파산 시 비상 대출
    self.userBalance = 500
    amount = self.userUnit
    self.lastResultToast = "🚨 파산! 비상 사채 $500 긴급 수혈!"
    self.toastTimer = 2.5
  end

  self.userBalance = self.userBalance - amount
  self.userBetSide = side
  self.userBetAmount = amount
  self.userBetOdds = odds
  return true
end

-- 관전자 전재산 올인 (ALL-IN)
function BettingMarket:placeUserAllIn(side, odds)
  if self.userBetSide ~= nil or self.userBalance <= 0 then return false end
  local amount = self.userBalance
  self.userBalance = 0
  self.userBetSide = side
  self.userBetAmount = amount
  self.userBetOdds = odds
  self.lastResultToast = string.format("🔥 전재산 $%d 올인! 인생 승부수! 🔥", amount)
  self.toastTimer = 2.5
  return true
end

-- 베팅 단위 변경 ($50 -> $100 -> $250 -> $50)
function BettingMarket:cycleUserUnit()
  if self.userUnit == 50 then
    self.userUnit = 100
  elseif self.userUnit == 100 then
    self.userUnit = 250
  else
    self.userUnit = 50
  end
end

-- 매치 종료 시 배당 정산
function BettingMarket:settle(winnerIsA)
  local winningSide = winnerIsA and "ALPHA" or "BETA"

  -- 1) 사용자 정산
  if self.userBetSide ~= nil then
    if self.userBetSide == winningSide then
      local payout = math.floor(self.userBetAmount * self.userBetOdds)
      local profit = payout - self.userBetAmount
      self.userBalance = self.userBalance + payout
      self.lastResultToast = string.format("★ 잭팟 적중! +$%d 획득! ★", profit)
      self.toastTimer = 3.0
    else
      self.lastResultToast = string.format("☠ 베팅 실패! -$%d 탕진... ☠", self.userBetAmount)
      self.toastTimer = 3.0
    end
    self.userBetSide = nil
    self.userBetAmount = 0
    self.userBetOdds = 0
  end

  -- 2) 도박꾼 AI 4인방 정산
  for _, b in ipairs(self.bettors) do
    if b.betSide ~= nil then
      if b.betSide == winningSide then
        local payout = math.floor(b.betAmount * b.betOdds)
        b.balance = b.balance + payout
        if b.type == "martingale" then
          b.currentStake = 40 -- 승리 시 기본 베팅액으로 리셋
        end
      else
        if b.type == "martingale" then
          b.currentStake = b.currentStake * 2 -- 패배 시 베팅액 2배 증액!
        end
      end
      b.betSide = nil
      b.betAmount = 0
      b.betOdds = 0
    end

    table.insert(b.history, b.balance)
    if #b.history > 20 then
      table.remove(b.history, 1)
    end
    if b.balance < 10 then
      b.isBankrupt = true
    end
  end
end

function BettingMarket:update(dt)
  if self.toastTimer > 0 then
    self.toastTimer = self.toastTimer - dt
  end
end

return BettingMarket
