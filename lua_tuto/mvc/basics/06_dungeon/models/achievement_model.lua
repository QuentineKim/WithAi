-- achievement_model.lua
-- 처치 골드 누적 업적. 다른 모델에 의존하지 않고 EventBus 만 구독해 달성 여부를 판단한다.

local AchievementModel = {}
AchievementModel.__index = AchievementModel

function AchievementModel.new(bus, goldGoal)
  local goal = goldGoal or 15
  local self = setmetatable({
    bus = bus,
    goal = goal,
    totalGold = 0,
    unlocked = false,
  }, AchievementModel)
  bus:on("enemy_killed", function(data)
    self:onEnemyKilled(data)
  end)
  return self
end

function AchievementModel:onEnemyKilled(data)
  self.totalGold = self.totalGold + ((data and data.gold) or 0)
  if not self.unlocked and self.totalGold >= self.goal then
    self.unlocked = true
    self.bus:emit("achievement_unlocked", {
      text = string.format("처치 골드 %d 이상 달성", self.goal),
      gold = self.totalGold,
      goal = self.goal,
    })
  end
end

return AchievementModel
