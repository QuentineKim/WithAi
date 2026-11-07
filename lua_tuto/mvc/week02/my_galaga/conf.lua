-- conf.lua
-- 2주차 겔러그 실습 창 설정 (LÖVE 11.x)

function love.conf(t)
  t.window.title = "Galaga (Monolith) - Week02 Practice"
  t.window.width = 600
  t.window.height = 800
  t.window.resizable = false
  t.console = false
end

