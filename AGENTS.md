# AGENTS.md
> Claude Code / Codex CLI 공통 지침 — Single Source of Truth
> 브랜치·커밋·버전 규칙 및 Flutter 개발 컨벤션을 포함합니다.

---

## [1] 브랜치 정책 (Branch Strategy)

- 기본 브랜치는 `main`이다.
- `main` 브랜치는 항상 안정적이고 빌드 가능한 상태를 유지한다.
- `main` 브랜치에는 직접 기능 개발을 하지 않는다.
- 모든 개발 작업은 `feature` 브랜치에서 수행한다.

### [1-1] 작업 시작 전 Branch Out 규칙

작업 시작 절차:
1. 현재 브랜치 확인: `git branch --show-current`
2. `main`인 경우 → 작업 중단, feature 브랜치 생성 후 진행
   ```bash
   git checkout -b feature/<description> main
   ```
3. 생성한 브랜치에서 이후 모든 작업을 진행한다.

브랜치 네이밍 규칙:
- `feature/{기능명-간단설명}`
  - 예: `feature/capture-background-removal`, `feature/stage-motion-preset`, `feature/library-grid`

### [1-2] 브랜치 단일 책임 원칙

- 하나의 브랜치는 하나의 목적만 가진다.
- 성격이 다른 변경이 필요할 경우, 브랜치를 분리한다.

---

## [2] 개발 및 병합(Merge) 전략

- `feature` 브랜치에서 기능 단위로 개발 및 커밋한다.
- 기능이 완료되면 `main` 브랜치로 **Squash Merge**한다.
- 병합 후 `feature` 브랜치는 삭제한다.

```bash
git merge --squash feature/xxx
git commit -m "feat: 의미 있는 단일 변경 설명"
```

### [2-1] 병합 전 main 동기화 규칙

- 병합 전 반드시 `main`의 최신 상태를 기준으로 한다.
- 충돌 해결은 `feature` 브랜치에서 완료한 후 병합한다.

### [2-2] 병합 후 진행 현황 문서 갱신 규칙

- `feature` 브랜치를 `main`에 Squash Merge하여 새로운 커밋이 추가되면, 즉시 `docs/PROGRESS.md`를 갱신한다.
- 갱신 형식과 항목은 반드시 `docs/PROGRESS_GUIDE.md`를 기준으로 따른다.
- 이 규칙은 사람이 수행한 머지와 Agent가 수행/지원한 머지 모두 동일하게 적용한다.

---

## [3] 커밋 메시지 컨벤션

모든 커밋 메시지는 **제목(subject) + 본문(body)** 구조로 작성한다.
한 줄 커밋 메시지는 허용하지 않는다.

### 커밋 타입

| 타입 | 설명 |
|------|------|
| `feat:` | 새로운 기능 추가 |
| `fix:` | 버그 수정 |
| `ui:` | UI 변경 및 레이아웃 수정 |
| `refactor:` | 리팩토링 (기능 변화 없음) |
| `docs:` | 문서 추가/수정 |
| `chore:` | 설정, 빌드, 기타 |

### 템플릿

```
<type>: <subject>

<body 2-3줄>
```

### 제목 작성 규칙
- 변경의 결과가 무엇인지 드러나야 한다.
- 명령형 동사 사용 (add, update, fix, remove 등)
- 구현 세부사항(변수명, 함수명 등) 포함 금지

### 본문 작성 규칙
- 반드시 작성, 2~3줄 이내
- 왜 이 변경이 필요한지 / 변경 범위 / 사용자 관점 영향 중 최소 하나 포함
- 문장 형태로 작성 (단순 키워드 나열 금지)

### 예시

```
feat: add motion preset selection on stage

무대에서 캐릭터 추가 시 움직임 프리셋을 선택할 수 있도록 UI를 추가합니다.
floating / bouncing / gliding / rolling / spinning 5종을 AnimationController로 구현합니다.
```

```
fix: resolve background removal crash on low-memory devices

저사양 기기에서 Dart 픽셀 처리 중 OOM이 발생하던 문제를 수정합니다.
입력 이미지를 Isolate에서 1500px로 리사이즈한 후 처리하도록 개선했습니다.
```

---

## [3-1] 버전 관리 (Semantic Versioning)

- 형식: `MAJOR.MINOR.PATCH`
- 버전 증가는 `main`에 **Squash Merge로 들어가는 단일 커밋 기준**으로만 수행한다.
- `feature` 브랜치의 개별 커밋에서는 버전을 올리지 않는다.

| 커밋 타입 | 버전 증가 |
|-----------|-----------|
| `fix:` | PATCH (`1.0.0` → `1.0.1`) |
| `feat:` | MINOR (`1.0.0` → `1.1.0`) |
| 호환성/정책/데이터 의미 변경 | MAJOR (`1.0.0` → `2.0.0`) — `feat:` 사용 + 본문에 영향 명시 |

### versionCode 규칙 (pubspec.yaml build-number 기준)

```
build-number = major*10000 + minor*100 + patch
예: 1.0.0 → 10000,  1.1.0 → 10100,  1.1.3 → 10103
```

---

## [4] 작업 시작 전 체크리스트

코드 작업 시작 전 반드시 확인:
- [ ] 현재 브랜치가 `main`이 아닌가?
- [ ] 작업 목적에 맞는 `feature/xxx` 브랜치인가?
- [ ] 브랜치명이 네이밍 규칙을 따르는가?
- [ ] 이번 작업이 `main`에 Squash Merge될 때 올릴 버전(SEMVER)을 결정했는가?

**`main` 브랜치 감지 시 동작:**
1. 작업 중단
2. "현재 main 브랜치입니다. feature 브랜치 생성이 필요합니다" 안내
3. 브랜치 생성 명령 제안 후 대기

---

## [5] AI 응답 공통 규칙

- `main` 브랜치에서 직접 작업하는 흐름을 제안하지 않는다.
- `feature` 브랜치 없이 커밋하는 예시는 제공하지 않는다.
- 코드 변경 제안 시 **커밋 메시지 예시를 항상 함께 제공**한다.
- `feature -> main` 머지 완료 안내 시 `docs/PROGRESS_GUIDE.md` 기준의 `docs/PROGRESS.md` 업데이트 단계를 함께 안내한다.
- 규칙과 충돌하는 요청이 들어온 경우, 먼저 규칙 위반을 명시한다.

---

## [6] Flutter / Dart 개발 컨벤션

### 6-1. 언어 & 스타일
- Dart 공식 스타일 가이드 준수 (2 space indent)
- 파일명: `snake_case.dart`
- 클래스명: `PascalCase`
- 변수·함수명: `camelCase`
- 상수: `lowerCamelCase` (Dart 관례)

### 6-2. 아키텍처 레이어 규칙

```
UI (Screen / Widget)
    ↓ 의존
ViewModel (StateNotifier / AsyncNotifier)
    ↓ 의존
UseCase (비즈니스 로직, 선택적)
    ↓ 의존
Repository (추상 클래스 인터페이스)
    ↓ 구현
DataSource (Drift DB / File System / Image Processing)
```

- UI는 ViewModel만 의존한다.
- Repository는 반드시 추상 클래스 + 구현 클래스로 분리한다.
- `core/` 모듈은 `feature/`에 의존하지 않는다.

### 6-3. 상태관리 (Riverpod)

```dart
// ✅ Repository Provider (싱글턴)
final characterRepositoryProvider = Provider(
  (ref) => CharacterRepository(ref.watch(appDatabaseProvider)),
);

// ✅ ViewModel — StateNotifierProvider
final libraryViewModelProvider =
    StateNotifierProvider<LibraryViewModel, LibraryState>(
  (ref) => LibraryViewModel(ref.watch(getCharactersUseCaseProvider)),
);
```

- `ProviderScope`는 `main.dart` `runApp` 최상위에서 한 번만 선언한다.
- `ref.watch`는 build/notifier 내부에서만, `ref.read`는 이벤트 핸들러에서 사용한다.

### 6-4. 비동기 처리
- 배경 제거 등 픽셀 처리는 반드시 `compute()` 또는 `Isolate.run()`으로 메인 스레드 분리한다.
- 파일 I/O는 `async/await` + `try-catch`로 처리한다.

### 6-5. 금지 목록 (Do NOT Use)

```
❌ Provider 패키지 (구버전) → flutter_riverpod 사용
❌ Feature 레벨 setState → ViewModel 상태로 관리
❌ 파일 경로 하드코딩 → path_provider 사용
❌ 고해상도 이미지 리사이즈 없이 처리 → 1500px 이하로 먼저 축소
❌ ML Kit / 서버 AI (v1 금지) → 규칙 기반 배경 제거만 사용
```

### 6-6. 빌드 명령어

```bash
flutter pub get               # 패키지 설치
flutter run                   # 실기기/에뮬레이터 실행
flutter build apk             # Android APK
flutter build ios             # iOS 빌드
flutter test                  # 전체 유닛 테스트
flutter analyze               # 정적 분석
dart fix --apply              # 자동 수정
```
