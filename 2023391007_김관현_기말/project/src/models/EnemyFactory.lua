-- EnemyFactory.lua
-- 적 종류 문자열 → 생성 함수 등록표 (Factory 패턴).
-- 등록되지 않은 종류가 들어오면 즉시 에러를 발생시킨다.

local BasicEnemy = require("BasicEnemy")
local ScoutEnemy = require("ScoutEnemy")
local TankEnemy = require("TankEnemy")

local error = error
local tostring = tostring
local type = type

local M = {}

local REGISTRY = {
  basic = function(x, y)
    return BasicEnemy(x, y)
  end,
  scout = function(x, y)
    return ScoutEnemy(x, y)
  end,
  tank = function(x, y)
    return TankEnemy(x, y)
  end,
}

--- 새 적 종류를 등록한다.
-- @param kind string
-- @param ctor function(x, y) -> EnemyModel
function M.register(kind, ctor)
  if type(kind) ~= "string" or kind == "" then
    error("EnemyFactory.register: kind 는 비어 있지 않은 문자열이어야 합니다", 0)
  end
  if type(ctor) ~= "function" then
    error("EnemyFactory.register: ctor 는 함수여야 합니다", 0)
  end
  REGISTRY[kind] = ctor
end

--- 등록된 적 종류인지 확인한다.
function M.has(kind)
  return REGISTRY[kind] ~= nil
end

--- 종류 문자열로 적 인스턴스를 생성한다. 모르는 종류는 에러.
-- @param kind string
-- @param x number
-- @param y number
function M.create(kind, x, y)
  local ctor = REGISTRY[kind]
  if not ctor then
    error("EnemyFactory.create: 알 수 없는 적 종류입니다: " .. tostring(kind), 0)
  end
  return ctor(x, y)
end

return M
