-- boss_enrage_test.lua
-- 보스 2페이즈 광폭화, 조준 경고선 레이저, StarfieldView 워프 연출을 검사한다.
-- 실행: cd project/tests && lua boss_enrage_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
h.setup(app)

local BossModel = require("BossModel")
local BossView = require("BossView")
local StarfieldView = require("StarfieldView")
local GameModel = require("GameModel")

local DT = 1 / 60
local IDLE = { move = 0, fire = false, missile = false }

local function printed(gfx, text)
  for _, c in ipairs(gfx.calls) do
    if (c.name == "print" or c.name == "printf") and tostring(c.args[1]):find(text, 1, true) then
      return true
    end
  end
  return false
end

print("[boss_enrage_test] " .. app .. "/")

h.test("BossModel: HP 50% 이하 시 enraged 전환 및 이동 속도 증가", function()
  local b = BossModel(200, 70, 40)
  local x0 = b.x
  b:update(DT, 600, {}, 300)
  local normalMove = math.abs(b.x - x0)
  b:takeDamage(20)
  local x1 = b.x
  b:update(DT, 600, {}, 300)
  local rageMove = math.abs(b.x - x1)
  return b.enraged == true and rageMove > normalMove * 1.4
end)

h.test("BossModel: 광폭화 중 idle → warning → firing → idle 레이저 전이", function()
  local b = BossModel(200, 70, 40)
  b:takeDamage(20)
  b.laserCooldown = 0.01
  local out = {}
  b:update(DT, 600, out, 310)
  local isWarning = b.laserState == "warning" and b.laserX == 310
  for _ = 1, 55 do
    b:update(DT, 600, out, 310)
  end
  local isFiring = b.laserState == "firing"
  for _ = 1, 35 do
    b:update(DT, 600, out, 310)
  end
  local backIdle = b.laserState == "idle"
  return isWarning and isFiring and backIdle
end)

h.test("BossPhase: 레이저 firing 중 플레이어가 범위 안이면 1회만 피격(방어막 흡수 포함)", function()
  local g = GameModel({ width = 600, height = 800, seed = 1 })
  g.score = 1000
  g:update(DT, IDLE)
  for _, e in ipairs(g.enemies) do
    e.alive = false
  end
  g.boss.enraged = true
  g.boss.laserState = "firing"
  g.boss.laserTimer = 0.4
  g.boss.laserX = g.player.x + g.player.w * 0.5
  g.boss.laserHit = false
  g.shield = true
  g:update(DT, IDLE)
  local absorbed = g.lives == 3 and g.shield == false

  g.boss.laserHit = false
  g:update(DT, IDLE)
  g:update(DT, IDLE)
  return absorbed and g.lives == 2
end)

h.test("BossView: warning 시 DANGER 경고 문구, firing 시 레이저 빔 사각형을 그린다", function()
  local b = BossModel(200, 70, 40)
  b.enraged = true
  b.laserState = "warning"
  b.laserX = 300
  local gfxW = h.fakeGfx()
  BossView.draw(gfxW, b, 600)
  local hasDanger = printed(gfxW, "DANGER")

  b.laserState = "firing"
  local gfxF = h.fakeGfx()
  BossView.draw(gfxF, b, 600)
  return hasDanger and h.count(gfxF, "rectangle") >= 5
end)

h.test("StarfieldView: boss_appeared 시 워프 활성화 및 update/draw 정상 동작", function()
  local sf = StarfieldView(600, 800, h.fixedRand())
  local y0 = sf.stars[1].y
  sf:onEvent({ type = "boss_appeared" })
  local warped = sf.warp > 1.5
  sf:update(DT)
  local moved = sf.stars[1].y ~= y0
  local gfx = h.fakeGfx()
  sf:draw(gfx)
  return warped and moved and h.count(gfx, "rectangle") >= 40
end)

h.finish()
