-- TankEnemy.lua
-- 중장갑 적 클래스. 체력이 2이며 크기가 크고 격파 점수가 높다.

local class = require("class")
local EnemyModel = require("EnemyModel")

local TankEnemy = class(EnemyModel)

function TankEnemy:init(x, y)
  EnemyModel.init(self, x, y, "tank")
  self.w = 42
  self.h = 32
  self.hp = 2
  self.maxHp = 2
  self.scoreValue = 250
  self.diveSpeed = 140
end

return TankEnemy
