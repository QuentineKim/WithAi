-- GameModel.lua
-- 겔러그의 "상태 + 규칙"을 조율한다. love 비의존, 결정적.
-- 5주차: 단계마다 다른 규칙(편대 재생성, 보스 등장·피격·승리)은 진행 단계 State(self.phase)에 맡긴다.
-- 여기에는 모든 단계에 공통인 규칙만 남는다.

local class = require("class")
local Rng = require("rng")
local PlayerModel = require("PlayerModel")
local EnemyFactory = require("EnemyFactory")
local BulletModel = require("BulletModel")
local WeaponDecorator = require("WeaponDecorator")
local homing = require("homing")
local FormationPhase = require("FormationPhase")

local GameModel = class()

-- 규칙 상수(설정). love 와 무관한 월드 수치.
local PLAYER_SPEED = 320
local ENEMY_BULLET_SPEED = 240
local ENEMY_FIRE_INTERVAL = 0.6
local FORMATION_SPEED = 40
local FORMATION_DESCEND = 16
local MISSILE_SPEED = 440
local MISSILE_SPREAD = 55 * math.pi / 180
local MISSILE_COOLDOWN = 0.6
local GRAZE_MARGIN = 18
local GRAZE_STEP = 25
local OVERDRIVE_TIME = 5.0
local SPREAD_TIME = 8.0
local SLOW_TIME = 6.0
local SLOW_SCALE = 0.45
local POWERUP_SPEED = 110
local POWERUP_KINDS = { "spread", "shield", "slow" }

-- AABB 겹침
local function overlaps(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

local function overlapsExpanded(a, b, m)
  return a.x < b.x + b.w + m and b.x - m < a.x + a.w and a.y < b.y + b.h + m and b.y - m < a.y + a.h
end

--- @param opts table  { width=number, height=number, seed=number, waves=table|nil }
function GameModel:init(opts)
  opts = opts or {}
  self.width = opts.width or 600
  self.height = opts.height or 800
  self.rng = Rng(opts.seed or 1)
  self.waves = opts.waves
  self._weaponBase = WeaponDecorator.BaseWeapon()
  self._weaponSpread = WeaponDecorator.SpreadDecorator(self._weaponBase)
  self._weaponOverdrive = WeaponDecorator.RapidDecorator(self._weaponSpread, 0.5)
  self._aiCtx = {
    rng = self.rng,
    playerX = 0,
    playerY = 0,
    width = self.width,
    height = self.height,
  }
  self:reset()
end

function GameModel:reset()
  self.player = PlayerModel(self.width * 0.5 - 20, self.height - 60)
  self.bullets = {}
  self.enemyBullets = {}
  self.enemies = {}
  self.powerups = {}
  self.score = 0
  self.lives = 3
  self.grazeGauge = 0
  self.overdriveTimer = 0
  self.spreadTimer = 0
  self.slowTimer = 0
  self.shield = false
  self.state = "playing" -- 결과: "playing" | "gameover" | "won"
  self.formationDir = 1
  self.enemyFireTimer = ENEMY_FIRE_INTERVAL
  self.missileCooldown = 0
  self.waveIndex = 0
  self.boss = nil -- BossPhase 가 채운다 (View 가 읽는다)
  self.events = {} -- 스텝마다 쌓이고, 소비자(View)가 drainEvents() 로 비운다
  self:spawnFormation()
  self.phase = nil
  self:changePhase(FormationPhase())
end

--- 진행 단계를 바꾼다. 새 단계의 enter 가 곧바로 호출된다.
function GameModel:changePhase(phase)
  self.phase = phase
  phase:enter(self)
end

function GameModel:spawnFormation()
  if self.waves and #self.waves > 0 then
    self.waveIndex = (self.waveIndex % #self.waves) + 1
    local wave = self.waves[self.waveIndex]
    for _, spawn in ipairs(wave.spawns) do
      self.enemies[#self.enemies + 1] = EnemyFactory.create(spawn.kind, spawn.x, spawn.y)
    end
    return
  end

  for row = 0, 3 do
    for col = 0, 7 do
      self.enemies[#self.enemies + 1] = EnemyFactory.create("basic", 60 + col * 60, 60 + row * 50)
    end
  end
end

function GameModel:_emit(evt)
  self.events[#self.events + 1] = evt
end

--- 쌓인 이벤트를 넘기고 비운다. 프레임당 1회(모든 고정 스텝이 끝난 뒤) 호출한다.
function GameModel:drainEvents()
  local out = self.events
  self.events = {}
  return out
end

--- 고정 스텝 1회. 모든 상태 변경은 여기서(그리고 여기서 부르는 단계 State 에서)만.
-- @param input table  { move = -1|0|1, fire = boolean, missile = boolean }
--
-- 이벤트 계약 (GameModel → View):
--   { type = "fire" }
--   { type = "enemy_hit", x = number, y = number }
--   { type = "enemy_destroyed", x = number, y = number }
--   { type = "player_hit" }
--   { type = "game_over" }
--   { type = "formation_cleared" }
--   { type = "boss_appeared" }
--   { type = "boss_hit", x = number, y = number }
--   { type = "boss_destroyed", x = number, y = number }
function GameModel:update(dt, input)
  if self.state ~= "playing" then
    return
  end

  local move = input.move or 0
  local fire = input.fire or false

  -- 플레이어 타이머
  if self.overdriveTimer > 0 then
    self.overdriveTimer = math.max(0, self.overdriveTimer - dt)
  end
  if self.spreadTimer > 0 then
    self.spreadTimer = math.max(0, self.spreadTimer - dt)
  end
  if self.slowTimer > 0 then
    self.slowTimer = math.max(0, self.slowTimer - dt)
  end

  -- 플레이어
  self.player:move(dt, move, PLAYER_SPEED)
  self.player:clamp(0, self.width)
  self.player:tickCooldown(dt)
  if fire and self.player:canFire() then
    local weapon = self._weaponBase
    if self.overdriveTimer > 0 then
      weapon = self._weaponOverdrive
    elseif self.spreadTimer > 0 then
      weapon = self._weaponSpread
    end
    weapon:fire(self.player, self.bullets)
    self.player:resetCooldown(weapon:cooldown())
    self:_emit({ type = "fire" })
  end

  -- 트윈 유도 미사일 측면 사출 + 감쇠 사인파 조향
  self.missileCooldown = self.missileCooldown - dt
  if input.missile and self.missileCooldown <= 0 then
    local p = self.player
    local cx = p.x + p.w * 0.5 - 3
    local baseAngle = -math.pi * 0.5
    local a1 = baseAngle - MISSILE_SPREAD
    local a2 = baseAngle + MISSILE_SPREAD
    local m1 = BulletModel(cx - 8, p.y, math.cos(a1) * MISSILE_SPEED, math.sin(a1) * MISSILE_SPEED, 6, 14, "missile")
    local m2 = BulletModel(cx + 8, p.y, math.cos(a2) * MISSILE_SPEED, math.sin(a2) * MISSILE_SPEED, 6, 14, "missile")
    m1.phase = 0
    m2.phase = math.pi
    self.bullets[#self.bullets + 1] = m1
    self.bullets[#self.bullets + 1] = m2
    self.missileCooldown = MISSILE_COOLDOWN
    self:_emit({ type = "fire" })
  end
  self:_steerMissiles(dt)

  -- 플레이어 총알 이동/제거
  for i = #self.bullets, 1, -1 do
    local b = self.bullets[i]
    b:update(dt)
    if b:isOffscreen(self.width, self.height) then
      table.remove(self.bullets, i)
    end
  end

  self:_updateFormation(dt)
  self:_updateEnemies(dt)
  self:_updateEnemyFire(dt)
  self.phase:update(self, dt)

  -- 적 총알 이동/제거 (슬로우 파워업 적용)
  local enemyBulletDt = (self.slowTimer > 0) and (dt * SLOW_SCALE) or dt
  for i = #self.enemyBullets, 1, -1 do
    local b = self.enemyBullets[i]
    b:update(enemyBulletDt)
    if b:isOffscreen(self.width, self.height) then
      table.remove(self.enemyBullets, i)
    end
  end

  self:_updatePowerups(dt)
  self:_resolveCollisions()
  self.phase:resolveCollisions(self)
  self.phase:afterStep(self)
end

function GameModel:_updateFormation(dt)
  local minx, maxx = math.huge, -math.huge
  for _, e in ipairs(self.enemies) do
    if e.alive then
      minx = math.min(minx, e.homeX)
      maxx = math.max(maxx, e.homeX + e.w)
    end
  end
  if minx == math.huge then
    return
  end
  local dx = self.formationDir * FORMATION_SPEED * dt
  if maxx + dx > self.width - 10 or minx + dx < 10 then
    self.formationDir = -self.formationDir
    for _, e in ipairs(self.enemies) do
      e.homeY = e.homeY + FORMATION_DESCEND
    end
  else
    for _, e in ipairs(self.enemies) do
      e.homeX = e.homeX + dx
    end
  end
end

function GameModel:_updateEnemies(dt)
  local aiCtx = self._aiCtx
  aiCtx.playerX = self.player.x + self.player.w * 0.5
  aiCtx.playerY = self.player.y + self.player.h * 0.5
  for _, e in ipairs(self.enemies) do
    if e.alive then
      e:update(dt, aiCtx)
    end
  end
end

function GameModel:_updateEnemyFire(dt)
  self.enemyFireTimer = self.enemyFireTimer - dt
  if self.enemyFireTimer > 0 then
    return
  end
  self.enemyFireTimer = ENEMY_FIRE_INTERVAL

  local alive = {}
  for _, e in ipairs(self.enemies) do
    if e.alive and e.y >= 0 then
      alive[#alive + 1] = e
    end
  end
  if #alive == 0 then
    return
  end
  local e = alive[self.rng:range(#alive)]
  self.enemyBullets[#self.enemyBullets + 1] =
    BulletModel(e:centerX() - 2, e.y + e.h, 0, ENEMY_BULLET_SPEED, 4, 12, "enemy")
end

function GameModel:_updatePowerups(dt)
  for i = #self.powerups, 1, -1 do
    local pu = self.powerups[i]
    pu.y = pu.y + pu.vy * dt
    if overlaps(pu, self.player) then
      if pu.kind == "spread" then
        self.spreadTimer = SPREAD_TIME
      elseif pu.kind == "shield" then
        self.shield = true
      elseif pu.kind == "slow" then
        self.slowTimer = SLOW_TIME
      end
      self:_emit({ type = "powerup_picked", kind = pu.kind, x = pu.x, y = pu.y })
      table.remove(self.powerups, i)
    elseif pu.y > self.height + 24 then
      table.remove(self.powerups, i)
    end
  end
end

-- 모든 단계에 공통인 충돌. 단계 고유 충돌(보스)은 phase:resolveCollisions 가 맡는다.
function GameModel:_resolveCollisions()
  -- 플레이어 총알 × 적
  for bi = #self.bullets, 1, -1 do
    local b = self.bullets[bi]
    for _, e in ipairs(self.enemies) do
      if e.alive and overlaps(b, e) then
        if e:hit(1) then
          local isDive = (e.aiState == "dive")
          local pts = (e.scoreValue or 100) * (isDive and 2 or 1)
          self.score = self.score + pts
          local ex, ey = e:centerX(), e:centerY()
          self:_emit({ type = "enemy_destroyed", x = ex, y = ey })
          if isDive and self.rng:range(2) == 1 then
            local kind = POWERUP_KINDS[self.rng:range(#POWERUP_KINDS)]
            self.powerups[#self.powerups + 1] = {
              x = ex - 9,
              y = ey - 9,
              w = 18,
              h = 18,
              vy = POWERUP_SPEED,
              kind = kind,
            }
          end
        else
          self:_emit({ type = "enemy_hit", x = e:centerX(), y = e:centerY() })
        end
        table.remove(self.bullets, bi)
        break
      end
    end
  end

  -- 적 총알 × 플레이어 (충돌 + 스침 Graze)
  for i = #self.enemyBullets, 1, -1 do
    local eb = self.enemyBullets[i]
    if overlaps(eb, self.player) then
      table.remove(self.enemyBullets, i)
      if self.shield then
        self.shield = false
        self:_emit({ type = "shield_broken" })
      else
        self.lives = self.lives - 1
        self:_emit({ type = "player_hit" })
        if self.lives <= 0 then
          self.state = "gameover"
          self:_emit({ type = "game_over" })
          break
        end
      end
    elseif not eb.grazed and overlapsExpanded(eb, self.player, GRAZE_MARGIN) then
      eb.grazed = true
      self.score = self.score + 25
      self:_emit({ type = "graze", x = self.player.x + self.player.w * 0.5, y = self.player.y })
      if self.overdriveTimer <= 0 then
        self.grazeGauge = self.grazeGauge + GRAZE_STEP
        if self.grazeGauge >= 100 then
          self.grazeGauge = 0
          self.overdriveTimer = OVERDRIVE_TIME
          self:_emit({ type = "overdrive_started" })
        end
      end
    end
  end
end

-- 살아있는 적·보스 중 가장 가까운 쪽으로 미사일을 감쇠 사인파 조향으로 꺾는다.
function GameModel:_steerMissiles(dt)
  local targets
  for i = 1, #self.bullets do
    local b = self.bullets[i]
    if b.kind == "missile" then
      if not targets then
        targets = {}
        for _, e in ipairs(self.enemies) do
          if e.alive then
            targets[#targets + 1] = { x = e:centerX(), y = e:centerY() }
          end
        end
        if self.boss and self.boss.alive then
          targets[#targets + 1] = { x = self.boss:centerX(), y = self.boss:centerY() }
        end
      end
      local tx, ty = homing.nearest(targets, b.x, b.y)
      if tx then
        homing.steerWave(b, tx, ty, MISSILE_SPEED, dt)
      end
    end
  end
end

return GameModel
