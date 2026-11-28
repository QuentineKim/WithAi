-- PlayerView.lua
-- 플레이어를 그린다. Model 을 읽기만 한다(쓰기 금지).

local PlayerView = {}

local COLOR = { 0.4, 0.9, 1 }

--- @param gfx       table    love.graphics 또는 같은 함수를 가진 가짜(테스트용)
--- @param player    table    PlayerModel (읽기 전용)
--- @param shield    boolean|nil  보호막 활성 여부
--- @param overdrive boolean|nil  오버드라이브 활성 여부
function PlayerView.draw(gfx, player, shield, overdrive)
  if overdrive then
    gfx.setColor(1, 0.85, 0.2)
    gfx.rectangle("line", player.x - 2, player.y - 2, player.w + 4, player.h + 4)
  end
  if shield then
    gfx.setColor(0.3, 0.95, 1)
    gfx.rectangle("line", player.x - 5, player.y - 5, player.w + 10, player.h + 10)
  end
  gfx.setColor(COLOR[1], COLOR[2], COLOR[3])
  gfx.rectangle("fill", player.x, player.y, player.w, player.h)
end

return PlayerView
