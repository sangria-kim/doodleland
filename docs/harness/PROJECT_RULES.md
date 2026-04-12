# PROJECT_RULES.md — DoodleLand 하네스 공통 규칙

> 이 문서는 planner, implementer, reviewer, fixer 모든 역할이 공유하는 프로젝트 규칙이다.
> 코드 변경 전 반드시 읽는다.

---

## 1. Domain Model

### 1.1 Character (DB 엔티티)

Drift 테이블 `Characters`에 매핑되는 영속 모델.

| 필드 | 타입 | 설명 |
|------|------|------|
| id | int | auto-increment PK |
| name | String | 캐릭터 이름 |
| originalImagePath | String | 원본 이미지 경로 |
| transparentImagePath | String | 배경 제거된 이미지 경로 |
| thumbnailPath | String | 썸네일 경로 |
| width | int | 원본 가로 픽셀 |
| height | int | 원본 세로 픽셀 |
| createdAt | DateTime | 생성 시각 |

파일: `lib/core/database/app_database.dart`

### 1.2 PlacedCharacter (런타임 모델)

무대에 배치된 캐릭터의 전체 상태. `@immutable`, `copyWith`로만 수정.

| 필드 | 타입 | 설명 |
|------|------|------|
| instanceId | String | 무대 내 고유 ID |
| characterId | int | DB Character.id |
| characterName | String | 이름 |
| transparentImagePath | String | 투명 PNG |
| thumbnailPath | String | 썸네일 |
| sourceWidth / sourceHeight | int | 원본 크기 |
| objectMotion | MotionPreset | 캐릭터 자체 애니메이션 |
| stageMotion | StageMotion | 무대 이동 설정 |
| stageRuntime | StageMotionRuntimeState | 위치/방향/속도/일시정지 |
| touchPreset | TouchPreset | 탭 반응 |
| scale | double | 확대/축소 (현재 1.0) |
| zIndex | int | 깊이 순서 |
| removalState | PlacedCharacterRemovalState | normal / removing |

파일: `lib/feature/stage/domain/model/placed_character.dart`

### 1.3 StageBackground

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 'forest', 'sky', 'ocean', 'starry_night', 'candy_land' |
| name | String | 한국어 이름 |
| assetPath | String | assets 경로 |
| groundY | double | 지면 Y좌표 (0.0~1.0 정규화) |

5종 배경. 파일: `lib/feature/stage/domain/model/stage_background.dart`

### 1.4 MotionPreset / TouchPreset

**MotionPreset** (5종):
- `floating` — 둥실둥실: 위아래 떠다님
- `bouncing` — 통통 점프: 경쾌한 튀어오름
- `gliding` — 씽씽 활공: 상승-급강하 반복
- `rolling` — 데굴데굴: 제자리 회전
- `fluttering` — 나풀나풀: 수직 낙하 + 좌우 흔들림

파일: `lib/feature/stage/domain/model/motion_preset.dart`

**TouchPreset** (1종):
- `defaultBounce` — scale 1.0 → 1.12 → 1.0, 300ms

파일: `lib/feature/stage/domain/model/touch_preset.dart`

### 1.5 StageMotion / StageMotionRuntimeState

**StageMotion** (저장 설정):
- `enabled`: 이동 활성화 여부
- `pathType`: `horizontalPingPong` (좌우 왕복) / `verticalLeafFall` (수직 낙하 순환)

**StageMotionRuntimeState** (런타임 상태):
- `position`: 정규화 좌표 (0.0~1.0)
- `direction`: leftToRight / rightToLeft
- `speed`: 0.1~0.4 (생성 시 랜덤 1회 지정)
- `isFlippedHorizontally`: 좌우 반전 (현재 미사용, 확장 대비)
- `isPaused`: 드래그/제거 중 일시정지

파일: `lib/feature/stage/domain/model/stage_motion.dart`

### 1.6 StageMotionEngine

매 프레임 위치 계산 엔진. 주요 메서드:
- `tick()` — 프레임별 위치 갱신 (isPaused이면 즉시 반환)
- `pauseForDrag()` — isPaused = true
- `applyDragPosition()` — 드래그 중 위치 적용 + clamp
- `resumeFromDrag()` — 위치 적용 + isPaused = false
- `clampPosition()` — 무대 경계 제한

파일: `lib/feature/stage/domain/model/stage_motion_engine.dart`

### 1.7 StageState (ViewModel 상태)

- `placedCharacters`: 배치된 캐릭터 목록 (최대 10개)
- `errorMessage`: 오류 메시지
- `selectedBackground`: 현재 배경

파일: `lib/feature/stage/presentation/stage_viewmodel.dart`

---

## 2. State Machine

### 2.1 PlacedCharacter 생명주기

```
[created]
  │ placeCharacter() → 리스트에 추가
  ▼
[normal] ─── entrance animation (800ms) ───┐
  │                                         │
  │ (entrance 완료)                          │
  ▼                                         │
[active] ◄──────────────────────────────────┘
  │
  ├─── (드래그 시작) ──→ [paused] ──(드래그 종료)──→ [active]
  │
  ├─── (탭) ──→ bounce animation (300ms) ──→ [active]
  │
  └─── (길게 누르기) ──→ requestCharacterRemoval()
                          │
                          ▼
                    [removing] ─── remove animation (1000ms)
                          │
                          ▼ completeCharacterRemoval()
                    [disposed] (리스트에서 제거)
```

**상태별 규칙:**

| 상태 | 진입 조건 | 허용 동작 | 금지 동작 |
|------|----------|----------|----------|
| created | placeCharacter() 호출 | 없음 (즉시 normal로 전이) | — |
| normal/active | 생성 직후 또는 드래그 종료 | 드래그, 탭, 길게 누르기, 위치 업데이트 | — |
| paused (drag) | 드래그 시작 | 위치 이동, 드래그 종료 | stageMotion tick, 길게 누르기 |
| removing | requestCharacterRemoval() | remove animation 재생 | 드래그, 탭, 위치 업데이트, bringToFront, 재 remove 요청 |
| disposed | completeCharacterRemoval() | — | 모든 동작 |

### 2.2 StageMotion 런타임 상태

```
[running] (isPaused=false, motion.enabled=true)
  │
  ├─── pauseForDrag() ──→ [paused] ──resumeFromDrag()──→ [running]
  │
  └─── requestCharacterRemoval() ──→ [permanently paused] ──→ [disposed]
```

- `tick()`은 `!motion.enabled || runtime.isPaused || delta <= Duration.zero` 일 때 즉시 반환
- horizontalPingPong: 경계 도달 시 방향 자동 반전
- verticalLeafFall: 하단 도달 시 상단에서 재시작 (순환)

### 2.3 Entrance Effect 생명주기

```
[pending] (_pendingEntranceInstanceIds에 추가)
  │ (이미지 로드 완료)
  ▼
[playing] (_entryController.forward(), 800ms)
  │ Scale: 0.5→1.5→1.0, Opacity: 0→1
  ▼
[completed] (instanceId를 pending에서 제거)
```

### 2.4 Remove Effect 생명주기

```
[triggered] (removalState == removing 감지)
  │ (_isRemoving = true, _removeController.forward())
  ▼
[playing] (1000ms)
  │ TranslateY: 0→8→-36px
  │ TranslateX: ±12px
  │ Scale: 1.0→1.08→0.58
  │ Rotation: ±0.16rad
  │ Opacity: 1.0→0.0
  ▼
[completed] (onRemoveAnimationCompleted → completeCharacterRemoval)
```

---

## 3. Interaction Rules

| 상호작용 A + B | 결과 | 코드 위치 |
|---------------|------|----------|
| drag + removing | drag 무시 | `_handlePanStart`: `_isRemoving` 체크 |
| drag + stageMotion | motion 일시정지 | `pauseForDrag()` 호출 |
| drag end + stageMotion | motion 재개 | `resumeFromDrag()` 호출 |
| removing + updateCharacterPosition | update 무시 | ViewModel: `removalState == removing → return false` |
| removing + bringCharacterToFront | 무시 | ViewModel: `removalState == removing → return` |
| removing + 재 remove 요청 | 무시 | ViewModel: `이미 removing → return false` |
| bounce(tap) + removing | tap 불가 | `_isRemoving` 체크 |
| entrance + 입력 | 독립 실행 | entrance는 별도 controller |

**핵심 원칙:**
- `removing` 상태의 캐릭터는 모든 사용자 입력을 무시한다
- 드래그 중 stageMotion은 반드시 일시정지하고, 드래그 종료 시 재개한다
- entrance animation은 사용자 입력과 독립적으로 실행된다

---

## 4. Animation Rules

### 4.1 일반 규칙
- animation은 반드시 **state 기반**으로 시작/종료한다
- `Future.delayed` 사용을 최소화한다 — AnimationController의 completion 기반으로 상태 전환한다
- AnimationController는 반드시 `dispose()`에서 해제한다
- Ticker는 반드시 `dispose()`에서 해제한다

### 4.2 ObjectMotion (MotionPreset 기반)
- 2초 주기 순환: `(elapsed.inMilliseconds % 2000) / 2000.0`
- MotionPreset별 Transform 계산은 widget build 시 phase 값 기반

### 4.3 StageMotion (위치 이동)
- `Ticker` 기반 매 프레임 업데이트
- `basePixelsPerSecond = 180`, 캐릭터별 speed로 조절
- 경계 계산에 오브젝트 크기 반영

### 4.4 효과 타이밍 상수
| 효과 | 시간 | 비고 |
|------|------|------|
| 등장 (entrance) | 800ms | Scale 0.5→1.5→1.0 |
| 제거 (remove) | 1000ms | TranslateY/X + Scale + Rotation + Opacity |
| 바운스 (bounce) | 300ms | Scale 1.0→1.12→1.0 |
| Confetti | 800ms | 28개 파티클, 크기 3~6px |

---

## 5. Implementation Constraints

1. **요청 범위 외 수정 금지**: task에서 명시한 파일/기능만 수정한다.
2. **불필요한 리팩터링 금지**: 동작하는 코드의 구조를 변경하지 않는다.
3. **상태 변경 시 영향 범위 명시**: 새 상태나 전이를 추가할 때 영향받는 모든 경로를 문서화한다.
4. **Isolate 분리 대상**: 이미지 픽셀 처리는 반드시 `compute()` 또는 `Isolate.run()`으로 분리한다.
5. **최대 배치 수 10개 제한**: `isFull` 체크를 우회하지 않는다.
6. **좌표 정규화**: position은 항상 0.0~1.0 정규화 좌표를 사용한다.
7. **불변 모델 원칙**: Domain 모델은 `@immutable`이며 `copyWith`로만 수정한다.
8. **기존 패턴 준수**: StateNotifier + Riverpod 패턴을 따른다. 새로운 상태관리 패턴을 도입하지 않는다.

---

## 6. Review Guidelines

reviewer는 다음 체크리스트를 순서대로 검토한다.

### 6.1 상태 전이 누락
- [ ] 새 상태를 추가했다면 모든 진입/이탈 경로가 정의되어 있는가?
- [ ] removing 상태에서의 모든 입력이 올바르게 차단되는가?
- [ ] 상태 전이 시 isPaused가 올바르게 설정되는가?

### 6.2 입력 충돌
- [ ] drag 중 remove 요청이 들어올 경우 처리가 있는가?
- [ ] removing 중 drag/tap이 무시되는가?
- [ ] 동시 tap + drag 시나리오가 고려되었는가?

### 6.3 Animation 타이밍
- [ ] AnimationController가 dispose 전에 forward/reverse 호출되는 경로가 있는가?
- [ ] 동일 controller에 대해 동시 forward가 호출되는 경로가 있는가?
- [ ] animation 완료 콜백에서 state 업데이트가 누락되지 않았는가?

### 6.4 Cleanup 누락
- [ ] 추가된 Timer가 dispose에서 cancel 되는가?
- [ ] 추가된 AnimationController가 dispose에서 해제되는가?
- [ ] 추가된 Ticker가 dispose에서 해제되는가?
- [ ] 추가된 StreamSubscription이 dispose에서 cancel 되는가?

### 6.5 중복 호출
- [ ] setState / state 할당이 불필요하게 반복되는가?
- [ ] 동일 이벤트에 대해 handler가 중복 등록되는가?

### 6.6 경계값
- [ ] position clamp가 누락된 경로가 있는가?
- [ ] 0 division 가능성이 있는가?
- [ ] 빈 리스트 접근 (first, last, [index])이 보호되는가?

---

## 7. Testing Guidelines

### 7.1 품질 게이트 (순서대로 실행, 하나라도 실패 시 중단)

```bash
dart format --set-exit-if-changed lib/ test/
flutter analyze
flutter test
```

### 7.2 상태 전이 테스트 필수 항목
- normal → removing → disposed 정상 흐름
- removing 상태에서 updateCharacterPosition 호출 시 무시 확인
- removing 상태에서 bringCharacterToFront 호출 시 무시 확인
- 이미 removing인 캐릭터에 requestCharacterRemoval 호출 시 false 반환

### 7.3 인터랙션 충돌 테스트 항목
- 드래그 시작 → isPaused=true 확인
- 드래그 종료 → isPaused=false, 위치 반영 확인
- 10개 배치 후 추가 배치 시도 → isFull 차단 확인
