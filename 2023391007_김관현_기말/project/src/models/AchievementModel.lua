-- AchievementModel.lua
-- 업적 모델 (Observer). GameModel 을 전혀 모르고 drainEvents() 이벤트만 소비해 업적을 판정한다.
-- love / io / print 비의존.

local class = require("class")

local AchievementModel = class()

local TRIGGER_HAPPY_SHOTS = 20
local LAST_STAND_HITS = 2
local LAST_STAND_KILLS = 3

local DEFS = {
  trigger_happy = "TRIGGER HAPPY",
  last_stand = "LAST STAND",
  clean_boss = "UNTOUCHABLE BOSS",
}

function AchievementModel:init()
  self.listeners = {}
  self.unlocked = {}
  self.unlockedOrder = {}
  self.shotsFired = 0
  self.playerHits = 0
  self.lastStandKills = 0
  self.gameOver = false
  self.inBossFight = false
  self.bossFightHit = false
end

function AchievementModel:subscribe(fn)
  if type(fn) == "function" then
    self.listeners[#self.listeners + 1] = fn
  end
end

function AchievementModel:isUnlocked(id)
  return self.unlocked[id] == true
end

function AchievementModel:unlockedCount()
  return #self.unlockedOrder
end

function AchievementModel:_unlock(id)
  if self.unlocked[id] then
    return
  end
  self.unlocked[id] = true
  self.unlockedOrder[#self.unlockedOrder + 1] = id
  local evt = {
    type = "achievement_unlocked",
    id = id,
    title = DEFS[id] or id,
  }
  for i = 1, #self.listeners do
    self.listeners[i](evt)
  end
end

function AchievementModel:onEvent(ev)
  if type(ev) ~= "table" or not ev.type then
    return
  end
  local t = ev.type

  if t == "fire" then
    self.shotsFired = self.shotsFired + 1
    if self.shotsFired >= TRIGGER_HAPPY_SHOTS then
      self:_unlock("trigger_happy")
    end
  elseif t == "player_hit" then
    self.playerHits = self.playerHits + 1
    if self.inBossFight then
      self.bossFightHit = true
    end
  elseif t == "game_over" then
    self.gameOver = true
  elseif t == "enemy_destroyed" then
    if not self.gameOver and self.playerHits >= LAST_STAND_HITS then
      self.lastStandKills = self.lastStandKills + 1
      if self.lastStandKills >= LAST_STAND_KILLS then
        self:_unlock("last_stand")
      end
    end
  elseif t == "boss_appeared" then
    self.inBossFight = true
    self.bossFightHit = false
  elseif t == "boss_destroyed" then
    if self.inBossFight and not self.bossFightHit then
      self:_unlock("clean_boss")
    end
    self.inBossFight = false
  end
end

return AchievementModel
