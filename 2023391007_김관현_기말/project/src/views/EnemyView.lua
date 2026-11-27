-- EnemyView.lua
-- 살아있는 적을 그린다. Model 을 읽기만 한다.

local EnemyView = {}

local DEFAULT_COLOR = { 1, 0.4, 0.4 }
local COLORS = {
  basic = { 1, 0.4, 0.4 },
  scout = { 1, 0.85, 0.25 },
  tank = { 0.45, 0.75, 1 },
}

--- @param enemies table  EnemyModel 배열 (읽기 전용)
function EnemyView.draw(gfx, enemies)
  for i = 1, #enemies do
    local e = enemies[i]
    if e.alive then
      local c = COLORS[e.kind] or DEFAULT_COLOR
      gfx.setColor(c[1], c[2], c[3])
      gfx.rectangle("fill", e.x, e.y, e.w, e.h)
    end
  end
end

return EnemyView
