-- 문자열 처리 연습문제 (병합본)
-- 현재 브랜치의 간단 예제와 incoming 브랜치의 큰 연습문제를 함께 유지한다.

-- 현재 브랜치: compact examples
-- 1. `text = Lua is fun`에서 `fun`이 들어 있는지 확인하고, 시작 위치와 끝 위치를 출력하세요.
local text1 = "Lua is fun"
local s1, e1 = string.find(text1, "fun")
if s1 then
    print(string.format("발견됨 (시작: %d, 끝: %d)", s1, e1))
else
    print("발견되지 않음")
end

-- 2. `text = player.png`가 `.png`로 끝나는지 확인하세요.
local text2 = "player.png"
local ends_with_png = string.find(text2, "%.png$") ~= nil
print(ends_with_png and ".png로 끝남" or ".png로 끝나지 않음")

-- 3. `text = score = 3500`에서 숫자 `3500`만 추출하세요.
local text3 = "score = 3500"
local score = string.match(text3, "%d+")
print("추출된 숫자 =", score)

-- 4. `text = Email: hero@example.com`에서 사용자명 `hero`와 도메인 `example.com`을 각각 추출하세요.
local text4 = "Email: hero@example.com"
local user, domain = string.match(text4, "([%w_]+)@([%w%.]+)")
print(string.format("사용자명 = %s, 도메인 = %s", user, domain))

-- 5. `text = red,green,blue,yellow`에서 모든 색 이름을 하나씩 출력하세요.
local text5 = "red,green,blue,yellow"
for color in string.gmatch(text5, "[^,]+") do
    print("색상:", color)
end

-- 6. `text = x=10 y=25 z=7`에서 모든 좌표 이름과 값을 추출해 `x 10`, `y 25`, `z 7` 형태로 출력하세요.
local text6 = "x=10 y=25 z=7"
for axis, val in string.gmatch(text6, "(%a+)=(%d+)") do
    print(string.format("  %s %s", axis, val))
end

-- 7. `text = [WARN] low hp`에서 로그 레벨 `WARN`과 메시지 `low hp`를 분리해 추출하세요.
local text7 = "[WARN] low hp"
local level, msg = string.match(text7, "%[(%a+)%]%s*(.+)")
print(string.format("레벨 = [%s], 메시지 = %s", level, msg))

-- 8. `text = items: sword(2), potion(10), key(1)`에서 아이템 이름과 개수를 모두 추출하세요.
local text8 = "items: sword(2), potion(10), key(1)"
for item, count in string.gmatch(text8, "(%a+)%((%d+)%)") do
    print(string.format("  아이템: %s, 개수: %s", item, count))
end

-- 9. `text = path/to/player_idle_01.png`에서 파일명 `player_idle_01`과 확장자 `png`를 분리해 추출하세요.
local text9 = "path/to/player_idle_01.png"
local filename, ext = string.match(text9, "([^/\\]+)%.(%w+)$")
print(string.format("파일명 = %s, 확장자 = %s", filename, ext))

-- 10. `text = [[move(player, 10) wait() attack(enemy_boss)]]`에서 함수 호출 이름 `move`, `wait`, `attack`을 모두 추출하세요. 단, 괄호 안 인자는 출력하지 않습니다.
local text10 = [[move(player, 10) wait() attack(enemy_boss)]]
for fn_name in string.gmatch(text10, "([%a_][%w_]*)%s*%(") do
    print("  함수 이름:", fn_name)
end

-- incoming branch: larger tutorial
-- Lv.1 기초 찾기 (1-20)
do
local text = "I like apple pie."
local a = string.find(text, "apple")
if a then
    print("Found at 1 :", a)
else
    print("Not found")
end

local text2 = "A small game starts today."
local b = string.find(text2, "game")
if b then
    print("Found at 2 :", b)
else
    print("Not found")
end

local text3 = "Lua lua LUA"
local c = string.find(text3, "lua")
if c then
    print("Found at 3 :", c)
else
    print("Not found")
end

local text4 = "hello world"
local d = string.find(text4, " ")
if d then
    print("Found at 4 :", d)
else
    print("Not found")
end

local text5 = "red,green,blue"
local e = string.find(text5, ',')
if e then
    print("Found at 5 :", e)
else
    print("Not found")
end

local text6 = "banana"
local _, last_pos = string.find(text6, '.*a')
print("Found at 6 : ", last_pos)

local text7 = "ID: player-01"
if string.find(text7, "^ID:") then
    print("Found at 7 :    yes")
else
    print("Not found")
end

local text8 = "sprite/player.png"
print("Found at 8 :", string.match(text8, "%.png$"))

local text9 = "ERROR: file not found"
local g = string.find(text9, "error")
print("Found at 9 대소문자 구분 :", g)
local g2 = string.find(text9:lower(), "error")
print("Found at 9 소문자 변환 :", g2)

local text10 = "Visit https://example.com now"
local a10 = string.find(text10, "://", 1, true)
print("Found at 10 :", a10)

local text11 = "ha ha ha"
local _, a11 = string.find(text11, "ha")
local b11 = string.find(text11, "ha", a11 + 1)
print("Found at 11 :", b11)

local text12 = "ab--ab--ab"
local a12 = 1
local s12, e12
for i = 1, 3 do
    s12, e12 = string.find(text12, "ab", a12, true)
    if not s12 then break end
    a12 = e12 + 1
end
if s12 then
    print("Found at 12 :", s12)
else
    print("Not found")
end

local text13 = "12345 cat 678"
local a13 = string.find(text13, "cat", 6)
if a13 then
    print("Found at 13 :", a13)
else
    print("Not found")
end

local text14 = "This is a simple island."
local a14 = 1
local b14 = {}
while true do
    local s14, e14 = string.find(text14, "is", a14, true)
    if not s14 then break end
    table.insert(b14, s14)
    a14 = e14 + 1
end
print("Found at 14 :", table.concat(b14, ", "))

local text15 = "name [player] score"
local a15 = string.find(text15, "[", 1, true)
local b15 = string.find(text15, "]", a15, true)
if a15 then
    print("Found at 15 :", a15, b15)
else
    print("Not found")
end

local text16 = "player level 42"
print("Found at 16 :", string.match(text16, "%d+"))

local text17 = "123456"
if string.match(text17, "%D+") then
    print("Found at 17 :yes")
else
    print("Found at 17 :no")
end

local text18 = "level Up"
local pos18 = string.find(text18, "%u")
print("Found at 18 :", pos18)

local text19 = "1234abcDEF"
local pos19 = string.find(text19, "%l", 5)
print("Found at 19 :", pos19)

local text20 = "price = 9.99"
local pos20 = string.find(text20, "%.")
print("Found at 20 :", pos20)
end

-- Lv.2 find 패턴 확장 (21-35)
do
local text21 = "cat scatter catapult cat"
local res21 = {}
local cur21 = 1
while true do
    local s21, e21 = string.find(text21, "cat", cur21, true)
    if not s21 then break end
    local before_ok = (s21 == 1) or not string.match(string.sub(text21, s21 - 1, s21 - 1), "%w")
    local after_ok = (e21 == #text21) or not string.match(string.sub(text21, e21 + 1, e21 + 1), "%w")
    if before_ok and after_ok then
        table.insert(res21, s21)
    end
    cur21 = e21 + 1
end
print("Found at 21 :", table.concat(res21, ", "))

local text22 = "one  two   three"
local s22, e22 = string.find(text22, "%s%s+")
print("Found at 22 :", s22, e22)

local text23 = "Servers: 10.0.0.1 and 192.168.1.20"
local s23, e23 = string.find(text23, "%d+%.%d+%.%d+%.%d+")
print("Found at 23 :", s23, e23)

local text24 = "Events: 2026-09-05 and 2026-12-25"
local s24, e24 = string.find(text24, "%d%d%d%d%-%d%d%-%d%d")
print("Found at 24 :", s24, e24)

local text25 = [[say "hello world" then "bye"]]
local s25, e25 = string.find(text25, '".-"')
print("Found at 25 :", s25, e25)

local text26 = "<div>content</div> <span>text</span>"
local s26, e26 = string.find(text26, "<([%w]+)>.-</%1>")
print("Found at 26 :", s26, e26)

local text27 = "draw(player, 10, 20)"
local s27, e27 = string.find(text27, "draw%s*%(")
local fn_s27, fn_e27 = string.find(text27, "draw", s27, true)
print("Found at 27 :", fn_s27, fn_e27)

local text28 = "flags: 0xFF and 0x10"
local s28, e28 = string.find(text28, "0x%x+")
print("Found at 28 :", s28, e28)

local text29 = "local hp = 100 -- player health"
local s29 = string.find(text29, "--", 1, true)
print("Found at 29 :", s29)

local text30 = "move(10, 20) then wait()"
local s30, e30 = string.find(text30, "%b()")
print("Found at 30 :", s30, e30)

local text31 = "Contact dev@example.com for help"
local s31, e31 = string.find(text31, "[%w%.%_%-]+@[%w%.%_%-]+")
print("Found at 31 :", s31, e31)

local text32 = "Values: 3.14, 10.0, 7"
local s32, e32 = string.find(text32, "%d+%.%d+")
print("Found at 32 :", s32, e32)

local text33 = "name\tvalue"
local s33 = string.find(text33, "%s")
print("Found at 33 :", s33)

local text34 = "HP=120 MP=35"
local s34, e34 = string.find(text34, "%d+")
print("Found at 34 :", s34, e34)

local text35 = "Load /assets/images/player.png now"
local s35, e35 = string.find(text35, "/[%w%._/]+")
print("Found at 35 :", s35, e35)
end

-- 종료: both branches retained and kept in separate sections.

