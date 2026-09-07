-- Lv.1 기초 찾기 (1-20)
do
-- 1. text = "I like apple pie."에서 apple의 포함 여부와 위치를 구한다.
local text = "I like apple pie."
local a = string.find(text, "apple")
if a then
    print("Found at 1 :", a)
else
    print("Not found")
end
-- 2. text = "A small game starts today."에서 game의 시작 위치를 구한다.
local text2 = "A small game starts today."
local b = string.find(text2, "game")
if b then
    print("Found at 2 :", b)
else
    print("Not found")
end
-- 3. text = "Lua lua LUA"에서 소문자 lua의 첫 위치를 구한다.
local text3 = "Lua lua LUA"
local c = string.find(text3, "lua")
if c then
    print("Found at 3 :", c)
else
    print("Not found")
end
-- 4. text = "hello world"에서 첫 공백 위치를 구한다.
local text4 = "hello world"
local d = string.find(text4, " ")
if d then
    print("Found at 4 :", d)
else
    print("Not found")
end
-- 5. text = "red,green,blue"에서 첫 콤마 위치를 구한다.
local text5 = "red,green,blue"
local e = string.find(text5, ',')
if e then
    print("Found at 5 :", e)
else
    print("Not found")
end
-- 6. text = "banana"에서 a가 마지막으로 나타나는 위치를 구한다.
local text6 = "banana"
local _, last_pos = string.find(text6, '.*a')
print("Found at 6 : ", last_pos)
-- 7. text = "ID: player-01"이 ID:로 시작하는지 확인한다.
local text7 = "ID: player-01"
if string.find(text7, "^ID:") then
    print("Found at 7 :    yes")
else
    print("Not found")
end
-- 8. text = "sprite/player.png"가 .png로 끝나는지 확인한다.
local text8 = "sprite/player.png"
print("Found at 8 :", string.match(text8, "%.png$"))
-- 9. text = "ERROR: file not found"에 error가 있는지 확인한다. 대소문자 구분 여부도 관찰한다.
local text9 = "ERROR: file not found"
local g = string.find(text9, "error")
print("Found at 9 대소문자 구분 :", g)
local g2 = string.find(text9:lower(), "error")
print("Found at 9 소문자 변환 :", g2)

-- 10. text = "Visit https://example.com now"에서 ://의 위치를 구한다.
local text10 = "Visit https://example.com now"
local a = string.find(text10, "://", 1, true)
print("Found at 10 :", a)
-- 11. text = "ha ha ha"에서 두 번째 ha의 위치를 구한다.
local text11 = "ha ha ha"
local _, a = string.find(text11, "ha")
local b = string.find(text11, "ha", a + 1)
print("Found at 11 :", b)
-- 12. text = "ab--ab--ab"에서 세 번째 ab의 위치를 구한다.
local text12 = "ab--ab--ab"
local a = 1
local s, e
for i = 1, 3 do
    s, e = string.find(text12, "ab", a, true)
    if not s then break end
    a = e + 1
end
if s then
    print("Found at 12 :", s)
else
    print("Not found")
end

-- 13. text = "12345 cat 678"에서 6번째 문자 이후의 cat 위치를 구한다.
local text13 = "12345 cat 678"
local a = string.find(text13, "cat", 6)
if a then
    print("Found at 13 :", a)
else
    print("Not found")
end
-- 14. text = "This is a simple island."에서 is가 나타나는 모든 위치를 구한다.
local text14 = "This is a simple island."
local a = 1
local b = {}
while true do
    local s, e = string.find(text14, "is", a, true)
    if not s then break end
    table.insert(b, s)
    a = e + 1
end
print("Found at 14 :", table.concat(b, ", "))

-- 15. text = "name [player] score"에서 첫 [와 ]의 위치를 구한다.
local text15 = "name [player] score"
local a = string.find(text15, "[", 1, true)
local b = string.find(text15, "]", a, true)
if a then
    print("Found at 15 :", a, b)
else
    print("Not found")
end
-- 16. text = "player level 42"에 숫자가 있는지 확인한다.
local text16 = "player level 42"
print("Found at 16 :", string.match(text16, "%d+"))
-- 17. text = "123456"에 숫자가 아닌 문자가 있는지 확인한다.
local text17 = "123456"
if string.match(text17, "%D+") then
    print("Found at 17 :yes")
else
    print("Found at 17 :no")
end
-- 18. text = "level Up"에서 첫 대문자 위치를 구한다.
local text18 = "level Up"
local pos18 = string.find(text18, "%u")
print("Found at 18 :", pos18)

-- 19. text = "1234abcDEF"에서 5번째 문자 이후 첫 소문자 위치를 구한다.
local text19 = "1234abcDEF"
local pos19 = string.find(text19, "%l", 5)
print("Found at 19 :", pos19)

-- 20. text = "price = 9.99"에서 점(.) 문자의 위치를 구한다.
local text20 = "price = 9.99"
local pos20 = string.find(text20, "%.")
print("Found at 20 :", pos20)
end

-- Lv.2 find 패턴 확장 (21-35)
do
-- 21. text = "cat scatter catapult cat"에서 독립 단어 cat의 위치만 찾는다.
local text21 = "cat scatter catapult cat"
local res21 = {}
local cur21 = 1
while true do
    local s, e = string.find(text21, "cat", cur21, true)
    if not s then break end
    local before_ok = (s == 1) or not string.match(string.sub(text21, s - 1, s - 1), "%w")
    local after_ok = (e == #text21) or not string.match(string.sub(text21, e + 1, e + 1), "%w")
    if before_ok and after_ok then
        table.insert(res21, s)
    end
    cur21 = e + 1
end
print("Found at 21 :", table.concat(res21, ", "))

-- 22. text = "one  two   three"에서 2칸 이상 연속된 공백의 위치를 구한다.
local text22 = "one  two   three"
local s22, e22 = string.find(text22, "%s%s+")
print("Found at 22 :", s22, e22)

-- 23. text = "Servers: 10.0.0.1 and 192.168.1.20"에서 첫 IPv4 형태의 위치를 구한다.
local text23 = "Servers: 10.0.0.1 and 192.168.1.20"
local s23, e23 = string.find(text23, "%d+%.%d+%.%d+%.%d+")
print("Found at 23 :", s23, e23)

-- 24. text = "Events: 2026-09-05 and 2026-12-25"에서 첫 날짜의 위치를 구한다.
local text24 = "Events: 2026-09-05 and 2026-12-25"
local s24, e24 = string.find(text24, "%d%d%d%d%-%d%d%-%d%d")
print("Found at 24 :", s24, e24)

-- 25. text = [[say "hello world" then "bye"]]에서 첫 큰따옴표 문자열의 범위를 구한다.
local text25 = [[say "hello world" then "bye"]]
local s25, e25 = string.find(text25, '".-"')
print("Found at 25 :", s25, e25)

-- 26. text = "<div>content</div> <span>text</span>"에서 첫 태그 구간의 범위를 구한다.
local text26 = "<div>content</div> <span>text</span>"
local s26, e26 = string.find(text26, "<([%w]+)>.-</%1>")
print("Found at 26 :", s26, e26)

-- 27. text = "draw(player, 10, 20)"에서 함수 호출 이름 draw의 위치를 구한다.
local text27 = "draw(player, 10, 20)"
local s27, e27 = string.find(text27, "draw%s*%(")
local fn_s27, fn_e27 = string.find(text27, "draw", s27, true)
print("Found at 27 :", fn_s27, fn_e27)

-- 28. text = "flags: 0xFF and 0x10"에서 첫 16진수 토큰의 위치를 구한다.
local text28 = "flags: 0xFF and 0x10"
local s28, e28 = string.find(text28, "0x%x+")
print("Found at 28 :", s28, e28)

-- 29. text = "local hp = 100 -- player health"에서 주석 시작 위치를 구한다.
local text29 = "local hp = 100 -- player health"
local s29 = string.find(text29, "--", 1, true)
print("Found at 29 :", s29)

-- 30. text = "move(10, 20) then wait()"에서 첫 괄호 블록의 범위를 구한다.
local text30 = "move(10, 20) then wait()"
local s30, e30 = string.find(text30, "%b()")
print("Found at 30 :", s30, e30)

-- 31. text = "Contact dev@example.com for help"에서 이메일의 위치를 구한다.
local text31 = "Contact dev@example.com for help"
local s31, e31 = string.find(text31, "[%w%.%_%-]+@[%w%.%_%-]+")
print("Found at 31 :", s31, e31)

-- 32. text = "Values: 3.14, 10.0, 7"에서 첫 소수의 위치를 구한다.
local text32 = "Values: 3.14, 10.0, 7"
local s32, e32 = string.find(text32, "%d+%.%d+")
print("Found at 32 :", s32, e32)

-- 33. text = "name\tvalue"에서 첫 탭 또는 공백의 위치를 구한다.
local text33 = "name\tvalue"
local s33 = string.find(text33, "%s")
print("Found at 33 :", s33)

-- 34. text = "HP=120 MP=35"에서 첫 숫자 덩어리의 범위를 구한다.
local text34 = "HP=120 MP=35"
local s34, e34 = string.find(text34, "%d+")
print("Found at 34 :", s34, e34)

-- 35. text = "Load /assets/images/player.png now"에서 첫 경로의 범위를 구한다.
local text35 = "Load /assets/images/player.png now"
local s35, e35 = string.find(text35, "/[%w%._/]+")
print("Found at 35 :", s35, e35)
end

-- Lv.3 match 기초 추출 (36-50)
do
-- 36. text = "There are 24 enemies."에서 첫 숫자를 추출한다.
local text36 = "There are 24 enemies."
print("Found at 36 :", string.match(text36, "%d+"))

-- 37. text = "Email: knight@example.com"에서 @ 앞 사용자명을 추출한다.
local text37 = "Email: knight@example.com"
print("Found at 37 :", string.match(text37, "([%w%.%_%-]+)@"))

-- 38. text = "Email: knight@example.com"에서 @ 뒤 도메인을 추출한다.
local text38 = "Email: knight@example.com"
print("Found at 38 :", string.match(text38, "@([%w%.%_%-]+)"))

-- 39. text = "Save file: player.stats.json"에서 확장자를 추출한다.
local text39 = "Save file: player.stats.json"
print("Found at 39 :", string.match(text39, "%.([%w]+)$"))

-- 40. text = "https://game.example.com/start"에서 프로토콜을 추출한다.
local text40 = "https://game.example.com/start"
print("Found at 40 :", string.match(text40, "^(%a+)://"))

-- 41. text = "Release date: 2026/09/05"에서 연, 월, 일을 각각 추출한다.
local text41 = "Release date: 2026/09/05"
local y41, m41, d41 = string.match(text41, "(%d%d%d%d)/(%d%d)/(%d%d)")
print("Found at 41 :", y41, m41, d41)

-- 42. text = "Start at 08:35 sharp"에서 시와 분을 각각 추출한다.
local text42 = "Start at 08:35 sharp"
local h42, min42 = string.match(text42, "(%d%d):(%d%d)")
print("Found at 42 :", h42, min42)

-- 43. text = "name=kim"에서 key와 value를 추출한다.
local text43 = "name=kim"
local k43, v43 = string.match(text43, "([%w_]+)=([%w_]+)")
print("Found at 43 :", "key=" .. k43, "value=" .. v43)

-- 44. text = "Hello brave player"에서 첫 단어를 추출한다.
local text44 = "Hello brave player"
print("Found at 44 :", string.match(text44, "^%s*(%a+)"))

-- 45. text = "The final score"에서 마지막 단어를 추출한다.
local text45 = "The final score"
print("Found at 45 :", string.match(text45, "(%a+)%s*$"))

-- 46. text = "color = rgb(12,34,56)"에서 R, G, B 값을 추출한다.
local text46 = "color = rgb(12,34,56)"
local r46, g46, b46 = string.match(text46, "rgb%((%d+),%s*(%d+),%s*(%d+)%)")
print("Found at 46 :", r46, g46, b46)

-- 47. text = "position: x=10,y=20"에서 x 값과 y 값을 추출한다.
local text47 = "position: x=10,y=20"
local x47, y47 = string.match(text47, "x=(%d+),%s*y=(%d+)")
print("Found at 47 :", "x=" .. x47, "y=" .. y47)

-- 48. text = "Changes: +42 -7 0"에서 첫 정수의 부호와 숫자를 분리한다.
local text48 = "Changes: +42 -7 0"
local sign48, num48 = string.match(text48, "([%+%-]?)(%d+)")
print("Found at 48 :", "sign=" .. (sign48 ~= "" and sign48 or "none"), "num=" .. num48)

-- 49. text = "price=12.50"에서 정수부와 소수부를 분리한다.
local text49 = "price=12.50"
local int49, frac49 = string.match(text49, "(%d+)%.(%d+)")
print("Found at 49 :", "int=" .. int49, "frac=" .. frac49)

-- 50. text = "bookkeeper"에서 처음 연속 중복되는 문자를 찾는다.
local text50 = "bookkeeper"
local dup50 = string.match(text50, "(.)%1")
print("Found at 50 :", dup50)
end

-- Lv.4 match 중급 파싱 (51-65)
do
-- 51. text = "player_01"이 식별자 규칙에 맞는지 전체 검증한다. "1player"도 시험한다.
local text51 = "player_01"
local is_id51_1 = string.match(text51, "^[%a_][%w_]*$") ~= nil
local is_id51_2 = string.match("1player", "^[%a_][%w_]*$") ~= nil
print("Found at 51 :", text51 .. " -> " .. tostring(is_id51_1), "1player -> " .. tostring(is_id51_2))

-- 52. text = "score = 1234"에서 변수명과 값을 추출한다.
local text52 = "score = 1234"
local var52, val52 = string.match(text52, "^%s*([%a_][%w_]*)%s*=%s*(%d+)%s*$")
print("Found at 52 :", var52, val52)

-- 53. text = "local hp = 100"에서 변수명과 숫자값을 추출한다.
local text53 = "local hp = 100"
local var53, val53 = string.match(text53, "local%s+([%a_][%w_]*)%s*=%s*(%d+)")
print("Found at 53 :", var53, val53)

-- 54. text = "move(player, 10, 20)"에서 함수명과 인자 문자열을 추출한다.
local text54 = "move(player, 10, 20)"
local fn54, args54 = string.match(text54, "([%a_][%w_]*)%s*%((.-)%)")
print("Found at 54 :", fn54, "[" .. args54 .. "]")

-- 55. text = "user:'tom'"에서 key와 따옴표 안 value를 추출한다.
local text55 = "user:'tom'"
local k55, v55 = string.match(text55, "([%w_]+):'([^']*)'")
print("Found at 55 :", k55, v55)

-- 56. text = "[INFO] init done"에서 로그 레벨과 메시지를 추출한다.
local text56 = "[INFO] init done"
local lvl56, msg56 = string.match(text56, "^%[([%u]+)%]%s*(.*)$")
print("Found at 56 :", lvl56, msg56)

-- 57. text = "[2026-09-05 10:30:15] hello"에서 날짜, 시간, 메시지를 추출한다.
local text57 = "[2026-09-05 10:30:15] hello"
local date57, time57, msg57 = string.match(text57, "^%[(%d%d%d%d%-%d%d%-%d%d)%s+(%d%d:%d%d:%d%d)%]%s*(.*)$")
print("Found at 57 :", date57, time57, msg57)

-- 58. text = "version v1.2.3"에서 major, minor, patch를 추출한다.
local text58 = "version v1.2.3"
local maj58, min58, pat58 = string.match(text58, "v(%d+)%.(%d+)%.(%d+)")
print("Found at 58 :", maj58, min58, pat58)

-- 59. text = "accent color: #FFA07A"에서 RR, GG, BB를 추출한다.
local text59 = "accent color: #FFA07A"
local r59, g59, b59 = string.match(text59, "#(%x%x)(%x%x)(%x%x)")
print("Found at 59 :", r59, g59, b59)

-- 60. text = "report.final.txt"에서 확장자를 제외한 베이스 이름을 추출한다.
local text60 = "report.final.txt"
local base60 = string.match(text60, "^(.*)%.[%w_]+$")
print("Found at 60 :", base60)

-- 61. text = "### Intro to Lua"에서 샵 개수와 제목을 추출한다.
local text61 = "### Intro to Lua"
local hashes61, title61 = string.match(text61, "^(#+)%s+(.*)$")
print("Found at 61 :", #hashes61, title61)

-- 62. text = "  key_name : some value  "에서 key와 value를 공백을 제외하고 추출한다.
local text62 = "  key_name : some value  "
local k62, v62 = string.match(text62, "^%s*([%w_]+)%s*:%s*(.-)%s*$")
print("Found at 62 :", k62, v62)

-- 63. text = "updated 2026-09-05T14:30"에서 날짜와 시간을 추출한다.
local text63 = "updated 2026-09-05T14:30"
local d63, t63 = string.match(text63, "(%d%d%d%d%-%d%d%-%d%d)T(%d%d:%d%d)")
print("Found at 63 :", d63, t63)

-- 64. text = "function foo_bar123(a, b)"에서 함수명을 추출한다.
local text64 = "function foo_bar123(a, b)"
local fn64 = string.match(text64, "function%s+([%a_][%w_]*)")
print("Found at 64 :", fn64)

-- 65. text = "game.core.player"에서 마지막 모듈 세그먼트를 추출한다.
local text65 = "game.core.player"
local seg65 = string.match(text65, "([%a_][%w_]*)$")
print("Found at 65 :", seg65)
end

-- Lv.5 gmatch 기초 순회 (66-80)
do
-- 66. text = "Hello, brave Lua player!"의 모든 단어를 순회한다.
local text66 = "Hello, brave Lua player!"
local words66 = {}
for w in string.gmatch(text66, "%a+") do
    table.insert(words66, w)
end
print("Found at 66 :", table.concat(words66, ", "))

-- 67. text = "One two three four five"의 단어 개수를 센다.
local text67 = "One two three four five"
local cnt67 = 0
for _ in string.gmatch(text67, "%S+") do
    cnt67 = cnt67 + 1
end
print("Found at 67 :", cnt67)

-- 68. text = "Player 12 found 3 keys and 100 coins"의 모든 숫자를 추출한다.
local text68 = "Player 12 found 3 keys and 100 coins"
local nums68 = {}
for n in string.gmatch(text68, "%d+") do
    table.insert(nums68, n)
end
print("Found at 68 :", table.concat(nums68, ", "))

-- 69. text = "sword,shield,potion,bow"의 모든 CSV 셀을 순회한다.
local text69 = "sword,shield,potion,bow"
local cells69 = {}
for c in string.gmatch(text69, "([^,]+)") do
    table.insert(cells69, c)
end
print("Found at 69 :", table.concat(cells69, ", "))

-- 70. text = "New #lua #game_dev release"의 모든 해시태그를 추출한다.
local text70 = "New #lua #game_dev release"
local tags70 = {}
for tag in string.gmatch(text70, "#([%w_]+)") do
    table.insert(tags70, tag)
end
print("Found at 70 :", table.concat(tags70, ", "))

-- 71. text = "Thanks @alice and @bob for testing"의 모든 멘션을 추출한다.
local text71 = "Thanks @alice and @bob for testing"
local mentions71 = {}
for m in string.gmatch(text71, "@([%w_]+)") do
    table.insert(mentions71, m)
end
print("Found at 71 :", table.concat(mentions71, ", "))

-- 72. text = "assets/images/player/avatar.png"를 슬래시 기준으로 토큰화한다.
local text72 = "assets/images/player/avatar.png"
local tokens72 = {}
for t in string.gmatch(text72, "[^/]+") do
    table.insert(tokens72, t)
end
print("Found at 72 :", table.concat(tokens72, ", "))

-- 73. text = "first line\nsecond line\nthird line"의 각 줄을 순회한다.
local text73 = "first line\nsecond line\nthird line"
local lines73 = {}
for line in string.gmatch(text73, "[^\r\n]+") do
    table.insert(lines73, line)
end
print("Found at 73 :", table.concat(lines73, " | "))

-- 74. text = "user=kim&level=15&mode=hard"의 모든 key,value 쌍을 추출한다.
local text74 = "user=kim&level=15&mode=hard"
local pairs74 = {}
for k, v in string.gmatch(text74, "([^&=]+)=([^&]*)") do
    table.insert(pairs74, k .. "=" .. v)
end
print("Found at 74 :", table.concat(pairs74, ", "))

-- 75. text = "A 7 B 42 C 105 D 99"에서 두 자리 숫자 토큰만 추출한다.
local text75 = "A 7 B 42 C 105 D 99"
local two_digits75 = {}
for token in string.gmatch(text75, "%S+") do
    if string.match(token, "^%d%d$") then
        table.insert(two_digits75, token)
    end
end
print("Found at 75 :", table.concat(two_digits75, ", "))

-- 76. text = "x:10,y:20,z:30"의 좌표를 테이블로 만든다.
local text76 = "x:10,y:20,z:30"
local coords76 = {}
for k, v in string.gmatch(text76, "([%a_]):(%d+)") do
    coords76[k] = tonumber(v)
end
print("Found at 76 :", "x=" .. tostring(coords76.x), "y=" .. tostring(coords76.y), "z=" .. tostring(coords76.z))

-- 77. text = "Lua lua GAME game game"의 단어 빈도를 대소문자 무시 기준으로 집계한다.
local text77 = "Lua lua GAME game game"
local freq77 = {}
for w in string.gmatch(text77, "%a+") do
    local lower = string.lower(w)
    freq77[lower] = (freq77[lower] or 0) + 1
end
local res77 = {}
for k, v in pairs(freq77) do
    table.insert(res77, k .. ":" .. v)
end
print("Found at 77 :", table.concat(res77, ", "))

-- 78. text = "<div>Hello</div><p>World</p><img>"의 태그 이름을 순회한다.
local text78 = "<div>Hello</div><p>World</p><img>"
local tags78 = {}
for tag in string.gmatch(text78, "<%/?([%a%d]+)") do
    table.insert(tags78, tag)
end
print("Found at 78 :", table.concat(tags78, ", "))

-- 79. text = [[print("hello") say("world again")]]의 큰따옴표 문자열을 추출한다.
local text79 = [[print("hello") say("world again")]]
local strs79 = {}
for s in string.gmatch(text79, '"(.-)"') do
    table.insert(strs79, s)
end
print("Found at 79 :", table.concat(strs79, ", "))

-- 80. text = "Builds: 2026-01-01, 2026-05-30, 2026-09-05"의 모든 날짜를 추출한다.
local text80 = "Builds: 2026-01-01, 2026-05-30, 2026-09-05"
local dates80 = {}
for d in string.gmatch(text80, "%d%d%d%d%-%d%d%-%d%d") do
    table.insert(dates80, d)
end
print("Found at 80 :", table.concat(dates80, ", "))
end

-- Lv.6 gmatch 고급 파싱 (81-90)
do
-- 81. text = "local player_1 = enemy2 + 10"에서 Lua 식별자 토큰을 추출한다.
local text81 = "local player_1 = enemy2 + 10"
local idents81 = {}
for id in string.gmatch(text81, "[%a_][%w_]*") do
    table.insert(idents81, id)
end
print("Found at 81 :", table.concat(idents81, ", "))

-- 82. text = "draw(player) move(enemy, 2) wait()"에서 함수 호출 이름을 추출한다.
local text82 = "draw(player) move(enemy, 2) wait()"
local fns82 = {}
for fn in string.gmatch(text82, "([%a_][%w_]*)%s*%(") do
    table.insert(fns82, fn)
end
print("Found at 82 :", table.concat(fns82, ", "))

-- 83. text = "scores = [1, 2, 3, 4]"에서 정수를 배열로 만든다.
local text83 = "scores = [1, 2, 3, 4]"
local arr83 = {}
for n in string.gmatch(text83, "%d+") do
    table.insert(arr83, tonumber(n))
end
print("Found at 83 :", table.concat(arr83, ", "))

-- 84. text = "delta=-3.5 speed=10.0 bonus=+2"에서 부호가 있는 숫자 토큰을 추출한다.
local text84 = "delta=-3.5 speed=10.0 bonus=+2"
local signed84 = {}
for s in string.gmatch(text84, "[%+%-]?%d+%.?%d*") do
    table.insert(signed84, s)
end
print("Found at 84 :", table.concat(signed84, ", "))

-- 85. text = "TODO: add sound\nFIXME: reset state\nTODO: tune balance"에서 TODO 항목을 추출한다.
local text85 = "TODO: add sound\nFIXME: reset state\nTODO: tune balance"
local todos85 = {}
for todo in string.gmatch(text85, "TODO:%s*([^\r\n]+)") do
    table.insert(todos85, todo)
end
print("Found at 85 :", table.concat(todos85, " | "))

-- 86. text = [[id="p01" name="Blue Knight" class="warrior"]]에서 모든 속성 key,value를 추출한다.
local text86 = [[id="p01" name="Blue Knight" class="warrior"]]
local attrs86 = {}
for k, v in string.gmatch(text86, '([%w_]+)="(.-)"') do
    table.insert(attrs86, k .. '="' .. v .. '"')
end
print("Found at 86 :", table.concat(attrs86, ", "))

-- 87. text = "[INFO] start\n[ERROR] fail\n[WARN] retry\n[ERROR] timeout"에서 레벨별 줄 수를 집계한다.
local text87 = "[INFO] start\n[ERROR] fail\n[WARN] retry\n[ERROR] timeout"
local counts87 = {}
for lvl in string.gmatch(text87, "%[([%u]+)%]") do
    counts87[lvl] = (counts87[lvl] or 0) + 1
end
local res87 = {}
for k, v in pairs(counts87) do
    table.insert(res87, k .. ":" .. v)
end
print("Found at 87 :", table.concat(res87, ", "))

-- 88. text = "draw(player, move(enemy, 10)) wait()"에서 괄호 블록을 순회 추출한다.
local text88 = "draw(player, move(enemy, 10)) wait()"
local blocks88 = {}
local cur88 = 1
while true do
    local s, e = string.find(text88, "%b()", cur88)
    if not s then break end
    table.insert(blocks88, string.sub(text88, s, e))
    cur88 = e + 1
end
print("Found at 88 :", table.concat(blocks88, ", "))

-- 89. text = "player.attack enemy.move ui.show"에서 모듈명.함수명 토큰을 추출한다.
local text89 = "player.attack enemy.move ui.show"
local calls89 = {}
for mod, fn in string.gmatch(text89, "([%a_][%w_]*)%.([%a_][%w_]*)") do
    table.insert(calls89, mod .. "." .. fn)
end
print("Found at 89 :", table.concat(calls89, ", "))

-- 90. text = "the quick brown brown fox and the the dog"에서 중복 단어와 위치를 찾는다.
local text90 = "the quick brown brown fox and the the dog"
local dups90 = {}
local cur90 = 1
while true do
    local s, e, w = string.find(text90, "([%a_]+)%s+%1", cur90)
    if not s then break end
    table.insert(dups90, string.format("%s(at %d)", w, s))
    cur90 = e + 1
end
print("Found at 90 :", table.concat(dups90, ", "))
end

-- Lv.7 종합/어려움 (91-100)
do
-- 91. text = "banana bandana"에서 겹치는 ana의 모든 위치를 찾는다.
local text91 = "banana bandana"
local pos91 = {}
local cur91 = 1
while true do
    local s, e = string.find(text91, "ana", cur91, true)
    if not s then break end
    table.insert(pos91, s)
    cur91 = s + 1
end
print("Found at 91 :", table.concat(pos91, ", "))

-- 92. text = "# Title\nintro\n## Chapter 1\ntext\n### Details"에서 제목 라인의 위치와 제목을 추출한다.
local text92 = "# Title\nintro\n## Chapter 1\ntext\n### Details"
local titles92 = {}
local line_idx92 = 0
for line in string.gmatch(text92, "[^\r\n]+") do
    line_idx92 = line_idx92 + 1
    local hashes, title = string.match(line, "^(#+)%s+(.*)$")
    if hashes then
        table.insert(titles92, string.format("line %d: %s", line_idx92, title))
    end
end
print("Found at 92 :", table.concat(titles92, " | "))

-- 93. text = "[graphics]\nwidth=1280\nheight=720\n\n[audio]\nvolume=80"를 INI 구조로 파싱한다.
local text93 = "[graphics]\nwidth=1280\nheight=720\n\n[audio]\nvolume=80"
local ini93 = {}
local current_sec93 = nil
for line in string.gmatch(text93, "[^\r\n]+") do
    local sec = string.match(line, "^%[(.+)%]$")
    if sec then
        current_sec93 = sec
        ini93[current_sec93] = ini93[current_sec93] or {}
    else
        local k, v = string.match(line, "^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if k and current_sec93 then
            ini93[current_sec93][k] = v
        end
    end
end
print("Found at 93 :", "graphics.width=" .. tostring(ini93.graphics.width),
    "audio.volume=" .. tostring(ini93.audio.volume))

-- 94. text = [[load "player one" --verbose 2]]를 따옴표 안 공백을 보존하는 토큰 배열로 만든다.
local text94 = [[load "player one" --verbose 2]]
local tokens94 = {}
local cur94 = 1
while cur94 <= #text94 do
    local s, e = string.find(text94, "^%s+", cur94)
    if s then
        cur94 = e + 1
    else
        local qs, qe, quoted = string.find(text94, '^"([^"]*)"', cur94)
        if qs then
            table.insert(tokens94, quoted)
            cur94 = qe + 1
        else
            local ws, we, word = string.find(text94, "^(%S+)", cur94)
            if ws then
                table.insert(tokens94, word)
                cur94 = we + 1
            else
                break
            end
        end
    end
end
print("Found at 94 :", table.concat(tokens94, ", "))

-- 95. text = "Hello {{name}}, you scored {{score}} points."에서 플레이스홀더 이름과 위치를 추출한다.
local text95 = "Hello {{name}}, you scored {{score}} points."
local holders95 = {}
local cur95 = 1
while true do
    local s, e, name = string.find(text95, "{{(.-)}}", cur95)
    if not s then break end
    table.insert(holders95, string.format("%s(at %d)", name, s))
    cur95 = e + 1
end
print("Found at 95 :", table.concat(holders95, ", "))

-- 96. text = [[127.0.0.1 - frank [05/Sep/2026:10:30:15 +0900] "GET /index.html HTTP/1.1" 200 1234]]를 필드별로 파싱한다.
local text96 = [[127.0.0.1 - frank [05/Sep/2026:10:30:15 +0900] "GET /index.html HTTP/1.1" 200 1234]]
local ip96, user96, time96, req96, status96, bytes96 = string.match(
    text96,
    '^(%S+)%s+%S+%s+(%S+)%s+%[(.-)%]%s+"(.-)"%s+(%d+)%s+(%d+)$'
)
print("Found at 96 :", "ip=" .. ip96, "user=" .. user96, "req=" .. req96, "status=" .. status96)

-- 97. text = [[10.0.0.2 - - [05/Sep/2026:10:31:00 +0900] "GET /missing HTTP/1.1" 404 512 "-" "Mozilla/5.0"]]에서 - 필드도 보존한다.
local text97 = [[10.0.0.2 - - [05/Sep/2026:10:31:00 +0900] "GET /missing HTTP/1.1" 404 512 "-" "Mozilla/5.0"]]
local ip97, ident97, auth97, time97, req97, status97, size97, ref97, agent97 = string.match(
    text97,
    '^(%S+)%s+(%S+)%s+(%S+)%s+%[(.-)%]%s+"(.-)"%s+(%S+)%s+(%S+)%s+"(.-)"%s+"(.-)"$'
)
print("Found at 97 :", "ip=" .. ip97, "ident=" .. ident97, "auth=" .. auth97, "status=" .. status97, "ref=" .. ref97)

-- 98. text = "Read [Lua guide](https://lua.org) and [API docs](https://lua.org/manual)"에서 링크를 모두 추출한다.
local text98 = "Read [Lua guide](https://lua.org) and [API docs](https://lua.org/manual)"
local links98 = {}
for label, url in string.gmatch(text98, "%[([^%]]+)%]%(([^%)]+)%)") do
    table.insert(links98, label .. " -> " .. url)
end
print("Found at 98 :", table.concat(links98, ", "))

-- 99. text = "[2026-09-05 10:00] [INFO] core: started\n[2026-09-05 10:01] [WARN] net: slow\n[2026-09-05 10:02] [ERROR] save: failed"에서 분류, 타임스탬프, 모듈, 메시지, 카운트를 추출한다.
local text99 =
"[2026-09-05 10:00] [INFO] core: started\n[2026-09-05 10:01] [WARN] net: slow\n[2026-09-05 10:02] [ERROR] save: failed"
local count99 = 0
local logs99 = {}
for line in string.gmatch(text99, "[^\r\n]+") do
    local ts, lvl, mod, msg = string.match(line, "^%[(.-)%]%s+%[(.-)%]%s+([%w_]+):%s*(.*)$")
    if ts then
        count99 = count99 + 1
        table.insert(logs99, string.format("[%s][%s] %s -> %s", ts, lvl, mod, msg))
    end
end
print("Found at 99 : total=" .. count99, table.concat(logs99, " | "))

-- 100. text = [[local hp = 100 -- initial\nmove(player, 10)\nname = "Knight Mage"\nif hp > 0 then attack() end]]를 식별자, 숫자, 문자열, 연산자, 주석 토큰으로 분류하고 첫 오류 위치를 보고한다.
local text100 = [[local hp = 100 -- initial\nmove(player, 10)\nname = "Knight Mage"\nif hp > 0 then attack() end]]

-- 리터럴 \n 문자열을 실제 개행문자로 변환 (둘 다 대응)
local src100 = string.gsub(text100, "\\n", "\n")

local tokens100 = {
    ident = {},
    number = {},
    string = {},
    comment = {},
    operator = {}
}

local cur100 = 1
local len100 = #src100
local err_pos100 = nil

while cur100 <= len100 do
    -- 1. 공백 및 줄바꿈 건너뛰기
    local _, ws_e = string.find(src100, "^%s+", cur100)
    if ws_e then
        cur100 = ws_e + 1
    else
        -- 힌트: "문자열 리터럴과 주석을 먼저 인식해야 내부 기호를 잘못 해석하지 않는다."
        local cs, ce, comment = string.find(src100, "^%-%-([^\r\n]*)", cur100)
        local ss, se, str_val = string.find(src100, '^"([^"]*)"', cur100)
        local ns, ne, num_val = string.find(src100, "^%d+%.?%d*", cur100)
        local is, ie, id_val  = string.find(src100, "^[%a_][%w_]*", cur100)
        -- 연산자 및 구분 기호 (==, <=, >=, ~= 등 2문자 연산자 우선 매칭)
        local os, oe, op_val  = string.find(src100, "^([~=<>]=)", cur100)
        if not os then
            os, oe, op_val = string.find(src100, "^([%+%-%*%/%=><~%(%),])", cur100)
        end

        if cs then
            table.insert(tokens100.comment, comment)
            cur100 = ce + 1
        elseif ss then
            table.insert(tokens100.string, str_val)
            cur100 = se + 1
        elseif ns then
            table.insert(tokens100.number, num_val)
            cur100 = ne + 1
        elseif is then
            table.insert(tokens100.ident, id_val)
            cur100 = ie + 1
        elseif os then
            table.insert(tokens100.operator, op_val)
            cur100 = oe + 1
        else
            err_pos100 = cur100
            break
        end
    end
end

print("Found at 100 :")
print("  - 식별자(ident)   :", table.concat(tokens100.ident, ", "))
print("  - 숫자(number)    :", table.concat(tokens100.number, ", "))
print("  - 문자열(string)  :", table.concat(tokens100.string, ", "))
print("  - 주석(comment)   :", table.concat(tokens100.comment, ", "))
print("  - 연산자(operator):", table.concat(tokens100.operator, " "))
if err_pos100 then
    print("  - 첫 오류 위치    : " .. err_pos100 .. " (문자: '" .. string.sub(src100, err_pos100, err_pos100) .. "')")
else
    print("  - 첫 오류 위치    : 없음 (모든 토큰 파싱 성공)")
end
end
-- 실행용 기본 틀
-- local text = "여기에 문제의 text를 넣으세요"

-- 문제에 따라 find, match, gmatch 중 하나를 선택하세요.
-- 결과를 print하거나 테이블에 저장해 확인하세요.
