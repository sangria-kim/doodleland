# 01. 기술 스택 결정서

## 프로젝트명
아이 그림 인터랙티브 샌드박스 앱

## 프레임워크
- **Flutter** (Dart)
- 최소 버전: Flutter 3.24+ / Dart 3.5+
- 타깃 플랫폼: Android, iOS, iPad

## v1 / v2 범위 요약

### v1 (현재 범위)
- 배경 제거: **앱 내 처리**
- AI agent: **사용하지 않음**
- 그림 판별 / 모션 추천: **제외**
- 캐릭터 탭 반응: **공통 기본 동작 1종** (위로 통통 튀기)

### v2 (후속 확장)
- AI agent를 활용한 그림 판별
- AI 기반 모션 추천
- 카테고리별 / 상황별 세분화된 터치 동작

## 상태관리
- **Riverpod** (`flutter_riverpod`)
- 이유: Provider 대비 테스트 용이, 의존성 주입 내장, 비동기 상태 처리 편리

## 2D 무대 렌더링
- **1차 선택:** `CustomPainter` + `AnimationController`
  - 스프라이트 10개 이하의 단순 2D 배치에 충분
  - Flutter 내장이므로 추가 의존성 없음
- **대안 (복잡도 증가 시):** Flame 엔진
  - 게임루프, 스프라이트 시트, 충돌 감지가 필요해질 경우 전환 검토

## 이미지 처리

### 카메라 / 갤러리
- `image_picker` — 카메라 촬영 및 갤러리 접근

### 이미지 크롭
- `image_cropper` — 자유 직사각 크롭 지원, 네이티브 크롭 UI 제공

### 배경 제거
- **앱 내 규칙 기반 처리** (AI agent / 서버 호출 없음)
  - 방식: 배경색 추정 + threshold + edge flood fill + 간단한 노이즈 제거
  - 비용: 무료
  - 오프라인: 가능
  - 전제: 흰 종이 / 단일 그림 / 비교적 단순한 촬영 배경
  - 출력: 투명 배경 PNG
- **ML Kit Subject Segmentation 미채택 근거:**
  - 공식 지원이 Android 중심(Beta)이며, iOS 지원이 공식적으로 확인되지 않음
  - 사진 속 전경 피사체 분리 용도로 설계되어 흰 종이 위 2D 손그림 컷아웃과 입력 특성이 다름
  - unbundled model이라 첫 사용 시 모델 다운로드 필요 (오프라인 즉시 사용 불가)
  - v2에서 Android 한정 실험적 검토 가능하나 v1 기본 경로로는 부적합
- 처리 파이프라인:
  1. 크롭된 이미지 입력 (최대 1500×1500px로 리사이즈)
  2. 모서리 영역을 샘플링하여 배경색(흰색/단색) 추정
  3. 밝기/색상 유사도 threshold로 배경 후보 마스크 생성
  4. 가장자리에서 시작하는 flood fill로 외곽 배경 확장
  5. 작은 노이즈 제거 후 alpha 적용
  6. PNG 형식으로 저장
- **성능 기준:** 1000×1000px 이미지 기준 3초 이내 처리 목표
- **품질 검증:** 투명 영역이 전체의 95% 이상이거나 5% 미만이면 실패로 판단 → 사용자에게 재촬영 안내
- **촬영 가이드:** 흰 종이 위에 그린 그림을 밝은 조명 아래서 촬영하도록 안내 UI 제공

### 이미지 변환
- `image` (dart 패키지) — 픽셀 처리, PNG 인코딩, 썸네일 생성, 간단한 마스크 후처리
- **주의:** Dart 픽셀 조작은 네이티브 대비 느림. 고해상도 이미지는 반드시 리사이즈 후 처리

### 이미지 크기 정책
- **입력 최대 해상도:** 갤러리/카메라에서 가져온 이미지가 1500×1500px 초과 시 비율 유지하며 축소
- **배경 제거 처리 해상도:** 최대 1500×1500px
- **저장 원본:** 크롭 후 리사이즈된 이미지 (원본 고해상도는 보관하지 않음)
- **썸네일:** 200px (긴 변 기준)

## 로컬 저장
- **DB:** Drift (SQLite 래퍼) — 캐릭터 메타데이터 저장
- **파일:** 앱 내부 디렉토리 (`getApplicationDocumentsDirectory`)
  - 원본 크롭 이미지: `images/original/`
  - 투명 배경 이미지: `images/transparent/`
  - 썸네일: `images/thumbnail/`

## 화면 방향
- **가로 고정** (`landscape`)
- `SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])`

## 주요 패키지 요약

| 영역 | 패키지 | 용도 |
|------|--------|------|
| 상태관리 | `flutter_riverpod` | 전역 상태 관리 |
| 카메라/갤러리 | `image_picker` | 이미지 입력 |
| 크롭 | `image_cropper` | 자유 직사각 크롭 |
| 이미지처리 | `image` | 배경 제거 후처리, PNG 변환, 썸네일 생성 |
| DB | `drift` + `sqlite3_flutter_libs` | 로컬 메타데이터 저장 |
| 경로 | `path_provider` | 앱 내부 파일 경로 |
| 권한 | `permission_handler` | 카메라/갤러리 권한 요청 |

## 개발 환경
- IDE: Android Studio 또는 VS Code + Flutter 확장
- 테스트: 실기기 우선 (카메라/갤러리/터치 입력/큰 화면 확인)
- 빌드: `flutter build apk` (Android), `flutter build ios` (iOS)
- **참고:** v1 범위에는 AI 연동 및 서버 구성 없음

## 패키지 호환성 주의사항
- `image_cropper`: 네이티브 의존성(Android: uCrop, iOS: TOCropViewController) 존재. Flutter 3.24+와의 호환 버전을 프로젝트 초기에 확인할 것
- `image`: 픽셀 단위 조작 성능이 낮으므로 입력 이미지를 반드시 리사이즈 후 처리. Isolate 활용 검토
- `drift`: `sqlite3_flutter_libs`와 함께 사용. iOS에서는 시스템 SQLite를 사용하므로 별도 확인 불필요
