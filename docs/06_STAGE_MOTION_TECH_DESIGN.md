# 06. Stage Motion 기술 설계 (v1)

## 1) 설계 목표
- 기존 단일 모션 처리 구조를 `objectMotion`과 `stageMotion`으로 분리합니다.
- v1은 좌우 왕복 이동만 구현하지만, 상하/대각선/경로 이동 확장이 가능한 구조를 유지합니다.
- 저장 설정과 런타임 상태를 분리해, 상호작용(특히 드래그) 중 상태 전이를 명확히 제어합니다.

## 2) 계층 책임

### 2-1. Motion Definition Layer
- `motion_preset.dart`: 그림 자체 애니메이션(`objectMotion`) 정의
- `stage_motion.dart`: 무대 이동 설정(`stageMotion`) + 런타임 상태(`stageRuntime`) 정의

### 2-2. Stage Motion Engine
- 파일: `stage_motion_engine.dart`
- 책임:
  - tick 단위 위치 갱신
  - 경계 판정
  - 방향 전환
  - 드래그 pause/resume 규칙 적용
  - 드래그 위치 clamp 처리

### 2-3. Render / Interaction Layer
- 파일: `stage_screen.dart`
- 책임:
  - 오브젝트 모션 렌더링(회전/부유/바운스)
  - 신규 추가 오브젝트의 1회 입장 애니메이션 제어(`instanceId` 기준)
  - 제거 요청 오브젝트의 퇴장 애니메이션 제어(`removing` 상태)
  - confetti 파티클 오버레이 렌더링 및 수명 종료 처리
  - Stage Motion Engine tick 결과를 정렬 좌표로 반영
  - 사용자 제스처 이벤트를 엔진 API로 연결

## 3) 경계 판정 방식
- 좌표는 정규화 좌표(0.0~1.0)로 관리합니다.
- 경계 계산 시 캐릭터 실제 표시 크기(이미지 비율 + `placed.scale`)를 반영합니다.
- v1 경계 전환 시점은 "이미지 절반이 화면 밖으로 이동한 순간"입니다.
- 수평 경계(align x 정규화 좌표 기준):
  - `minX = -objectWidth / (2 * (stageWidth - objectWidth))`
  - `maxX = 1 + objectWidth / (2 * (stageWidth - objectWidth))`
- Y는 화면 이탈을 방지하도록 별도 clamp를 적용합니다.

## 4) 방향 전환 처리 방식
- 오른쪽 경계 도달: `direction = rightToLeft`
- 왼쪽 경계 도달: `direction = leftToRight`
- v1에서는 좌우 반전 렌더링을 적용하지 않습니다.

## 5) 드래그 이벤트 연동 방식
- `onPanStart`
  - stage motion 즉시 pause
  - 현재 위치를 드래그 시작점으로 저장
- `onPanUpdate`
  - 입력 delta 기반 위치 계산
  - 엔진 clamp 적용 후 현재 위치 갱신
  - ViewModel에 동기화
- `onPanEnd/onPanCancel`
  - 드롭 위치 유지
  - 드래그 시작 전 진행 방향 유지
  - `speed`는 유지
  - stage motion resume

## 6) 속도 정책
- 속도 범위: `0.1 ~ 0.4`
- 캐릭터 생성 시 1회 랜덤 부여
- 이동 프레임 중 재랜덤 없음
- 드래그 종료 후에도 기존 속도 유지

## 7) 확장 고려 사항
- `StageMotionPathType`에 신규 경로 타입을 추가할 수 있습니다.
  - 예: `verticalPingPong`, `diagonalPingPong`, `pathFollow`
- `StageMotionEngine.tick`은 `pathType` switch 구조로 확장합니다.
- 향후 경로 기반 이동 시, 런타임 상태에 path index/progress를 추가합니다.
- 피드백 이펙트는 오버레이 기반 구조이므로 sparkle, star burst, 사운드/햅틱 트리거를 동일 레이어에서 확장할 수 있습니다.

## 8) 신규 오브젝트 피드백 설계
- 입장 애니메이션은 신규 오브젝트에만 적용합니다.
  - 스케일 시퀀스: `0.5 -> 1.5 -> 1.0`
  - 지속시간: `800ms`
  - opacity 보간: `0.0~0.62` 구간에서 `0 -> 1`
  - 재생 완료 후 `pendingEntranceInstanceIds`에서 제거해 재빌드 시 재실행을 방지합니다.
- confetti는 오브젝트 위젯 내부가 아닌 별도 오버레이(`_ConfettiEffectOverlay`)에서 관리합니다.
  - 파티클은 작은 사각형 중심으로 생성하며 일부 원형을 혼합합니다.
  - 그림 상단 기준으로 더 위에서 생성해 그림 하단 방향으로 낙하하며, `800ms` 수명으로 종료합니다.
  - 효과 종료 시 active burst를 즉시 제거해 잔여 위젯/연산이 남지 않도록 관리합니다.

## 9) 제거(Soft Exit) 설계
- 제거는 `즉시 리스트 삭제`가 아니라 `요청 -> 상태 전환 -> 애니메이션 완료 -> 최종 삭제` 순서로 처리합니다.
- 상태 관리:
  - `PlacedCharacter.removalState`: `normal` / `removing`
  - `StageViewModel.requestCharacterRemoval(instanceId)`: `removing` 전환 + `stageRuntime.isPaused=true`
  - `StageViewModel.completeCharacterRemoval(instanceId)`: 애니메이션 완료 후 실제 리스트 제거
- 시작 시 정지 원칙:
  - 제거 시작 프레임의 `stageRuntime.position`을 고정 기준으로 사용합니다.
  - `stageMotion` tick, object motion, 드래그 입력을 즉시 중단합니다.
  - `removing` 상태에서는 탭/드래그/중복 제거 요청을 무시합니다.
- 퇴장 애니메이션(`1000ms`) 구성:
  - translateY: `0 -> +8 -> -36px`
  - translateX: 방향 기반 `±12px` drift
  - scale: `1.0 -> 1.08 -> 0.58`
  - rotate: 방향 기반 `±0.16rad`
  - opacity: `1.0 -> 0.0` (`0.45~1.0` 구간 가속)
- 안정성:
  - 위젯 dispose 시 remove controller를 안전하게 dispose합니다.
  - 빠른 연속 삭제에서도 각 오브젝트가 독립적으로 완료 콜백을 처리합니다.
