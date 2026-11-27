-- enemy_factory_test.lua
-- R3 적 3종 상속(BasicEnemy / ScoutEnemy / TankEnemy)과 EnemyFactory 등록표를 창 없이 검사한다.
-- 실행: cd project/tests && lua enemy_factory_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
local root = h.setup(app)

local EnemyFactory = require("EnemyFactory")
local EnemyModel = require("EnemyModel")
local EnemyView = require("EnemyView")
local WaveParser = require("WaveParser")
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

print("[enemy_factory_test] " .. app .. "/")

-- 1. 3종 생성 및 속성·상속 확인
h.test("basic / scout / tank 3종 생성 및 EnemyModel 메서드 상속 확인", function()
  local b = EnemyFactory.create("basic", 10, 20)
  local s = EnemyFactory.create("scout", 30, 40)
  local t = EnemyFactory.create("tank", 50, 60)

  local okBasic = b.kind == "basic" and b.hp == 1 and b.scoreValue == 100 and b:centerX() == 10 + b.w * 0.5
  local okScout = s.kind == "scout" and s.hp == 1 and s.scoreValue == 150 and s.diveSpeed > b.diveSpeed
  local okTank = t.kind == "tank" and t.hp == 2 and t.maxHp == 2 and t.scoreValue == 250 and t.w > b.w
  local okInherit = b.centerY == EnemyModel.centerY and s.hit == EnemyModel.hit
  return okBasic and okScout and okTank and okInherit
end)

-- 2. 모르는 종류 에러
h.test("등록되지 않은 적 종류 생성 시 에러 발생", function()
  local ok, err = pcall(EnemyFactory.create, "unknown_kind", 0, 0)
  return (not ok) and tostring(err):find("unknown_kind", 1, true) ~= nil
end)

-- 3. TankEnemy 2발 격파 + enemy_hit / enemy_destroyed 이벤트 + 250점 반영
h.test("TankEnemy 는 1발 맞고 생존(enemy_hit), 2발에 격파되며 250점을 준다", function()
  local waves = {
    { id = 1, spawns = { { kind = "tank", x = 100, y = 100 } } },
  }
  local g = GameModel({ width = 600, height = 800, seed = 1, waves = waves })
  local tank = g.enemies[1]

  -- 1발 피격
  g.bullets[#g.bullets + 1] = BulletModel(tank.x + 5, tank.y + 5, 0, 0, 4, 12, "player")
  g:update(DT, IDLE)
  local ev1 = g:drainEvents()
  if not tank.alive or tank.hp ~= 1 or g.score ~= 0 or not hasEvent(ev1, "enemy_hit") then
    error("1발 피격 후 상태 또는 enemy_hit 이벤트 불일치")
  end

  -- 2발 피격 → 격파
  g.bullets[#g.bullets + 1] = BulletModel(tank.x + 5, tank.y + 5, 0, 0, 4, 12, "player")
  g:update(DT, IDLE)
  local ev2 = g:drainEvents()
  return (not tank.alive) and tank.hp == 0 and g.score == 250 and hasEvent(ev2, "enemy_destroyed")
end)

-- 4. 확장성: Factory.register 로 새 종류 등록 후 GameModel 수정 없이 생성
h.test("EnemyFactory.register 로 새 종류를 등록해 GameModel 수정 없이 생성 가능", function()
  local class = require("class")
  local CustomEnemy = class(EnemyModel)
  function CustomEnemy:init(x, y)
    EnemyModel.init(self, x, y, "custom_test")
    self.hp = 1
    self.maxHp = 1
    self.scoreValue = 300
  end

  EnemyFactory.register("custom_test", function(x, y)
    return CustomEnemy(x, y)
  end)

  local waves = {
    { id = 1, spawns = { { kind = "custom_test", x = 120, y = 80 } } },
  }
  local g = GameModel({ width = 600, height = 800, seed = 1, waves = waves })
  local e = g.enemies[1]
  return e.kind == "custom_test" and e.scoreValue == 300 and e.x == 120 and e.y == 80
end)

-- 5. waves.txt 에 적힌 모든 적 종류가 EnemyFactory 에 등록되어 있다
h.test("waves.txt 의 모든 spawn.kind 가 EnemyFactory 에 등록되어 있다", function()
  local f = assert(io.open(root .. "waves.txt", "r"))
  local text = f:read("*a")
  f:close()
  local waves = WaveParser.parse(text)
  local kinds = {}
  for _, w in ipairs(waves) do
    for _, s in ipairs(w.spawns) do
      if not EnemyFactory.has(s.kind) then
        error("미등록 적 종류: " .. tostring(s.kind))
      end
      kinds[s.kind] = true
    end
  end
  return kinds.basic == true and kinds.scout == true and kinds.tank == true
end)

-- 6. EnemyView 종류별 색상 분기 및 미등록 종류 기본색 fallback
h.test("EnemyView.draw 는 적 종류별 색상을 적용하고 미등록 종류는 기본색으로 그린다", function()
  local colors = {}
  local gfx = h.fakeGfx()
  gfx.setColor = function(r, g, b)
    colors[#colors + 1] = { r, g, b }
  end

  local enemies = {
    EnemyFactory.create("basic", 0, 0),
    EnemyFactory.create("scout", 50, 0),
    EnemyFactory.create("tank", 100, 0),
    EnemyModel(150, 0, "unlisted_kind"),
  }
  EnemyView.draw(gfx, enemies)

  -- basic(1, 0.4, 0.4), scout(1, 0.85, 0.25), tank(0.45, 0.75, 1), fallback(1, 0.4, 0.4)
  return #colors == 4
    and colors[1][2] ~= colors[2][2]
    and colors[2][3] ~= colors[3][3]
    and colors[4][1] == colors[1][1]
    and colors[4][2] == colors[1][2]
    and colors[4][3] == colors[1][3]
end)

h.finish()
