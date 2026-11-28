-- BulletView.lua
-- 플레이어/적 총알을 그린다. Model 을 읽기만 한다.

local BulletView = {}

local PLAYER_COLOR = { 1, 1, 0.3 }
local MISSILE_COLOR = { 0.4, 1, 0.6 }
local ENEMY_COLOR = { 1, 0.6, 0.2 }

local function drawAll(gfx, list)
  for i = 1, #list do
    local b = list[i]
    if b.kind == "missile" then
      local trail = b.trail
      if trail and #trail > 0 then
        local n = #trail
        for j = 1, n do
          local pt = trail[j]
          local ratio = j / n
          local size = 2 + ratio * 3
          gfx.setColor(0.25, 0.95, 0.85, ratio * 0.65)
          gfx.rectangle("fill", pt.x - size * 0.5, pt.y - size * 0.5, size, size)
        end
      end
      gfx.setColor(MISSILE_COLOR[1], MISSILE_COLOR[2], MISSILE_COLOR[3])
      gfx.rectangle("fill", b.x, b.y, b.w, b.h)
      gfx.setColor(PLAYER_COLOR[1], PLAYER_COLOR[2], PLAYER_COLOR[3])
    else
      gfx.rectangle("fill", b.x, b.y, b.w, b.h)
    end
  end
end

--- @param bullets      table  플레이어 BulletModel 배열 (읽기 전용)
--- @param enemyBullets table  적 BulletModel 배열 (읽기 전용)
function BulletView.draw(gfx, bullets, enemyBullets)
  gfx.setColor(PLAYER_COLOR[1], PLAYER_COLOR[2], PLAYER_COLOR[3])
  drawAll(gfx, bullets)
  gfx.setColor(ENEMY_COLOR[1], ENEMY_COLOR[2], ENEMY_COLOR[3])
  drawAll(gfx, enemyBullets)
end

return BulletView
