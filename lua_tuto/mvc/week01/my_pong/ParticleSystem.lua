-- ParticleSystem.lua
-- 트론 네온 스파크 파티클 관리 모듈

local ParticleSystem = {}

function ParticleSystem.new()
  return {
    particles = {},
  }
end

-- 스파크 방출
function ParticleSystem.emit(ps, x, y, count, color, baseVx, baseVy)
  for _ = 1, count do
    local angle = math.random() * math.pi * 2
    local speed = math.random(80, 260)
    local vx = math.cos(angle) * speed + (baseVx or 0) * 0.2
    local vy = math.sin(angle) * speed + (baseVy or 0) * 0.2
    local life = 0.25 + math.random() * 0.35
    local p = {
      x = x,
      y = y,
      vx = vx,
      vy = vy,
      r = color[1],
      g = color[2],
      b = color[3],
      life = life,
      maxLife = life,
      size = math.random(2, 4),
    }
    table.insert(ps.particles, p)
  end
end

-- 파티클 물리 갱신 (고정 타임스텝 호출)
function ParticleSystem.update(ps, dt)
  for i = #ps.particles, 1, -1 do
    local p = ps.particles[i]
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(ps.particles, i)
    else
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      p.vx = p.vx * 0.96 -- 감속 마찰
      p.vy = p.vy * 0.96
    end
  end
end

return ParticleSystem

