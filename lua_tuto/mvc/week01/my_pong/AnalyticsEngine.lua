-- AnalyticsEngine.lua
-- ELO 레이팅, 승률 추정, 동적 배당률 및 실시간 랠리 텔레메트리 엔진

local AnalyticsEngine = {}
AnalyticsEngine.__index = AnalyticsEngine

function AnalyticsEngine.new()
  local self = setmetatable({}, AnalyticsEngine)

  -- ELO 레이팅 (초기값 1500)
  self.ratingA = 1500
  self.ratingB = 1500
  self.kFactor = 32

  -- 전적
  self.totalMatches = 0
  self.winsA = 0
  self.winsB = 0

  -- 랠리 및 속도 통계
  self.currentRally = 0
  self.maxRally = 0
  self.totalHits = 0
  self.peakSpeed = 0

  -- 실시간 모멘텀 (0.0: Beta 절대 우세 ~ 1.0: Alpha 절대 우세)
  self.liveMomentum = 0.5

  return self
end

-- 기대 승률 계산: E_A = 1 / (1 + 10^((R_B - R_A)/400))
function AnalyticsEngine:getExpectedProbabilities()
  local expA = 1 / (1 + 10 ^ ((self.ratingB - self.ratingA) / 400))
  local expB = 1 - expA
  return expA, expB
end

-- 북메이커 동적 배당률 계산 (마진 8% 적용)
function AnalyticsEngine:getOdds()
  local probA, probB = self:getExpectedProbabilities()
  local margin = 0.08
  -- 최소 배당 1.05배 클램프
  local oddsA = math.max(1.05, (1 - margin) / math.max(0.01, probA))
  local oddsB = math.max(1.05, (1 - margin) / math.max(0.01, probB))
  return oddsA, oddsB, probA, probB
end

-- 경기(Set) 종료 시 ELO 갱신
function AnalyticsEngine:recordMatchResult(winnerIsA)
  local probA, probB = self:getExpectedProbabilities()
  local scoreA = winnerIsA and 1 or 0
  local scoreB = winnerIsA and 0 or 1

  self.ratingA = math.floor(self.ratingA + self.kFactor * (scoreA - probA) + 0.5)
  self.ratingB = math.floor(self.ratingB + self.kFactor * (scoreB - probB) + 0.5)

  self.totalMatches = self.totalMatches + 1
  if winnerIsA then
    self.winsA = self.winsA + 1
  else
    self.winsB = self.winsB + 1
  end
end

-- 랠리 타격 기록
function AnalyticsEngine:recordHit(ballSpeed)
  self.currentRally = self.currentRally + 1
  self.totalHits = self.totalHits + 1
  if self.currentRally > self.maxRally then
    self.maxRally = self.currentRally
  end
  if ballSpeed > self.peakSpeed then
    self.peakSpeed = ballSpeed
  end
end

-- 실점 시 랠리 리셋
function AnalyticsEngine:resetRally()
  self.currentRally = 0
end

-- 실시간 랠리 모멘텀 계산 (공 위치 및 방향 기반)
function AnalyticsEngine:updateMomentum(ball, arenaX, arenaW)
  local relX = (ball.x - arenaX) / arenaW -- 0.0 (왼쪽/Alpha) ~ 1.0 (오른쪽/Beta)
  local targetMomentum
  if ball.vx > 0 then
    -- 공이 오른쪽으로 향함: Alpha가 공을 성공적으로 쳐서 공격 중
    targetMomentum = 0.5 + (relX * 0.4)
  else
    -- 공이 왼쪽으로 향함: Beta가 공을 쳐서 Alpha를 위협 중
    targetMomentum = 0.5 - ((1 - relX) * 0.4)
  end

  self.liveMomentum = self.liveMomentum + (targetMomentum - self.liveMomentum) * 0.1
end

return AnalyticsEngine
