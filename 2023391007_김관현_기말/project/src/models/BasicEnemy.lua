-- BasicEnemy.lua
-- 기본 적 클래스. EnemyModel 을 상속한다.

local class = require("class")
local EnemyModel = require("EnemyModel")

local BasicEnemy = class(EnemyModel)

function BasicEnemy:init(x, y)
  EnemyModel.init(self, x, y, "basic")
  self.hp = 1
  self.maxHp = 1
  self.scoreValue = 100
  self.diveSpeed = 190
end

return BasicEnemy
