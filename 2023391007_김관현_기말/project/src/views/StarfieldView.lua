-- StarfieldView.lua
-- 3겹 패럴랙스 우주 배경 + 보스 등장/오버드라이브 시 초고속 워프 연출.
-- love 비의존(주입받은 gfx 와 rand 만 사용).

local class = require("class")

local StarfieldView = class()

local LAYERS = {
  { count = 18, speed = 28, size = 1, alpha = 0.45 },
  { count = 16, speed = 62, size = 2, alpha = 0.72 },
  { count = 11, speed = 118, size = 2, alpha = 0.95 },
}

function StarfieldView:init(width, height, rand)
  self.width = width or 600
  self.height = height or 800
  self.rand = rand or math.random
  self.warp = 0
  self.stars = {}

  for li = 1, #LAYERS do
    local cfg = LAYERS[li]
    for _ = 1, cfg.count do
      self.stars[#self.stars + 1] = {
        x = self.rand() * self.width,
        y = self.rand() * self.height,
        speed = cfg.speed,
        size = cfg.size,
        alpha = cfg.alpha,
      }
    end
  end
end

function StarfieldView:onEvent(ev)
  if type(ev) ~= "table" or not ev.type then
    return
  end
  if ev.type == "boss_appeared" then
    self.warp = 2.0
  elseif ev.type == "boss_destroyed" then
    self.warp = math.max(self.warp, 1.0)
  elseif ev.type == "overdrive_started" then
    self.warp = math.max(self.warp, 1.2)
  end
end

function StarfieldView:update(dt)
  local mult = 1 + self.warp * 5.0
  local h = self.height
  local w = self.width
  for i = 1, #self.stars do
    local s = self.stars[i]
    s.y = s.y + s.speed * mult * dt
    if s.y > h then
      s.y = s.y - h
      s.x = self.rand() * w
    end
  end
  if self.warp > 0 then
    self.warp = math.max(0, self.warp - dt)
  end
end

function StarfieldView:draw(gfx)
  local warp = self.warp
  local extraH = warp * 18
  for i = 1, #self.stars do
    local s = self.stars[i]
    if warp > 0 then
      gfx.setColor(0.55, 0.85, 1, s.alpha)
      gfx.rectangle("fill", s.x, s.y, s.size, s.size + extraH)
    else
      gfx.setColor(0.85, 0.9, 1, s.alpha)
      gfx.rectangle("fill", s.x, s.y, s.size, s.size)
    end
  end
end

return StarfieldView
