# 기말과제 진행 현황 및 남은 TODO (`2023391007_김관현_기말`)

> 기준일: `2026-11-28` (마감: `2026-12-05(토) 23:59 KST`)
> 현재 상태: **R1 ~ R7 + 게임플레이·연출 업그레이드 + 보고서 2종 + 최종 회고 완료** — 남은 작업: **LÖVE 11.5 실기 실행 최종 확인 및 압축 제출**

---

## 1. 완료된 항목 (1~7회차)

| 회차 | 요건 | 커밋 | 작업 로그 | 테스트 현황 |
|---|---|---|---|---|
| 1회차 | 기준선 + **R1** (`HelpScene` 추가 및 리뷰 보완) | `4dd0049`, `89018b4` | `001`, `002` | `scene_test.lua` 19/19 |
| 2회차 | **R2** (`docs/waves_format.md`, `waves.txt`, `WaveParser`) | `2eb0aef` | `003` | `wave_parser_test.lua` 10/10 |
| 3회차 | **R3** (적 3종 `Basic`/`Scout`/`Tank` 상속 + `EnemyFactory`) | `5b31ea1` | `004` | `enemy_factory_test.lua` 6/6 |
| 4회차 | **R4** (적 AI 4상태 `enter`→`formation`→`dive`→`return`, `rng` 결정성) | `8699286` | `005` | `enemy_ai_test.lua` 6/6 |
| 5회차 | **R5** (업적 3종 `trigger_happy`/`last_stand`/`clean_boss` + `EffectsView` 폭죽·경보·통합 배너) | `a723406` | `006` | `achievement_test.lua` 8/8 |
| 6회차 | **R6** (`HighScoreModel` 저장/복원) + **패럴랙스 우주 · 감쇠 사인파 트윈 유도탄 · Graze/Overdrive/파워업(`WeaponDecorator`) · 보스 광폭화/레이저** | `a723406`, `4f919e1` | `007` | 신규 4종 21/21 |
| 7회차 | **R7** (`SniperEnemy` 추가 + `before-r7` 대비 번짐 실측 `models 3 / views 1 / controllers 0 / scenes 0`) | `26563b9` | `008` | `enemy_factory_test.lua` 7/7 (총 80/80) |

- 공통 검사 통과: `layer_check.lua` (39개 파일, 위반 0건), `phase_test.lua` (9/9), `luac -l -p` (전역 쓰기 0건).

---

## 2. 남은 필수 기능 (5~7회차)

### [x] 5회차 — R5: 업적 3개 이상 (이벤트 구독 + View 알림)
- **완료 내역**: `AchievementModel`이 `GameModel:drainEvents()` 이벤트만 구독해 특이 업적 3종(`trigger_happy`, `last_stand`, `clean_boss`)을 판정(`GameModel.lua` 무수정).
- **요란한 연출 + 통합 배너**: `EffectsView.lua` 배너 영역에 업적 알림 큐(`ACHIEVEMENT UNLOCKED!` 네온 점멸 박스)·폭죽 3지점 다색 파티클·보스 등장 붉은 경보/흔들림·보스 격파 대폭발을 통합 구현, `achievement_test.lua` 8/8 통과 및 `report_게임인공지능.md` 3-3 Observer 행 추가 완료.

### [x] 6회차 — R6: 하이스코어 저장/불러오기 + 게임플레이·연출 업그레이드 (Steps A~E)
- **완료 내역**:
  - **R6 (`HighScoreModel`)**: 순수 문자열 직렬화/역직렬화(`pcall(parseStrict, text)` 손상 복구) + `main.lua` 파일 I/O 격리 + `ResultScene`/`ResultView` `BEST / NEW!` 표시 (`highscore_test.lua` 6/6).
  - **패럴랙스 우주 (`StarfieldView`)**: 3층 별 스크롤 + 보스/오버드라이브 워프 가속.
  - **감쇠 사인파 트윈 유도탄 (`homing.steerWave`, `BulletModel`, `BulletView`)**: `wrapPi` + 각속도 제한 + 감쇠 사인파 사행 + `±55°` 반대 위상 트윈 발사 + 8점 네온 궤적 (`homing_test.lua` 4/4).
  - **Graze·Overdrive·파워업 (`WeaponDecorator` 가산점)**: 18px 스침 게이지 100% → 5초 오버드라이브(3갈래 2배 연사), 돌격 격추 2배 점수 + `spread`/`shield`/`slow` 캡슐 드롭 (`powerup_graze_test.lua` 6/6).
  - **보스 2페이즈 광폭화 & 경고선 레이저 (`BossModel`, `BossPhase`, `BossView`)**: HP ≤ 50% 시 붉은 광폭화(1.6배속, 조준 부채꼴 탄막) + `idle`→`warning(DANGER)`→`firing` 레이저 (`boss_enrage_test.lua` 5/5).
- **문서**: `report_게임시스템설계.md` Q3 작성, `report_게임인공지능.md` 3-3 Decorator 행 추가, `worklogs/007_2026-11-28_r6_and_gameplay_upgrade.md` 작성 완료.

### [x] 7회차 — R7: 번짐 실측 (새 적 1종 `SniperEnemy` 추가)
- **완료 내역**: `before-r7`(`7f11e8b`) 태그 후 `SniperEnemy.lua`·`EnemyFactory.lua`·`EnemyView.lua`·`waves.txt`·`enemy_factory_test.lua`만 수정·커밋(`26563b9`)하고 계층별 hunk 실측 완료 (`models 3 / views 1 / controllers 0 / scenes 0`, `GameModel.lua` 0줄 수정).
- **문서**: `report_게임인공지능.md` Q3 및 3-5 번짐 실측 표·해석, `worklogs/008_2026-11-28_r7_spread_measure.md`, `worklogs/999_retrospective.md` 작성 완료.

---

## 3. AI 협업 로그(`worklogs/`) 필수 요건 체크리스트

> 공통 명세 4절 기준 (미달 시 로그 점수 상한 5점)

- [x] 세션 로그 5개 이상 (`001` ~ `005` 작성 완료, R5~R7 추가 시 8개)
- [x] 서로 다른 날짜 3일 이상 (`2026-11-21`, `2026-11-26`, `2026-11-27` — 3일 달성)
- [x] 프롬프트 기록 10개 이상 (현재 10개+, R5~R7에서 추가)
- [x] 거절 또는 수정 사례 3개 이상 (`002` R1 리뷰 수정, `003` `math.huge` 수정, `004` `takeDamage` 충돌 수정, `005` `_aiCtx` GC 수정)
- [x] **"AI가 틀렸고 내가 잡았다" 정식 양식 2건 정리**
  - [x] 게임시스템설계(Lua 함정) 1건 (`003` `WaveParser.lua:78`의 `math.huge` 통과 버그 정식 양식 정리)
  - [x] 게임인공지능(구조·패턴 문제) 1건 (`004` `GameModel.lua:238` `takeDamage`→`hit` 정적 계약 충돌 정식 양식 정리)
- [ ] **경계 위반 거절 1건 이상** — `layer_check` 출력 **원문** + 거절 이유 + 고친 프롬프트 (R6 또는 R7 세션에서 기록 확보 권장)
- [x] **명세 기반 프롬프트 1건** — README·계약 문서(`docs/waves_format.md`)·테스트(`wave_parser_test.lua`) 첨부 비교 기록 (`003` 정리)
- [x] **최종 회고 작성**: `worklogs/999_retrospective.md` (공통 명세 4-3 양식 준수)

---

## 4. 보고서 2종 및 최종 제출 체크리스트

### 과목별 보고서
- [x] `docs/report_게임시스템설계.md` (3-1 출처 표, 3-2 14행 줄 번호 동기화, 3-3 Q1~Q3, 3-4 최종 정리 완료)
- [x] `docs/report_게임인공지능.md` (3-1 출처 표, 3-2 AI 설계, 3-3 패턴표 7행 줄 번호 동기화 + Decorator, 3-4 Q1~Q3, 3-5 R7 번짐 실측 표·해석, 3-6 최종 정리 완료)

### 최종 마감 직전 (12/03 ~ 12/05)
- [ ] LÖVE 11.5 창으로 직접 실행해 전체 플레이 흐름(타이틀 → 도움말 → 1~3웨이브(`sniper` 포함) → 적 돌격/복귀 → 업적 알림 → 보스전 광폭화/레이저 → 결과 → 하이스코어 저장/재실행 복원) 시각 확인
- [x] 전체 테스트(80건) + `layer_check.lua`(39개 파일 0건) + `luac -l -p` 전역 쓰기 0건 최종 재실행
- [x] `git log --stat --date=iso > 2023391007_김관현_기말/docs/git_log.txt` 생성 (로그 커밋 해시와 일치 대조)
- [ ] 로그·문서에 개인정보/API 키 누락·노출 여부 점검
- [ ] `2023391007_김관현_기말.zip` 압축 및 두 과목 게시판 제출 (공통 압축파일 + 과목별 보고서)
