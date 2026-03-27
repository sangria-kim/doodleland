# 그림놀이터 구현 계획 (2026-03-27 기준)

## 0) 현재 상태 요약 (코드/문서 대조)
- 구현 완료: 앱 부트스트랩, 가로 고정, Riverpod `ProviderScope`, 홈 화면, 기본 라우팅 골격
- 미구현: capture/crop/preview 실제 기능, 배경 제거 파이프라인, Drift DB/Repository, 라이브러리 바텀시트, 무대/애니메이션/드래그
- 결론: MVP 기능은 대부분 착수 전이며, 현재 코드는 "초기 셸(shell)" 단계

## 1) 앱 골격을 MVP 구조로 확장

### 1-1. feature-first 디렉토리 및 라우팅 실체화
- Commit 단위 1: `refactor` — feature 폴더/파일 골격을 문서 구조와 일치하게 생성
- Commit 단위 2: `feat` — placeholder 라우트를 실제 화면 클래스(빈 상태 포함)로 교체
- Commit 단위 3: `ui` — 공통 테마/spacing/text style 토큰 정리 및 홈 화면 스타일 업데이트
- Commit 단위 4: `chore` — `assets/backgrounds/` 에 5종 배경 이미지(forest/sky/ocean/starry_night/candy_land) 추가 및 pubspec.yaml assets 등록

### 1-2. 공통 인프라 (DB/스토리지/권한) 기초 구성
- Commit 단위 1: `feat` — Drift `characters` 스키마 + DB provider + 기본 DAO 추가
- Commit 단위 2: `feat` — 파일 저장 경로 유틸(`original/transparent/thumbnail`) 구현
- Commit 단위 3: `feat` — 카메라/갤러리 권한 요청 유틸 및 실패 상태 처리 공통화

## 2) Capture to Library 파이프라인 완성

### 2-1. 캡처/크롭/미리보기 사용자 흐름 구현
- Commit 단위 1: `feat` — `/capture` 소스 선택 화면 + `image_picker` 연동
- Commit 단위 2: `feat` — `/capture/crop` 자유 직사각 크롭(`image_cropper`) 연동
- Commit 단위 3: `feat` — `/capture/preview` 결과 미리보기 + 처리 중 로딩 UI 구현; "저장하기" / "저장하고 하나 더!"(저장 후 소스 선택으로 이동) / "다시 찍기" 3-버튼 플로우 및 네비게이션 처리 포함

### 2-2. 규칙 기반 배경 제거 엔진 구현
- Commit 단위 1: `feat` — 리사이즈(최대 1500px), 모서리 샘플링, threshold 마스크 구현
- Commit 단위 2: `feat` — edge flood fill + 노이즈 제거 + PNG alpha 인코딩 구현
- Commit 단위 3: `fix` — 품질 검증(투명영역 5%/95%) 경고 로직 및 예외 케이스 보정

### 2-3. 라이브러리 저장/조회/삭제 구현
- Commit 단위 1: `feat` — 저장 유스케이스(파일 3종 + DB insert + 자동 이름 생성)
- Commit 단위 2: `feat` — 라이브러리 조회(usecase/viewmodel) 및 바텀시트 UI 구현; 빈 상태(캐릭터 0개) 안내 UI + "그림 만들기" 버튼(캡처 화면 이동) 포함
- Commit 단위 3: `feat` — 길게 누르기 삭제(DB + 파일 동시 삭제) 및 확인 다이얼로그

## 3) Stage 놀이 핵심 루프 구현

### 3-1. 배경 선택 및 무대 진입 흐름
- Commit 단위 1: `feat` — 배경 선택 화면(5개 기본 배경 + groundY 메타데이터) 구현
- Commit 단위 2: `feat` — 홈의 "놀이 시작" 가드(캐릭터 0개 시 캡처 유도) 구현
- Commit 단위 3: `feat` — 무대 진입 시 선택 배경 전달 및 교체 액션 연결

### 3-2. 캐릭터 배치와 움직임 프리셋
- Commit 단위 1: `feat` — `PlacedCharacter` 모델 + stage state/viewmodel 구현
- Commit 단위 2: `feat` — 캐릭터 추가 바텀시트(캐릭터 + motion preset 선택) 구현
- Commit 단위 3: `feat` — 등장 애니메이션(scale 0→1.2→1.0) 및 기본 루프 시작 연결; 등장 초기 위치를 선택 배경의 groundY 비율 기준으로 계산하는 로직 포함

### 3-3. 상호작용(탭/드래그/레이어/제거) 완성
- Commit 단위 1: `feat` — 탭 시 공통 `defaultBounce` 재생(중복 탭 무시 포함)
- Commit 단위 2: `feat` — 드래그 이동, 경계 제한, 드래그 중 pause/resume 구현
- Commit 단위 3: `feat` — zIndex 정렬, 길게 누르기 제거, 10개 제한/툴팁 처리; 무대 UI 버튼 자동 페이드아웃(일정 시간 터치 없을 시) 선택 구현

## 4) 안정화/테스트/릴리즈 준비

### 4-1. 테스트 및 품질 점검
- Commit 단위 1: `test` — 배경 제거 알고리즘 단위 테스트(샘플 이미지 기반)
- Commit 단위 2: `test` — 저장 유스케이스/삭제 플로우 테스트
- Commit 단위 3: `test` — stage 상태 전이(추가/탭/드래그/제거) 테스트

### 4-2. 성능/분석/출시 점검
- Commit 단위 1: `refactor` — 픽셀 처리 `Isolate.run()` 분리 및 프레임 드랍 완화
- Commit 단위 2: `chore` — `flutter analyze`, `flutter test` 기준 경고/실패 0건 달성
- Commit 단위 3: `chore` — Android 빌드 검증 + 릴리즈 체크리스트 문서화

## 5) 브랜치/머지/버전 운영 계획
- 원칙: 각 작은 주제(1-1, 1-2, 2-1...)를 독립 `feature/...` 브랜치로 수행
- 머지: `main`에 `git merge --squash feature/...`로 단일 커밋 반영
- 버전: main squash 커밋 기준으로 증가
  - `feat/ui` 중심 머지: MINOR 증가
  - `fix/refactor/chore/test` 중심 머지: PATCH 증가
- 머지 직후: `docs/PROGRESS.md`를 `docs/PROGRESS_GUIDE.md` 형식으로 즉시 갱신
