-- ScoutEnemy.lua
-- 정찰형 적 클래스. 크기가 작고 돌격 속도가 빠르다.

local class = require("class")
local EnemyModel = require("EnemyModel")

local ScoutEnemy = class(EnemyModel)

function ScoutEnemy:init(x, y)
  EnemyModel.init(self, x, y, "scout")
  self.w = 32
  self.h = 24
  self.hp = 1
  self.maxHp = 1
  self.scoreValue = 150
  self.diveSpeed = 270
end

return ScoutEnemy
