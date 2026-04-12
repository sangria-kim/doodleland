# CLAUDE.md — 그림놀이터 프로젝트 컨텍스트

## 대답은 항상 한국어로 작성

## 공통 규칙 참조
- 브랜치 정책, 커밋 컨벤션, 버전 관리, Flutter 개발 규칙은 모두 `AGENTS.md`를 따른다.
- 작업 전 `AGENTS.md`를 우선 확인한다.

## 문서 구조

```text
/
├── AGENTS.md
├── CLAUDE.md
└── docs/
    ├── 01_TECH_STACK.md
    ├── 02_ARCHITECTURE.md
    ├── 03_FEATURE_SPEC.md
    ├── 04_SCREEN_FLOW.md
    ├── PROGRESS.md
    ├── PROGRESS_GUIDE.md
    └── plan.md
```

## 프로젝트 개요
- 아이가 그린 그림을 촬영하거나 선택한다.
- 크롭 후 저장 시 규칙 기반으로 배경을 제거한다.
- 캐릭터를 로컬 DB와 파일 저장소에 보관한다.
- 무대에서 배경을 고르고 캐릭터를 추가해 움직이게 한다.

## 현재 구현 요약

### 라우트
| 경로 | 화면 |
|------|------|
| `/` | `HomeScreen` |
| `/capture` | `CaptureScreen` |
| `/capture/crop` | `CropScreen` |
| `/capture/preview` | `PreviewScreen` |
| `/stage/background` | `BackgroundSelectScreen` |
| `/stage` | `StageScreen` |

### 핵심 동작
- 홈에서 `그림 만들기` 또는 `놀이 시작`
- 빈 라이브러리에서 `놀이 시작` 시 캡처 화면으로 유도
- 크롭 화면 진입 시 네이티브 cropper 자동 실행
- 미리보기 화면은 현재 **크롭 결과 확인 단계**
- 배경 제거는 저장 버튼을 눌렀을 때 실행
- 무대에서는 배경 5종, 모션 5종, 최대 10개 캐릭터 배치 지원

## 현재 기술 스택 요약
- Flutter / Dart
- Riverpod
- GoRouter
- Drift + sqlite3_flutter_libs
- image_picker
- image_cropper
- image
- path_provider
- permission_handler

## 현재 구조 메모

### 실제 사용 중인 공통 모듈
- `lib/core/database`
- `lib/core/permission`
- `lib/core/presentation`
- `lib/core/storage`
- `lib/core/theme`

### feature 메모
- `capture`: 선택, 크롭, 저장 처리
- `library`: 조회/삭제 상태 관리, 재사용 화면
- `stage`: 배경 선택, 배치, 애니메이션, 상호작용
- `home`: 진입 화면

### placeholder 파일
아래 파일은 현재 구현 경로에 연결되지 않았다.
- `lib/feature/capture/data/image_processor.dart`
- `lib/feature/stage/presentation/stage_painter.dart`
- `lib/feature/stage/presentation/widget/background_selector.dart`

## 데이터 모델 메모

### Character
- Drift row 모델 사용
- 저장 필드:
  - `id`
  - `name`
  - `originalImagePath`
  - `transparentImagePath`
  - `thumbnailPath`
  - `width`
  - `height`
  - `createdAt`

### PlacedCharacter
- 런타임 전용 모델
- 주요 필드:
  - `instanceId`
  - `characterId`
  - `characterName`
  - `transparentImagePath`
  - `thumbnailPath`
  - `sourceWidth`
  - `sourceHeight`
  - `motionPreset`
  - `touchPreset`
  - `position`
  - `scale`
  - `zIndex`

### StageBackground
- `id`
- `name`
- `assetPath`
- `groundY`

## 구현 시 주의할 현재 동작
- 미리보기 화면을 "배경 제거 결과"로 가정하면 안 된다.
- stage 렌더링은 `CustomPainter`가 아니라 widget `Stack` 기반이다.
- 라이브러리는 현재 독립 라우트보다 바텀시트/재사용 컴포넌트 용도로 쓰인다.
- 캐릭터 탭 반응은 수직 점프가 아니라 scale bounce다.

## 하네스
- 하네스 규칙과 역할별 프롬프트는 `docs/harness/`를 참조한다.
- 실행 규칙은 `AGENTS.md [7]`을 따른다.
- 실행기: `scripts/harness_runner.py`

## 참고 문서
- 세부 기술 근거: `docs/01_TECH_STACK.md`
- 구조와 모델: `docs/02_ARCHITECTURE.md`
- 기능 기준: `docs/03_FEATURE_SPEC.md`
- 화면 흐름: `docs/04_SCREEN_FLOW.md`
- 진행 현황: `docs/PROGRESS.md`
