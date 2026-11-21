-- kill_list_model.lua
-- 처치한 적 목록. 다른 모델에 의존하지 않고 이벤트 버스만 구독해 기록한다.

local KillListModel = {}
KillListModel.__index = KillListModel

function KillListModel.new(bus)
  local self = setmetatable({ kills = {} }, KillListModel)
  bus:on("enemy_killed", function(data)
    self:record(data and data.name)
  end)
  return self
end

function KillListModel:record(name)
  if name then
    self.kills[#self.kills + 1] = name
  end
end

function KillListModel:count()
  return #self.kills
end

return KillListModel
