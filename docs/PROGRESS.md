# 그림놀이터 앱 개발 진행 현황

## 📊 전체 진행률

| 카테고리 | 진행률 | 상태 |
|---------|-------|------|
| **아키텍처 & 기초 설정** | 50% | ✅ |
| **UI 컴포넌트** | 50% | 🔄 |
| **드로잉 엔진** | 0% | 🔄 |
| **배경 제거 (규칙 기반)** | 100% | ✅ |
| **애니메이션 & 스테이지** | 75% | 🔄 |
| **데이터베이스 (Drift)** | 100% | ✅ |
| **테스트 & 배포** | 100% | ✅ |

---

## 🚧 현재 상태

**진행 중인 작업**
- 없음

**해결 필요한 블로킹 이슈**
- 없음

**다음 예정 작업**
- 다음 목표는 다음 단계 요구사항 확정 시 추가 계획을 수립합니다.

---

## 📝 커밋 로그

### 2026-03-28

#### ui: expand stage to full screen immersive (`commit: 3c4f8d2`)
- 배경과 캐릭터 이동 가능한 무대 영역을 시스템 바까지 포함한 전체화면으로 확장했습니다.
- 상단 앱바를 제거하고 오버레이 헤더를 유지해 조작은 그대로 둔 채 화면 경계 충돌을 해소했습니다.
- `stage_screen`에서 상태바/네비게이션바 숨김을 적용해 무대 체감 영역을 최대로 확보했습니다.

#### fix: restore stage background rendering with jpg assets (`commit: cfd7c79`)
- 무대 배경 선택 후 이미지가 보이지 않던 문제를 새 `bg_*.jpg` 자산 경로로 정리해 해결했습니다.
- 배경 선택 카드에서 내부 기준값(`groundY`) 노출을 제거해 사용자 라벨을 간결하게 정리했습니다.
- 스쿼시 머지 기준 PATCH 규칙에 맞춰 버전을 `1.2.3+10203`으로 상향했습니다.

#### feat: add stage character motion playback (`commit: 2829e26`)
- 캐릭터 배치 후 선택한 모션 프리셋이 무대에서 자동으로 재생되도록 애니메이션 경로를 연결했습니다.
- 드래그/탭 인터랙션 시 모션을 일시 정지했다가 종료 후 자연스럽게 다시 재개되도록 반응 흐름을 정리했습니다.
- 무대 상호작용 상태 변화가 애니메이션과 충돌하지 않도록 업데이트 경로를 정합했습니다.

#### fix: prevent stage placement ticker overflow crash (`commit: f062ded`)
- 무대 캐릭터 배치 시 다중 AnimationController 사용으로 발생하던 ticker provider 크래시를 수정했습니다.
- 배치 위젯의 ticker provider 믹스인을 다중 컨트롤러에 맞게 조정해 캐릭터 추가/탭 애니메이션이 안정적으로 동작하도록 개선했습니다.

### 2026-03-27

#### fix: recover crop rerun action state (`commit: c051a19`)
- 크롭 재실행 버튼이 바쁠 때 비활성화된 채 멈추는 현상을 수정했습니다.
- 로컬 진행 플래그를 UI 상태로 바인딩해 버튼/프로그레스가 즉시 동기화되도록 변경했습니다.
- 크롭 화면 진입 시 실행 타이밍을 다음 프레임으로 미루어 화면 전환 직후 안정적으로 동작하게 했습니다.

#### fix: prevent crop action lock on rerun (`commit: c812c79`)
- 크롭 재실행 시 내부 플래그가 잠겨 버튼이 먹통이 되는 경로를 제거해 동일 동작을 반복 수행할 수 있도록 했습니다.
- 진행 중·완료 상태에 따라 버튼 활성 조건을 명확히 분기하고, 크롭 실패 시 복구 경로를 보여주도록 처리했습니다.
- 크롭 경로 존재성 검증을 강화해 잘못된 호출에서 즉시 복귀하도록 안정성을 개선했습니다.

#### fix: clarify crop rerun recovery path (`commit: 913b0cd`)
- 크롭 재실행 성공/실패 종료 처리에서 불필요한 분기를 제거하고 성공 시 피드백 정리를 일관되게 수행했습니다.
- 소스 파일 존재성 검사 후 동일 경로에서 동작하도록 정리해 크롭 루틴의 종료 동선을 단순화했습니다.

#### ui: fix overflow-safe responsive capture, playground, and stage screens (`commit: a0a5bb8`)
- 소형/저소형 화면에서 하단 버튼이 화면 밖으로 넘어가는 오버플로우를 방지하기 위해 반응형 크기 계산을 통일했습니다.
- 그림 가져오기, 미리보기, 크롭, 홈, 캐릭터 선택 시트의 버튼·간격·폰트 크기를 가용 높이 기준으로 동적으로 축소했습니다.
- `SingleChildScrollView` 없이 화면 안에서 레이아웃이 수렴하도록 조정해 터치 영역과 시각적 일관성을 유지했습니다.

#### chore: merge 4-2 performance and release readiness (`commit: d450370`)
- 배경 제거/썸네일 파이프라인의 무거운 픽셀 연산을 Isolate로 이전해 성능 점검을 강화했습니다.
- `flutter analyze` 경고 정리와 `flutter test` 통과 상태를 기준으로 반영했습니다.
- `1.2.2+10202` 버전 반영과 Android 릴리즈 체크리스트 문서를 함께 정리했습니다.

#### test: add 4-1 quality coverage set (`commit: d5803af`)
- 배경 제거, 저장/삭제 유스케이스, 무대 상태 전이 테스트를 4-1 계획대로 통합했습니다.
- 통합된 테스트 커버리지를 기준으로 회귀 탐지 범위를 확대하고 실패 시나리오 처리도 검증했습니다.
- patch 반영으로 `1.2.1+10201` 버전 라벨을 반영했습니다.

#### feat: complete stage character interaction controls (`commit: c81f55b`)
- 무대 캐릭터에 탭 반응(중복 탭 방지), 드래그 이동, 길게 눌러 제거를 연결해 기본 상호작용 루프를 완성했습니다.
- 이동 중 zIndex 조정으로 터치된 캐릭터를 전면으로 올려 레이어 충돌을 자연스럽게 해결했습니다.
- 상태 전이(이동/제거/레이어) 유닛 테스트를 함께 반영해 회귀 탐지를 강화했습니다.

#### feat: add staged character entry baseline and animation (`commit: 16615be`)
- 캐릭터 추가 시 선택된 배경의 groundY 기준 위치로 배치 좌표를 계산해 시작점을 정교화했습니다.
- 무대 진입 애니메이션을 scale 0→1.2→1.0 시퀀스로 적용해 기본 등장 루프 동작을 추가했습니다.

#### fix: wrap widget test app with provider scope (`commit: 52929e1`)
- 기본 위젯 테스트에서 ProviderScope 미설정으로 앱 렌더링이 중단되던 예외를 해결했습니다.
- 회귀 테스트 실행 경로에서 DoodlelandApp을 ProviderScope로 감싸 안정적으로 통합 테스트가 종료되도록 조정했습니다.

#### fix: restore stage motion and placement references (`commit: 078febc`)
- `stage_screen`에서 누락된 모델 임포트로 인한 컴파일 실패를 수정해 무대 렌더링 경로의 타입 해석을 복구했습니다.
- 캐릭터 선택 모달의 motion 상태 참조를 현재 타입에 맞춰 정정해 화면 진입 시 런타임 예외 가능성을 줄였습니다.

#### feat: add stage background selection and start guard (`commit: 7a824ae`)
- 배경 선택 화면(5종/groundY 메타)과 홈의 놀이 시작 가이드를 연결해 시작 플로우를 완성했습니다.
- 선택된 배경을 무대 상태로 반영하고 변경 액션까지 포함해 무대 진입 UX를 이어붙였습니다.
- 배경 선택·가드·상태 반영 흐름을 확인하는 위젯/유닛 테스트를 함께 추가했습니다.

#### feat: connect library to stage placement flow (`commit: f8d959a`)
- 라이브러리 바텀시트에서 캐릭터를 선택하고 움직임 프리셋을 지정해 무대에 배치할 수 있습니다.
- 조회/삭제 상태 반영과 배치 상한(10개) 제어를 함께 반영해 2-3 연동 플로우를 완결했습니다.

#### feat: implement rule-based background removal pipeline (`commit: 587be8b`)
- 캡처 저장 플로우에 규칙 기반 배경 제거를 적용해 투명 PNG를 자동으로 생성합니다.
- 모서리 샘플링 마스크를 edge flood fill와 노이즈 컴포넌트 정제로 보완해 경계 정확도를 개선합니다.
- 저장 완료 시 투명도 비율 기반 품질 경고를 반환해 사용자 대응이 필요한 케이스를 안내합니다.

#### feat: add capture source to preview image pipeline (`commit: 950c5b3`)
- 카메라/갤러리 선택 화면부터 크롭과 미리보기, 저장/재촬영 흐름을 한 번에 완료했습니다.
- 저장, 다시 찍기, 하나 더 저장하기 액션으로 캡처-라이브러리 연결 흐름을 사용자 입장에서 완결했습니다.
- 저장 유스케이스 단위 테스트를 추가해 결과물 저장 동선을 검증 가능한 구조로 정리했습니다.

#### feat: add common infra for character persistence and permissions (`commit: f4f1322`)
- 공통 인프라로 Drift 스키마/DAO, 캐릭터 저장 경로, 권한 실패 정규화 유틸을 반영했습니다.
- `save_character` 저장 흐름에 바로 연결 가능한 저장소 계층과 테스트를 추가해 라이브러리 기반을 정비했습니다.
- v1.1.0(+10100)으로 버전/빌드코드 규칙에 맞춰 기능 추가 반영용 버전을 상향했습니다.

#### docs: fix missing merge history in progress log (`commit: 27839c4`)
- 누락된 커밋 기록 항목을 정합성 점검 후 보강했으며, 최신 main 히스토리 반영성을 회복했습니다.
- 문서 로그와 실제 커밋 목록의 동기화를 위해 `commit id` 순서를 최신 기준으로 정렬했습니다.
- 향후 추적 자동화를 위해 누락 탐지 기준을 재확인 가능한 상태로 정리했습니다.

#### docs: add implementation plan and sync progress state (`commit: 3641c9f`)
- 구현 계획 문서를 프로젝트 기준 상태와 정합되게 통합해 이후 단계 실행 가이드를 완성했습니다.
- 전체 진행률과 다음 작업 항목을 plan 기준에 맞춰 재정렬해 공수 산정의 기준점을 마련했습니다.
- PROGRESS 운영 포맷을 실제 수행 흐름에 맞게 정비했습니다.

#### docs: update branch policy for document-only changes (`commit: cc9cc5b`)
- 문서 작업의 예외 규칙을 규정해 코드/문서 작업의 브랜치 정책 분기를 명확히 했습니다.
- 운영 문서 수정 절차를 정리해 협업 시 브랜치 변경 충돌 가능성을 줄였습니다.
- 정책 변경 내용을 기준 문서에 반영해 즉시 적용 가능한 형태로 확정했습니다.

#### docs: sync progress docs with commit-id tracking (`commit: 8e24f09`)
- 커밋 추적 가시성을 높이기 위해 PROGRESS 로그에 commit id 중심 규격을 추가했습니다.
- 커밋 로그를 최신 상태 기준으로 유지하는 포맷을 정리하고 관리 기준을 통일했습니다.
- 추적 누락 위험을 줄이기 위한 문서 갱신 루틴을 구체화했습니다.

#### docs: log feature-first skeleton merge (`commit: dcadb81`)
- squash merge 후 AGENTS 규칙에 따라 1-1 적용 결과를 PROGRESS 진행률/현재 상태에 반영했습니다.
- 커밋 기준 이력의 최신성을 보장하도록 현재 작업 상태를 최신 순으로 갱신했습니다.
- 이어지는 기능 브랜치 계획(1-2) 진입점을 문맥상 명시했습니다.

#### feat: materialize feature-first app skeleton (`commit: 83e261e`)
- feature-first 디렉터리와 캡처/라이브러리/스테이지 모듈 골격을 연결해 라우팅 대상 화면을 실제 클래스로 정리했습니다.
- 홈 화면 테마 토큰을 도입하고 공통 버튼/간격 기준을 적용해 기본 UX 스타일을 정비했습니다.
- 기본 배경 5종 자산을 추가해 배경 선택 기능 구현의 리소스 선행 조건을 준비했습니다.

#### docs: update merge workflow with progress sync rule (`commit: 4f931b2`)
- feature -> main 병합 후 PROGRESS 갱신 규칙을 AGENTS 공통 지침에 반영
- PROGRESS_GUIDE 기준으로 기록 포맷을 따르도록 머지 후 절차를 명확화

#### docs: PROGRESS 및 PROGRESS guide 추가 (`commit: 4d671c4`)
- 프로젝트 진행률 추적용 PROGRESS 문서와 업데이트 가이드를 신규 추가
- main 커밋 중심으로 진행 현황을 기록하는 운영 기준을 수립

#### chore: align doodleland app bootstrap and remove duplicate project (`commit: 2557eb4`)
- 중복 생성된 프로젝트 구조를 정리하고 단일 앱 루트 기준으로 정돈
- 앱 부트스트랩, 라우팅, 기본 화면 구성 파일을 현 구조에 맞춰 정렬

#### init doodlealand project (`commit: cb8d451`)
- Flutter 프로젝트 생성 및 의존성 추가 (Riverpod, Drift, ML Kit)
- Clean Architecture 폴더 구조 구성
- 기본 앱 설정 (테마, 의존성 주입) 완료
