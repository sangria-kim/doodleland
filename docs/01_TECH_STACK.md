# 01. 기술 스택 결정서

## 프로젝트명
그림놀이터

## 현재 기준 버전
- 앱 버전: `1.3.0+10300`
- Dart SDK constraint: `^3.11.3`

## 프레임워크 / 플랫폼
- **Flutter** (Dart)
- 타깃 플랫폼: Android, iOS
- 화면 방향: 가로 고정
- Android 시스템 UI: `immersiveSticky` 전체화면

## 상태관리 / 라우팅 / 로컬 데이터
- 상태관리: **Riverpod** (`flutter_riverpod`)
- 라우팅: **GoRouter** (`go_router`)
- 로컬 DB: **Drift** + `sqlite3_flutter_libs`
- 파일 저장 경로: **path_provider**
- 권한 처리: **permission_handler**

## 이미지 입력 / 처리

### 이미지 입력
- `image_picker`
- 카메라: `Permission.camera`
- 갤러리: `Permission.photos`
- 현재 옵션: `maxWidth: 1920`, `imageQuality: 90`

### 이미지 크롭
- `image_cropper`
- 현재 구현은 네이티브 크롭 화면을 즉시 호출하는 방식입니다.
- 자동 감지 크롭 박스 추천 기능은 현재 구현되어 있지 않습니다.
- 사용 가능한 비율 프리셋:
  - `original`
  - `3x2`
  - `4x3`
  - `16x9`

### 배경 제거
- `image` 패키지 기반 규칙형 파이프라인
- 서버 호출, AI/ML 모델, ML Kit는 현재 사용하지 않습니다.
- 처리 순서:
  1. 입력 이미지를 읽고 최대 `1500px`로 축소
  2. 가장자리 샘플링으로 배경색 추정
  3. 색상 거리 threshold로 전경 후보 분리
  4. 가장자리 flood fill로 배경 누수 제거
  5. connected component 기반 노이즈 제거
  6. 투명 PNG 저장
- 품질 경고는 투명 비율이 `5% 미만` 또는 `95% 초과`일 때 반환합니다.
- 현재는 미리보기 진입 시점이 아니라 저장 버튼을 눌렀을 때 배경 제거가 실행됩니다.

### 비동기 처리
- 배경 제거는 `Isolate.run()`으로 분리 실행합니다.
- 썸네일 PNG 생성도 `Isolate.run()`으로 분리 실행합니다.

## 무대 렌더링
- 현재 구현은 `CustomPainter`가 아니라 **위젯 기반 `Stack` + `Transform` + `AnimationController`** 입니다.
- 캐릭터별로 개별 `AnimationController`를 사용해 등장, 탭 반응, 기본 모션, 제거(soft exit)를 제어합니다.
- `stage_painter.dart`는 현재 placeholder 상태이며 실제 렌더링 경로에 연결되어 있지 않습니다.

## 로컬 저장 구조

### DB
- `characters` 테이블 1개
- 저장 컬럼:
  - `id`
  - `name`
  - `originalImagePath`
  - `transparentImagePath`
  - `thumbnailPath`
  - `width`
  - `height`
  - `createdAt`

### 파일 저장
- 기준 디렉터리: `getApplicationDocumentsDirectory()`
- 루트 폴더: `characters/`
- 하위 폴더:
  - `characters/original/`
  - `characters/transparent/`
  - `characters/thumbnail/`
- 파일명은 `{kind}_{timestamp}.png` 형식으로 생성합니다.

## 현재 v1 구현 범위
- 규칙 기반 배경 제거
- 로컬 캐릭터 저장/조회/삭제
- 배경 5종 선택
- 캐릭터 5종 모션 선택
- 탭 반응, 드래그 이동, 길게 눌러 제거
- 무대 최대 10개 배치

## 현재 미구현 / 보류 항목
- 저장 전 투명 결과 미리보기
- 씬 영속 저장 / 불러오기
- AI 기반 그림 분류, 모션 추천
- 카테고리별 터치 반응
- `image_processor.dart` 실사용 구현
