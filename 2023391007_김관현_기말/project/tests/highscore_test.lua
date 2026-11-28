-- highscore_test.lua
-- R6 하이스코어 직렬화/역직렬화(손상 복구) 및 ResultScene 연동을 창 없이 검사한다.
-- 실행: cd project/tests && lua highscore_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
local root = h.setup(app)

local HighScoreModel = require("HighScoreModel")
local SceneStack = require("SceneStack")

local function printed(gfx, text)
  for _, c in ipairs(gfx.calls) do
    if (c.name == "print" or c.name == "printf") and tostring(c.args[1]):find(text, 1, true) then
      return true
    end
  end
  return false
end

print("[highscore_test] " .. app .. "/")

h.test("정상 직렬화 후 역직렬화하면 bestScore 와 plays 가 일치한다", function()
  local raw = HighScoreModel.serialize({ bestScore = 3450, plays = 7 })
  local data, ok = HighScoreModel.deserialize(raw)
  return ok == true and data.bestScore == 3450 and data.plays == 7
end)

h.test("깨진 문자열·빈 문자열·nil·음수·inf 입력 시 죽지 않고 기본값으로 복구한다", function()
  local nilData, nilOk = HighScoreModel.deserialize(nil)
  if nilOk ~= false or nilData.bestScore ~= 0 or nilData.plays ~= 0 then
    error("badInput nil failed recovery")
  end
  local badInputs = {
    "",
    "corrupted garbage!!!",
    "best=-100\nplays=2\n",
    "best=inf\nplays=1\n",
    "best=nan\nplays=1\n",
    "best=500\n",
    12345,
  }
  for i = 1, #badInputs do
    local data, ok = HighScoreModel.deserialize(badInputs[i])
    if ok ~= false or data.bestScore ~= 0 or data.plays ~= 0 then
      error("badInput #" .. i .. " failed recovery")
    end
  end
  return true
end)

h.test("record(score): 최고 기록 갱신 시 true, 미갱신 시 false 와 plays 증가", function()
  local hs = HighScoreModel("best=500\nplays=2\n")
  local r1 = hs:record(300)
  local r2 = hs:record(1200)
  local r3 = hs:record(1200)
  return r1 == false and r2 == true and r3 == false and hs.bestScore == 1200 and hs.plays == 5
end)

h.test("ResultScene 연동: 최고 기록 갱신 시 saveHighScore 호출 및 BEST / NEW! 출력", function()
  local ctx = h.fakeCtx()
  local savedText = nil
  ctx.highScore = HighScoreModel("best=400\nplays=1\n")
  ctx.saveHighScore = function(text)
    savedText = text
  end
  local stack = SceneStack()
  stack:push(ctx.scenes.Result(ctx, { state = "won", score = 1500 }))
  local gfx = h.fakeGfx()
  stack:draw(gfx)
  local parsed, ok = HighScoreModel.deserialize(savedText)
  return ok == true and parsed.bestScore == 1500 and parsed.plays == 2
    and printed(gfx, "BEST 1500") and printed(gfx, "NEW!")
end)

h.test("ctx.highScore 가 없어도 ResultScene 은 에러 없이 동작한다", function()
  local ctx = h.fakeCtx()
  local stack = SceneStack()
  stack:push(ctx.scenes.Result(ctx, { state = "gameover", score = 200 }))
  local gfx = h.fakeGfx()
  stack:draw(gfx)
  return printed(gfx, "GAME OVER")
end)

h.test("HighScoreModel.lua 에는 io · love · print 가 없다 (정적 검사)", function()
  local f = assert(io.open(root .. "models/HighScoreModel.lua", "r"))
  local src = f:read("*a"):gsub("%-%-[^\n]*", "")
  f:close()
  local hasForbidden = src:find("[^%w_]io[^%w_]") or src:find("[^%w_]love[^%w_]") or src:find("[^%w_]print[^%w_]")
  return hasForbidden == nil
end)

h.finish()
