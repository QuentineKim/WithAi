-- EnemyModel.lua
-- 적 1기의 "상태"만 담는다. 편대 이동/발사 결정은 GameModel 이 조율. love 비의존.

local class = require("class")
local EnemyAI = require("EnemyAI")

local EnemyModel = class()

--- 적 상태
-- @field x,y        number  좌상단 좌표
-- @field homeX,homeY number 편대 기준 좌표
-- @field w,h        number  크기
-- @field kind       string  적 종류 (기본 "basic")
-- @field hp,maxHp   number  체력
-- @field scoreValue number  격파 점수
-- @field diveSpeed  number  돌격 속도
-- @field aiState    string  현재 AI 상태 ("enter"|"formation"|"dive"|"return")
-- @field stateTimer number  상태 전이 타이머
-- @field diveVx,diveVy number 돌격 속도 벡터
-- @field alive      boolean 생존 여부
function EnemyModel:init(x, y, kind)
  self.x = x
  self.y = y
  self.homeX = x
  self.homeY = y
  self.w = 36
  self.h = 28
  self.kind = kind or "basic"
  self.hp = 1
  self.maxHp = 1
  self.scoreValue = 100
  self.diveSpeed = 190
  self.aiState = "enter"
  self.stateTimer = EnemyAI.ENTER_DURATION
  self.diveVx = 0
  self.diveVy = 0
  self.alive = true
end

--- 적 AI 상태를 갱신한다 (EnemyAI 에 위임).
function EnemyModel:update(dt, ctx)
  EnemyAI.update(self, dt, ctx)
end

--- 피해를 입고 격파되었으면 true 를 반환한다.
function EnemyModel:hit(dmg)
  if not self.alive then
    return false
  end
  self.hp = self.hp - (dmg or 1)
  if self.hp <= 0 then
    self.hp = 0
    self.alive = false
    return true
  end
  return false
end

function EnemyModel:centerX()
  return self.x + self.w * 0.5
end

function EnemyModel:centerY()
  return self.y + self.h * 0.5
end

return EnemyModel
