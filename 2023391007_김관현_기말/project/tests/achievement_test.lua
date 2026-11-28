-- achievement_test.lua
-- R5 업적(AchievementModel) 이벤트 구독, View 배너·폭죽 연출, PlayScene 연동을 창 없이 검사한다.
-- 실행: cd project/tests && lua achievement_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
local root = h.setup(app)

local AchievementModel = require("AchievementModel")
local EffectsView = require("EffectsView")
local BulletModel = require("BulletModel")
local SceneStack = require("SceneStack")

local DT = 1 / 60

local function printed(gfx, text)
  for _, c in ipairs(gfx.calls) do
    if (c.name == "print" or c.name == "printf") and tostring(c.args[1]):find(text, 1, true) then
      return true
    end
  end
  return false
end

print("[achievement_test] " .. app .. "/")

h.test("trigger_happy: 발사 19회 미달성 → 20회 1회 달성 → 추가 발사 중복 없음", function()
  local ach = AchievementModel()
  local got = {}
  ach:subscribe(function(ev)
    got[#got + 1] = ev
  end)
  for _ = 1, 19 do
    ach:onEvent({ type = "fire" })
  end
  local before = not ach:isUnlocked("trigger_happy") and #got == 0
  ach:onEvent({ type = "fire" })
  local at20 = ach:isUnlocked("trigger_happy") and #got == 1 and got[1].type == "achievement_unlocked"
    and got[1].id == "trigger_happy" and got[1].title == "TRIGGER HAPPY"
  ach:onEvent({ type = "fire" })
  ach:onEvent({ type = "fire" })
  return before and at20 and #got == 1
end)

h.test("last_stand: 2회 피격 전 격추는 미집계, 2회 피격 후 3기 격추 시 1회 달성", function()
  local ach = AchievementModel()
  local count = 0
  ach:subscribe(function(ev)
    if ev.id == "last_stand" then
      count = count + 1
    end
  end)
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "player_hit" })
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "player_hit" })
  local stillLocked = not ach:isUnlocked("last_stand") and count == 0
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "enemy_destroyed" })
  local atTwo = not ach:isUnlocked("last_stand")
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "enemy_destroyed" })
  return stillLocked and atTwo and ach:isUnlocked("last_stand") and count == 1
end)

h.test("last_stand: game_over 이후 격추 이벤트로는 달성되지 않는다", function()
  local ach = AchievementModel()
  ach:onEvent({ type = "player_hit" })
  ach:onEvent({ type = "player_hit" })
  ach:onEvent({ type = "game_over" })
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "enemy_destroyed" })
  ach:onEvent({ type = "enemy_destroyed" })
  return not ach:isUnlocked("last_stand")
end)

h.test("clean_boss: 보스 등장 전 피격은 무관, 보스전 무피격 격파 시 1회 달성", function()
  local ach = AchievementModel()
  local count = 0
  ach:subscribe(function(ev)
    if ev.id == "clean_boss" then
      count = count + 1
    end
  end)
  ach:onEvent({ type = "player_hit" })
  ach:onEvent({ type = "boss_appeared" })
  ach:onEvent({ type = "boss_destroyed" })
  ach:onEvent({ type = "boss_destroyed" })
  return ach:isUnlocked("clean_boss") and count == 1
end)

h.test("clean_boss: 보스전 중 피격되면 보스 격파 시 미달성", function()
  local ach = AchievementModel()
  ach:onEvent({ type = "boss_appeared" })
  ach:onEvent({ type = "player_hit" })
  ach:onEvent({ type = "boss_destroyed" })
  return not ach:isUnlocked("clean_boss")
end)

h.test("경계값: nil 및 미지원 이벤트는 에러 없이 무시한다", function()
  local ach = AchievementModel()
  ach:onEvent(nil)
  ach:onEvent({})
  ach:onEvent({ type = "unknown" })
  ach:onEvent({ type = "enemy_hit" })
  return ach:unlockedCount() == 0
end)

h.test("EffectsView: 보스 경보·업적 폭죽·배너 큐 순차 표시·보스 대폭발", function()
  local fx = EffectsView(h.fixedRand())
  fx:onEvent({ type = "boss_appeared" })
  local gfxWarn = h.fakeGfx()
  fx:drawBanner(gfxWarn, 600, 800)
  local hasBossWarning = printed(gfxWarn, "BOSS") and fx.shake > 0 and fx.flash > 0

  fx:onEvent({ type = "achievement_unlocked", id = "trigger_happy", title = "TRIGGER HAPPY" })
  fx:onEvent({ type = "achievement_unlocked", id = "clean_boss", title = "UNTOUCHABLE BOSS" })
  local hasFireworks = #fx.particles >= 20

  local gfx1 = h.fakeGfx()
  fx:drawBanner(gfx1, 600, 800)
  local showsFirst = printed(gfx1, "ACHIEVEMENT") and printed(gfx1, "TRIGGER HAPPY") and h.count(gfx1, "rectangle") >= 2

  for _ = 1, 200 do
    fx:update(DT)
  end
  local gfx2 = h.fakeGfx()
  fx:drawBanner(gfx2, 600, 800)
  local showsSecond = printed(gfx2, "UNTOUCHABLE BOSS")

  for _ = 1, 220 do
    fx:update(DT)
  end
  local gfx3 = h.fakeGfx()
  fx:drawBanner(gfx3, 600, 800)
  local cleared = not printed(gfx3, "UNTOUCHABLE BOSS")

  fx:onEvent({ type = "boss_destroyed", x = 300, y = 120 })
  local hasBossBlast = #fx.particles >= 20

  return hasBossWarning and hasFireworks and showsFirst and showsSecond and cleared and hasBossBlast
end)

h.test("통합 + 비의존: PlayScene 보스 무피격 격파 시 업적 알림 출력, GameModel 은 업적을 모름", function()
  local ctx = h.fakeCtx()
  local stack = SceneStack()
  stack:push(ctx.scenes.Play(ctx))
  local play = stack:top()

  play.game.score = 1000
  stack:update(DT)
  for _, e in ipairs(play.game.enemies) do
    e.alive = false
  end
  play.game.boss.hp = 1
  play.game.bullets[#play.game.bullets + 1] =
    BulletModel(play.game.boss.x + 10, play.game.boss.y + 10, 0, 0, 4, 12, "player")
  stack:update(DT)

  local gfx = h.fakeGfx()
  stack:draw(gfx)
  local unlockedAndShown = play.achievements:isUnlocked("clean_boss") and printed(gfx, "UNTOUCHABLE BOSS")

  local f = assert(io.open(root .. "models/GameModel.lua", "r"))
  local src = f:read("*a"):gsub("%-%-[^\n]*", "")
  f:close()
  local noAchievementRef = not src:find("Achievement", 1, true) and not src:find("achievement", 1, true)

  return unlockedAndShown and noAchievementRef
end)

h.finish()
