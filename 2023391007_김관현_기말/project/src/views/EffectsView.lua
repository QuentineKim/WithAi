-- EffectsView.lua
-- 연출(파티클·번쩍임·화면 흔들림·웨이브 배너). 2주차에서 Model 에 섞여 있던 것들이다.
-- Model 이 남긴 이벤트를 받아 "보이는 효과"만 만든다. 연출 상태는 View 의 것이다.
-- 연출용 난수는 게임 규칙에 영향이 없으므로 View 에 있어도 결정성(Model 의 약속)이 깨지지 않는다.

local class = require("class")

local EffectsView = class()

local BURST = 12
local PARTICLE_LIFE = 0.5
local FIREWORK_LIFE = 0.85
local FLASH_TIME = 0.06
local SHAKE_TIME = 0.3
local SHAKE_PIXELS = 10
local BANNER_TIME = 1.0
local BOSS_WARN_TIME = 1.6
local ACH_DURATION = 2.6
local GRAVITY = 180

local FIREWORK_COLORS = {
  { 1, 0.85, 0.2 },
  { 0.2, 0.95, 1 },
  { 1, 0.35, 0.85 },
  { 0.5, 1, 0.4 },
}

--- @param rand function|nil  0~1 난수 함수. 테스트에서 고정값을 주입할 수 있다. 기본 math.random
function EffectsView:init(rand, width, height)
  self.rand = rand or math.random
  self.width = width or 600
  self.height = height or 800
  self.particles = {}
  self.flash = 0
  self.flashColor = { 0.3, 0.3, 0.4 }
  self.shake = 0
  self.banner = 0
  self.bannerText = "WAVE CLEAR"
  self.bannerColor = { 0.6, 1, 0.6 }
  self.achQueue = {}
  self.achCurrent = nil
  self.achTimer = 0
  self.ox, self.oy = 0, 0
end

function EffectsView:_burst(x, y)
  for _ = 1, BURST do
    local a = self.rand() * math.pi * 2
    local s = 40 + self.rand() * 120
    self.particles[#self.particles + 1] = {
      x = x,
      y = y,
      vx = math.cos(a) * s,
      vy = math.sin(a) * s,
      life = PARTICLE_LIFE,
      r = 1,
      g = 0.8,
      b = 0.2,
      size = 3,
      gravity = 0,
    }
  end
end

function EffectsView:_firework(cx, cy, count)
  for _ = 1, count do
    local a = self.rand() * math.pi * 2
    local s = 70 + self.rand() * 170
    local idx = math.floor(self.rand() * #FIREWORK_COLORS) + 1
    local col = FIREWORK_COLORS[idx] or FIREWORK_COLORS[1]
    self.particles[#self.particles + 1] = {
      x = cx,
      y = cy,
      vx = math.cos(a) * s,
      vy = math.sin(a) * s,
      life = FIREWORK_LIFE,
      r = col[1],
      g = col[2],
      b = col[3],
      size = 4,
      gravity = GRAVITY,
    }
  end
end

function EffectsView:_sparks(x, y, count, r, g, b)
  for _ = 1, count do
    local a = self.rand() * math.pi * 2
    local s = 50 + self.rand() * 90
    self.particles[#self.particles + 1] = {
      x = x,
      y = y,
      vx = math.cos(a) * s,
      vy = math.sin(a) * s,
      life = 0.28,
      r = r,
      g = g,
      b = b,
      size = 2,
      gravity = 0,
    }
  end
end

function EffectsView:_celebrate()
  local w, h = self.width, self.height
  self:_firework(w * 0.25, h * 0.22, 12)
  self:_firework(w * 0.50, h * 0.18, 12)
  self:_firework(w * 0.75, h * 0.22, 12)
  if self.flash < 0.14 then
    self.flash = 0.14
    self.flashColor = { 1, 0.85, 0.2 }
  end
  if self.shake < 0.18 then
    self.shake = 0.18
  end
end

--- Model 이벤트 → 연출. (사운드를 붙인다면 여기서 love.audio 를 호출한다)
function EffectsView:onEvent(ev)
  if type(ev) ~= "table" or not ev.type then
    return
  end
  if ev.type == "enemy_destroyed" then
    self:_burst(ev.x, ev.y)
    self.flash = FLASH_TIME
    self.flashColor = { 0.3, 0.3, 0.4 }
  elseif ev.type == "player_hit" then
    self.shake = SHAKE_TIME
  elseif ev.type == "formation_cleared" then
    self.banner = BANNER_TIME
    self.bannerText = "WAVE CLEAR"
    self.bannerColor = { 0.6, 1, 0.6 }
  elseif ev.type == "boss_appeared" then
    self.banner = BOSS_WARN_TIME
    self.bannerText = "WARNING: BOSS INCOMING!"
    self.bannerColor = { 1, 0.3, 0.3 }
    self.flash = 0.22
    self.flashColor = { 0.45, 0.08, 0.08 }
    self.shake = 0.45
  elseif ev.type == "boss_destroyed" then
    local bx = ev.x or (self.width * 0.5)
    local by = ev.y or (self.height * 0.25)
    self:_firework(bx, by, 14)
    self:_firework(bx - 45, by + 15, 11)
    self:_firework(bx + 45, by + 15, 11)
    self.flash = 0.25
    self.flashColor = { 1, 0.85, 0.2 }
    self.shake = 0.5
  elseif ev.type == "achievement_unlocked" then
    self:_celebrate()
    if not self.achCurrent then
      self.achCurrent = ev
      self.achTimer = ACH_DURATION
    else
      self.achQueue[#self.achQueue + 1] = ev
    end
  elseif ev.type == "graze" then
    self:_sparks(ev.x or (self.width * 0.5), ev.y or (self.height * 0.8), 4, 0.3, 0.95, 1)
  elseif ev.type == "overdrive_started" then
    self:_celebrate()
    self.banner = 1.4
    self.bannerText = "OVERDRIVE! x2 FIRE"
    self.bannerColor = { 1, 0.85, 0.2 }
  elseif ev.type == "powerup_picked" then
    self.flash = 0.08
    self.flashColor = { 0.3, 0.9, 0.6 }
  elseif ev.type == "shield_broken" then
    self.flash = 0.15
    self.flashColor = { 0.2, 0.9, 1 }
    self.shake = 0.2
  elseif ev.type == "boss_enraged" then
    self.flash = 0.25
    self.flashColor = { 0.9, 0.1, 0.15 }
    self.shake = 0.45
    self.banner = 1.5
    self.bannerText = "BOSS ENRAGED!"
    self.bannerColor = { 1, 0.2, 0.25 }
  end
end

-- 연출 시간 진행. 흔들림 오프셋도 여기서 정해 draw 는 읽기만 한다.
function EffectsView:update(dt)
  if self.flash > 0 then
    self.flash = self.flash - dt
  end
  if self.banner > 0 then
    self.banner = self.banner - dt
  end
  if self.achCurrent then
    self.achTimer = self.achTimer - dt
    if self.achTimer <= 0 then
      if #self.achQueue > 0 then
        self.achCurrent = table.remove(self.achQueue, 1)
        self.achTimer = ACH_DURATION
      else
        self.achCurrent = nil
        self.achTimer = 0
      end
    end
  end
  if self.shake > 0 then
    self.shake = self.shake - dt
    self.ox = (self.rand() - 0.5) * SHAKE_PIXELS
    self.oy = (self.rand() - 0.5) * SHAKE_PIXELS
  else
    self.ox, self.oy = 0, 0
  end

  local list = self.particles
  for i = #list, 1, -1 do
    local p = list[i]
    p.vy = p.vy + (p.gravity or 0) * dt
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(list, i)
    end
  end
end

function EffectsView:drawFlash(gfx, width, height)
  if self.flash > 0 then
    local c = self.flashColor
    gfx.setColor(c[1], c[2], c[3], 0.55)
    gfx.rectangle("fill", 0, 0, width, height)
  end
end

function EffectsView:drawParticles(gfx)
  for i = 1, #self.particles do
    local p = self.particles[i]
    gfx.setColor(p.r or 1, p.g or 0.8, p.b or 0.2)
    local size = p.size or 3
    gfx.rectangle("fill", p.x, p.y, size, size)
  end
end

function EffectsView:drawBanner(gfx, width, height)
  if self.banner > 0 then
    local c = self.bannerColor
    gfx.setColor(c[1], c[2], c[3])
    gfx.printf(self.bannerText, 0, height * 0.4, width, "center")
  end

  if self.achCurrent then
    local boxW, boxH = 360, 54
    local boxX = (width - boxW) * 0.5
    local boxY = height * 0.12
    gfx.setColor(0.08, 0.05, 0.18, 0.88)
    gfx.rectangle("fill", boxX, boxY, boxW, boxH)
    if math.floor(self.achTimer * 8) % 2 == 0 then
      gfx.setColor(1, 0.85, 0.2)
    else
      gfx.setColor(0.2, 0.95, 1)
    end
    gfx.rectangle("line", boxX, boxY, boxW, boxH)
    gfx.setColor(1, 0.85, 0.2)
    gfx.printf("ACHIEVEMENT UNLOCKED!", boxX, boxY + 8, boxW, "center")
    gfx.setColor(1, 1, 1)
    gfx.printf(self.achCurrent.title or self.achCurrent.id or "", boxX, boxY + 28, boxW, "center")
  end
end

return EffectsView
