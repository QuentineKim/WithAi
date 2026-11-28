-- WeaponDecorator.lua
-- Decorator 패턴으로 플레이어 무기(기본 단발 → 3갈래 산탄 → 연사 2배 오버드라이브)를 조합한다.
-- love / io / print 비의존.

local class = require("class")
local BulletModel = require("BulletModel")

local BULLET_SPEED = 520
local BASE_COOLDOWN = 0.25
local SPREAD_ANGLE = 14 * math.pi / 180

local BaseWeapon = class()

function BaseWeapon:init() end

function BaseWeapon:cooldown()
  return BASE_COOLDOWN
end

function BaseWeapon:fire(player, out)
  out[#out + 1] = BulletModel(player.x + player.w * 0.5 - 2, player.y, 0, -BULLET_SPEED, 4, 12, "player")
end

local SpreadDecorator = class()

function SpreadDecorator:init(inner)
  self.inner = inner
end

function SpreadDecorator:cooldown()
  return self.inner:cooldown()
end

function SpreadDecorator:fire(player, out)
  self.inner:fire(player, out)
  local cx = player.x + player.w * 0.5 - 2
  local leftAngle = -math.pi * 0.5 - SPREAD_ANGLE
  local rightAngle = -math.pi * 0.5 + SPREAD_ANGLE
  out[#out + 1] = BulletModel(
    cx,
    player.y,
    math.cos(leftAngle) * BULLET_SPEED,
    math.sin(leftAngle) * BULLET_SPEED,
    4,
    12,
    "player"
  )
  out[#out + 1] = BulletModel(
    cx,
    player.y,
    math.cos(rightAngle) * BULLET_SPEED,
    math.sin(rightAngle) * BULLET_SPEED,
    4,
    12,
    "player"
  )
end

local RapidDecorator = class()

function RapidDecorator:init(inner, factor)
  self.inner = inner
  self.factor = factor or 0.5
end

function RapidDecorator:cooldown()
  return self.inner:cooldown() * self.factor
end

function RapidDecorator:fire(player, out)
  self.inner:fire(player, out)
end

return {
  BaseWeapon = BaseWeapon,
  SpreadDecorator = SpreadDecorator,
  RapidDecorator = RapidDecorator,
}
