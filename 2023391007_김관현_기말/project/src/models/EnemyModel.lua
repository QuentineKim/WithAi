-- EnemyModel.lua
-- 적 1기의 "상태"만 담는다. 편대 이동/발사 결정은 GameModel 이 조율. love 비의존.

local class = require("class")

local EnemyModel = class()

--- 적 상태
-- @field x,y        number  좌상단 좌표
-- @field w,h        number  크기
-- @field kind       string  적 종류 (기본 "basic")
-- @field hp,maxHp   number  체력
-- @field scoreValue number  격파 점수
-- @field diveSpeed  number  돌격 속도 (R4 AI 에서 사용)
-- @field alive      boolean 생존 여부
function EnemyModel:init(x, y, kind)
  self.x = x
  self.y = y
  self.w = 36
  self.h = 28
  self.kind = kind or "basic"
  self.hp = 1
  self.maxHp = 1
  self.scoreValue = 100
  self.diveSpeed = 190
  self.alive = true
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
