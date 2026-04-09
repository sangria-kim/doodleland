# 그림놀이터 앱 개발 진행 현황

## 📊 전체 진행률

| 카테고리 | 진행률 | 상태 |
|---------|-------|------|
| **아키텍처 & 공통 인프라** | 95% | ✅ |
| **캡처 & 저장 플로우** | 100% | ✅ |
| **라이브러리** | 85% | 🔄 |
| **스테이지 & 애니메이션** | 96% | 🔄 |
| **배경 제거 (규칙 기반)** | 100% | ✅ |
| **테스트 & 배포** | 96% | 🔄 |

---

## 🚧 현재 상태

**진행 중인 작업**
- 없음

**해결 필요한 블로킹 이슈**
- 없음

**다음 예정 작업**
- 실제 기기(저사양/고사양) 기준 BGM/SFX 볼륨 밸런싱 및 기기별 청감 점검
- 교체된 숲/하늘/바다 배경 이미지 색감 및 가독성 QA
- 실제 기기 샘플(회색/유색 용지) 기준 outline-guided threshold 미세 튜닝
- 저장 전 화면과 실제 투명 결과 표시 흐름 정합화
- confetti 강도(수량/수명) 저사양 기기 기준 미세 튜닝
---

## 📝 커밋 로그

### 2026-04-09

#### fix: keep back button on stage background selection
- 배경 바꾸기 진입을 스택 push로 처리해 배경 고르기 화면에서 `push`된 경로로 복귀할 수 있도록 정리했습니다.
- 배경 선택 화면에 AppBar 뒤로가기 버튼을 추가하고 pop 우선 복귀 흐름을 적용해 라우트 스택이 사라지는 문제를 해결했습니다.
- 버그 수정 반영으로 `versionName`을 `1.10.4`, `versionCode`를 `11004`로 상향했습니다.

#### fix: refine auto framing padding
- 자동 인식 결과 기반 초기 크롭 프레임이 다리 같은 하단/끝부분에서 잘리는 케이스를 줄이기 위해 프레이밍 여유 계산을 조정했습니다.
- 좌우 패딩 계수를 `6%`에서 `5%`, 상하 패딩 계수를 `10%`에서 `8%`, 하단 바이어스를 `2%`에서 `1.5%`로 완화했습니다.
- 버그 수정 반영으로 `versionName`을 `1.10.3`, `versionCode`를 `11003`으로 상향했습니다.

#### fix: normalize stage drag movement direction
- 데굴데굴 포함 모든 무대 모션에서 손가락 움직임과 반대되는 드래그 반전을 제거했습니다.
- 드래그 시작/갱신 좌표 변환을 전역 좌표 기반으로 정규화해 회전 상태와 관계없는 일관된 조작을 보장했습니다.
- 버그 수정 기준으로 `versionName`을 `1.10.2`, `versionCode`를 `11002`로 상향했습니다.

#### fix: keep stage bgm playing during interaction sfx
- 캐릭터 등장/제거 효과음 재생 시 BGM이 중단되던 문제를 수정해 배경음이 지속 재생되도록 안정화했습니다.
- BGM/SFX 재생 컨텍스트를 분리해 효과음이 배경음 위에 자연스럽게 겹쳐 출력되도록 조정했습니다.
- 숲/푸른 하늘/바다 배경 이미지를 최신 자산으로 교체해 무대 시각 품질을 함께 개선했습니다.

### 2026-04-08

#### feat: add stage background music and interaction sound effects
- 무대 배경이 숲/푸른 하늘/바다일 때 각각 전용 BGM이 재생되고, 별빛 밤/캔디 랜드 배경에서는 무음으로 유지되도록 추가했습니다.
- 캐릭터가 무대에 추가될 때 `spawn pop`, 제거가 시작될 때 `remove swoosh` 효과음을 재생해 상호작용 피드백을 강화했습니다.
- 라우트 연동으로 `/stage` 계열 화면에서만 BGM이 유지되고, 홈/캡처 등으로 이동하면 자동 정지되도록 정리했습니다.

#### ui: add soft exit animation for stage object removal
- 길게 누른 캐릭터를 즉시 삭제하지 않고 `removing` 상태로 전환한 뒤, `1000ms` 퇴장 애니메이션 완료 시점에 최종 제거하도록 변경했습니다.
- 제거 시작 프레임에서 stage/object motion과 드래그 입력을 즉시 중단해, 기존 이동과 퇴장 연출이 섞이지 않도록 정리했습니다.
- 퇴장 연출 강도를 조정해 상향 이동/축소/페이드와 함께 방향 기반 드리프트/틸트가 보이도록 개선했습니다.

#### docs: synchronize stage entrance and removal behavior specs
- 기능 명세/화면 흐름/화면 브리프/기술 설계/QA 체크리스트 문서에 soft exit 제거 규칙과 값 기준을 반영했습니다.
- 등장 애니메이션과 confetti 설명을 현재 구현 값(`scale 0.5 -> 1.5 -> 1.0`, `800ms`) 기준으로 동기화했습니다.
- 아키텍처 문서에 `PlacedCharacter.removalState` 모델 필드를 추가해 코드와 문서 간 불일치를 해소했습니다.

### 2026-04-07

#### feat: add stage entrance bounce and confetti feedback
- 새 그림이 무대에 추가될 때만 1회 재생되는 입장 애니메이션을 scale `0.5 -> 1.5 -> 1.0` 시퀀스(`800ms`)로 적용했습니다.
- 그림 상단보다 더 위에서 시작해 그림 하단 방향으로 낙하하는 confetti 파티클 레이어를 추가하고 `800ms` 수명으로 정리했습니다.
- 기능 명세/기술 설계/QA 체크리스트 문서를 신규 피드백 정책에 맞춰 함께 동기화했습니다.

### 2026-04-06

#### fix: preserve stage motion direction after drag drop
- 무대에서 캐릭터를 드래그 후 놓을 때 진행 방향이 항상 좌->우로 초기화되던 문제를 수정했습니다.
- 드롭 이후에는 기존 진행 방향과 속도를 유지한 채 이동을 재개하도록 Stage Motion 엔진 동작을 조정했습니다.
- 관련 테스트와 Stage Motion 문서를 함께 갱신하고 버전을 `1.8.2+10802`로 상향했습니다.

#### fix: improve outline-guided background removal for colored drawings
- 진한 외곽선이 있는 그림에서 내부 색 영역은 유지하고 외부 배경은 강하게 제거하도록 outline-guided 마스크 경로를 추가했습니다.
- 초기 aggressive 제거 기반에 제한 복원과 선 보호를 결합해 배경 잔여를 줄이면서 색 손실을 완화했습니다.
- 관련 배경 제거 테스트를 보강하고 버전을 `1.8.1+10801`로 상향했습니다.

#### feat: add phase1 drawing detection and background removal upgrades
- Capture 단계 자동 인식 모듈을 추가하고 DetectionResult 정규화 좌표를 Crop 초기 박스에 연동했습니다.
- BackgroundRemover를 인터페이스 중심으로 재구성하고 선화/채색/경계 보존 union 마스크와 회색 종이 억제 후처리를 적용했습니다.
- 관련 테스트를 보강하고 버전을 `1.8.0+10800`으로 상향했습니다.

### 2026-04-05

#### docs: define phase1 capture detection and removal architecture
- 자동 인식/배경 제거 개선의 Phase1 범위와 제외 항목을 문서 기준으로 확정했습니다.
- Capture→Crop 전달 방식, 정규화 bbox 좌표계, 인터페이스 기반 모듈 경계를 명시했습니다.
- Phase2는 참고 항목으로만 유지하고 이번 구현에서 제외한다는 원칙을 문서에 반영했습니다.

### 2026-04-03

#### feat: redesign character placement flow with motion preview
- 무대 캐릭터 추가 흐름을 풀스크린 2단계 구조로 개편하고 그림 고르기/움직임 고르기 레이아웃을 정리했습니다.
- 움직임 카드 선택 시 좌측 선택 이미지를 실시간 프리뷰로 반영하고 우측 카드는 아이콘·이름·선택 상태 중심으로 단순화했습니다.
- 모션 프리셋을 4종으로 통일하고 아키텍처/기능 명세/화면 브리프 문서를 동일 기준으로 동기화했습니다.

### 2026-04-02

#### feat: maximize crop editor workspace and simplify controls
- 크롭 화면을 상단 헤더/하단 메뉴 없이 이미지 중심 레이아웃으로 재구성하고 우측 세로 비율 패널과 오버레이 액션 구조로 정리했습니다.
- 비율 버튼과 상단 액션 버튼의 크기·정렬을 통일하고, 패널 대비/간격을 조정해 편집 집중도를 높였습니다.
- 초기화 확인 다이얼로그를 텍스트 액션 기반 모달로 개선하고 버전을 `1.7.0+10700`으로 상향했습니다.

#### feat: separate object and stage motion systems
- 무대 캐릭터 움직임을 object motion과 stage motion으로 분리하고, 경계/방향/드래그 상태를 전담하는 stage motion engine 계층을 추가했습니다.
- 스테이지 이동 규칙을 좌우 왕복 기반으로 재정의하고, 속도는 생성 시 `0.1~0.4` 범위 랜덤 1회 부여 후 유지되도록 조정했습니다.
- 반전 렌더링을 제거하고 이미지 절반이 화면 밖으로 이동한 뒤 방향 전환되도록 경계를 보정했으며 관련 기능/아키텍처/기술 설계/QA 문서를 함께 갱신했습니다.

#### feat: add first-pass child drawing background removal
- 외부 배경 제거를 우선하는 1차 배경 제거 파이프라인을 앱 저장 경로에 연결했습니다.
- 종이 배경 샘플링, stroke reinforce, edge flood fill 기반 마스크 생성으로 안정적인 투명 PNG 생성을 우선 적용했습니다.
- 디버그 산출물 저장과 버전 반영을 함께 정리해 실제 기기 검증 기준을 `1.5.0+10500`으로 맞췄습니다.

### 2026-04-01

#### docs: update progress merge logging policy
- `PROGRESS` 갱신을 squash merge 후 별도 커밋으로 남기지 않고, 최종 squash merge commit에 함께 포함하도록 정책을 변경했습니다.
- 커밋 로그 형식에서 commit id를 제거하고, 실제 변경 내용만 남기는 방식으로 운영 기준을 단순화했습니다.
- 기존 로그에서도 commit id 표기를 제거하고, 진행 상황 기록과 직접 관련 없는 보정용 로그는 정리했습니다.

### 2026-03-31

#### feat: update image crop experience
- `crop_your_image` 기반으로 크롭 화면을 앱 내부 편집 UI로 전환하고 자유/고정 비율 동작을 분리했습니다.
- 가로모드와 태블릿에서 이미지 영역을 더 크게 확보하도록 상단/하단 컨트롤 구조를 다시 설계했습니다.
- 크롭 전용 테스트를 추가하고 Android APK 빌드와 실기기 설치까지 확인하며 버전을 `1.4.0+10400`으로 상향했습니다.

### 2026-03-30

#### ui: refresh home capture stage navigation surfaces
- 메인 화면의 버튼 배치·크기·단색 스타일을 반응형 기준으로 정렬해 일관된 상단 UI 톤을 맞췄습니다.
- 그림 가져오기, 배경 선택, 놀이 화면 버튼/카운트 오버레이를 동일한 동작 감지 기준으로 정렬해 상호작용 통일감을 확보했습니다.
- 배경 카드 비율과 무대 상단 컨트롤 자동 숨김 기능을 추가 반영하고 앱 버전을 `1.3.1+10301`으로 상향했습니다.

#### ui: align capture entry screen with app bar navigation
- 그림 가져오기 화면에 AppBar를 추가해 뒤로가기 동선을 명확히 노출했습니다.
- 배경 고르기 화면과 동일한 상단 구조를 맞춰 화면 간 내비게이션 일관성을 정비했습니다.
- 기존 캡처 선택/크롭/미리보기 처리 플로우는 건드리지 않고 진입 구조만 정리했습니다.

### 2026-03-29

#### ui: streamline stage setup and character selection flow
- 배경 고르기와 그림 가져오기 화면에서 중복 안내 문구를 제거해 타이틀 중심 구조로 정리했습니다.
- 캐릭터 선택 시트를 반응형 2단계 레이아웃으로 재구성하고 모션 선택 카드를 설명형 UI로 개선했습니다.
- 그림 선택 카드의 비율과 제목 영역을 조정해 overflow 없이 안정적으로 보이도록 다듬고 버전을 `1.3.0+10300`으로 상향했습니다.

#### fix: keep capture flow in landscape fullscreen mode
- 갤러리 선택 뒤 네이티브 크롭 화면이 세로로 전환되던 문제를 Android 크롭 액티비티 방향 설정으로 수정했습니다.
- 홈, 그림 가져오기, 크롭, 미리보기, 배경 고르기, 무대 화면의 전체화면 정책을 앱 루트에서 공통 관리하도록 리팩터링했습니다.
- 저장 후 메인 복귀 시 전체화면이 풀리던 문제를 정리하고 버전을 `1.2.5+10205`로 상향했습니다.

#### fix: preserve transparent character rendering across capture and stage
- 잘라낸 캐릭터의 투명 경계와 썸네일 비율을 유지해 저장 후에도 사각 배경이 남지 않도록 수정했습니다.
- 무대에서는 투명 PNG만 직접 렌더링하도록 바꿔 배치된 그림에 카드 프레임과 이름 라벨이 보이지 않게 정리했습니다.
- 배경 제거, 저장 썸네일, 무대 배치 흐름 테스트를 보강하고 버전을 `1.2.4+10204`로 상향했습니다.

### 2026-03-28

#### ui: expand stage to full screen immersive
- 배경과 캐릭터 이동 가능한 무대 영역을 시스템 바까지 포함한 전체화면으로 확장했습니다.
- 상단 앱바를 제거하고 오버레이 헤더를 유지해 조작은 그대로 둔 채 화면 경계 충돌을 해소했습니다.
- `stage_screen`에서 상태바/네비게이션바 숨김을 적용해 무대 체감 영역을 최대로 확보했습니다.

#### fix: restore stage background rendering with jpg assets
- 무대 배경 선택 후 이미지가 보이지 않던 문제를 새 `bg_*.jpg` 자산 경로로 정리해 해결했습니다.
- 배경 선택 카드에서 내부 기준값(`groundY`) 노출을 제거해 사용자 라벨을 간결하게 정리했습니다.
- 스쿼시 머지 기준 PATCH 규칙에 맞춰 버전을 `1.2.3+10203`으로 상향했습니다.

#### feat: add stage character motion playback
- 캐릭터 배치 후 선택한 모션 프리셋이 무대에서 자동으로 재생되도록 애니메이션 경로를 연결했습니다.
- 드래그/탭 인터랙션 시 모션을 일시 정지했다가 종료 후 자연스럽게 다시 재개되도록 반응 흐름을 정리했습니다.
- 무대 상호작용 상태 변화가 애니메이션과 충돌하지 않도록 업데이트 경로를 정합했습니다.

#### fix: prevent stage placement ticker overflow crash
- 무대 캐릭터 배치 시 다중 AnimationController 사용으로 발생하던 ticker provider 크래시를 수정했습니다.
- 배치 위젯의 ticker provider 믹스인을 다중 컨트롤러에 맞게 조정해 캐릭터 추가/탭 애니메이션이 안정적으로 동작하도록 개선했습니다.

### 2026-03-27

#### fix: recover crop rerun action state
- 크롭 재실행 버튼이 바쁠 때 비활성화된 채 멈추는 현상을 수정했습니다.
- 로컬 진행 플래그를 UI 상태로 바인딩해 버튼/프로그레스가 즉시 동기화되도록 변경했습니다.
- 크롭 화면 진입 시 실행 타이밍을 다음 프레임으로 미루어 화면 전환 직후 안정적으로 동작하게 했습니다.

#### fix: prevent crop action lock on rerun
- 크롭 재실행 시 내부 플래그가 잠겨 버튼이 먹통이 되는 경로를 제거해 동일 동작을 반복 수행할 수 있도록 했습니다.
- 진행 중·완료 상태에 따라 버튼 활성 조건을 명확히 분기하고, 크롭 실패 시 복구 경로를 보여주도록 처리했습니다.
- 크롭 경로 존재성 검증을 강화해 잘못된 호출에서 즉시 복귀하도록 안정성을 개선했습니다.

#### fix: clarify crop rerun recovery path
- 크롭 재실행 성공/실패 종료 처리에서 불필요한 분기를 제거하고 성공 시 피드백 정리를 일관되게 수행했습니다.
- 소스 파일 존재성 검사 후 동일 경로에서 동작하도록 정리해 크롭 루틴의 종료 동선을 단순화했습니다.

#### ui: fix overflow-safe responsive capture, playground, and stage screens
- 소형/저소형 화면에서 하단 버튼이 화면 밖으로 넘어가는 오버플로우를 방지하기 위해 반응형 크기 계산을 통일했습니다.
- 그림 가져오기, 미리보기, 크롭, 홈, 캐릭터 선택 시트의 버튼·간격·폰트 크기를 가용 높이 기준으로 동적으로 축소했습니다.
- `SingleChildScrollView` 없이 화면 안에서 레이아웃이 수렴하도록 조정해 터치 영역과 시각적 일관성을 유지했습니다.

#### chore: merge 4-2 performance and release readiness
- 배경 제거/썸네일 파이프라인의 무거운 픽셀 연산을 Isolate로 이전해 성능 점검을 강화했습니다.
- `flutter analyze` 경고 정리와 `flutter test` 통과 상태를 기준으로 반영했습니다.
- `1.2.2+10202` 버전 반영과 Android 릴리즈 체크리스트 문서를 함께 정리했습니다.

#### test: add 4-1 quality coverage set
- 배경 제거, 저장/삭제 유스케이스, 무대 상태 전이 테스트를 4-1 계획대로 통합했습니다.
- 통합된 테스트 커버리지를 기준으로 회귀 탐지 범위를 확대하고 실패 시나리오 처리도 검증했습니다.
- patch 반영으로 `1.2.1+10201` 버전 라벨을 반영했습니다.

#### feat: complete stage character interaction controls
- 무대 캐릭터에 탭 반응(중복 탭 방지), 드래그 이동, 길게 눌러 제거를 연결해 기본 상호작용 루프를 완성했습니다.
- 이동 중 zIndex 조정으로 터치된 캐릭터를 전면으로 올려 레이어 충돌을 자연스럽게 해결했습니다.
- 상태 전이(이동/제거/레이어) 유닛 테스트를 함께 반영해 회귀 탐지를 강화했습니다.

#### feat: add staged character entry baseline and animation
- 캐릭터 추가 시 선택된 배경의 groundY 기준 위치로 배치 좌표를 계산해 시작점을 정교화했습니다.
- 무대 진입 애니메이션을 scale 0→1.2→1.0 시퀀스로 적용해 기본 등장 루프 동작을 추가했습니다.

#### fix: wrap widget test app with provider scope
- 기본 위젯 테스트에서 ProviderScope 미설정으로 앱 렌더링이 중단되던 예외를 해결했습니다.
- 회귀 테스트 실행 경로에서 DoodlelandApp을 ProviderScope로 감싸 안정적으로 통합 테스트가 종료되도록 조정했습니다.

#### fix: restore stage motion and placement references
- `stage_screen`에서 누락된 모델 임포트로 인한 컴파일 실패를 수정해 무대 렌더링 경로의 타입 해석을 복구했습니다.
- 캐릭터 선택 모달의 motion 상태 참조를 현재 타입에 맞춰 정정해 화면 진입 시 런타임 예외 가능성을 줄였습니다.

#### feat: add stage background selection and start guard
- 배경 선택 화면(5종/groundY 메타)과 홈의 놀이 시작 가이드를 연결해 시작 플로우를 완성했습니다.
- 선택된 배경을 무대 상태로 반영하고 변경 액션까지 포함해 무대 진입 UX를 이어붙였습니다.
- 배경 선택·가드·상태 반영 흐름을 확인하는 위젯/유닛 테스트를 함께 추가했습니다.

#### feat: connect library to stage placement flow
- 라이브러리 바텀시트에서 캐릭터를 선택하고 움직임 프리셋을 지정해 무대에 배치할 수 있습니다.
- 조회/삭제 상태 반영과 배치 상한(10개) 제어를 함께 반영해 2-3 연동 플로우를 완결했습니다.

#### feat: implement rule-based background removal pipeline
- 캡처 저장 플로우에 규칙 기반 배경 제거를 적용해 투명 PNG를 자동으로 생성합니다.
- 모서리 샘플링 마스크를 edge flood fill와 노이즈 컴포넌트 정제로 보완해 경계 정확도를 개선합니다.
- 저장 완료 시 투명도 비율 기반 품질 경고를 반환해 사용자 대응이 필요한 케이스를 안내합니다.

#### feat: add capture source to preview image pipeline
- 카메라/갤러리 선택 화면부터 크롭과 미리보기, 저장/재촬영 흐름을 한 번에 완료했습니다.
- 저장, 다시 찍기, 하나 더 저장하기 액션으로 캡처-라이브러리 연결 흐름을 사용자 입장에서 완결했습니다.
- 저장 유스케이스 단위 테스트를 추가해 결과물 저장 동선을 검증 가능한 구조로 정리했습니다.

#### feat: add common infra for character persistence and permissions
- 공통 인프라로 Drift 스키마/DAO, 캐릭터 저장 경로, 권한 실패 정규화 유틸을 반영했습니다.
- `save_character` 저장 흐름에 바로 연결 가능한 저장소 계층과 테스트를 추가해 라이브러리 기반을 정비했습니다.
- v1.1.0(+10100)으로 버전/빌드코드 규칙에 맞춰 기능 추가 반영용 버전을 상향했습니다.

#### docs: add implementation plan and sync progress state
- 구현 계획 문서를 프로젝트 기준 상태와 정합되게 통합해 이후 단계 실행 가이드를 완성했습니다.
- 전체 진행률과 다음 작업 항목을 plan 기준에 맞춰 재정렬해 공수 산정의 기준점을 마련했습니다.
- PROGRESS 운영 포맷을 실제 수행 흐름에 맞게 정비했습니다.

#### docs: update branch policy for document-only changes
- 문서 작업의 예외 규칙을 규정해 코드/문서 작업의 브랜치 정책 분기를 명확히 했습니다.
- 운영 문서 수정 절차를 정리해 협업 시 브랜치 변경 충돌 가능성을 줄였습니다.
- 정책 변경 내용을 기준 문서에 반영해 즉시 적용 가능한 형태로 확정했습니다.

#### feat: materialize feature-first app skeleton
- feature-first 디렉터리와 캡처/라이브러리/스테이지 모듈 골격을 연결해 라우팅 대상 화면을 실제 클래스로 정리했습니다.
- 홈 화면 테마 토큰을 도입하고 공통 버튼/간격 기준을 적용해 기본 UX 스타일을 정비했습니다.
- 기본 배경 5종 자산을 추가해 배경 선택 기능 구현의 리소스 선행 조건을 준비했습니다.

#### docs: update merge workflow with progress sync rule
- feature -> main 병합 후 PROGRESS 갱신 규칙을 AGENTS 공통 지침에 반영
- PROGRESS_GUIDE 기준으로 기록 포맷을 따르도록 머지 후 절차를 명확화

#### docs: PROGRESS 및 PROGRESS guide 추가
- 프로젝트 진행률 추적용 PROGRESS 문서와 업데이트 가이드를 신규 추가
- main 커밋 중심으로 진행 현황을 기록하는 운영 기준을 수립

#### chore: align doodleland app bootstrap and remove duplicate project
- 중복 생성된 프로젝트 구조를 정리하고 단일 앱 루트 기준으로 정돈
- 앱 부트스트랩, 라우팅, 기본 화면 구성 파일을 현 구조에 맞춰 정렬

#### init doodlealand project
- Flutter 프로젝트 생성 및 의존성 추가 (Riverpod, Drift, ML Kit)
- Clean Architecture 폴더 구조 구성
- 기본 앱 설정 (테마, 의존성 주입) 완료
