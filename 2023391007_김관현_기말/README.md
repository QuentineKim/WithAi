# MVC 겔러그 기말 프로젝트 (`2023391007_김관현_기말`)

> 현재 상태: R1(도움말 씬 `HelpScene` 추가) 구현 및 테스트 통과 (R2~R7 미구현)

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
    src/      ← main.lua, conf.lua, models/, views/, controllers/, scenes/
    tests/    ← helper.lua, layer_check.lua, phase_test.lua, scene_test.lua
  docs/       ← report_게임시스템설계.md, report_게임인공지능.md (waves_format.md·git_log.txt 추후 추가)
  worklogs/   ← 001_2026-11-21_baseline_r1.md (세션별 로그 및 최종 회고)
```

## 3. 테스트 및 정적 검사 실행
헤드리스 테스트 및 계층 검사는 현재 환경에 설치된 **Lua 5.1.5 (`lua`)** 로 실행합니다 (`luajit` 대신 `lua` 사용). 기본 대상이 `src`이므로 인자 없이 실행하거나 VS Code task **`Lua: Run current file`**로도 바로 실행할 수 있습니다.

```sh
cd project/tests
lua layer_check.lua src
lua phase_test.lua src
lua scene_test.lua src
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
