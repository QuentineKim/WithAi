-- BossPhase.lua
-- 진행 단계(State) ②: 보스전. 보스 등장·이동·탄막·피격·격파(승리)를 맡는다.
-- 남은 편대는 계속 움직이고 쏘지만(공통 규칙), 전멸해도 새 편대는 나오지 않는다.

local class = require("class")
local BossModel = require("BossModel")

local BossPhase = class()

local BOSS_HP = 40
local BOSS_REWARD = 2000

BossPhase.name = "boss"

-- AABB 겹침
local function overlaps(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

function BossPhase:enter(game)
  game.boss = BossModel(game.width * 0.5 - 60, 70, BOSS_HP)
  game:_emit({ type = "boss_appeared" })
end

function BossPhase:update(game, dt)
  local boss = game.boss
  if boss and boss.alive then
    local px = game.player.x + game.player.w * 0.5
    boss:update(dt, game.width, game.enemyBullets, px)
  end
end

function BossPhase:resolveCollisions(game)
  if game.state ~= "playing" then
    return
  end
  local boss = game.boss
  if not (boss and boss.alive) then
    return
  end
  local wasEnraged = boss.enraged
  for bi = #game.bullets, 1, -1 do
    local b = game.bullets[bi]
    if overlaps(b, boss) then
      table.remove(game.bullets, bi)
      game:_emit({ type = "boss_hit", x = b.x, y = b.y })
      if boss:takeDamage(1) then
        game.score = game.score + BOSS_REWARD
        game.state = "won"
        game:_emit({ type = "boss_destroyed", x = boss:centerX(), y = boss:centerY() })
        break
      end
    end
  end
  if not wasEnraged and boss.enraged and boss.alive then
    game:_emit({ type = "boss_enraged" })
  end

  if game.state == "playing" and boss.alive and boss.laserState == "firing" and not boss.laserHit then
    local bx = boss.laserX - boss.laserW * 0.5
    local by = boss.y + boss.h
    local bw = boss.laserW
    local bh = game.height
    local p = game.player
    if bx < p.x + p.w and p.x < bx + bw and by < p.y + p.h and p.y < by + bh then
      boss.laserHit = true
      if game.shield then
        game.shield = false
        game:_emit({ type = "shield_broken" })
      else
        game.lives = game.lives - 1
        game:_emit({ type = "player_hit" })
        if game.lives <= 0 then
          game.state = "gameover"
          game:_emit({ type = "game_over" })
        end
      end
    end
  end
end

function BossPhase:afterStep(game) end

return BossPhase
