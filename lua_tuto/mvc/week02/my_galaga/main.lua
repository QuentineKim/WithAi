-- main.lua
-- 겔러그 (Galaga Monolith) - 2주차 실습 (요란한 보스 탄막 추가 버전)
-- 특징: 의도적 모놀리식 안티패턴 + 대형 네온 보스 + 3단 탄막(원형/부채꼴/회오리) + 연쇄 대폭발
-- ⚠️ [BOSS] 주석: 보스 하나를 넣기 위해 파일 전역(상태, 총알 구조, 이동, 충돌, 연출, 렌더)으로 전파된 지점들

-- ── 1. 파일 전역 상태 덩어리 ──────────────────────────────────────────────
local player
local bullets = {}
local enemies = {}
local enemyBullets = {} -- [BOSS] 이제 보스 탄막을 위해 vx, vy, color 필드가 섞여 들어감
local particles = {}

local score = 0
local lives = 3
local wave = 1
local gameover = false
local won = false

-- 편대 및 일반 적 탄막 상태
local formationDir = 1
local formationSpeed = 45
local enemyShootTimer = 0

-- [BOSS] 보스 관련 전역 상태들이 파일 최상단에 침투
local boss = nil
local bossSpawned = false
local bossWarningTimer = 0
local bossDefeatedTimer = 0
local bossExplosionQueue = {}

-- 연출 상태 (⚠️ View 연출 타이머가 전역 로직에 결합)
local screenShake = 0
local flash = 0

-- 폰트
local fontRegular, fontTitle, fontBig

-- ── 2. 매직 넘버 상수들 ────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 600, 800
local PLAYER_SPEED = 340
local BULLET_SPEED = 560
local ENEMY_BULLET_SPEED = 260
local COOLDOWN_TIME = 0.20

-- [BOSS] 보스 관련 상수들
local BOSS_SPAWN_SCORE = 1200 -- 1200점 이상 달성 시 또는 1웨이브 클리어 시 보스 출현
local BOSS_MAX_HP = 90
local BOSS_BULLET_SPEED = 220

-- ── 3. 편대 생성 및 보스 스폰 ────────────────────────────────────────────
local function spawnFormation()
  enemies = {}
  local rows = 4
  local cols = 8
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      enemies[#enemies + 1] = {
        x = 50 + col * 62,
        y = 70 + row * 48,
        w = 38,
        h = 26,
        alive = true,
        row = row,
      }
    end
  end
end

-- [BOSS] 요란한 대형 보스 스폰 함수
local function spawnBoss()
  boss = {
    x = (SCREEN_W - 130) * 0.5,
    y = -100, -- 상단 화면 밖에서 서서히 강림
    targetY = 75,
    w = 130,
    h = 75,
    hp = BOSS_MAX_HP,
    maxHp = BOSS_MAX_HP,
    alive = true,
    dir = 1,
    speed = 90,
    timer = 0,
    attackTimer = 1.0,
    pattern = 1, -- 1: 360도 원형 방사, 2: 7방향 부채꼴 조준탄, 3: 나선 회오리탄
    spiralAngle = 0,
    spiralShotsLeft = 0,
    hitFlash = 0,
  }
  bossSpawned = true
  bossWarningTimer = 2.4 -- 2.4초간 경고 사이렌 연출
  screenShake = 0.5
end

local function resetGame()
  player = {
    x = (SCREEN_W - 42) * 0.5,
    y = SCREEN_H - 70,
    w = 42,
    h = 24,
    cooldown = 0,
  }
  bullets = {}
  enemyBullets = {}
  particles = {}
  score = 0
  lives = 3
  wave = 1
  gameover = false
  won = false

  formationDir = 1
  formationSpeed = 45
  enemyShootTimer = 0.8

  -- [BOSS] 보스 상태 리셋
  boss = nil
  bossSpawned = false
  bossWarningTimer = 0
  bossDefeatedTimer = 0
  bossExplosionQueue = {}

  screenShake = 0
  flash = 0
  spawnFormation()
end

-- 충돌 판정 (AABB)
local function overlaps(a, b)
  return a.x < b.x + b.w
    and b.x < a.x + a.w
    and a.y < b.y + b.h
    and b.y < a.y + a.h
end

-- ── 4. 요란한 파괴 파티클 및 화면 효과 ────────────────────────────────────
local function explode(x, y, count, isPlayer, customCol)
  local particleCount = count or 30
  for _ = 1, particleCount do
    local angle = math.random() * math.pi * 2
    local speed = math.random(50, 280)
    local pColor

    if customCol then
      pColor = customCol
    elseif isPlayer then
      pColor = { 1.0, 0.2, 0.8 }
    else
      local r = math.random()
      if r < 0.33 then
        pColor = { 1.0, 0.9, 0.2 }
      elseif r < 0.66 then
        pColor = { 1.0, 0.4, 0.1 }
      else
        pColor = { 1.0, 1.0, 1.0 }
      end
    end

    particles[#particles + 1] = {
      x = x,
      y = y,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed,
      r = pColor[1],
      g = pColor[2],
      b = pColor[3],
      size = math.random(2, 5),
      life = 0.35 + math.random() * 0.45,
      maxLife = 0.8,
    }
  end

  flash = isPlayer and 0.18 or 0.08
  if isPlayer then
    screenShake = 0.40
  else
    screenShake = math.max(screenShake, 0.12)
  end
end

-- ── 5. LÖVE 수명주기 콜백 ────────────────────────────────────────────────
function love.load()
  math.randomseed(os.time())

  if love.filesystem.getInfo("font.ttf") then
    fontRegular = love.graphics.newFont("font.ttf", 13)
    fontTitle   = love.graphics.newFont("font.ttf", 18)
    fontBig     = love.graphics.newFont("font.ttf", 32)
  else
    fontRegular = love.graphics.getFont()
    fontTitle   = fontRegular
    fontBig     = fontRegular
  end

  resetGame()
end

function love.update(dt)
  -- 연출 타이머 감쇠
  if screenShake > 0 then
    screenShake = screenShake - dt
  end
  if flash > 0 then
    flash = flash - dt
  end
  if bossWarningTimer > 0 then
    bossWarningTimer = bossWarningTimer - dt
  end

  -- [BOSS] 보스 피격 플래시 감쇠
  if boss and boss.hitFlash > 0 then
    boss.hitFlash = boss.hitFlash - dt
  end

  -- [BOSS] 보스 격파 시 요란한 연쇄 대폭발 큐 처리
  if bossDefeatedTimer > 0 then
    bossDefeatedTimer = bossDefeatedTimer - dt
    if math.random() < 0.45 and boss then
      local rx = boss.x + math.random() * boss.w
      local ry = boss.y + math.random() * boss.h
      explode(rx, ry, 25, false, { 1.0, math.random() * 0.6, 0.1 })
      screenShake = 0.35
    end
    if bossDefeatedTimer <= 0 then
      -- 최종 잭팟 초대형 폭발
      if boss then
        explode(boss.x + boss.w * 0.5, boss.y + boss.h * 0.5, 90, false, { 1.0, 0.85, 0.2 })
        boss = nil
      end
      won = true
      screenShake = 0.7
      flash = 0.3
    end
  end

  -- 파티클 업데이트
  for i = #particles, 1, -1 do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vx = p.vx * 0.95
    p.vy = p.vy * 0.95
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(particles, i)
    end
  end

  if gameover or won then
    return
  end

  -- ── 5-1. 플레이어 이동 및 클램프 ────────────────────────────────────────
  local moveDir = 0
  if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    moveDir = moveDir - 1
  end
  if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    moveDir = moveDir + 1
  end

  player.x = player.x + moveDir * PLAYER_SPEED * dt
  if player.x < 0 then
    player.x = 0
  elseif player.x > SCREEN_W - player.w then
    player.x = SCREEN_W - player.w
  end

  -- ── 5-2. 플레이어 발사 ──────────────────────────────────────────────────
  player.cooldown = player.cooldown - dt
  if love.keyboard.isDown("space") and player.cooldown <= 0 then
    bullets[#bullets + 1] = {
      x = player.x + player.w * 0.5 - 2.5,
      y = player.y - 4,
      w = 5,
      h = 14,
    }
    player.cooldown = COOLDOWN_TIME
  end

  -- 총알 이동
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    b.y = b.y - BULLET_SPEED * dt
    if b.y + b.h < 0 then
      table.remove(bullets, i)
    end
  end

  -- ── 5-3. 적 편대 이동 및 보스 스폰 조건 ──────────────────────────────────
  local minX, maxX = math.huge, -math.huge
  local hasAlive = false

  for _, e in ipairs(enemies) do
    if e.alive then
      hasAlive = true
      minX = math.min(minX, e.x)
      maxX = math.max(maxX, e.x + e.w)
    end
  end

  if hasAlive then
    local dx = formationDir * formationSpeed * dt
    if maxX + dx > SCREEN_W - 15 or minX + dx < 15 then
      formationDir = -formationDir
      for _, e in ipairs(enemies) do
        e.y = e.y + 18
      end
    else
      for _, e in ipairs(enemies) do
        e.x = e.x + dx
      end
    end
  else
    -- [BOSS] 적 편대가 전멸했거나 점수가 넘으면 보스 출현!
    if not bossSpawned then
      spawnBoss()
    elseif not (boss and boss.alive) and bossDefeatedTimer <= 0 then
      -- 보스도 잡았으면 다음 웨이브
      wave = wave + 1
      formationSpeed = formationSpeed + 10
      spawnFormation()
    end
  end

  -- [BOSS] 점수 조건으로도 보스 출현
  if not bossSpawned and score >= BOSS_SPAWN_SCORE then
    spawnBoss()
  end

  -- ── 5-4. 적 총알 발사 (일반 적) ─────────────────────────────────────────
  enemyShootTimer = enemyShootTimer - dt
  if enemyShootTimer <= 0 and hasAlive then
    enemyShootTimer = math.max(0.35, 0.85 - wave * 0.05)
    local aliveList = {}
    for _, e in ipairs(enemies) do
      if e.alive then
        aliveList[#aliveList + 1] = e
      end
    end

    if #aliveList > 0 then
      local shooter = aliveList[math.random(#aliveList)]
      -- [BOSS] 일반 적 총알도 이제 vx, vy 벡터를 공유
      enemyBullets[#enemyBullets + 1] = {
        x = shooter.x + shooter.w * 0.5 - 2.5,
        y = shooter.y + shooter.h,
        w = 5,
        h = 12,
        vx = 0,
        vy = ENEMY_BULLET_SPEED,
        color = { 1.0, 0.7, 0.2 },
      }
    end
  end

  -- ── 5-5. [BOSS] 보스 이동 및 요란한 3단 탄막 패턴 ────────────────────────
  if boss and boss.alive and bossWarningTimer <= 0 then
    boss.timer = boss.timer + dt

    -- 등장 애니메이션: 위에서 부드럽게 하강
    if boss.y < boss.targetY then
      boss.y = boss.y + 80 * dt
    else
      -- 좌우로 유연하게 활공하며 살짝 위아래 호버링
      boss.x = boss.x + boss.dir * boss.speed * dt
      boss.y = boss.targetY + math.sin(boss.timer * 3) * 12

      if boss.x < 20 then
        boss.x = 20
        boss.dir = 1
      elseif boss.x > SCREEN_W - boss.w - 20 then
        boss.x = SCREEN_W - boss.w - 20
        boss.dir = -1
      end
    end

    -- ── [BOSS] 3대 요란한 탄막 패턴 시스템 ────────────────────────────────
    boss.attackTimer = boss.attackTimer - dt

    -- 패턴 3(나선 회오리탄) 잔여 연속 발사 처리
    if boss.spiralShotsLeft > 0 then
      boss.spiralAngle = boss.spiralAngle + 0.38
      local cx = boss.x + boss.w * 0.5
      local cy = boss.y + boss.h * 0.6
      local spd = 240
      -- 2방향 동시 나선 분사
      enemyBullets[#enemyBullets + 1] = {
        x = cx - 3, y = cy - 3, w = 6, h = 6,
        vx = math.cos(boss.spiralAngle) * spd,
        vy = math.sin(boss.spiralAngle) * spd,
        color = { 1.0, 0.85, 0.1 },
      }
      enemyBullets[#enemyBullets + 1] = {
        x = cx - 3, y = cy - 3, w = 6, h = 6,
        vx = math.cos(boss.spiralAngle + math.pi) * spd,
        vy = math.sin(boss.spiralAngle + math.pi) * spd,
        color = { 1.0, 0.4, 0.1 },
      }
      boss.spiralShotsLeft = boss.spiralShotsLeft - 1
    end

    if boss.attackTimer <= 0 then
      local cx = boss.x + boss.w * 0.5
      local cy = boss.y + boss.h * 0.7

      if boss.pattern == 1 then
        -- 🌟 [패턴 1: 360도 원형 방사 탄막 (16발)]
        local bulletCount = 16
        for i = 1, bulletCount do
          local angle = (i / bulletCount) * math.pi * 2 + (boss.timer * 0.5)
          enemyBullets[#enemyBullets + 1] = {
            x = cx - 3, y = cy - 3, w = 6, h = 6,
            vx = math.cos(angle) * BOSS_BULLET_SPEED,
            vy = math.sin(angle) * BOSS_BULLET_SPEED,
            color = { 1.0, 0.15, 0.3 }, -- 붉은 에너지 탄
          }
        end
        boss.attackTimer = 1.2
        boss.pattern = 2
        screenShake = 0.15

      elseif boss.pattern == 2 then
        -- 🎯 [패턴 2: 플레이어 정조준 7방향 부채꼴 확산탄]
        local px = player.x + player.w * 0.5
        local py = player.y + player.h * 0.5
        local baseAngle = math.atan2(py - cy, px - cx)
        local spreadCount = 7
        for i = -3, 3 do
          local angle = baseAngle + (i * 0.16)
          local spd = BOSS_BULLET_SPEED * 1.25
          enemyBullets[#enemyBullets + 1] = {
            x = cx - 3, y = cy - 3, w = 6, h = 10,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            color = { 0.2, 0.8, 1.0 }, -- 푸른 고속 조준탄
          }
        end
        boss.attackTimer = 1.4
        boss.pattern = 3
        screenShake = 0.2

      elseif boss.pattern == 3 then
        -- 🌀 [패턴 3: 나선형 회오리 탄막 트리거 (총 24연발)]
        boss.spiralShotsLeft = 24
        boss.attackTimer = 1.8
        boss.pattern = 1
        screenShake = 0.25
      end
    end
  end

  -- ── 5-6. 적 및 보스 총알 이동 및 화면 밖 제거 ────────────────────────────
  for i = #enemyBullets, 1, -1 do
    local eb = enemyBullets[i]
    eb.x = eb.x + (eb.vx or 0) * dt
    eb.y = eb.y + (eb.vy or ENEMY_BULLET_SPEED) * dt

    if eb.y > SCREEN_H + 20 or eb.y < -30 or eb.x < -30 or eb.x > SCREEN_W + 30 then
      table.remove(enemyBullets, i)
    end
  end

  -- ── 5-7. 충돌 판정 (내 총알 × 일반 적 및 보스) ───────────────────────────
  for bi = #bullets, 1, -1 do
    local b = bullets[bi]
    local bulletHit = false

    -- [BOSS] 내 총알 × 보스 충돌
    if boss and boss.alive and bossWarningTimer <= 0 and overlaps(b, boss) then
      boss.hp = boss.hp - 1
      boss.hitFlash = 0.08
      score = score + 25
      explode(b.x, b.y, 6, false, { 1.0, 0.9, 0.3 })
      bulletHit = true

      if boss.hp <= 0 then
        -- [BOSS] 보스 체력 소진 ➔ 연쇄 대폭발 시작!
        boss.alive = false
        score = score + 5000
        bossDefeatedTimer = 2.0 -- 2초 동안 화려한 연쇄 폭발
        screenShake = 0.6
        flash = 0.25
      end
    end

    -- 내 총알 × 일반 적 충돌
    if not bulletHit then
      for _, e in ipairs(enemies) do
        if e.alive and overlaps(b, e) then
          e.alive = false
          score = score + 100
          explode(e.x + e.w * 0.5, e.y + e.h * 0.5, 28, false)
          bulletHit = true
          break
        end
      end
    end

    if bulletHit then
      table.remove(bullets, bi)
    end
  end

  -- ── 5-8. 충돌 판정 (적/보스 총알 × 플레이어) ─────────────────────────────
  for ei = #enemyBullets, 1, -1 do
    local eb = enemyBullets[ei]
    if overlaps(eb, player) then
      table.remove(enemyBullets, ei)
      lives = lives - 1
      explode(player.x + player.w * 0.5, player.y + player.h * 0.5, 35, true)
      if lives <= 0 then
        gameover = true
      end
    end
  end

  -- 적이 플레이어 높이까지 내려왔을 때
  for _, e in ipairs(enemies) do
    if e.alive and (e.y + e.h >= player.y) then
      gameover = true
      explode(player.x + player.w * 0.5, player.y + player.h * 0.5, 45, true)
      break
    end
  end
end

-- ── 6. 렌더링 (draw) ──────────────────────────────────────────────────────
function love.draw()
  local shakeX, shakeY = 0, 0
  if screenShake > 0 then
    local intensity = screenShake * 24
    shakeX = (math.random() - 0.5) * intensity
    shakeY = (math.random() - 0.5) * intensity
  end

  love.graphics.push()
  love.graphics.translate(shakeX, shakeY)

  -- 우주 배경
  love.graphics.clear(0.02, 0.02, 0.06)

  -- 화면 번쩍임 효과
  if flash > 0 then
    love.graphics.setColor(1.0, 1.0, 1.0, 0.4)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
  end

  -- ── 6-1. 플레이어 (사각형의 마젠타색) ───────────────────────────────────
  love.graphics.setColor(1.0, 0.15, 0.75, 0.35)
  love.graphics.rectangle("fill", player.x - 2, player.y - 2, player.w + 4, player.h + 4)
  love.graphics.setColor(1.0, 0.15, 0.75, 1.0)
  love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
  love.graphics.setColor(1.0, 0.85, 0.95, 0.9)
  love.graphics.rectangle("fill", player.x + player.w * 0.5 - 3, player.y + 3, 6, player.h - 6)

  -- ── 6-2. 플레이어 총알 ──────────────────────────────────────────────────
  for _, b in ipairs(bullets) do
    love.graphics.setColor(0.2, 0.95, 1.0, 0.5)
    love.graphics.rectangle("fill", b.x - 1, b.y - 1, b.w + 2, b.h + 2)
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  end

  -- ── 6-3. 일반 적 편대 ───────────────────────────────────────────────────
  for _, e in ipairs(enemies) do
    if e.alive then
      if e.row == 0 then
        love.graphics.setColor(1.0, 0.25, 0.25)
      elseif e.row == 1 then
        love.graphics.setColor(1.0, 0.6, 0.2)
      elseif e.row == 2 then
        love.graphics.setColor(0.3, 0.85, 1.0)
      else
        love.graphics.setColor(0.4, 1.0, 0.4)
      end
      love.graphics.rectangle("fill", e.x, e.y, e.w, e.h, 2, 2)
      love.graphics.setColor(1, 1, 1, 0.7)
      love.graphics.rectangle("fill", e.x + 6, e.y + 6, 6, 6)
      love.graphics.rectangle("fill", e.x + e.w - 12, e.y + 6, 6, 6)
    end
  end

  -- ── 6-4. [BOSS] 요란한 대형 보스 렌더링 ──────────────────────────────────
  if boss and (boss.alive or bossDefeatedTimer > 0) then
    local bx, by = boss.x, boss.y
    local bw, bh = boss.w, boss.h

    -- 피격 시 번쩍임
    if boss.hitFlash > 0 then
      love.graphics.setColor(1, 1, 1, 0.9)
    else
      -- 보스 본체 네온 장갑
      love.graphics.setColor(0.9, 0.1, 0.35, 0.9)
    end

    -- 1) 보스 양 날개 포탑 (좌우)
    love.graphics.rectangle("fill", bx, by + 15, 30, bh - 15, 3, 3)
    love.graphics.rectangle("fill", bx + bw - 30, by + 15, 30, bh - 15, 3, 3)

    -- 2) 보스 메인 바디
    love.graphics.setColor(0.15, 0.18, 0.32, 0.95)
    love.graphics.rectangle("fill", bx + 20, by, bw - 40, bh, 4, 4)
    love.graphics.setColor(1.0, 0.2, 0.4, 0.8)
    love.graphics.rectangle("line", bx + 20, by, bw - 40, bh, 4, 4)

    -- 3) 중앙 에너지 코어 (체력에 따라 색상 변화)
    local hpRatio = boss.hp / boss.maxHp
    if hpRatio > 0.5 then
      love.graphics.setColor(0.2, 1.0, 0.4, 0.9) -- 초록
    elseif hpRatio > 0.25 then
      love.graphics.setColor(1.0, 0.85, 0.1, 0.9) -- 주황
    else
      love.graphics.setColor(1.0, 0.1, 0.2, 0.9 + 0.1 * math.sin(boss.timer * 15)) -- 위험 빨강 점멸
    end
    love.graphics.circle("fill", bx + bw * 0.5, by + bh * 0.55, 16)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", bx + bw * 0.5, by + bh * 0.55, 8)
  end

  -- ── 6-5. 적 & 보스 탄막 렌더링 ──────────────────────────────────────────
  for _, eb in ipairs(enemyBullets) do
    local col = eb.color or { 1.0, 0.7, 0.2 }
    love.graphics.setColor(col[1], col[2], col[3], 0.4)
    love.graphics.rectangle("fill", eb.x - 2, eb.y - 2, eb.w + 4, eb.h + 4)
    love.graphics.setColor(col[1], col[2], col[3], 1.0)
    love.graphics.rectangle("fill", eb.x, eb.y, eb.w, eb.h)
  end

  -- ── 6-6. 파티클 ─────────────────────────────────────────────────────────
  for _, p in ipairs(particles) do
    local alpha = p.life / p.maxLife
    love.graphics.setColor(p.r, p.g, p.b, alpha)
    love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
  end

  love.graphics.pop() -- 화면 흔들림 복원

  -- ── 6-7. [BOSS] 보스 경고 사이렌 연출 ───────────────────────────────────
  if bossWarningTimer > 0 then
    local blink = (math.sin(love.timer.getTime() * 14) > 0)
    if blink then
      love.graphics.setColor(1.0, 0.1, 0.1, 0.25)
      love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
      love.graphics.setFont(fontTitle)
      love.graphics.setColor(1.0, 0.2, 0.2, 1.0)
      love.graphics.printf("⚠️ 경고! 거대 보스 전함 출현! ⚠️", 0, SCREEN_H * 0.4, SCREEN_W, "center")
    end
  end

  -- ── 6-8. [BOSS] 보스 대형 체력 바 ───────────────────────────────────────
  if boss and boss.alive and bossWarningTimer <= 0 then
    local barW = 340
    local barX = (SCREEN_W - barW) * 0.5
    local barY = 46
    local ratio = math.max(0, boss.hp / boss.maxHp)

    -- HP 배경
    love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
    love.graphics.rectangle("fill", barX, barY, barW, 10, 2, 2)
    -- HP 게이지
    love.graphics.setColor(1.0, 0.2, 0.4, 0.95)
    love.graphics.rectangle("fill", barX, barY, barW * ratio, 10, 2, 2)
    -- 테두리
    love.graphics.setColor(1.0, 0.6, 0.7, 0.7)
    love.graphics.rectangle("line", barX, barY, barW, 10, 2, 2)

    love.graphics.setFont(fontRegular)
    love.graphics.setColor(1.0, 0.3, 0.4, 0.9)
    love.graphics.printf(string.format("BOSS HP: %d / %d", boss.hp, boss.maxHp), 0, barY - 18, SCREEN_W, "center")
  end

  -- ── 6-9. 상단 HUD ───────────────────────────────────────────────────────
  love.graphics.setFont(fontTitle)
  love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
  love.graphics.printf(string.format("SCORE: %06d", score), 20, 14, 250, "left")

  -- 라이프
  love.graphics.setColor(1.0, 0.2, 0.75, 1.0)
  love.graphics.printf("LIVES: ", SCREEN_W - 180, 14, 80, "left")
  for i = 1, 3 do
    if i <= lives then
      love.graphics.setColor(1.0, 0.15, 0.75, 1.0)
    else
      love.graphics.setColor(0.3, 0.3, 0.4, 0.6)
    end
    love.graphics.rectangle("fill", SCREEN_W - 100 + (i - 1) * 24, 16, 16, 14, 2, 2)
  end

  -- ── 6-10. 승리 (VICTORY) UI ─────────────────────────────────────────────
  if won then
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    love.graphics.setFont(fontBig)
    love.graphics.setColor(1.0, 0.85, 0.1, 1.0)
    love.graphics.printf("★ BOSS DESTROYED! ★", 0, SCREEN_H * 0.5 - 90, SCREEN_W, "center")

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0.3, 1.0, 0.5, 1.0)
    love.graphics.printf(string.format("최종 승리 점수: %d", score), 0, SCREEN_H * 0.5 - 30, SCREEN_W, "center")

    love.graphics.setColor(1.0, 1.0, 1.0, 0.9)
    love.graphics.printf("[R] 키를 눌러 다시 도전", 0, SCREEN_H * 0.5 + 20, SCREEN_W, "center")
  end

  -- ── 6-11. 게임 오버 UI ──────────────────────────────────────────────────
  if gameover then
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

    love.graphics.setFont(fontBig)
    love.graphics.setColor(1.0, 0.2, 0.3, 1.0)
    love.graphics.printf("GAME OVER", 0, SCREEN_H * 0.5 - 90, SCREEN_W, "center")

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1.0, 0.9, 0.2, 1.0)
    love.graphics.printf(string.format("최종 점수: %d", score), 0, SCREEN_H * 0.5 - 30, SCREEN_W, "center")

    love.graphics.setColor(1.0, 1.0, 1.0, 0.9)
    love.graphics.printf("[R] 키를 눌러 다시 시작", 0, SCREEN_H * 0.5 + 20, SCREEN_W, "center")

    love.graphics.setFont(fontRegular)
    love.graphics.setColor(0.6, 0.6, 0.7, 0.8)
    love.graphics.printf("조작: A/D 또는 ←/→ (이동) | Space (발사) | Esc (종료)", 0, SCREEN_H * 0.5 + 70, SCREEN_W, "center")
  end
end

-- ── 7. 키 입력 ────────────────────────────────────────────────────────────
function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "r" and (gameover or won) then
    resetGame()
  end
end
