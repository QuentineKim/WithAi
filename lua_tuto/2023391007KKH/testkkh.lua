-- 02-1 타입 확인
-- 아래 각 값의 type()을 예측한 뒤 실행해서 확인하라.
print(type(42))    -- number
print(type(42.0))  -- number
print(type("42"))  -- string
print(type(nil))   -- nil
print(type(true))  -- boolean
print(type(print)) -- function
print(type({}))    -- table
print(type(type))  -- function

-- 02-2 전역 오염 찾기
-- 아래 코드에서 의도치 않은 전역 변수를 찾아 local로 수정하라.
function createBullet(x, y)
    local speed = 500
    local dx = 0
    local dy = -1
    local bullet = { x = x, y = y, speed = speed, dx = dx, dy = dy }
    return bullet
end

bullet = createBullet(100, 200)
print(bullet.x, bullet.y, bullet.speed, bullet.dx, bullet.dy)

-- 02-3 다중할당
-- a,b,c에 a, b, c에 10, 20, 30을 다중 할당하고, a와 c의 값을 temp 변수 없이 교환하라.
a, b, c = 10, 20, 30
print(a, b, c)
a, c = c, a
print(a, b, c)

-- 02-4 진위 판별
-- 아래 각 조건이 "참"인지 "거짓"인지 예측하라
if 0 then print("A") end       -- true
if "" then print("B") end      -- true
if nil then print("C") end     -- false
if false then print("D") end   -- false
if 0.0 then print("E") end     -- true
if "false" then print("F") end -- true

-- 03-1 swhitch 대체
-- 아래 C# 코드를 Lua 테이블 디스패치로 변환하라.
-- switch (enemyType) {
--     case "slime": speed = 50; break;
--     case "bat": speed = 150; break;
--     case "boss": speed = 30; break;
--     default: speed = 100; break;
-- }
local speedMap = {
    slime = 50,
    bat = 150,
    boss = 30,
}
local enemyType = "slime"
local speed = speedMap[enemyType] or 100
print(speed)

-- 03-2 continue 대체
-- 1부터 20까지의 숫자 중, 3의 배수만 출력하는 코드를 작성하라. (Lua 5.1에는 continue가 없음을 기억하라)
for i = 1, 20 do
    if i % 3 == 0 then
        print(i)
    end
end

-- 03-3 and/or 함정
-- 아래 코드의 출력을 예측하라. 왜 그런 결과가 나오는지 설명하라.

local a = true and false or "fallback"
local b = true and 0 or "fallback"
local c = nil and "yes" or "no"
print(a, b, c)
-- 출력: fallback 0 no
-- 이유: and/or는 논리 연산자일 뿐 단축 평가를 지원한다.

-- 03-4 숫자 for 차이
--C의 for (int i = 0; i < 10; i++)를 Lua로 변환하라. 시작값과 끝값에 주의할 것.
for i = 0, 9 do
    print(i)
end

-- 04-1  string.format 활용
-- 게임 로그 메시지를 format으로 구성하라.
-- 출력: "[Wave 03] Enemy spawned at (12.50, -8.30) — HP: 100"
local wave = 3
local x, y = 12.5, -8.3
local hp = 100
-- 여기에 string.format 작성
local msg = string.format("[Wave %d] Enemy spawned at (%.2f, %.2f) — HP: %d", wave, x, y, hp)
print(msg)

-- 04-2 패턴 매칭
-- 아래 문자열에서 모든 색상 코드(#RRGGBB 형식)를 추출하라.

local text = "Background: #FF0000, Text: #00FF00, Border: #0000FF"
-- 힌트: %x는 16진수 문자
for color in string.gmatch(text, "#%x%x%x%x%x%x") do
    print(color)
end

-- 04-3 효율적 문자열 연결
-- 1부터 100까지의 숫자를 "1, 2, 3, ..., 100" 형태로 결합하라. table.concat을 사용하여 효율적으로 작성하라.

local tbl = {}
for i = 1, 100 do
    table.insert(tbl, i)
end
local result = table.concat(tbl, ", ")
print(result)

-- 04-4 파싱
-- "Player[Lv.15] HP:80/100" 문자열에서 이름, 레벨, 현재HP, 최대HP를 추출하라.

local text = "Player[Lv.15] HP:80/100"
local name, level, curHp, maxHp = string.match(text, "(%a+)%[Lv%.(%d+)%] HP:(%d+)/(%d+)")
print(name, level, curHp, maxHp)

-- 05-1 다중반환
-- 플레이어 위치와 방향을 반환하는 함수를 작성하라.

--  getPlayerInfo() → x, y, angle
--  호출 예: local x, y, angle = getPlayerInfo()
local function getPlayerInfo()
    local x = 100
    local y = 200
    local angle = 90
    return x, y, angle
end
local x, y, angle = getPlayerInfo()
print(x, y, angle)

-- 05-2 고차 함수
-- 숫자 테이블과 함수를 받아, 각 요소에 함수를 적용한 새 테이블을 반환하는 map 함수를 작성하라.

--local numbers = { 1, 2, 3, 4, 5 }
--local doubled = map(numbers, function(x) return x * 2 end)
---- doubled = {2, 4, 6, 8, 10}

local function map(numbers, func)
    local result = {}
    for _, num in ipairs(numbers) do
        table.insert(result, func(num))
    end
    return result
end

local numbers = { 1, 2, 3, 4, 5 }
local doubled = map(numbers, function(x) return x * 2 end)
print(table.concat(doubled, ", "))

-- 05-3 클로저 활용
-- makeHealthBar(maxHp)를 호출하면 damage(amount), heal(amount), getPercent() 메서드를 가진 테이블을 반환하는 함수를 작성하라. HP는 0 미만 또는 maxHp 초과가 되지 않아야 한다.

local function makeHealthBar(maxHp)
    local hp = maxHp
    return {
        damage = function(amount)
            hp = hp - amount
            if hp < 0 then hp = 0 end
        end,
        heal = function(amount)
            hp = hp + amount
            if hp > maxHp then hp = maxHp end
        end,
        getPercent = function()
            return hp / maxHp * 100
        end
    }
end

local bar = makeHealthBar(100)
bar.damage(30)
bar.heal(20)
print(bar.getPercent()) -- 90

-- 05-4 콜론 문법
-- 아래 코드의 버그를 찾아 수정하라
local enemy = { hp = 100, name = "Goblin" }

function enemy:takeDamage(amount)
    self.hp = self.hp - amount
    if self.hp <= 0 then
        print(self.name .. " is dead!")
    end
end

enemy:takeDamage(30) -- 여기서 에러 발생. 왜?
print(enemy.hp)      -- 70

-- 06-1 인벤토리 시스템
-- 문자열 배열로 인벤토리를 만들고, 아래 기능을 구현하라:
-- addItem(inventory, item): 끝에 아이템 추가
-- removeItem(inventory, index): 특정 위치 아이템 제거
-- findItem(inventory, item): 아이템 이름으로 인덱스 검색 (없으면 nil)
-- printInventory(inventory): 전체 목록 출력

local function addItem(inventory, item)
    table.insert(inventory, item)
end
local function removeItem(inventory, index)
    table.remove(inventory, index)
end
local function findItem(inventory, item)
    for i, v in ipairs(inventory) do
        if v == item then
            return i
        end
    end
    return nil
end
local function printInventory(inventory)
    for i, v in ipairs(inventory) do
        print(i, v)
    end
end

local inventory = {}
addItem(inventory, "사과")
addItem(inventory, "바나나")
addItem(inventory, "체리")
printInventory(inventory)
removeItem(inventory, 2)
printInventory(inventory)
print(findItem(inventory, "바나나"))

-- 06-2 점수 테이블 정렬
-- 플레이어 이름과 점수 쌍의 배열을 만들고 점수 내림차순으로 정렬하라
local leaderboard = {
    { name = "앨리스", score = 100 },
    { name = "밥", score = 200 },
    { name = "찰리", score = 300 },
}
table.sort(leaderboard, function(a, b) return a.score > b.score end)
for i, v in ipairs(leaderboard) do
    print(i, v.name, v.score)
end

-- 06-3 함정이해
-- 아래 코드의 출력을 예측하고, 왜 그런 결과가 나오는지 설명하라.

local a = { 1, 2, 3 }
local b = { 1, nil, 3 }
local c = { x = 1, y = 2, z = 3 }
print(#a, #b, #c)
-- 3 1 0
-- 이유: #은 배열의 길이를 반환하는데, b는 nil이 있어 배열이 끊어지고 c는 해시 테이블이라서 길이를 반환하지 않는다.

-- 06-4 Swap-Remove 구현
-- swapRemove(t, i) 함수를 구현하고, 100개 요소 배열에서 50번 인덱스를 제거하는 데 table.remove와 swapRemove의 동작 차이를 설명하라.

local function swapRemove(t, i)
    t[i] = t[#t]
    table.remove(t)
end
local t = {}
for i = 1, 100 do
    t[i] = "item" .. i
end
print("테이블 전체 크기", #t)
swapRemove(t, 50)
print("제거 후 50번 위치값", t[50])
print("테이블 전체 크기", #t)
--table.remove(t, 50)
print("테이블 전체 크기", #t)
print("제거 후 50번 위치값", t[50])
