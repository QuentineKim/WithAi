-- ResultView.lua
-- 결과 오버레이: GAME OVER 또는 YOU WIN + 최종 점수.

local ResultView = {}

function ResultView.draw(gfx, width, height, won, score, bestScore, isNewRecord)
  gfx.setColor(0, 0, 0, 0.5)
  gfx.rectangle("fill", 0, 0, width, height)
  if won then
    gfx.setColor(0.6, 1, 0.6)
  else
    gfx.setColor(1, 0.5, 0.5)
  end
  gfx.printf((won and "YOU WIN!" or "GAME OVER") .. "\nSCORE " .. score, 0, height * 0.38, width, "center")
  if bestScore ~= nil then
    if isNewRecord then
      gfx.setColor(1, 0.85, 0.2)
    else
      gfx.setColor(0.8, 0.9, 1)
    end
    gfx.printf("BEST " .. bestScore .. (isNewRecord and "  NEW!" or ""), 0, height * 0.48, width, "center")
  end
  gfx.setColor(1, 1, 1)
  gfx.printf("R : RETRY\nEnter : TITLE", 0, height * 0.58, width, "center")
end

return ResultView
