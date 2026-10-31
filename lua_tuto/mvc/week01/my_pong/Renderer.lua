-- Renderer.lua
-- 트론 네온 렌더러 + 4인방 HUD (한글 UI / 순수 View)

local constants = require("constants")
local lg = love.graphics

local Renderer = {}

-- 폰트 캐싱
local fontRegular, fontTitle, fontSmall, fontScore, fontToast

local function ensureFonts()
  if fontRegular then return end
  if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo("font.ttf") then
    fontRegular = lg.newFont("font.ttf", 12)
    fontTitle   = lg.newFont("font.ttf", 14)
    fontSmall   = lg.newFont("font.ttf", 10.5)
    fontScore   = lg.newFont("font.ttf", 26)
    fontToast   = lg.newFont("font.ttf", 18)
  else
    fontRegular = lg.getFont()
    fontTitle   = fontRegular
    fontSmall   = fontRegular
    fontScore   = fontRegular
    fontToast   = fontRegular
  end
end

-- 네온 다층 글로우 사각형
function Renderer.drawNeonRect(x, y, w, h, color, glowRadius, pulse)
  local r, g, b = color[1], color[2], color[3]
  local p = pulse or 1.0

  -- 1) 외부 글로우
  for i = glowRadius, 1, -1 do
    local alpha = (0.06 / (i * 0.7)) * p
    lg.setColor(r, g, b, alpha)
    lg.rectangle("fill", x - i * 2, y - i * 2, w + i * 4, h + i * 4, 3, 3)
  end

  -- 2) 메인 바디
  lg.setColor(r, g, b, 0.95 * p)
  lg.rectangle("fill", x, y, w, h, 2, 2)

  -- 3) 백색 코어
  lg.setColor(1, 1, 1, 0.85 * p)
  lg.rectangle("fill", x + 2, y + 2, math.max(0, w - 4), math.max(0, h - 4), 1, 1)
end

-- 메인 화면 렌더링
function Renderer.draw(game)
  ensureFonts()

  local pulse = 0.9 + 0.1 * math.sin(game.time * 6)
  local ax, ay = constants.ARENA_X, constants.ARENA_Y
  local aw, ah = constants.ARENA_W, constants.ARENA_H

  -- ── 1. 아레나 배경 및 그리드 ──────────────────────────────────────────
  local grid = constants.COLOR_GRID
  lg.setColor(grid[1], grid[2], grid[3], grid[4])
  for gx = ax, ax + aw, 36 do
    lg.line(gx, ay, gx, ay + ah)
  end
  for gy = ay, ay + ah, 36 do
    lg.line(ax, gy, ax + aw, gy)
  end

  -- 아레나 네온 외곽선
  local ballSpd = math.sqrt(game.ball.vx * game.ball.vx + game.ball.vy * game.ball.vy)
  if ballSpd > 1000 then
    lg.setColor(1.0, 0.2, 0.3, 0.85 * pulse)
  else
    lg.setColor(0.0, 0.85, 1.0, 0.8)
  end
  lg.rectangle("line", ax, ay, aw, ah)
  lg.rectangle("line", ax + 2, ay + 2, aw - 4, ah - 4)

  -- 중앙 점선 네트
  for y = ay + 10, ay + ah - 15, 24 do
    Renderer.drawNeonRect(ax + (aw - 2) * 0.5, y, 2, 12, { 0.2, 0.5, 0.8 }, 2, pulse)
  end

  -- ── 2. 아레나 상단 실시간 모멘텀 바 & 액션 알림 ───────────────────────
  local momentum = game.analytics.liveMomentum
  local barW = aw - 40
  local barX = ax + 20
  local barY = ay + 10

  lg.setColor(0.05, 0.08, 0.15, 0.9)
  lg.rectangle("fill", barX, barY, barW, 6, 2, 2)
  lg.setColor(constants.COLOR_CYAN[1], constants.COLOR_CYAN[2], constants.COLOR_CYAN[3], 0.9)
  lg.rectangle("fill", barX, barY, barW * momentum, 6, 2, 2)
  lg.setColor(constants.COLOR_MAGENTA[1], constants.COLOR_MAGENTA[2], constants.COLOR_MAGENTA[3], 0.9)
  lg.rectangle("fill", barX + barW * momentum, barY, barW * (1 - momentum), 6, 2, 2)

  -- 최근 공방 상황 및 구속 텍스트
  lg.setFont(fontSmall)
  if game.lastHitAction ~= "" then
    if string.find(game.lastHitAction, "스매시") then
      lg.setColor(constants.COLOR_MAGENTA[1], constants.COLOR_MAGENTA[2], constants.COLOR_MAGENTA[3], 0.95)
    else
      lg.setColor(constants.COLOR_CYAN[1], constants.COLOR_CYAN[2], constants.COLOR_CYAN[3], 0.95)
    end
    lg.printf(string.format("%s  [구속: %d px/s]", game.lastHitAction, math.floor(ballSpd)), ax, ay + 20, aw, "center")
  end

  -- ── 3. 패들과 공 ────────────────────────────────────────────────────────
  Renderer.drawNeonRect(game.left.x, game.left.y, game.left.w, game.left.h, game.left.color, 4, pulse)
  Renderer.drawNeonRect(game.right.x, game.right.y, game.right.w, game.right.h, game.right.color, 4, pulse)

  -- 공 라이트 잔상
  local b = game.ball
  local trail = b.trail
  local yellow = constants.COLOR_YELLOW
  for i = 1, #trail do
    local pt = trail[i]
    local ratio = 1 - (i / (#trail + 1))
    local size = (b.w * 0.7) * ratio
    lg.setColor(yellow[1], yellow[2], yellow[3], 0.55 * ratio)
    lg.rectangle("fill", pt.x - size * 0.5, pt.y - size * 0.5, size, size)
  end

  -- 공 본체
  local ballCol = (ballSpd > 1200) and constants.COLOR_GOLD or yellow
  Renderer.drawNeonRect(b.x, b.y, b.w, b.h, ballCol, 5, 1.1)

  -- 파티클
  for _, p in ipairs(game.ps.particles) do
    local alpha = (p.life / p.maxLife)
    lg.setColor(p.r, p.g, p.b, alpha * 0.4)
    lg.circle("fill", p.x, p.y, p.size * 2)
    lg.setColor(1, 1, 1, alpha * 0.9)
    lg.circle("fill", p.x, p.y, p.size * 0.8)
  end

  -- 상단 점수
  lg.setFont(fontScore)
  lg.setColor(constants.COLOR_CYAN[1], constants.COLOR_CYAN[2], constants.COLOR_CYAN[3], 0.95)
  lg.printf(tostring(game.scoreL), ax, ay + 36, aw * 0.5 - 40, "right")
  lg.setColor(constants.COLOR_MAGENTA[1], constants.COLOR_MAGENTA[2], constants.COLOR_MAGENTA[3], 0.95)
  lg.printf(tostring(game.scoreR), ax + aw * 0.5 + 40, ay + 36, aw * 0.5 - 40, "left")

  -- 카지노 토스트 알림 메시지
  local market = game.market
  if market.toastTimer > 0 and market.lastResultToast ~= "" then
    local toastA = math.min(1.0, market.toastTimer)
    lg.setFont(fontToast)
    if string.find(market.lastResultToast, "잭팟") or string.find(market.lastResultToast, "올인") then
      lg.setColor(constants.COLOR_GOLD[1], constants.COLOR_GOLD[2], constants.COLOR_GOLD[3], toastA)
    else
      lg.setColor(constants.COLOR_RED[1], constants.COLOR_RED[2], constants.COLOR_RED[3], toastA)
    end
    lg.printf(market.lastResultToast, ax, ay + ah * 0.5 - 40, aw, "center")
  end

  if game.isPaused then
    lg.setFont(fontTitle)
    lg.setColor(1, 1, 0.2, 0.95)
    lg.printf("|| 일시정지 - [스페이스]를 눌러 재개 ||", ax, ay + ah * 0.5 + 20, aw, "center")
  end

  -- ── 4. 우측 도박장 텔레메트리 HUD 패널 ──────────────────────────────────
  local hx, hy = constants.HUD_X, constants.HUD_Y
  local hw, hh = constants.HUD_W, constants.HUD_H

  lg.setColor(constants.COLOR_PANEL[1], constants.COLOR_PANEL[2], constants.COLOR_PANEL[3], constants.COLOR_PANEL[4])
  lg.rectangle("fill", hx, hy, hw, hh, 4, 4)
  lg.setColor(constants.COLOR_BORDER[1], constants.COLOR_BORDER[2], constants.COLOR_BORDER[3], 0.8)
  lg.rectangle("line", hx, hy, hw, hh, 4, 4)

  -- 헤더
  lg.setFont(fontTitle)
  lg.setColor(constants.COLOR_GOLD[1], constants.COLOR_GOLD[2], constants.COLOR_GOLD[3], 1.0)
  lg.printf("★ 하이롤러 사이버 ★", hx, hy + 8, hw, "center")
  lg.setColor(0.3, 0.6, 0.8, 0.5)
  lg.line(hx + 10, hy + 26, hx + hw - 10, hy + 26)

  -- AI 배당 정보 (수비형 알파 vs 공격형 베타)
  local oddsA, oddsB, probA, probB = game.analytics:getOdds()
  local cy = hy + 30

  lg.setFont(fontSmall)
  -- 알파 (수비 특화)
  lg.setColor(constants.COLOR_CYAN[1], constants.COLOR_CYAN[2], constants.COLOR_CYAN[3])
  lg.printf(string.format("알파 [철벽수비] ELO %d (%.0f%%)", game.analytics.ratingA, probA * 100), hx + 10, cy, hw - 20, "left")
  lg.setColor(constants.COLOR_ORANGE[1], constants.COLOR_ORANGE[2], constants.COLOR_ORANGE[3])
  lg.printf(string.format("배당: %.2f배", oddsA), hx + hw - 80, cy, 70, "right")

  -- 베타 (공격 특화)
  cy = cy + 16
  lg.setColor(constants.COLOR_MAGENTA[1], constants.COLOR_MAGENTA[2], constants.COLOR_MAGENTA[3])
  lg.printf(string.format("베타 [맹공격형] ELO %d (%.0f%%)", game.analytics.ratingB, probB * 100), hx + 10, cy, hw - 20, "left")
  lg.setColor(constants.COLOR_ORANGE[1], constants.COLOR_ORANGE[2], constants.COLOR_ORANGE[3])
  lg.printf(string.format("배당: %.2f배", oddsB), hx + hw - 80, cy, 70, "right")

  -- 구분선
  cy = cy + 20
  lg.setColor(0.3, 0.6, 0.8, 0.5)
  lg.line(hx + 10, cy, hx + hw - 10, cy)

  -- 경기 속보 지표
  cy = cy + 5
  lg.setFont(fontSmall)
  lg.setColor(0.85, 0.9, 0.95)
  lg.printf(string.format("전적: 알파 %d : 베타 %d", game.analytics.winsA, game.analytics.winsB), hx + 10, cy, hw - 20, "left")
  lg.printf(string.format("랠리: %d회 | 최고 구속: %d px/s", game.analytics.currentRally, math.floor(game.analytics.peakSpeed)),
    hx + 10, cy + 13, hw - 20, "left")

  -- 구분선
  cy = cy + 30
  lg.setColor(0.3, 0.6, 0.8, 0.5)
  lg.line(hx + 10, cy, hx + hw - 10, cy)

  -- ── 도박꾼 AI 4인방 라인업 ───────────────────────────────────────────
  cy = cy + 5
  lg.setFont(fontRegular)
  lg.setColor(constants.COLOR_GOLD[1], constants.COLOR_GOLD[2], constants.COLOR_GOLD[3])
  lg.printf("도박꾼 AI 4인방 베팅 현황", hx + 10, cy, hw - 20, "left")

  lg.setFont(fontSmall)
  cy = cy + 16
  for _, b in ipairs(market.bettors) do
    if b.isBankrupt then
      lg.setColor(constants.COLOR_RED[1], constants.COLOR_RED[2], constants.COLOR_RED[3])
      lg.printf(string.format("%s: 탕진! [파산]", b.name), hx + 10, cy, hw - 20, "left")
    else
      lg.setColor(0.9, 0.95, 1.0)
      lg.printf(string.format("%s: $%d", b.name, b.balance), hx + 10, cy, hw - 20, "left")
      if b.betSide then
        local sideCol = (b.betSide == "ALPHA") and constants.COLOR_CYAN or constants.COLOR_MAGENTA
        local sideName = (b.betSide == "ALPHA") and "알파" or "베타"
        lg.setColor(sideCol[1], sideCol[2], sideCol[3])
        lg.printf(string.format("-> %s $%d", sideName, b.betAmount), hx + hw - 90, cy, 80, "right")
      else
        lg.setColor(0.5, 0.5, 0.5)
        lg.printf("[관망]", hx + hw - 60, cy, 50, "right")
      end
    end
    cy = cy + 15
  end

  -- 구분선
  cy = cy + 6
  lg.setColor(0.3, 0.6, 0.8, 0.5)
  lg.line(hx + 10, cy, hx + hw - 10, cy)

  -- ── 관전자(유저) 지갑 및 배팅 현황 ──────────────────────────────────
  cy = cy + 6
  lg.setFont(fontRegular)
  lg.setColor(0.3, 1.0, 0.5)
  lg.printf(string.format("내 지갑 잔고: $%d", market.userBalance), hx + 10, cy, hw - 20, "left")

  cy = cy + 17
  lg.setFont(fontSmall)
  if market.userBetSide then
    local sideCol = (market.userBetSide == "ALPHA") and constants.COLOR_CYAN or constants.COLOR_MAGENTA
    local name = (market.userBetSide == "ALPHA") and "알파" or "베타"
    lg.setColor(sideCol[1], sideCol[2], sideCol[3])
    lg.printf(string.format("★ 베팅 중: %s에 $%d (%.2f배)", name, market.userBetAmount, market.userBetOdds), hx + 10, cy,
      hw - 20, "left")
  else
    lg.setColor(0.6, 0.6, 0.6)
    lg.printf(string.format("베팅 대기 중 (1회 단위: $%d)", market.userUnit), hx + 10, cy, hw - 20, "left")
  end

  -- 구분선
  cy = cy + 24
  lg.setColor(0.3, 0.6, 0.8, 0.5)
  lg.line(hx + 10, cy, hx + hw - 10, cy)

  -- ── 조작 단축키 ──────────────────────────────────────────────────────
  cy = cy + 6
  lg.setFont(fontRegular)
  lg.setColor(0.4, 0.85, 1.0)
  lg.printf("도박 및 조작 단축키", hx + 10, cy, hw - 20, "left")

  cy = cy + 18
  lg.setFont(fontSmall)
  lg.setColor(0.8, 0.88, 0.95)
  lg.printf(string.format("[1] : 알파에 $%d 베팅", market.userUnit), hx + 10, cy, hw - 20, "left")
  lg.printf(string.format("[2] : 베타에 $%d 베팅", market.userUnit), hx + 10, cy + 14, hw - 20, "left")
  lg.setColor(constants.COLOR_GOLD[1], constants.COLOR_GOLD[2], constants.COLOR_GOLD[3])
  lg.printf("[A] : 전재산 올인 (ALL-IN)!", hx + 10, cy + 28, hw - 20, "left")
  lg.setColor(0.8, 0.88, 0.95)
  lg.printf(string.format("[C] : 베팅 단위 변경 ($%d)", market.userUnit), hx + 10, cy + 42, hw - 20, "left")
  lg.printf(string.format("[TAB] : 시뮬레이션 배속 (%dx)", game.timeScale), hx + 10, cy + 56, hw - 20, "left")
  lg.printf("[SPACE] : 일시정지  |  [R] : 리셋", hx + 10, cy + 70, hw - 20, "left")

  lg.setFont(fontRegular)
end

return Renderer
