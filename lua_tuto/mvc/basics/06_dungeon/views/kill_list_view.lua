-- kill_list_view.lua
-- 처치한 적 목록 패널. 읽는 모델: killList

local KillListView = { title = "처치 목록" }
KillListView.__index = KillListView

function KillListView.new()
  return setmetatable({}, KillListView)
end

function KillListView:lines(game)
  local kills = game.killList and game.killList.kills or {}
  if #kills == 0 then
    return { "(없음)" }
  end
  return { string.format("%s (총 %d마리)", table.concat(kills, ", "), #kills) }
end

return KillListView
