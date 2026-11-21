-- HelpScene.lua
-- 도움말 화면. TitleScene 위에 push 로 올라가고 H / Esc / Enter 로 pop 되어 복귀한다.
-- love 를 모른다. ctx 로만 의존하며 다른 Scene 을 require 하지 않는다.

local class = require("class")
local HelpView = require("HelpView")

local HelpScene = class()

HelpScene.transparent = false

function HelpScene:init(ctx)
  self.ctx = ctx
end

function HelpScene:keypressed(key)
  if key == "h" or key == "escape" or key == "return" then
    self.stack:pop()
  end
end

function HelpScene:draw(gfx)
  HelpView.draw(gfx, self.ctx.width, self.ctx.height)
end

return HelpScene
