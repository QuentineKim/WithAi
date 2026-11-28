-- powerup_graze_test.lua
-- WeaponDecorator(Decorator 패턴), 스침(Graze) 오버드라이브, 방어막, 슬로우, 강하 격추 보너스를 검사한다.
-- 실행: cd project/tests && lua powerup_graze_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
h.setup(app)

local WeaponDecorator = require("WeaponDecorator")
local GameModel = require("GameModel")
local BulletModel = require("BulletModel")

local DT = 1 / 60
local IDLE = { move = 0, fire = false, missile = false }

local function hasEvent(events, t)
  for _, e in ipairs(events) do
    if e.type == t then
      return true
    end
  end
  return false
end

print("[powerup_graze_test] " .. app .. "/")

h.test("WeaponDecorator: Base(1발) / Spread(3발) / Rapid(쿨다운 절반) 조합이 동작한다", function()
  local p = { x = 280, y = 700, w = 40, h = 24 }
  local base = WeaponDecorator.BaseWeapon()
  local spread = WeaponDecorator.SpreadDecorator(base)
  local overdrive = WeaponDecorator.RapidDecorator(spread, 0.5)
  local out1, out2, out3 = {}, {}, {}
  base:fire(p, out1)
  spread:fire(p, out2)
  overdrive:fire(p, out3)
  return #out1 == 1 and #out2 == 3 and #out3 == 3
    and math.abs(base:cooldown() - 0.25) < 1e-6
    and math.abs(overdrive:cooldown() - 0.125) < 1e-6
end)

h.test("Graze: 적 탄환이 18px 이내 스치면 게이지 +25, 같은 탄은 중복 스침 안 됨", function()
  local g = GameModel({ width = 600, height = 800, seed = 1 })
  for _, e in ipairs(g.enemies) do
    e.alive = false
  end
  local p = g.player
  local eb = BulletModel(p.x - 12, p.y + 4, 0, 0, 4, 12, "enemy")
  g.enemyBullets[1] = eb
  g:update(DT, IDLE)
  local ev1 = g:drainEvents()
  local afterFirst = g.grazeGauge == 25 and hasEvent(ev1, "graze") and g.lives == 3
  g:update(DT, IDLE)
  local ev2 = g:drainEvents()
  return afterFirst and g.grazeGauge == 25 and not hasEvent(ev2, "graze")
end)

h.test("Overdrive: 스침 4회(100%) 시 오버드라이브 5초 발동 및 3갈래 발사", function()
  local g = GameModel({ width = 600, height = 800, seed = 1 })
  for _, e in ipairs(g.enemies) do
    e.alive = false
  end
  local p = g.player
  for i = 1, 4 do
    g.enemyBullets[i] = BulletModel(p.x - 10, p.y + 4, 0, 0, 4, 12, "enemy")
  end
  g:update(DT, IDLE)
  local ev = g:drainEvents()
  local started = g.overdriveTimer > 4.9 and hasEvent(ev, "overdrive_started")
  g:update(DT, { move = 0, fire = true, missile = false })
  return started and #g.bullets == 3
end)

h.test("Shield: 방어막 보유 중 적 탄 피격 시 라이프를 잃지 않고 shield_broken 발행", function()
  local g = GameModel({ width = 600, height = 800, seed = 1 })
  g.shield = true
  local p = g.player
  g.enemyBullets[1] = BulletModel(p.x + 10, p.y + 5, 0, 0, 4, 12, "enemy")
  g:update(DT, IDLE)
  local ev = g:drainEvents()
  return g.lives == 3 and g.shield == false and hasEvent(ev, "shield_broken")
end)

h.test("Slow: slowTimer 활성화 시 적 탄환 이동 속도가 절반 이하로 감속된다", function()
  local g = GameModel({ width = 600, height = 800, seed = 1 })
  g.slowTimer = 3.0
  local eb = BulletModel(100, 100, 0, 240, 4, 12, "enemy")
  g.enemyBullets[1] = eb
  g:update(DT, IDLE)
  local dy = eb.y - 100
  return dy > 0 and dy <= 240 * DT * 0.5 + 1e-6
end)

h.test("Dive 격추 보너스: 돌격 중인 적 격추 시 점수가 2배가 된다", function()
  local g = GameModel({ width = 600, height = 800, seed = 1 })
  local target = g.enemies[1]
  target.aiState = "dive"
  target.hp = 1
  target.scoreValue = 100
  g.bullets[1] = BulletModel(target.x + 5, target.y + 5, 0, 0, 4, 12, "player")
  local before = g.score
  g:update(DT, IDLE)
  return g.score == before + 200
end)

h.finish()
