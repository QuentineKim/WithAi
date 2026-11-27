# 기말과제 진행 현황 및 남은 TODO (`2023391007_김관현_기말`)

> 기준일: `2026-11-27` (마감: `2026-12-05(토) 23:59 KST`)
> 현재 상태: **R1 ~ R4 완료 (11/28 중간 점검선 달성)** — 남은 핵심 작업: **R5 · R6 · R7 · 로그 필수 3항목 보강 · 보고서 마감 · 제출**

---

## 1. 완료된 항목 (1~4회차)

| 회차 | 요건 | 커밋 | 작업 로그 | 테스트 현황 |
|---|---|---|---|---|
| 1회차 | 기준선 + **R1** (`HelpScene` 추가 및 리뷰 보완) | `4dd0049`, `89018b4` | `001`, `002` | `scene_test.lua` 19/19 |
| 2회차 | **R2** (`docs/waves_format.md`, `waves.txt`, `WaveParser`) | `2eb0aef` | `003` | `wave_parser_test.lua` 10/10 |
| 3회차 | **R3** (적 3종 `Basic`/`Scout`/`Tank` 상속 + `EnemyFactory`) | `5b31ea1` | `004` | `enemy_factory_test.lua` 6/6 |
| 4회차 | **R4** (적 AI 4상태 `enter`→`formation`→`dive`→`return`, `rng` 결정성) | `8699286` | `005` | `enemy_ai_test.lua` 6/6 |

- 공통 검사 통과: `layer_check.lua` (34개 파일, 위반 0건), `phase_test.lua` (9/9), `luac -l -p` (전역 쓰기 0건).

---

## 2. 남은 필수 기능 (5~7회차)

### [ ] 5회차 — R5: 업적 3개 이상 (이벤트 구독 + View 알림)
- **목표**: `AchievementModel`이 `GameModel:drainEvents()` 이벤트만 구독해 업적 3개 이상 판정 (`GameModel`은 업적을 전혀 모름).
- **추천 업적 3종**:
  1. `streak_10`: 피격 없이 적 10기 연속 격추 (`enemy_destroyed` 카운트, `player_hit` 시 리셋)
  2. `flawless_wave`: 무피격으로 편대 1회 클리어 (`formation_cleared` 시 해당 웨이브 중 `player_hit` 0회)
  3. `boss_slayer`: 보스 첫 처치 (`boss_destroyed`)
- **구현 파일**: `models/AchievementModel.lua`, `views/EffectsView.lua`(또는 `HudView.lua` 달성 배너/알림), `scenes/PlayScene.lua`(이벤트 전달 연결), `tests/achievement_test.lua`(TDD, 최소 3~4건).
- **문서**: `report_게임인공지능.md` 3-3 패턴표에 **Observer(이벤트 구독)** 행 추가, `worklogs/006_YYYY-MM-DD_r5_achievements.md` 작성 후 커밋 1개.

### [ ] 6회차 — R6: 하이스코어 저장 / 불러오기
- **목표**: Model은 순수 문자열 직렬화/역직렬화만 담당(`io`/`love` 금지), 파일 I/O는 `main.lua`에서만 수행(`love.filesystem.read`/`write`). 깨진 파일·빈 파일이면 기본값으로 안전 복구.
- **구현 파일**: `models/HighScoreModel.lua`(`serialize`/`deserialize`, `pcall` 또는 안전한 파싱으로 손상 입력 방어), `main.lua`(로드/저장 콜백을 `ctx`로 주입), `scenes/PlayScene.lua`·`ResultScene.lua`·`views/ResultView.lua`(최고 기록 갱신·표시), `tests/highscore_test.lua`(TDD, 정상 + 깨진 문자열/빈 파일 복구 등 3건 이상).
- **문서**: `report_게임시스템설계.md` Q3(깨진 하이스코어 문자열 처리 흐름) 작성, `worklogs/007_YYYY-MM-DD_r6_highscore.md` 작성 후 커밋 1개.

### [ ] 7회차 — R7: 번짐 실측 (새 적 1종 추가)
- **절차 (순서 엄수)**:
  1. R1~R6 완료 커밋 직후 태그 생성: `git tag before-r7`
  2. 새 적 종류 1종 추가 (예: `SniperEnemy` 또는 `BomberEnemy` — `models/` + `EnemyFactory` 등록 + `waves.txt` + `EnemyView` 색상 + 테스트) 후 **커밋**
  3. 계층별 hunk 수 실측:
     ```bash
     for d in models views controllers scenes; do
       printf "%-12s %s\n" "$d" "$(git diff -U0 before-r7 HEAD -- 2023391007_김관현_기말/project/src/$d | grep -c '^@@')"
     done
     git diff --stat before-r7 HEAD -- 2023391007_김관현_기말/project/
     ```
  4. `report_게임인공지능.md` **Q3** 및 **3-5 번짐 실측** 표 + 3~5줄 해석 작성
  5. `worklogs/008_YYYY-MM-DD_r7_spread_measure.md` 작성 후 커밋 1개

---

## 3. AI 협업 로그(`worklogs/`) 필수 요건 체크리스트

> 공통 명세 4절 기준 (미달 시 로그 점수 상한 5점)

- [x] 세션 로그 5개 이상 (`001` ~ `005` 작성 완료, R5~R7 추가 시 8개)
- [x] 서로 다른 날짜 3일 이상 (`2026-11-21`, `2026-11-26`, `2026-11-27` — 3일 달성)
- [x] 프롬프트 기록 10개 이상 (현재 10개+, R5~R7에서 추가)
- [x] 거절 또는 수정 사례 3개 이상 (`002` R1 리뷰 수정, `003` `math.huge` 수정, `004` `takeDamage` 충돌 수정, `005` `_aiCtx` GC 수정)
- [ ] **"AI가 틀렸고 내가 잡았다" 정식 양식 2건 정리**
  - [ ] 게임시스템설계(Lua 함정) 1건 (예: `WaveParser.lua`의 `math.huge` 통과 버그 또는 R6 역직렬화 함정)
  - [ ] 게임인공지능(구조·패턴 문제) 1건 (예: `GameModel`의 `takeDamage` 보스 규칙 충돌 또는 `layer_check` 경계 위반 사례)
- [ ] **경계 위반 거절 1건 이상** — `layer_check` 출력 **원문** + 거절 이유 + 고친 프롬프트 (R5 또는 R6 세션에서 기록 확보 권장)
- [ ] **명세 기반 프롬프트 1건** — README·계약 문서(`docs/waves_format.md` 등)·테스트 첨부 기록 명시
- [ ] **최종 회고 작성**: `worklogs/999_retrospective.md` (공통 명세 4-3 양식 준수)

---

## 4. 보고서 2종 및 최종 제출 체크리스트

### 과목별 보고서
- [ ] `docs/report_게임시스템설계.md`
  - [x] 3-1 출처 표 (R1~R4 반영, R5~R7 추가 예정)
  - [x] 3-2 Lua 문법 매핑표 (12행 작성 완료, R5~R6 보완)
  - [x] 3-3 Q1 (`__index` 탐색 경로), Q2 (`WaveParser` / `gmatch` 한계)
  - [ ] 3-3 Q3 (R6 깨진 하이스코어 문자열 처리 흐름)
  - [ ] 3-4 알려진 문제와 한계 최종 정리
- [ ] `docs/report_게임인공지능.md`
  - [x] 3-1 출처 표, 3-2 적 AI 상태 설계표, 3-3 패턴표(State/Factory/DI + 과잉 패턴 회피), 3-4 Q1·Q2
  - [ ] 3-3 패턴표에 R5 Observer 행 추가
  - [ ] 3-4 Q3 + 3-5 번짐 실측 표 및 해석 (R7 완료 후)
  - [ ] 3-6 알려진 문제와 한계 최종 정리

### 최종 마감 직전 (12/03 ~ 12/05)
- [ ] LÖVE 11.5 창으로 직접 실행해 전체 플레이 흐름(타이틀 → 도움말 → 1~3웨이브 → 적 돌격/복귀 → 업적 알림 → 보스전 → 결과 → 하이스코어 저장/재실행 복원) 시각 확인
- [ ] 전체 테스트 + `layer_check.lua` + `luac -l -p` 전역 쓰기 0건 최종 재실행
- [ ] `git log --stat --date=iso > 2023391007_김관현_기말/docs/git_log.txt` 생성 (로그 커밋 해시와 일치 대조)
- [ ] 로그·문서에 개인정보/API 키 누락·노출 여부 점검
- [ ] `2023391007_김관현_기말.zip` 압축 및 두 과목 게시판 제출 (공통 압축파일 + 과목별 보고서)
