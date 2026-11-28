-- HudView.lua
-- 점수·라이프. Model 을 읽기만 한다.
-- 5주차: "GAME OVER / YOU WIN" 문구는 결과 씬(ResultView)으로 옮겼다.

local min = math.min

local HudView = {}

--- @param game table  GameModel (읽기 전용: score, lives, grazeGauge, overdriveTimer, shield, spreadTimer, slowTimer)
function HudView.draw(gfx, game, width, height)
  gfx.setColor(1, 1, 1)
  gfx.print("SCORE " .. game.score, 10, 10)
  gfx.print("LIVES " .. game.lives, width - 100, 10)

  local barW, barH = 110, 8
  local overdrive = game.overdriveTimer or 0
  if overdrive > 0 then
    local ratio = min(1, overdrive / 5.0)
    gfx.setColor(0.2, 0.2, 0.2)
    gfx.rectangle("fill", 10, 32, barW, barH)
    gfx.setColor(1, 0.85, 0.2)
    gfx.rectangle("fill", 10, 32, barW * ratio, barH)
    gfx.print("OVERDRIVE!", 126, 28)
  elseif game.grazeGauge ~= nil then
    local ratio = min(1, game.grazeGauge / 100)
    gfx.setColor(0.2, 0.2, 0.25)
    gfx.rectangle("fill", 10, 32, barW, barH)
    gfx.setColor(0.25, 0.95, 1)
    gfx.rectangle("fill", 10, 32, barW * ratio, barH)
    gfx.setColor(0.75, 0.9, 1)
    gfx.print("GRAZE", 126, 28)
  end

  local tagX = 10
  if game.shield then
    gfx.setColor(0.3, 0.95, 1)
    gfx.print("SHIELD", tagX, 46)
    tagX = tagX + 64
  end
  if (game.spreadTimer or 0) > 0 then
    gfx.setColor(0.3, 1, 0.5)
    gfx.print("SPREAD", tagX, 46)
    tagX = tagX + 64
  end
  if (game.slowTimer or 0) > 0 then
    gfx.setColor(0.8, 0.4, 1)
    gfx.print("SLOW", tagX, 46)
  end
end

return HudView
