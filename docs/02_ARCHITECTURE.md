# 02. 앱 아키텍처 & 데이터 모델

## 아키텍처 패턴
- **Feature-first 모듈 구조** + **Clean Architecture 레이어**
- 각 feature 모듈 내부에서 data → domain → presentation 레이어 분리

## MVP(v1) 범위 메모
- 배경 제거는 **capture feature 내부의 앱 내 이미지 처리**로 수행
- **AI 분류 / AI 모션 추천 / AI 루프 생성은 v1 범위에서 제외**
- 캐릭터 탭 반응은 공통 기본 동작 **`defaultBounce` 1종**만 제공
- v2에서 AI agent 연동 feature를 별도 확장한다

## 프로젝트 구조

```
lib/
├── main.dart
├── app.dart                          # MaterialApp, 라우팅, 테마
│
├── core/                             # 공통 모듈
│   ├── database/                     # Drift DB 설정, DAO
│   ├── storage/                      # 파일 저장/로드 유틸
│   ├── theme/                        # 색상, 텍스트 스타일, 공통 위젯
│   └── util/                         # 확장함수, 헬퍼
│
├── feature/
│   ├── capture/                      # 그림 가져오기
│   │   ├── data/                     # 이미지 처리, 규칙 기반 배경 제거
│   │   │   ├── image_processor.dart
│   │   │   └── background_remover.dart
│   │   ├── domain/                   # 유스케이스
│   │   │   └── save_character_usecase.dart
│   │   └── presentation/             # UI
│   │       ├── capture_screen.dart
│   │       ├── crop_screen.dart
│   │       ├── preview_screen.dart
│   │       └── capture_viewmodel.dart
│   │
│   ├── library/                      # 그림 라이브러리
│   │   ├── data/
│   │   │   └── character_repository.dart
│   │   ├── domain/
│   │   │   └── get_characters_usecase.dart
│   │   └── presentation/
│   │       ├── library_screen.dart
│   │       └── library_viewmodel.dart
│   │
│   ├── stage/                        # 무대 놀이
│   │   ├── data/
│   │   │   └── scene_repository.dart
│   │   ├── domain/
│   │   │   ├── model/
│   │   │   │   ├── motion_preset.dart
│   │   │   │   └── touch_preset.dart
│   │   │   └── place_character_usecase.dart
│   │   └── presentation/
│   │       ├── stage_screen.dart
│   │       ├── stage_painter.dart    # CustomPainter (캐릭터 렌더링)
│   │       ├── stage_viewmodel.dart
│   │       ├── background_select_screen.dart  # 배경 선택 화면
│   │       └── widget/
│   │           ├── background_selector.dart
│   │           ├── character_selector.dart
│   │           └── motion_selector.dart
│   │
│   └── home/                         # 홈 화면
│       └── presentation/
│           └── home_screen.dart
│
└── router/                           # GoRouter 라우팅 설정
    └── app_router.dart
```

## 데이터 모델

### Character (저장된 캐릭터)
```dart
class Character {
  final int id;
  final String name;                  // 자동 생성 (예: "그림 1")
  final String originalImagePath;     // 크롭된 원본
  final String transparentImagePath;  // 배경 제거된 PNG
  final String thumbnailPath;         // 썸네일
  final int width;                    // 이미지 너비 (px)
  final int height;                   // 이미지 높이 (px)
  final DateTime createdAt;
}
```

### Background (배경 템플릿)
```dart
class Background {
  final String id;
  final String name;           // 표시명 (예: "숲")
  final String assetPath;      // assets 경로
  final Color groundColor;     // 바닥선 색상 (디버그용)
  final double groundY;        // 바닥선 Y 비율 (0.0~1.0)
}
```

### PlacedCharacter (무대 위 배치된 캐릭터)
```dart
class PlacedCharacter {
  final String instanceId;     // 고유 인스턴스 ID (같은 캐릭터 여러 개 배치 가능)
  final int characterId;       // Character 테이블 FK
  final Offset position;       // 무대 내 위치 (비율 기반)
  final double scale;          // 크기 배율 (기본 1.0)
  final MotionPreset motion;   // 움직임 프리셋 (사용자 직접 선택)
  final TouchPreset touch;     // v1 공통 터치 반응
  final int zIndex;            // 레이어 순서 (탭하면 최상위로)
}
```

### MotionPreset (움직임 프리셋)
```dart
enum MotionPreset {
  floating,   // 둥실둥실 — sin파 상하 이동
  bouncing,   // 통통 점프 — 바운스 곡선
  gliding,    // 씽씽 활공 — 좌우 수평 이동
  rolling,    // 데굴데굴 — 회전 + 수평 이동
  spinning,   // 빙글빙글 — 제자리 360도 회전
}
```

### TouchPreset (터치 반응 프리셋)
```dart
enum TouchPreset {
  defaultBounce,  // v1 공통 탭 반응 — 위로 통통 튀었다 내려옴
}
```

> **참고:** v2에서는 `TouchPreset`을 AI 분류 기반 카테고리별 동작으로 확장한다.

## DB 스키마 (Drift)

### characters 테이블
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | INTEGER PK | 자동 증가 |
| name | TEXT | 캐릭터 이름 |
| original_image_path | TEXT | 크롭 원본 경로 |
| transparent_image_path | TEXT | 배경 제거 PNG 경로 |
| thumbnail_path | TEXT | 썸네일 경로 |
| width | INTEGER | 이미지 너비 |
| height | INTEGER | 이미지 높이 |
| created_at | INTEGER | Unix timestamp |

> **참고:** 무대 씬(StageScene)은 MVP에서는 영속 저장하지 않음. 앱 재시작 시 무대 초기화. 추후 씬 저장 기능 추가 가능.

## 레이어 간 의존 방향

```
UI (Screen/Widget)
    ↓ 의존
ViewModel (StateNotifier / Riverpod)
    ↓ 의존
UseCase (비즈니스 로직)
    ↓ 의존
Repository (데이터 접근 추상화)
    ↓ 구현
DataSource (Drift DB / File System / Image Processing)
```

## 라우팅 (GoRouter)

| 경로 | 화면 | 설명 |
|------|------|------|
| `/` | HomeScreen | 홈 (그림 만들기 / 놀이 시작) |
| `/capture` | CaptureScreen | 카메라/갤러리 선택 |
| `/capture/crop` | CropScreen | 크롭 화면 |
| `/capture/preview` | PreviewScreen | 배경제거 결과 미리보기 |
| `/stage/background` | BackgroundSelectScreen | 배경 선택 |
| `/stage` | StageScreen | 무대 놀이 화면 |

> **참고:** 라이브러리는 독립 화면(`/library`)을 두지 않는다. 무대 화면에서 `+` 버튼을 눌렀을 때 바텀시트로 캐릭터 목록을 표시하며, `library` feature의 presentation 레이어가 이 바텀시트를 담당한다.

## 의존성 주입 (Riverpod)

### Provider 구성 전략
- **ProviderScope:** `main.dart`의 `runApp`에서 최상위 `ProviderScope`로 감싼다
- **Repository Provider:** 각 feature의 Repository를 `Provider`로 등록 (싱글턴)
- **UseCase Provider:** Repository를 `ref.watch`로 주입받는 `Provider`
- **ViewModel Provider:** `StateNotifierProvider` 또는 `AsyncNotifierProvider`로 정의, UseCase를 주입받음
- **DB Provider:** Drift `AppDatabase` 인스턴스를 `Provider`로 등록, 각 DAO가 이를 참조

### 예시 구조
```dart
// core/database/
final appDatabaseProvider = Provider((ref) => AppDatabase());

// feature/library/data/
final characterRepositoryProvider = Provider(
  (ref) => CharacterRepository(ref.watch(appDatabaseProvider)),
);

// feature/library/domain/
final getCharactersUseCaseProvider = Provider(
  (ref) => GetCharactersUseCase(ref.watch(characterRepositoryProvider)),
);

// feature/library/presentation/
final libraryViewModelProvider = StateNotifierProvider<LibraryViewModel, LibraryState>(
  (ref) => LibraryViewModel(ref.watch(getCharactersUseCaseProvider)),
);
```

## v2 확장 포인트 (참고)
- AI agent 기반 그림 판별 feature 추가
- 카테고리별 모션 추천 및 루프 자산 생성 파이프라인 분리
- 세분화된 터치 동작을 위한 별도 domain / data 모듈 확장
