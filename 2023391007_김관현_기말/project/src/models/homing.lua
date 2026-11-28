-- homing.lua
-- 유도 조향(순수 함수). 투사체 속도를 목표 방향으로 조금씩 꺾고 속력은 유지한다.
-- 상태를 갖지 않으므로 어떤 투사체에도 붙일 수 있고, 단독으로 테스트할 수 있다.

local homing = {}

--- 목표 좌표 중 (x, y) 에 가장 가까운 것을 고른다.
-- @param targets table  { {x=, y=}, ... }  (중심 좌표)
-- @return number|nil, number|nil
function homing.nearest(targets, x, y)
  local bestX, bestY, bestD = nil, nil, math.huge
  for i = 1, #targets do
    local t = targets[i]
    local dx, dy = t.x - x, t.y - y
    local d = dx * dx + dy * dy
    if d < bestD then
      bestX, bestY, bestD = t.x, t.y, d
    end
  end
  return bestX, bestY
end

--- b.vx, b.vy 를 (tx, ty) 쪽으로 turn(0~1) 비율만큼 꺾는다. 속력은 speed 로 유지.
function homing.steer(b, tx, ty, speed, turn)
  local dx, dy = tx - b.x, ty - b.y
  local len = math.sqrt(dx * dx + dy * dy)
  if len == 0 then
    return
  end
  local wantX, wantY = dx / len * speed, dy / len * speed
  local vx = b.vx + (wantX - b.vx) * turn
  local vy = b.vy + (wantY - b.vy) * turn
  local sl = math.sqrt(vx * vx + vy * vy)
  if sl > 0 then
    b.vx, b.vy = vx / sl * speed, vy / sl * speed
  end
end

local PI = math.pi
local TWO_PI = PI * 2
local DEFAULT_OPTS = {}

--- 각도를 (-pi, pi] 범위로 정규화한다.
function homing.wrapPi(angle)
  local a = (angle + PI) % TWO_PI
  if a <= 0 then
    a = a + TWO_PI
  end
  return a - PI
end

--- 각속도 제한 회전 + 감쇠 사인파 사행(Damped Sine Weave) 유도 조향.
-- 초반에는 뱀처럼 S자로 크게 감아 돌다가 exp(-damp * age) 로 감쇠하며 목표에 수렴한다.
function homing.steerWave(b, tx, ty, speed, dt, opts)
  opts = opts or DEFAULT_OPTS
  local maxTurnRate = opts.maxTurnRate or 6.5
  local amp = opts.amp or 5.5
  local freq = opts.freq or 18.0
  local damp = opts.damp or 2.2

  b.age = (b.age or 0) + dt
  local cur = math.atan2(b.vy, b.vx)
  local target = math.atan2(ty - b.y, tx - b.x)
  local diff = homing.wrapPi(target - cur)
  local maxStep = maxTurnRate * dt
  local turn = math.max(-maxStep, math.min(maxStep, diff))
  local weave = amp * math.sin(freq * b.age + (b.phase or 0)) * math.exp(-damp * b.age) * dt
  local nextAngle = cur + turn + weave
  b.vx = math.cos(nextAngle) * speed
  b.vy = math.sin(nextAngle) * speed
end

return homing
