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
