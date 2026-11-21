-- dungeon_test.lua
-- 예제 6(던전 RPG) 헤드리스 테스트: Model 단위 → Model 간 이벤트 연동 → View 문자열 → Controller 라우팅.
-- 실행: lua lua_tuto/mvc/basics/tests/dungeon_test.lua   (luajit 도 가능)

local here = (arg and arg[0] or ""):match("(.*[/\\])") or "./"
local root = here .. "../06_dungeon/"
package.path = root .. "?.lua;" .. package.path

local initialGlobals = {}
for k in pairs(_G) do
  initialGlobals[k] = true
end

local EventBus = require("models.event_bus")
local QuestModel = require("models.quest_model")
local LogModel = require("models.log_model")
local KillListModel = require("models.kill_list_model")
local AchievementModel = require("models.achievement_model")
local InventoryModel = require("models.inventory_model")
local PlayerModel = require("models.player_model")
local GameModel = require("models.game_model")
local dungeonData = require("data.dungeon_data")

local ScreenView = require("views.screen_view")
local StatusView = require("views.status_view")
local EnemyView = require("views.enemy_view")
local KillListView = require("views.kill_list_view")
local LogView = require("views.log_view")

local InputRouter = require("controllers.input_router")
local ExploreController = require("controllers.explore_controller")
local BattleController = require("controllers.battle_controller")
local InventoryController = require("controllers.inventory_controller")
local ShopController = require("controllers.shop_controller")
local EndController = require("controllers.end_controller")

local passed, failed = 0, 0
local function check(name, cond)
  if cond then
    passed = passed + 1
    print("  ok   - " .. name)
  else
    failed = failed + 1
    print("  FAIL - " .. name)
  end
end

local function contains(lines, text)
  for _, line in ipairs(lines or {}) do
    if line:find(text, 1, true) then
      return true
    end
  end
  return false
end

-- 테스트용 작은 던전. 실제 데이터 파일과 독립적이라 기획 수치가 바뀌어도 테스트가 깨지지 않는다.
local function newGame(rooms, player)
  return GameModel.new({
    player = player or { name = "테스터", maxHp = 10, attack = 5 },
    inventoryCapacity = 2,
    logLimit = 3,
    rooms = rooms,
    quests = { { id = "kill", text = "1마리 처치", event = "enemy_killed", needed = 1 } },
  })
end

local WEAK = { kind = "enemy", enemy = { name = "쥐", hp = 5, attack = 1, gold = 2 } }
local TOUGH = { kind = "enemy", enemy = { name = "골렘", hp = 100, attack = 4, gold = 50 } }
local POTION = { kind = "item", item = { name = "물약", kind = "potion", power = 5 } }
local SWORD = { kind = "item", item = { name = "검", kind = "weapon", power = 3 } }
local EXIT = { kind = "exit" }

-- ── 0. 디커플링 ─────────────────────────────────────────────────────────────
print("[0] 디커플링: Model/Controller 에 print·io·love 없음")
local CHECKED_FILES = {
  "models/event_bus.lua", "models/player_model.lua", "models/enemy_model.lua",
  "models/inventory_model.lua", "models/dungeon_model.lua", "models/quest_model.lua",
  "models/log_model.lua", "models/kill_list_model.lua", "models/achievement_model.lua",
  "models/game_model.lua",
  "controllers/explore_controller.lua", "controllers/battle_controller.lua",
  "controllers/inventory_controller.lua", "controllers/shop_controller.lua",
  "controllers/end_controller.lua", "controllers/input_router.lua",
}
for _, path in ipairs(CHECKED_FILES) do
  local file = assert(io.open(root .. path, "r"), "파일 없음: " .. path)
  local clean = true
  for line in file:lines() do
    local code = line:gsub("%-%-.*$", "")
    if code:find("print%s*%(") or code:find("io%.") or code:find("love%.") then
      clean = false
    end
  end
  file:close()
  check(path, clean)
end

do
  local file = assert(io.open(root .. "models/achievement_model.lua", "r"))
  local content = file:read("*a")
  file:close()
  local hasForbiddenDep = content:find("GameModel", 1, true) or content:find("PlayerModel", 1, true)
      or content:find("game_model", 1, true) or content:find("player_model", 1, true)
  check("AchievementModel: GameModel·PlayerModel 의존 없음", not hasForbiddenDep)
end

do
  local leaked = {}
  for k in pairs(_G) do
    if not initialGlobals[k] then
      leaked[#leaked + 1] = tostring(k)
    end
  end
  check("전역 변수 오염 없음 (로드 시점)", #leaked == 0)
end

-- ── 1. 작은 Model 들 (단독) ─────────────────────────────────────────────────
print("[1] 작은 Model 단독 테스트")
do
  local bus = EventBus.new()
  local order = {}
  bus:on("ping", function()
    order[#order + 1] = "on"
  end)
  bus:onAny(function(t)
    order[#order + 1] = "any:" .. t
  end)
  bus:emit("ping")
  check("EventBus: onAny 가 먼저, 그다음 on", order[1] == "any:ping" and order[2] == "on")

  local quests = QuestModel.new(bus, { { id = "k", text = "2마리", event = "enemy_killed", needed = 2 } })
  local completed = 0
  bus:on("quest_completed", function()
    completed = completed + 1
  end)
  bus:emit("enemy_killed")
  bus:emit("enemy_killed")
  bus:emit("enemy_killed")
  check("QuestModel: GameModel 없이 이벤트만으로 진행", quests.quests[1].done and quests:countDone() == 1)
  check("QuestModel: 완료 이벤트는 한 번만", completed == 1)

  local log = LogModel.new(EventBus.new(), 2)
  log:push("a", {})
  log:push("b", {})
  log:push("c", {})
  check("LogModel: 최근 N개만 보관, 원본 type 저장", #log.entries == 2 and log.entries[1].type == "b")

  local inv = InventoryModel.new(1)
  check("InventoryModel: 용량 초과 거부", inv:add({ name = "x" }) and inv:add({ name = "y" }) == false)
  check("InventoryModel: 없는 번호 거부", inv:take(5) == nil and inv:take("1") == nil)

  local p = PlayerModel.new({ maxHp = 10, attack = 2 })
  p:takeDamage(4)
  check("PlayerModel: 회복은 최대치까지, 실제 회복량 반환", p:heal(100) == 4 and p.hp == 10)
  p:equip({ name = "검", power = 3 })
  check("PlayerModel: 장비 공격력 합산", p:getAttack() == 5)
end

-- ── 2. GameModel: 여러 Model 이 함께 움직이는 규칙 ──────────────────────────
print("[2] GameModel 통합 규칙")
do
  local g = newGame({ WEAK, EXIT })
  check("시작은 탐험 모드", g.mode == "explore")
  check("탐험 중 공격 불가", g:attack() == false)
  g:explore()
  check("적 방 → 전투 모드 + 적 생성", g.mode == "battle" and g.enemy and g.enemy.name == "쥐")
  check("전투 중 탐험 불가", g:explore() == false)
  g:attack()
  check("처치 → 탐험 복귀, 골드 획득", g.mode == "explore" and g.enemy == nil and g.player.gold == 2)
  check("처치 이벤트가 퀘스트로 전달", g.quests.quests[1].done == true)
  check("로그에 원본 이벤트 기록", g.log.entries[#g.log.entries].type == "quest_completed")
  g:explore()
  check("출구 → 승리", g.mode == "victory" and g:isOver())
end

do
  local g = newGame({ TOUGH })
  g:explore()
  g:attack()
  check("적이 살아 있으면 반격", g.player.hp == 6)
  g:attack()
  g:attack()
  check("체력 0 → 게임 오버", g.mode == "gameover" and g.player.hp == 0)
  check("게임 오버 후 행동 불가", g:attack() == false and g:openInventory() == false)
end

do
  local g = newGame({ TOUGH })
  g:explore()
  g:flee()
  check("도망: 한 대 맞고 탐험 복귀", g.player.hp == 6 and g.mode == "explore" and g.enemy == nil)
end

do
  local g = newGame({ POTION, SWORD, POTION, TOUGH })
  g:explore()
  g:explore()
  g:explore()
  check("가방이 차면 아이템을 두고 옴", #g.inventory.items == 2 and g.log.entries[#g.log.entries].type == "item_lost")
  g:explore()
  g:attack()
  check("전투 중 피해", g.player.hp == 6)
  g:openInventory()
  check("가방 열기 → inventory 모드, 복귀 모드 기억", g.mode == "inventory" and g.returnMode == "battle")
  check("없는 번호 사용 거부", g:useItem(9) == false and g.mode == "inventory")
  g:useItem(1)
  check("전투 중 물약: 회복 후 적의 턴", g.player.hp == 10 - 4 + 4 - 4 and g.mode == "battle")
  g:openInventory()
  g:useItem(1)
  check("검 장착", g.player:getAttack() == 8 and #g.inventory.items == 0)
end

-- ── 3. View: Model 을 읽어 문자열만 만든다 ──────────────────────────────────
print("[3] View")
do
  local g = newGame({ WEAK, EXIT })
  check("EnemyView: 적이 없으면 nil(숨김)", EnemyView.new():lines(g) == nil)
  g:explore()
  check("EnemyView: 전투 중 이름/HP 표시", contains(EnemyView.new():lines(g), "쥐  HP"))
  check("StatusView: 위치 표시", contains(StatusView.new():lines(g), "위치 1/2번 방"))
  check("LogView: 원본 이벤트 → 문장", contains(LogView.new():lines(g), "쥐 이(가) 나타났다!"))

  local hpBefore = g.player.hp
  StatusView.new():lines(g)
  check("View 는 Model 을 바꾸지 않음", g.player.hp == hpBefore and g.mode == "battle")

  local out = {}
  local screen = ScreenView.new(function(s)
    out[#out + 1] = s
  end, { status = StatusView.new(), enemy = EnemyView.new() }, {
    battle = { "status", "enemy" },
    default = { "status" },
  })
  screen:showNotice("알림")
  screen:render(g)
  check("ScreenView: 모드별 레이아웃으로 위젯 합성", contains(out, "-- 상태") and contains(out, "-- 적"))
  check("ScreenView: 알림 표시", contains(out, "! 알림"))
  out = {}
  screen:render(g)
  check("ScreenView: 알림은 한 번만", not contains(out, "! 알림"))
end

-- ── 4. Controller: 모드별 라우팅 ───────────────────────────────────────────
print("[4] Controller 라우팅")
do
  local notices, renders = {}, 0
  local fakeView = {
    showNotice = function(_, msg)
      notices[#notices + 1] = msg
    end,
    render = function()
      renders = renders + 1
    end,
  }
  local endController = EndController.new()
  local g = newGame({ WEAK, EXIT })
  local router = InputRouter.new(g, fakeView, {
    explore = ExploreController.new(),
    battle = BattleController.new(),
    inventory = InventoryController.new(),
    gameover = endController,
    victory = endController,
  })

  check("탐험 모드 a → ExploreController 가 거부", router:handle("a") and #notices == 1)
  router:handle(" n ")
  check("n → 전투 진입 (공백 무시)", g.mode == "battle")
  router:handle("i")
  check("전투 중 i → 가방", g.mode == "inventory")
  router:handle("zz")
  check("가방에서 숫자 아님 → 알림", notices[#notices]:find("번호", 1, true) ~= nil)
  router:handle("b")
  check("b → 전투로 복귀", g.mode == "battle")
  router:handle("a")
  router:handle("n")
  check("승리 모드 도달", g.mode == "victory")
  check("승리 후 아무 입력 → 종료", router:handle("x") == false)
  check("입력마다 render 호출", renders == 7)
  check("q 는 어느 모드에서나 종료", InputRouter.new(newGame({ EXIT }), fakeView, {}):handle("q") == false)
end

-- ── 5. MVC 퀴즈 확장 기능 ─────────────────────────────────────────────────
print("[5] MVC 퀴즈 확장 기능")
do
  local foundItemQuest = nil
  for _, q in ipairs(dungeonData.quests or {}) do
    if q.event == "item_used" and q.needed == 2 then
      foundItemQuest = q
    end
  end
  check("문제1: dungeon_data.lua 에 아이템 2번 사용 퀘스트 정의", foundItemQuest ~= nil)

  local g = GameModel.new(dungeonData)
  g:explore() -- 1번: 슬라임
  g:attack()
  g:attack()
  g:explore()  -- 2번: 회복 물약
  g:explore()  -- 3번: 고블린
  g:openInventory()
  g:useItem(1) -- 1번째 사용 (물약)
  g:attack()
  g:attack()
  g:attack()
  g:attack()
  g:explore()  -- 4번: 철검
  g:openInventory()
  g:useItem(1) -- 2번째 사용 (철검)
  local itemQuest = nil
  for _, q in ipairs(g.quests.quests) do
    if q.event == "item_used" then
      itemQuest = q
    end
  end
  check("문제1: 데이터 퀘스트 아이템 2번 사용 시 완료", itemQuest and itemQuest.done == true and itemQuest.progress == 2)
end

do
  local bus = EventBus.new()
  local kl = KillListModel.new(bus)
  check("문제2: 처치 전 KillListView 는 (없음) 표시", contains(KillListView.new():lines({ killList = kl }), "(없음)"))
  bus:emit("enemy_killed", { name = "슬라임", gold = 3 })
  bus:emit("enemy_killed", { name = "고블린", gold = 5 })
  check("문제2: KillListModel 단독 이벤트 기록", kl:count() == 2 and kl.kills[1] == "슬라임" and kl.kills[2] == "고블린")
  local viewLines = KillListView.new():lines({ killList = kl })
  check("문제2: KillListView 처치 목록 및 총 마릿수 표시", contains(viewLines, "슬라임, 고블린") and contains(viewLines, "총 2마리"))

  local g = newGame({ WEAK, EXIT })
  g:explore()
  g:attack()
  check("문제2: GameModel 전투 처치 후 KillListView 반영", contains(KillListView.new():lines(g), "쥐"))
end

do
  local bus = EventBus.new()
  local unlockedEvents = {}
  bus:on("achievement_unlocked", function(d)
    unlockedEvents[#unlockedEvents + 1] = d
  end)
  local ach = AchievementModel.new(bus, 15)
  bus:emit("enemy_killed", { name = "슬라임", gold = 10 })
  bus:emit("enemy_killed", { name = "박쥐", gold = 4 })
  check("문제3: 누적 골드 14 에서는 업적 미발행", not ach.unlocked and #unlockedEvents == 0)
  bus:emit("enemy_killed", { name = "쥐", gold = 1 })
  check("문제3: 누적 골드 15 도달 시 업적 1회 발행", ach.unlocked and #unlockedEvents == 1)
  bus:emit("enemy_killed", { name = "드래곤", gold = 20 })
  check("문제3: 추가 처치 시 중복 발행 안 됨", #unlockedEvents == 1)

  local g = GameModel.new({
    player = { name = "테스터", maxHp = 30, attack = 10 },
    inventoryCapacity = 2,
    logLimit = 5,
    goldAchievementGoal = 15,
    rooms = {
      { kind = "enemy", enemy = { name = "오크A", hp = 10, attack = 1, gold = 8 } },
      { kind = "enemy", enemy = { name = "오크B", hp = 10, attack = 1, gold = 7 } },
      EXIT,
    },
    quests = {},
  })
  g:explore()
  g:attack()
  g:explore()
  g:attack()
  local logLines = LogView.new():lines(g)
  check("문제3: GameModel 처치 골드 15 달성 시 로그 업적 표시", contains(logLines, "업적 달성"))
end

do
  local rooms = dungeonData.rooms
  check("문제4: dungeon_data.lua 출구 직전 방이 shop", rooms[#rooms].kind == "exit" and rooms[#rooms - 1].kind == "shop")

  local SHOP_DEFAULT = { kind = "shop" }
  local gPoor = newGame({ SHOP_DEFAULT, EXIT })
  gPoor:explore()
  check("문제4: 상점 방 진입 시 shop 모드 전환", gPoor.mode == "shop")
  local okPoor, errPoor = gPoor:buyPotion()
  check("문제4: 골드 부족 시 구매 실패 및 이유 반환", not okPoor and errPoor and errPoor:find("골드", 1, true) ~= nil)
  check("문제4: 골드 부족 실패 시 가방 변화 없음", #gPoor.inventory.items == 0 and gPoor.player.gold == 0)

  local STRONG_GOLD = { kind = "enemy", enemy = { name = "황금쥐", hp = 5, attack = 1, gold = 12 } }
  local g = newGame({ STRONG_GOLD, SHOP_DEFAULT, EXIT })
  g:explore()
  g:attack()  -- gold = 12
  g:explore() -- shop 진입
  local okBuy = g:buyPotion()
  check("문제4: 물약 구매 성공 (골드 5 차감, 가방 추가)", okBuy and g.player.gold == 7 and #g.inventory.items == 1)
  local okBuy2 = g:buyPotion()
  check("문제4: 2번째 물약 구매 성공 (가방 2/2)", okBuy2 and g.player.gold == 2 and #g.inventory.items == 2)
  g.player:addGold(10) -- gold = 12
  local okFull, errFull = g:buyPotion()
  check("문제4: 가방 가득 시 구매 실패 및 이유 반환", not okFull and errFull and errFull:find("가방", 1, true) ~= nil)
  check("문제4: 가방 가득 실패 시 골드 미차감", g.player.gold == 12)

  local notices = {}
  local fakeView = {
    showNotice = function(_, msg)
      notices[#notices + 1] = msg
    end,
    render = function() end,
  }
  local endCtrl = EndController.new()
  local gCtrl = newGame({ STRONG_GOLD, SHOP_DEFAULT, EXIT })
  local router = InputRouter.new(gCtrl, fakeView, {
    explore = ExploreController.new(),
    battle = BattleController.new(),
    inventory = InventoryController.new(),
    shop = ShopController.new(),
    gameover = endCtrl,
    victory = endCtrl,
  })
  router:handle("n")
  router:handle("a")
  router:handle("n")
  check("문제4: 라우터로 상점 진입", gCtrl.mode == "shop")
  router:handle("x")
  check("문제4: 상점 잘못된 입력 시 안내 메시지", #notices > 0 and notices[#notices]:find("b / l", 1, true) ~= nil)
  router:handle("b")
  check("문제4: ShopController b 입력으로 물약 구매", gCtrl.player.gold == 7 and #gCtrl.inventory.items == 1)
  router:handle("l")
  check("문제4: ShopController l 입력으로 탐험 복귀", gCtrl.mode == "explore")
  router:handle("n")
  check("문제4: 상점 나간 뒤 다음 방 출구 승리", gCtrl.mode == "victory")
end

do
  local leaked = {}
  for k in pairs(_G) do
    if not initialGlobals[k] then
      leaked[#leaked + 1] = tostring(k)
    end
  end
  check("전역 변수 오염 없음 (실행 종료 시점)", #leaked == 0)
end

print(string.format("\n결과: %d 통과, %d 실패", passed, failed))
if failed > 0 then
  os.exit(1)
end
