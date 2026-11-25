-- WaveParser.lua
-- waves.txt 형식의 문자열을 줄 단위로 파싱·검증한다.
-- Model 계층 규칙 준수: io, love, print 금지. 순수 문자열 입력만 처리한다.

local M = {}

local error = error
local tonumber = tonumber
local tostring = tostring
local type = type
local math_floor = math.floor
local math_huge = math.huge
local string_format = string.format

local function parseError(lineNo, reason)
  error(string_format("waves:%d: %s", lineNo, reason), 0)
end

local function parseNonNegNumber(tok, label, lineNo)
  local n = tonumber(tok)
  if n == nil or n ~= n or n == math_huge or n == -math_huge or n < 0 then
    parseError(lineNo, label .. " 는 0 이상의 숫자여야 합니다: " .. tostring(tok))
  end
  return n
end

local function splitTokens(trimmed)
  local tokens = {}
  for tok in trimmed:gmatch("%S+") do
    tokens[#tokens + 1] = tok
  end
  return tokens
end

--- 웨이브 정의 문자열을 파싱해 웨이브 목록을 반환한다.
-- @param text string
-- @return table  { { id = number, spawns = { { kind = string, x = number, y = number }, ... } }, ... }
function M.parse(text)
  if type(text) ~= "string" then
    parseError(1, "웨이브 입력은 문자열이어야 합니다")
  end

  local waves = {}
  local seenIds = {}
  local current = nil
  local currentLineNo = 1

  local pos = 1
  local len = #text
  local lineNo = 0

  while pos <= len do
    lineNo = lineNo + 1
    local nl = text:find("\n", pos, true)
    local rawLine
    if nl then
      rawLine = text:sub(pos, nl - 1)
      pos = nl + 1
    else
      rawLine = text:sub(pos)
      pos = len + 1
    end

    -- Windows CRLF 대응
    local line = rawLine:gsub("\r$", "")
    local trimmed = line:match("^%s*(.-)%s*$")

    if trimmed ~= "" and trimmed:sub(1, 1) ~= "#" then
      local tokens = splitTokens(trimmed)
      local cmd = tokens[1]

      if cmd == "wave" then
        if #tokens ~= 2 then
          parseError(lineNo, "wave 형식은 'wave <id>' 이어야 합니다")
        end
        local idStr = tokens[2]
        local id = tonumber(idStr)
        if not idStr:match("^%d+$") or id == nil or id < 1 or id == math_huge or math_floor(id) ~= id then
          parseError(lineNo, "wave 번호는 1 이상의 유한한 정수여야 합니다: " .. tostring(idStr))
        end
        if seenIds[id] then
          parseError(lineNo, "중복된 wave 번호입니다: " .. tostring(id))
        end
        if current and #current.spawns == 0 then
          parseError(currentLineNo, "웨이브 " .. tostring(current.id) .. " 에 적이 없습니다")
        end

        seenIds[id] = true
        current = { id = id, spawns = {} }
        currentLineNo = lineNo
        waves[#waves + 1] = current
      elseif cmd == "spawn" then
        if not current then
          parseError(lineNo, "wave 선언 전에 spawn 이 나왔습니다")
        end
        if #tokens ~= 4 then
          parseError(lineNo, "spawn 형식은 'spawn <kind> <x> <y>' 이어야 합니다")
        end
        local kind = tokens[2]
        if not kind:match("^[A-Za-z0-9_]+$") then
          parseError(lineNo, "잘못된 적 종류 이름입니다: " .. tostring(kind))
        end
        local x = parseNonNegNumber(tokens[3], "x 좌표", lineNo)
        local y = parseNonNegNumber(tokens[4], "y 좌표", lineNo)
        current.spawns[#current.spawns + 1] = {
          kind = kind,
          x = x,
          y = y,
        }
      else
        parseError(lineNo, "알 수 없는 명령어입니다: " .. tostring(cmd))
      end
    end
  end

  if #waves == 0 then
    parseError(1, "정의된 웨이브가 없습니다")
  end
  if current and #current.spawns == 0 then
    parseError(currentLineNo, "웨이브 " .. tostring(current.id) .. " 에 적이 없습니다")
  end

  return waves
end

return M
