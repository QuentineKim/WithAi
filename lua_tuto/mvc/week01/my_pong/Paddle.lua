-- Paddle.lua
-- 패들 엔티티 클래스 (역할별 커스텀 스탯 지원)

local class = require("class")
local constants = require("constants")

local Paddle = class()

function Paddle:init(x, color, name, customH, customSpeed)
  self.x = x
  self.w = constants.PADDLE_W
  self.h = customH or constants.PADDLE_H
  self.y = constants.ARENA_Y + (constants.ARENA_H - self.h) * 0.5
  self.color = color
  self.name = name or "Paddle"
  self.speed = customSpeed or constants.PADDLE_SPEED
end

-- dir: -1(위), 0(정지), 1(아래)
function Paddle:update(dt, dir)
  self.y = self.y + dir * self.speed * dt

  -- 아레나 내부 경계 클램핑
  local minY = constants.ARENA_Y
  local maxY = constants.ARENA_Y + constants.ARENA_H - self.h
  if self.y < minY then
    self.y = minY
  elseif self.y > maxY then
    self.y = maxY
  end
end

return Paddle
