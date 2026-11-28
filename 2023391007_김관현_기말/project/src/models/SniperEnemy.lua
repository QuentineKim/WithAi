-- SniperEnemy.lua
-- R7 신규 적 클래스: 고속 직선 돌격형 저격수 (HP 1, 점수 200, 빠른 돌격 속도).

local class = require("class")
local EnemyModel = require("EnemyModel")

local SniperEnemy = class(EnemyModel)

function SniperEnemy:init(x, y)
  EnemyModel.init(self, x, y, "sniper")
  self.w = 28
  self.h = 24
  self.hp = 1
  self.maxHp = 1
  self.scoreValue = 200
  self.diveSpeed = 340
end

return SniperEnemy
