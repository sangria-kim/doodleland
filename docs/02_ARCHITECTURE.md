# 02. 앱 아키텍처 & 데이터 모델

## 아키텍처 패턴
- **feature-first 구조**
- feature 내부는 `data / domain / presentation` 레이어로 분리
- 상태관리는 Riverpod `StateNotifierProvider` 중심
- 무대 씬은 현재 메모리 상태만 관리하며 DB에 저장하지 않음

## 현재 프로젝트 구조

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── character_dao.dart
│   ├── permission/
│   │   └── common_permission.dart
│   ├── presentation/
│   │   └── android_fullscreen_scope.dart
│   ├── storage/
│   │   └── character_storage_paths.dart
│   └── theme/
│       └── app_theme.dart
├── feature/
│   ├── capture/
│   │   ├── data/
│   │   │   ├── background_removal_config.dart
│   │   │   ├── background_remover.dart
│   │   │   ├── drawing_region_detector.dart
│   │   │   └── image_processor.dart
│   │   ├── domain/
│   │   │   └── save_character_usecase.dart
│   │   └── presentation/
│   │       ├── capture_screen.dart
│   │       ├── capture_viewmodel.dart
│   │       ├── crop_screen_args.dart
│   │       ├── crop_screen.dart
│   │       └── preview_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart
│   ├── library/
│   │   ├── data/
│   │   │   └── character_repository.dart
│   │   ├── domain/
│   │   │   ├── delete_character_usecase.dart
│   │   │   └── get_characters_usecase.dart
│   │   └── presentation/
│   │       ├── library_screen.dart
│   │       └── library_viewmodel.dart
│   └── stage/
│       ├── data/
│       │   └── scene_repository.dart
│       ├── domain/
│       │   ├── model/
│       │   │   ├── motion_preset.dart
│       │   │   ├── placed_character.dart
│       │   │   ├── stage_motion.dart
│       │   │   ├── stage_motion_engine.dart
│       │   │   ├── stage_background.dart
│       │   │   └── touch_preset.dart
│       │   └── place_character_usecase.dart
│       └── presentation/
│           ├── background_select_screen.dart
│           ├── stage_painter.dart
│           ├── stage_screen.dart
│           ├── stage_viewmodel.dart
│           └── widget/
│               ├── background_selector.dart
│               ├── character_selector.dart
│               └── motion_selector.dart
└── router/
    └── app_router.dart
```

## 구현 상태 메모
- `stage_painter.dart`
- `background_selector.dart`

위 2개 파일은 현재 placeholder 상태이며 실제 흐름에서 사용되지 않습니다.

## 핵심 데이터 모델

### Character
Drift가 생성하는 `Character` row 모델을 사용합니다.

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | `int` | PK |
| `name` | `String` | 시간 기반 자동 생성 이름 |
| `originalImagePath` | `String` | 크롭 결과 원본 복사본 |
| `transparentImagePath` | `String` | 배경 제거 PNG |
| `thumbnailPath` | `String` | 썸네일 PNG |
| `width` | `int` | 투명 결과 너비 |
| `height` | `int` | 투명 결과 높이 |
| `createdAt` | `DateTime` | 생성 시각 |

### StageBackground
```dart
class StageBackground {
  final String id;
  final String name;
  final String assetPath;
  final double groundY;
}
```

기본 배경 목록:
- `forest` / `숲` / `0.86`
- `sky` / `푸른 하늘` / `0.84`
- `ocean` / `바다` / `0.81`
- `starry_night` / `별빛 밤` / `0.83`
- `candy_land` / `캔디 랜드` / `0.88`

### PlacedCharacter
```dart
class PlacedCharacter {
  final String instanceId;
  final int characterId;
  final String characterName;
  final String transparentImagePath;
  final String thumbnailPath;
  final int sourceWidth;
  final int sourceHeight;
  final MotionPreset objectMotion;
  final StageMotion stageMotion;
  final StageMotionRuntimeState stageRuntime;
  final TouchPreset touchPreset;
  final double scale;
  final int zIndex;
  final PlacedCharacterRemovalState removalState; // normal / removing
}
```

### PlacedCharacterRemovalState
```dart
enum PlacedCharacterRemovalState {
  normal,
  removing,
}
```

### MotionPreset
```dart
enum MotionPreset {
  floating,
  bouncing,
  gliding,
  rolling,
}
```

### StageMotion (저장 설정)
```dart
class StageMotion {
  final bool enabled;
  final StageMotionPathType pathType; // v1: horizontalPingPong
}
```

### StageMotionRuntimeState (런타임 상태)
```dart
class StageMotionRuntimeState {
  final Offset position;
  final StageMotionDirection direction; // leftToRight / rightToLeft
  final double speed; // 0.1 ~ 0.4, 생성 시 1회 지정
  final bool isFlippedHorizontally;
  final bool isPaused;
}
```

저장/런타임 분리 기준:
- 저장 설정: `objectMotion`, `stageMotion`
- 런타임 상태: `stageRuntime`(`position`, `direction`, `speed`, `isFlippedHorizontally`, `isPaused`) + `removalState`
- 현재 stage 씬은 메모리 상태 기반이므로 DB 마이그레이션은 없습니다.

기본값 및 하위 호환:
- 기존 단일 `motionPreset` 의미는 `objectMotion`으로 승격합니다.
- `stageMotion` 기본값은 `enabled=true`, `pathType=horizontalPingPong`입니다.
- `stageRuntime.direction` 기본값은 `leftToRight`입니다.
- `stageRuntime.speed`는 캐릭터 생성 시 `0.1~0.4` 범위 랜덤 1회 부여 후 유지합니다.
- 드래그 종료 시 방향은 드래그 시작 전 진행 방향을 유지하며, 속도는 유지됩니다.
- `isFlippedHorizontally` 필드는 확장 대비로 유지하지만, v1 렌더링에서는 좌우 반전을 사용하지 않습니다.

### TouchPreset
```dart
enum TouchPreset {
  defaultBounce,
}
```

### StageState
```dart
class StageState {
  final List<PlacedCharacter> placedCharacters;
  final String? errorMessage;
  final StageBackground selectedBackground;
}
```

`isFull`은 파생 값으로 계산하며 최대 10개 배치를 기준으로 합니다.

### CaptureDetectionResult (Phase1)
```dart
class DetectionResult {
  final bool detected;
  final Rect boundingBox; // normalized 0.0~1.0, original-image space
  final double confidence;
  final Map<String, Object?>? debugData;
}
```

### BackgroundRemovalResult (Phase1)
```dart
class RemovalResult {
  final bool success;
  final Uint8List outputImageBytes; // transparent PNG
  final Uint8List? maskBytes;
  final Map<String, Object?>? debugData;
}
```

## DB 스키마

### characters
| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | INTEGER PK | 자동 증가 |
| `name` | TEXT | 자동 생성 이름 |
| `original_image_path` | TEXT | 원본 파일 경로 |
| `transparent_image_path` | TEXT | 배경 제거 파일 경로 |
| `thumbnail_path` | TEXT | 썸네일 파일 경로 |
| `width` | INTEGER | 결과 이미지 너비 |
| `height` | INTEGER | 결과 이미지 높이 |
| `created_at` | DATETIME | 생성 시각 |

## 레이어 간 의존 방향

```text
UI (Screen / Widget)
    ↓
ViewModel (StateNotifier)
    ↓
UseCase
    ↓
Repository
    ↓
DAO / File System / 이미지 처리
```

## Capture 파이프라인 모듈 경계 (Phase1)

- 자동 인식 모듈
  - 인터페이스: `DrawingRegionDetector.detect(inputImageBytes)`
  - 출력: `DetectionResult`
  - 역할: 크롭 화면 초기 선택 영역 후보 제공
- 배경 제거 모듈
  - 인터페이스: `BackgroundRemover.remove(croppedImageBytes)`
  - 출력: `RemovalResult`
  - 역할: 저장 시 최종 투명 PNG 생성
- UI/Flow 모듈
  - CaptureScreen에서 자동 인식 실행
  - `CropScreenArgs(sourceImagePath, detectionResult)`를 `GoRouter extra`로 전달
  - CropScreen에서 정규화 bbox를 viewport 좌표로 변환해 `InitialRectBuilder`에 반영
  - 사용자가 조정한 crop 값을 최우선으로 저장 처리에 사용

현재 구현에서의 구체 예:
- capture: `CaptureScreen` -> `CaptureViewModel` -> `SaveCharacterUseCase`
- library: `LibraryViewModel` -> `GetCharactersUseCase` / `DeleteCharacterUseCase` -> `CharacterRepository`
- stage: `StageScreen` -> `StageViewModel` -> `PlaceCharacterUseCase`

## 라우팅

| 경로 | 화면 | 설명 |
|------|------|------|
| `/` | `HomeScreen` | 홈 |
| `/capture` | `CaptureScreen` | 소스 선택 |
| `/capture/crop` | `CropScreen` | 자동 인식 결과를 반영한 크롭 편집 |
| `/capture/preview` | `PreviewScreen` | 저장 전 크롭 결과 확인 |
| `/stage/background` | `BackgroundSelectScreen` | 배경 선택 |
| `/stage` | `StageScreen` | 무대 |

추가 메모:
- `LibraryScreen`은 구현되어 있지만 현재 라우터에 연결되어 있지 않습니다.
- 무대에서 캐릭터 추가는 `CharacterSelector` 바텀시트로 처리합니다.
- `/capture/crop` 이동 시 `extra`는 `CropScreenArgs`를 사용하며 `sourceImagePath`와 `detectionResult`를 함께 전달합니다.

## 의존성 주입

### 공통 Provider
- `appDatabaseProvider`
- `characterDaoProvider`
- `characterRepositoryProvider`
- `imagePickerProvider`

### feature별 Provider
- `captureViewModelProvider`
- `libraryViewModelProvider`
- `saveCharacterUseCaseProvider`
- `drawingRegionDetectorProvider`
- `backgroundRemoverProvider`
- `getCharactersUseCaseProvider`
- `deleteCharacterUseCaseProvider`
- `stageViewModelProvider`
- `placeCharacterUseCaseProvider`
- `sceneRepositoryProvider`

## 현재 구현상 주의점
- 홈, 캡처, 스테이지 문서는 Clean Architecture 개념을 따르지만 stage 쪽은 현재 repository 추상화보다 in-memory 상태 관리 비중이 큽니다.
- 저장 전 미리보기 화면은 실제 투명 PNG가 아니라 크롭된 원본 이미지를 보여줍니다.
- stage 렌더링은 `CustomPainter`가 아니라 개별 위젯의 `GestureDetector`와 `Transform` 조합입니다.
