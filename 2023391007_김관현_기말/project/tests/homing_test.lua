-- homing_test.lua
-- 수학적 유도탄(homing.wrapPi / homing.steerWave), 트윈 측면 사출, 잔상 꼬리를 검사한다.
-- 실행: cd project/tests && lua homing_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
h.setup(app)

local homing = require("homing")
local BulletModel = require("BulletModel")
local GameModel = require("GameModel")

local DT = 1 / 60

print("[homing_test] " .. app .. "/")

h.test("wrapPi: 각도를 (-pi, pi] 범위로 정규화한다", function()
  local a = homing.wrapPi(math.pi * 2.5)
  local b = homing.wrapPi(-math.pi * 2.5)
  local c = homing.wrapPi(0)
  return math.abs(a - math.pi * 0.5) < 1e-6 and math.abs(b + math.pi * 0.5) < 1e-6 and c == 0
end)

h.test("steerWave: 초반 사인파 사행 후 시간 경과에 따라 목표에 수렴한다", function()
  local b = BulletModel(300, 700, -250, -350, 6, 14, "missile")
  b.phase = 0
  local tx, ty = 300, 150
  homing.steerWave(b, tx, ty, 440, DT)
  local spd1 = math.sqrt(b.vx * b.vx + b.vy * b.vy)
  local hit = false
  for _ = 1, 140 do
    homing.steerWave(b, tx, ty, 440, DT)
    b:update(DT)
    local dx, dy = tx - b.x, ty - b.y
    if dx * dx + dy * dy < 24 * 24 then
      hit = true
      break
    end
  end
  return math.abs(spd1 - 440) < 1e-4 and hit == true
end)

h.test("GameModel: X 입력 시 반대 위상의 트윈 미사일 2발이 측면 사출된다", function()
  local g = GameModel({ width = 600, height = 800, seed = 1 })
  g:update(DT, { move = 0, fire = false, missile = true })
  local missiles = {}
  for _, b in ipairs(g.bullets) do
    if b.kind == "missile" then
      missiles[#missiles + 1] = b
    end
  end
  return #missiles == 2 and missiles[1].vx < 0 and missiles[2].vx > 0
    and math.abs(missiles[2].phase - math.pi) < 1e-6
end)

h.test("BulletModel: 미사일 이동 시 trail 이 기록되고 최대 8개로 유지된다", function()
  local b = BulletModel(100, 500, 0, -400, 6, 14, "missile")
  for _ = 1, 15 do
    b:update(DT)
  end
  return type(b.trail) == "table" and #b.trail == 8
end)

h.finish()
