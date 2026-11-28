# MVC 겔러그 기말 프로젝트 (`2023391007_김관현_기말`)

> 현재 상태: R1(`HelpScene`) + R2(`WaveParser` · `waves.txt`) + R3(적 3종 · `EnemyFactory`) + R4(적 AI 4상태 `EnemyAI`) + R5(업적 3종 · `AchievementModel` + `EffectsView` 배너/연출) + R6(하이스코어 `HighScoreModel`) + 패럴랙스 우주·트윈 사행 유도탄·Graze/Overdrive/파워업(`WeaponDecorator`)·보스 광폭화/레이저 구현 및 전체 테스트 통과 (R7 번짐 실측만 남음)

## 1. 출발 코드
- **선택 B (공개 완성본)**: `lua_tuto/mvc/week05/examples/galaga_states`
- 본 프로젝트에서는 출발 코드를 기반으로 R1(`HelpScene`, `HelpView`)을 추가했습니다.
- `week05/examples/tests/equivalence_test.lua`는 `week04` 경로를 참조하므로 제외했습니다.

## 2. 디렉터리 구조
```text
2023391007_김관현_기말/
  README.md
  run.bat / run.sh
  project/
    src/      ← main.lua, conf.lua, waves.txt, models/, views/, controllers/, scenes/
    tests/    ← helper.lua, layer_check.lua, phase_test.lua, scene_test.lua, wave_parser_test.lua, enemy_factory_test.lua, enemy_ai_test.lua, achievement_test.lua, highscore_test.lua, homing_test.lua, powerup_graze_test.lua, boss_enrage_test.lua
  docs/       ← waves_format.md, report_게임시스템설계.md, report_게임인공지능.md (git_log.txt 추후 추가)
  worklogs/   ← 001~007 세션별 로그 (최종 회고 추후 추가)
```

## 3. 테스트 및 정적 검사 실행
헤드리스 테스트 및 계층 검사는 현재 환경에 설치된 **`lua`** 로 실행합니다 (`luajit` 대신 `lua` 사용). 기본 대상이 `src`이므로 인자 없이 실행하거나 VS Code task **`Lua: Run current file`**로도 바로 실행할 수 있습니다.

```sh
cd project/tests
lua layer_check.lua src
lua phase_test.lua src
lua scene_test.lua src
lua wave_parser_test.lua src
lua enemy_factory_test.lua src
lua enemy_ai_test.lua src
lua achievement_test.lua src
lua highscore_test.lua src
lua homing_test.lua src
lua powerup_graze_test.lua src
lua boss_enrage_test.lua src
```

## 4. 게임 실행 방법
LÖVE 11.5 환경에서 `run.bat`(Windows) 또는 `run.sh`(macOS/Linux)로 실행하거나, `project/src`를 직접 지정합니다.

```sh
# Windows (2023391007_김관현_기말 폴더에서)
run.bat

# macOS / Linux (2023391007_김관현_기말 폴더에서)
sh run.sh

# 또는 직접 실행
love project/src
```

*(Windows 저장소 루트에서 직접 실행 시: `.\love-11.5-win64\lovec.exe 2023391007_김관현_기말\project\src`)*

## 5. 조작법
- **타이틀 화면**: `Enter` / `Space` 시작, `H` 도움말, `Esc` 종료
- **도움말 화면**: `H` / `Esc` / `Enter` 타이틀로 복귀
- **플레이 화면**: `←` / `→` (`A` / `D`) 이동, `Space` 발사, `X` 유도 미사일, `P` / `Esc` 일시정지
- **일시정지 화면**: `P` / `Esc` 재개, `Q` 타이틀로 이동
- **결과 화면**: `R` 재도전, `Enter` 타이틀로 이동
