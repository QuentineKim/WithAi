-- Ball.lua
-- 공 엔티티 클래스 (트론 라이트 궤적 포함)

local class = require("class")
local constants = require("constants")

local Ball = class()

function Ball:init()
  self.w = constants.BALL_SIZE
  self.h = constants.BALL_SIZE
  self.trail = {}
  self.maxTrail = 18
  self:reset(1)
end

function Ball:reset(dir)
  self.x = constants.ARENA_X + (constants.ARENA_W - self.w) * 0.5
  self.y = constants.ARENA_Y + (constants.ARENA_H - self.h) * 0.5
  self.vx = constants.BALL_SPEED * (dir or 1)
  -- 발사 시 약간의 임의 수직 각도 부여 (-60 ~ +60 px/s)
  self.vy = (math.random() - 0.5) * 120
  self.trail = {}
end

function Ball:update(dt)
  -- 궤적 잔상 기록
  table.insert(self.trail, 1, {
    x = self.x + self.w * 0.5,
    y = self.y + self.h * 0.5,
  })
  if #self.trail > self.maxTrail then
    table.remove(self.trail)
  end

  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
end

return Ball
