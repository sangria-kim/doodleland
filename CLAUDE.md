# CLAUDE.md — 아이 그림 인터랙티브 샌드박스 앱

## 대답은 항상 한국어로 작성

---

## 공통 규칙 참조

브랜치 정책, 커밋 컨벤션, 버전 관리, Flutter 개발 컨벤션은 모두 `AGENTS.md`를 따른다.
→ 작업 전 반드시 `AGENTS.md` 확인

---

## 문서 구조

```
/
├── CLAUDE.md              ← 현재 파일 (Claude Code 전용, 프로젝트 전체 컨텍스트)
├── AGENTS.md              ← 브랜치/커밋/버전/Flutter 컨벤션 (공통 규칙 SST)
└── docs/
    ├── 01_TECH_STACK.md   ← 기술 스택 결정서 (패키지 선택 근거, 주의사항)
    ├── 02_ARCHITECTURE.md ← 아키텍처 & 데이터 모델 (프로젝트 구조, DB 스키마, DI 구성)
    ├── 03_FEATURE_SPEC.md ← 기능 명세 통합본 (Capture/Library/Stage 상세)
    └── 04_SCREEN_FLOW.md  ← 화면 흐름 & UI 가이드 (네비게이션, 화면별 레이아웃)
```

### 문서 읽는 순서 (작업 전)

| 작업 유형 | 읽어야 할 문서 |
|-----------|---------------|
| 신규 기능 개발 | `AGENTS.md` → `02_ARCHITECTURE.md` → `03_FEATURE_SPEC.md` |
| UI 구현 | `04_SCREEN_FLOW.md` → `03_FEATURE_SPEC.md` |
| 데이터 모델 / DB | `02_ARCHITECTURE.md` → `01_TECH_STACK.md` |
| 패키지 추가 검토 | `01_TECH_STACK.md` |
| 커밋 작성 | `AGENTS.md` |

---

## 프로젝트 개요

아이(3~5세)가 종이에 그린 그림을 촬영 → 배경 제거 → 캐릭터로 저장 → 테마 무대 위에서 움직이며 놀 수 있는 인터랙티브 샌드박스 앱.

---

## 기술 스택 (요약)

| 영역 | 선택 | 비고 |
|------|------|------|
| 프레임워크 | Flutter 3.24+ / Dart 3.5+ | |
| 타깃 플랫폼 | Android, iOS, iPad | |
| 화면 방향 | 가로(landscape) 고정 | |
| 상태관리 | `flutter_riverpod` | |
| DB | `drift` + `sqlite3_flutter_libs` | |
| 라우팅 | `go_router` | |
| 2D 렌더링 | `CustomPainter` + `AnimationController` | Flame은 v2 복잡도 증가 시 검토 |
| 카메라/갤러리 | `image_picker` | |
| 크롭 | `image_cropper` | 네이티브 UI (uCrop / TOCropViewController) |
| 이미지 처리 | `image` (Dart 패키지) | 픽셀 처리, PNG 인코딩, 썸네일 |
| 파일 경로 | `path_provider` | |
| 권한 | `permission_handler` | |

> 상세 선택 근거 및 주의사항은 `docs/01_TECH_STACK.md` 참조

---

## 아키텍처 (요약)

Feature-first 모듈 구조 + Clean Architecture 레이어

```
lib/
├── main.dart
├── app.dart                    # MaterialApp, 라우팅, 테마
├── core/
│   ├── database/              # Drift DB 설정, DAO
│   ├── storage/               # 파일 저장/로드 유틸
│   ├── theme/                 # 색상, 텍스트 스타일, 공통 위젯
│   └── util/                  # 확장함수, 헬퍼
├── feature/
│   ├── capture/               # 그림 가져오기 (카메라 → 크롭 → 배경제거 → 저장)
│   │   ├── data/              # image_processor.dart, background_remover.dart
│   │   ├── domain/            # save_character_usecase.dart
│   │   └── presentation/      # capture_screen, crop_screen, preview_screen, viewmodel
│   ├── library/               # 캐릭터 라이브러리 (바텀시트 전용, 독립 화면 없음)
│   │   ├── data/              # character_repository.dart
│   │   ├── domain/            # get_characters_usecase.dart
│   │   └── presentation/      # library_bottom_sheet.dart, viewmodel
│   ├── stage/                 # 무대 놀이
│   │   ├── data/              # scene_repository.dart
│   │   ├── domain/model/      # motion_preset.dart, touch_preset.dart
│   │   └── presentation/      # stage_screen, stage_painter, background_select_screen, viewmodel, widgets/
│   └── home/
│       └── presentation/      # home_screen.dart
└── router/
    └── app_router.dart
```

> 상세 DI 구성, Provider 패턴 예시는 `docs/02_ARCHITECTURE.md` 참조

---

## 라우팅

| 경로 | 화면 |
|------|------|
| `/` | HomeScreen |
| `/capture` | CaptureScreen |
| `/capture/crop` | CropScreen |
| `/capture/preview` | PreviewScreen |
| `/stage/background` | BackgroundSelectScreen |
| `/stage` | StageScreen |

> 라이브러리는 독립 경로 없음. 무대 화면의 바텀시트(`library` feature presentation)로만 접근.

---

## 핵심 데이터 모델

### Character (DB 저장)
```dart
class Character {
  final int id;
  final String name;                  // "그림 1", "그림 2", ... (순번 자동 생성)
  final String originalImagePath;     // images/original/{id}.png
  final String transparentImagePath;  // images/transparent/{id}.png
  final String thumbnailPath;         // images/thumbnail/{id}.png
  final int width;
  final int height;
  final DateTime createdAt;
}
```

### PlacedCharacter (무대 런타임, DB 저장 안 함)
```dart
class PlacedCharacter {
  final String instanceId;     // 같은 캐릭터 여러 개 배치 가능
  final int characterId;
  final Offset position;       // 비율 기반 좌표
  final double scale;          // 기본 1.0
  final MotionPreset motion;   // 사용자 선택
  final TouchPreset touch;     // v1: defaultBounce 고정
  final int zIndex;
}
```

### MotionPreset
```dart
enum MotionPreset {
  floating,   // 둥실둥실 — sin파 상하, 진폭 20px, 주기 2초, easeInOut
  bouncing,   // 통통 점프 — 높이 40px, 주기 1.2초, bounceOut
  gliding,    // 씽씽 활공 — 좌우 ±60px, 주기 3초, easeInOut
  rolling,    // 데굴데굴 — 회전 360° + 이동 ±80px, 주기 2.5초
  spinning,   // 빙글빙글 — 360° 제자리 회전, 주기 1.5초, linear
}
```

### TouchPreset
```dart
enum TouchPreset {
  defaultBounce,  // 위로 60px 튀었다 복귀, 0.5초, easeOut → easeIn (v1 공통)
}
```

### Background
```dart
class Background {
  final String id;         // forest | sky | ocean | starry_night | candy_land
  final String name;       // 숲 | 하늘 | 바다 | 별밤 | 사탕나라
  final String assetPath;
  final Color groundColor;
  final double groundY;    // 바닥선 Y 비율 (forest: 0.80, sky: 0.85, ocean: 0.75, ...)
}
```

> 상세 DB 스키마 및 Drift 테이블 정의는 `docs/02_ARCHITECTURE.md` 참조

---

## 배경 제거 파이프라인 (v1 규칙 기반)

AI/ML 미사용. 앱 내 처리만.

```
크롭 이미지 입력
    ↓ 1500×1500px 초과 시 비율 유지 리사이즈 (Isolate)
    ↓ 모서리 4영역 샘플링 → 배경색 추정
    ↓ 밝기/색상 유사도 threshold → 배경 후보 마스크
    ↓ 가장자리 flood fill → 외곽 배경 확장
    ↓ 작은 노이즈 제거
    ↓ alpha=0 처리 → 투명 배경 PNG 저장
```

**성능 기준:** 1000×1000px 이미지 3초 이내
**품질 검증:** 투명 영역 95%↑ 또는 5%↓ → 재촬영 안내 (저장은 허용)
**주의:** `image` 패키지 픽셀 처리는 느림 → 반드시 Isolate + 리사이즈 선처리

---

## 이미지 저장 경로

```
앱 내부 디렉토리 (getApplicationDocumentsDirectory)
├── images/original/{id}.png       # 크롭 원본
├── images/transparent/{id}.png    # 배경 제거 결과
└── images/thumbnail/{id}.png      # 200px 썸네일 (긴 변 기준)
```

---

## UI 핵심 규칙

- 전체 앱 가로(landscape) 고정, SafeArea 적용
- 터치 영역 최소 **56×56dp**, 주요 버튼 **80dp 이상** (3~5세 대상)
- 최소 폰트 **18sp**, 텍스트 최소화 (아이콘/일러스트 우선)
- 한국어 하드코딩 (MVP i18n 불필요)
- 파스텔톤 기본, **60fps** 애니메이션 목표

> 화면별 레이아웃, 네비게이션 흐름 상세는 `docs/04_SCREEN_FLOW.md` 참조

---

## v1 범위 제한 (반드시 준수)

| 항목 | v1 제한 | v2 예정 |
|------|---------|---------|
| 배경 제거 | 규칙 기반만 | AI/ML 검토 |
| AI agent | 사용 안 함 | 그림 판별, 모션 추천 |
| 캐릭터 탭 반응 | `defaultBounce` 1종 고정 | 카테고리별 세분화 |
| 무대 씬 저장 | 없음 (앱 재시작 시 초기화) | 씬 영속 저장 |
| 동시 배치 | 최대 10개 | |

---

## 주요 엣지케이스

- 빈 라이브러리에서 "놀이 시작" → 토스트 안내 + 캡처 화면으로 이동
- 무대 캐릭터 10개 도달 → `+` 버튼 비활성화 + "무대가 꽉 찼어요!" 툴팁
- 배경 제거 품질 불량 → 안내 메시지 표시 (저장 허용)
- 무대에서 배경 변경 시 → 배치된 캐릭터 위치 유지
- 드래그 중 → 기본 움직임 일시 정지, 드래그 해제 후 재개
- 탭 반응 재생 중 중복 탭 → 무시 (큐 없음)

---

## Claude Code 전용 워크플로우

- 병렬 feature 작업 시 `git worktree` 활용, 각 worktree는 독립 feature 브랜치 사용
- 작업 완료 결과는 `PROGRESS.md`에 기록
- 릴리즈노트 작성 시 릴리즈노트 스킬 사용
