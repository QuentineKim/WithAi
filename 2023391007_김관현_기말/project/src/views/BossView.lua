-- BossView.lua
-- 보스와 HP 바를 그린다. Model 을 읽기만 한다.

local BossView = {}

--- @param boss   table|nil  BossModel (읽기 전용). 없으면 아무것도 그리지 않는다
--- @param width  number     화면 폭
--- @param height number|nil 화면 높이 (기본 800)
function BossView.draw(gfx, boss, width, height)
  if not (boss and boss.alive) then
    return
  end
  local screenH = height or 800
  if boss.enraged then
    gfx.setColor(1, 0.15, 0.2)
  else
    gfx.setColor(0.9, 0.3, 0.9)
  end
  gfx.rectangle("fill", boss.x, boss.y, boss.w, boss.h)

  local barW = width - 200
  gfx.setColor(0.2, 0.2, 0.2)
  gfx.rectangle("fill", 100, 40, barW, 10)
  gfx.setColor(1, 0.2, 0.2)
  gfx.rectangle("fill", 100, 40, barW * (boss.hp / boss.maxHp), 10)

  local beamTop = boss.y + boss.h
  if boss.laserState == "warning" and boss.laserX then
    gfx.setColor(1, 0.2, 0.2, 0.85)
    for y = beamTop, screenH, 24 do
      gfx.rectangle("fill", boss.laserX - 2, y, 4, 12)
    end
    gfx.setColor(1, 0.3, 0.3)
    gfx.printf("DANGER", boss.laserX - 40, beamTop + 10, 80, "center")
  elseif boss.laserState == "firing" and boss.laserX then
    local lw = boss.laserW or 28
    local beamH = screenH - beamTop
    gfx.setColor(1, 0.15, 0.2, 0.85)
    gfx.rectangle("fill", boss.laserX - lw * 0.5, beamTop, lw, beamH)
    local coreW = lw * 0.45
    gfx.setColor(1, 0.95, 0.95)
    gfx.rectangle("fill", boss.laserX - coreW * 0.5, beamTop, coreW, beamH)
  end
end

return BossView
