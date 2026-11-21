-- HelpView.lua
-- 도움말 화면을 그린다. love 비의존(주입받은 gfx 로만 출력).

local HelpView = {}

local HELP_BODY = table.concat({
  "Left / Right (A / D) : MOVE",
  "Space                : FIRE",
  "X                    : HOMING MISSILE",
  "P / Esc              : PAUSE (in game)",
  "R                    : RETRY (on result)",
}, "\n")

function HelpView.draw(gfx, width, height)
  gfx.setColor(0.4, 0.9, 1)
  gfx.printf("HOW TO PLAY", 0, height * 0.24, width, "center")
  gfx.setColor(1, 1, 1)
  gfx.printf(HELP_BODY, 0, height * 0.36, width, "center")
  gfx.setColor(0.7, 0.85, 1)
  gfx.printf("H / Esc : BACK", 0, height * 0.68, width, "center")
end

return HelpView
