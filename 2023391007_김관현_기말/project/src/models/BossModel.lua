-- BossModel.lua
-- 보스 1기의 상태 + 이동 + 원형 탄막 발사. love 비의존.
-- 탄막은 기존 BulletModel(vx, vy 보유) 그대로 쓴다 → 총알 자료구조를 바꿀 필요가 없다.

local class = require("class")
local BulletModel = require("BulletModel")

local BossModel = class()

local SPEED = 70
local RAGE_SPEED_MULT = 1.6
local FIRE_INTERVAL = 1.2
local RAGE_FIRE_INTERVAL = 0.95
local RADIAL_COUNT = 18
local BULLET_SPEED = 180
local FAN_COUNT = 5
local FAN_SPREAD = 0.7
local LASER_WARN_TIME = 0.8
local LASER_FIRE_TIME = 0.45
local LASER_COOLDOWN = 2.4

--- 보스 상태
-- @field x,y,w,h     number
-- @field hp,maxHp    number
-- @field alive       boolean
-- @field dir         number  -1 | 1
-- @field fireTimer   number  다음 탄막까지 남은 시간(초)
-- @field enraged     boolean HP 50% 이하 광폭화 여부
-- @field laserState  string  "idle" | "warning" | "firing"
function BossModel:init(x, y, hp)
  self.x, self.y = x, y
  self.w, self.h = 120, 60
  self.hp, self.maxHp = hp, hp
  self.alive = true
  self.dir = 1
  self.fireTimer = 1.0
  self.enraged = false
  self.laserState = "idle"
  self.laserTimer = 0
  self.laserX = x + self.w * 0.5
  self.laserW = 28
  self.laserCooldown = 2.6
  self.laserHit = false
end

function BossModel:centerX()
  return self.x + self.w * 0.5
end

function BossModel:centerY()
  return self.y + self.h * 0.5
end

--- 좌우 왕복 이동 + 주기적 원형/부채꼴 탄막 + 광폭화 경고선 레이저.
function BossModel:update(dt, width, out, playerX)
  local spd = self.enraged and (SPEED * RAGE_SPEED_MULT) or SPEED
  self.x = self.x + self.dir * spd * dt
  if self.x < 10 then
    self.x, self.dir = 10, 1
  elseif self.x > width - 10 - self.w then
    self.x, self.dir = width - 10 - self.w, -1
  end

  if self.enraged then
    if self.laserState == "idle" then
      self.laserCooldown = self.laserCooldown - dt
      if self.laserCooldown <= 0 then
        self.laserState = "warning"
        self.laserTimer = LASER_WARN_TIME
        self.laserX = playerX or self:centerX()
        self.laserHit = false
      end
    elseif self.laserState == "warning" then
      self.laserTimer = self.laserTimer - dt
      if self.laserTimer <= 0 then
        self.laserState = "firing"
        self.laserTimer = LASER_FIRE_TIME
        self.laserHit = false
      end
    elseif self.laserState == "firing" then
      self.laserTimer = self.laserTimer - dt
      if self.laserTimer <= 0 then
        self.laserState = "idle"
        self.laserCooldown = LASER_COOLDOWN
        self.laserHit = false
      end
    end
  end

  self.fireTimer = self.fireTimer - dt
  if self.fireTimer <= 0 then
    self.fireTimer = self.enraged and RAGE_FIRE_INTERVAL or FIRE_INTERVAL
    local cx, cy = self:centerX(), self:centerY()
    for k = 0, RADIAL_COUNT - 1 do
      local a = (k / RADIAL_COUNT) * math.pi * 2
      out[#out + 1] = BulletModel(cx, cy, math.cos(a) * BULLET_SPEED, math.sin(a) * BULLET_SPEED, 6, 6, "enemy")
    end
    if self.enraged then
      local aimX = playerX or cx
      local base = math.atan2(600, aimX - cx)
      for i = 0, FAN_COUNT - 1 do
        local offset = ((i / (FAN_COUNT - 1)) - 0.5) * FAN_SPREAD
        local a = base + offset
        out[#out + 1] = BulletModel(cx, cy, math.cos(a) * (BULLET_SPEED * 1.25), math.sin(a) * (BULLET_SPEED * 1.25), 6, 6, "enemy")
      end
    end
  end
end

--- 피해를 받는다. @return boolean  이번 피해로 쓰러졌는가
function BossModel:takeDamage(amount)
  self.hp = self.hp - amount
  if self.hp <= self.maxHp * 0.5 then
    self.enraged = true
  end
  if self.hp <= 0 then
    self.hp = 0
    self.alive = false
    self.laserState = "idle"
    return true
  end
  return false
end

return BossModel
