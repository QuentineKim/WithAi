-- wave_parser_test.lua
-- R2 웨이브 데이터 파서(WaveParser)와 GameModel 웨이브 구동을 창 없이 검사한다.
-- 실행: cd project/tests && lua wave_parser_test.lua [src]

package.path = ((arg[0] or ""):match("(.*[/\\])") or "./") .. "?.lua;" .. package.path
local h = require("helper")
local app = arg[1] or "src"
local root = h.setup(app)

local WaveParser = require("WaveParser")
local GameModel = require("GameModel")

local DT = 1 / 60
local IDLE = { move = 0, fire = false, missile = false }

local function assertErrorWithLine(text, expectedLine)
  local ok, err = pcall(WaveParser.parse, text)
  if ok then
    error("에러가 발생해야 하는데 파싱이 성공함")
  end
  local msg = tostring(err)
  local lineToken = ":" .. tostring(expectedLine) .. ":"
  if not msg:find(lineToken, 1, true) then
    error("에러 메시지에 줄 번호 '" .. lineToken .. "' 가 없음: " .. msg)
  end
  return true
end

local function killAll(g)
  for _, e in ipairs(g.enemies) do
    e.alive = false
  end
end

print("[wave_parser_test] " .. app .. "/")

-- 1. [정상] 주석, 빈 줄, CRLF 가 섞인 2개 웨이브 파싱
h.test("[정상] 주석·빈 줄·CRLF 포함 2개 웨이브 파싱", function()
  local text = table.concat({
    "# 첫 번째 웨이브",
    "",
    "wave 1",
    "spawn basic 60 60",
    "spawn basic 120 80",
    "  # 중간 주석",
    "wave 2",
    "spawn basic 200 100",
  }, "\r\n")

  local waves = WaveParser.parse(text)
  if #waves ~= 2 then
    error("웨이브 수 불일치: " .. tostring(#waves))
  end
  local w1, w2 = waves[1], waves[2]
  return w1.id == 1
    and #w1.spawns == 2
    and w1.spawns[1].kind == "basic"
    and w1.spawns[1].x == 60
    and w1.spawns[1].y == 60
    and w1.spawns[2].x == 120
    and w1.spawns[2].y == 80
    and w2.id == 2
    and #w2.spawns == 1
    and w2.spawns[1].x == 200
    and w2.spawns[1].y == 100
end)

-- 2. [정상] 실제 project/src/waves.txt 파일 파싱
h.test("[정상] 실제 waves.txt 파일 파싱 성공 (2개 이상 웨이브)", function()
  local f = assert(io.open(root .. "waves.txt", "r"), "waves.txt 를 열 수 없음")
  local text = f:read("*a")
  f:close()
  local waves = WaveParser.parse(text)
  return #waves >= 2 and #waves[1].spawns >= 1 and #waves[2].spawns >= 1
end)

-- 3. [경계] 앞뒤 공백·탭, 최소 구성(1웨이브·적 1기), 경계 좌표(0, 0)
h.test("[경계] 공백·탭과 최소 구성(1웨이브 1기, 좌표 0, 0) 파싱", function()
  local text = "  \twave\t1  \n\t  spawn   scout_1   0   0  \n"
  local waves = WaveParser.parse(text)
  return #waves == 1
    and waves[1].id == 1
    and #waves[1].spawns == 1
    and waves[1].spawns[1].kind == "scout_1"
    and waves[1].spawns[1].x == 0
    and waves[1].spawns[1].y == 0
end)

-- 4. [경계/연동] GameModel 에 웨이브 주입 → 전멸 시 다음 웨이브 → 마지막 뒤 1웨이브 순환
h.test("[경계/연동] GameModel 웨이브 배치·진행·순환", function()
  local waves = WaveParser.parse(table.concat({
    "wave 1",
    "spawn basic 100 60",
    "spawn basic 200 60",
    "wave 2",
    "spawn basic 300 90",
  }, "\n"))

  local g = GameModel({ width = 600, height = 800, seed = 1, waves = waves })
  if #g.enemies ~= 2 or g.enemies[1].x ~= 100 or g.enemies[2].x ~= 200 or g.enemies[1].kind ~= "basic" then
    error("1웨이브 초기 배치 불일치")
  end

  -- 1웨이브 전멸 → 2웨이브
  killAll(g)
  g:update(DT, IDLE)
  if #g.enemies ~= 1 or g.enemies[1].x ~= 300 or g.enemies[1].y ~= 90 then
    error("2웨이브 전환 불일치")
  end

  -- 2웨이브 전멸 → 1웨이브 순환
  killAll(g)
  g:update(DT, IDLE)
  return #g.enemies == 2 and g.enemies[1].x == 100 and g.enemies[2].x == 200
end)

-- 5. [오류] 알 수 없는 명령어 / 오타 줄 (gmatch 만 썼을 때 놓치는 입력 방어)
h.test("[오류] 3번째 줄 오타 명령어(spwn) → 줄 번호 3과 함께 에러", function()
  local text = table.concat({
    "wave 1",
    "spawn basic 60 60",
    "spwn basic 120 60",
  }, "\n")
  return assertErrorWithLine(text, 3)
end)

-- 6. [오류] 인자 부족 · 인자 초과 · 비숫자 좌표
h.test("[오류] 인자 부족·초과·비숫자 좌표 → 해당 줄 번호와 함께 에러", function()
  local t1 = "wave 1\nspawn basic 60\n"
  local t2 = "wave 1\nspawn basic 60 60 extra\n"
  local t3 = "wave 1\nspawn basic abc 60\n"
  return assertErrorWithLine(t1, 2)
    and assertErrorWithLine(t2, 2)
    and assertErrorWithLine(t3, 2)
end)

-- 7. [오류] wave 헤더 없는 spawn, 음수 좌표, 중복/비정수 웨이브 번호
h.test("[오류] 헤더 전 spawn·음수 좌표·중복/비정수 wave 번호 → 줄 번호 에러", function()
  local t1 = "spawn basic 60 60\n"
  local t2 = "wave 1\nspawn basic -5 60\n"
  local t3 = "wave 1.5\nspawn basic 60 60\n"
  local t4 = "wave 1\nspawn basic 60 60\nwave 1\nspawn basic 120 60\n"
  return assertErrorWithLine(t1, 1)
    and assertErrorWithLine(t2, 2)
    and assertErrorWithLine(t3, 1)
    and assertErrorWithLine(t4, 3)
end)

-- 8. [오류] 빈 파일 및 적이 0기인 빈 웨이브
h.test("[오류] 빈 입력과 적이 없는 빈 웨이브 → 에러 발생", function()
  local t1 = "# 주석만 있는 파일\n   \n"
  local t2 = "wave 1\nwave 2\nspawn basic 60 60\n"
  local t3 = "wave 1\n"
  return assertErrorWithLine(t1, 1)
    and assertErrorWithLine(t2, 1)
    and assertErrorWithLine(t3, 1)
end)

-- 9. [경계/오류] 소수 좌표 허용 및 잘못된 적 종류·wave 0·인자 초과·빈 문자열·비문자열 에러
h.test("[경계/오류] 소수 좌표 허용 및 bad-kind·wave 0·빈/비문자열 입력 에러", function()
  local okWaves = WaveParser.parse("wave 1\nspawn basic 12.5 34.25\n")
  if okWaves[1].spawns[1].x ~= 12.5 or okWaves[1].spawns[1].y ~= 34.25 then
    error("소수 좌표 파싱 불일치")
  end
  return assertErrorWithLine("wave 1\nspawn bad-kind 60 60\n", 2)
    and assertErrorWithLine("wave 0\nspawn basic 60 60\n", 1)
    and assertErrorWithLine("wave 1 extra\nspawn basic 60 60\n", 1)
    and assertErrorWithLine("", 1)
    and assertErrorWithLine(12345, 1)
end)

-- 10. [오류] 무한대 wave ID(309자리) 및 nan/inf·음수 y 좌표 → 줄 번호 에러
h.test("[오류] 무한대 wave ID 및 nan/inf·음수 y 좌표 → 줄 번호 에러", function()
  local hugeId = "1" .. string.rep("0", 310)
  return assertErrorWithLine("wave " .. hugeId .. "\nspawn basic 60 60\n", 1)
    and assertErrorWithLine("wave 1\nspawn basic 60 -1\n", 2)
    and assertErrorWithLine("wave 1\nspawn basic inf 60\n", 2)
    and assertErrorWithLine("wave 1\nspawn basic 60 nan\n", 2)
end)

h.finish()
