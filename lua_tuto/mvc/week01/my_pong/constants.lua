-- constants.lua
-- 전역 설정, 아레나 규격, 도박 카지노 테마 및 물리 상수

local constants = {
  FIXED_DT = 1 / 60,
  TOTAL_W = 1000,
  TOTAL_H = 640,

  -- 경기장 (Arena) 규격
  ARENA_X = 10,
  ARENA_Y = 10,
  ARENA_W = 730,
  ARENA_H = 620,

  -- 우측 도박장 텔레메트리 HUD 패널 규격
  HUD_X = 750,
  HUD_Y = 10,
  HUD_W = 240,
  HUD_H = 620,

  -- 패들 기본 규격
  PADDLE_W = 14,
  PADDLE_H = 85,
  PADDLE_SPEED = 420, -- 기본 px/s

  -- [밸런스 특화] 수비형 알파 vs 공격형 베타
  DEF_PADDLE_H = 96,  -- 알파: 넓은 패들 (안정적 방어)
  DEF_SPEED    = 410, -- 알파: 안정적 이동
  DEF_ACCEL    = 1.05,-- 알파: 공 흡수/안정화 리턴

  ATK_PADDLE_H = 78,  -- 베타: 컴팩트한 패들 (모서리 스매시용)
  ATK_SPEED    = 470, -- 베타: 고속 돌진 스피드
  ATK_ACCEL    = 1.10,-- 베타: 날카롭고 강력한 스매시 가속!

  BALL_SIZE = 14,
  BALL_SPEED = 360,   -- 시작 속도 px/s

  WINNING_SCORE = 5,

  -- 트론 네온 & 카지노 팔레트 (RGB 0.0 ~ 1.0)
  COLOR_CYAN    = { 0.0, 0.95, 1.0 },       -- 알파 (철벽수비)
  COLOR_MAGENTA = { 1.0, 0.15, 0.7 },       -- 베타 (맹공격형)
  COLOR_YELLOW  = { 1.0, 0.95, 0.2 },       -- 공
  COLOR_GOLD    = { 1.0, 0.84, 0.0 },       -- 잭팟 / 대박
  COLOR_RED     = { 1.0, 0.2, 0.2 },        -- 파산 / 탕진
  COLOR_GREEN   = { 0.2, 1.0, 0.4 },        -- 수익
  COLOR_ORANGE  = { 1.0, 0.6, 0.1 },        -- 배당률
  COLOR_GRID    = { 0.04, 0.10, 0.18, 0.45 },
  COLOR_BG      = { 0.02, 0.03, 0.05 },
  COLOR_PANEL   = { 0.04, 0.07, 0.12, 0.92 },
  COLOR_BORDER  = { 0.1, 0.4, 0.65, 0.8 },
}

return constants
