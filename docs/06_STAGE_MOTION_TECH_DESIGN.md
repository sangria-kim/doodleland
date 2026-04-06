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
