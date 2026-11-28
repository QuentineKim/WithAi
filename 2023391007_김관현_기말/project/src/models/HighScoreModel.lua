-- HighScoreModel.lua
-- R6 하이스코어 직렬화 / 역직렬화 모델.
-- 순수 Lua 문자열 처리만 담당한다 (io / love / print 금지). 파일 입출력은 main.lua 에서만 수행.

local class = require("class")

local HighScoreModel = class()

local math_floor = math.floor
local math_huge = math.huge
local math_max = math.max
local string_format = string.format

HighScoreModel.DEFAULT = { bestScore = 0, plays = 0 }

local function defaultCopy()
  return {
    bestScore = HighScoreModel.DEFAULT.bestScore,
    plays = HighScoreModel.DEFAULT.plays,
  }
end

local function parseNonNegInt(str, label)
  if type(str) ~= "string" or not str:match("^%d+$") then
    error("invalid " .. label .. ": " .. tostring(str), 0)
  end
  local n = tonumber(str)
  if n == nil or n ~= n or n == math_huge or n == -math_huge or n < 0 or math_floor(n) ~= n then
    error("non-finite " .. label .. ": " .. tostring(str), 0)
  end
  return n
end

local function parseStrict(text)
  if type(text) ~= "string" or text == "" then
    error("empty or non-string highscore", 0)
  end
  local best, plays = nil, nil
  local pos, len = 1, #text
  while pos <= len do
    local nl = text:find("\n", pos, true)
    local raw
    if nl then
      raw = text:sub(pos, nl - 1)
      pos = nl + 1
    else
      raw = text:sub(pos)
      pos = len + 1
    end
    local trimmed = raw:gsub("\r$", ""):match("^%s*(.-)%s*$")
    if trimmed ~= "" then
      local key, val = trimmed:match("^([a-z]+)=(.+)$")
      if key == "best" then
        best = parseNonNegInt(val, "best")
      elseif key == "plays" then
        plays = parseNonNegInt(val, "plays")
      else
        error("unknown highscore line: " .. trimmed, 0)
      end
    end
  end
  if best == nil or plays == nil then
    error("missing required highscore fields", 0)
  end
  return { bestScore = best, plays = plays }
end

--- 상태 테이블을 저장용 문자열로 직렬화한다.
function HighScoreModel.serialize(data)
  data = data or HighScoreModel.DEFAULT
  local best = math_max(0, math_floor(tonumber(data.bestScore) or 0))
  local plays = math_max(0, math_floor(tonumber(data.plays) or 0))
  return string_format("best=%d\nplays=%d\n", best, plays)
end

--- 저장 문자열을 역직렬화한다. 깨진 입력이면 죽지 않고 기본값과 false 를 반환한다.
function HighScoreModel.deserialize(text)
  local ok, result = pcall(parseStrict, text)
  if ok and type(result) == "table" then
    return result, true
  end
  return defaultCopy(), false
end

function HighScoreModel:init(rawText)
  local data, ok = HighScoreModel.deserialize(rawText)
  self.bestScore = data.bestScore
  self.plays = data.plays
  self.loadedOk = ok
end

--- 판 종료 점수를 기록한다. 최고 기록을 경신하면 true 를 반환한다.
function HighScoreModel:record(score)
  score = math_max(0, math_floor(tonumber(score) or 0))
  self.plays = self.plays + 1
  if score > self.bestScore then
    self.bestScore = score
    return true
  end
  return false
end

function HighScoreModel:toString()
  return HighScoreModel.serialize(self)
end

return HighScoreModel
