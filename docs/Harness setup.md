## 목표

DoodleLand 프로젝트에 다음 4개 역할 기반의 자동화 하네스를 구축한다.
	•	planner
	•	implementer
	•	reviewer
	•	fixer

최종 목표는 다음과 같은 자동 루프이다:
task 입력
→ planner
→ implementer
→ test/build
→ reviewer
→ fixer
→ 재검증
→ 결과 보고
→ (사용자 실기기 테스트)

## 전체 구축 순서 (중요)

다음 순서를 반드시 지켜서 진행한다.
1단계: 공통 규칙 문서 작성
2단계: 역할별 프롬프트 작성
3단계: 리뷰 출력 포맷 정의
4단계: 품질 게이트 정의
5단계: 실행 루프(하네스) 구현
6단계: 단계별 적용 및 확장

### 공통 규칙 문서 작성

📄 생성 파일
/docs/harness/PROJECT_RULES.md

포함 내용
1. Domain Model
	•	Stage
	•	StageObject
	•	Motion
	•	Drag Interaction
	•	Particle
	•	Animation Lifecycle

2. State Machine
spawning → entering → active → removing → disposed
각 상태 정의:
	•	진입 조건
	•	허용 동작
	•	금지 동작

3. Interaction Rules
	•	drag vs motion
	•	drag vs removing
	•	entering vs input
	•	removing vs input

4. Animation Rules
	•	animation은 반드시 state 기반
	•	Future.delayed 최소화
	•	animation completion 기준 상태 전환

5. Implementation Constraints
	•	요청 범위 외 수정 금지
	•	불필요한 리팩터링 금지
	•	상태 변경 시 영향 범위 명시

6. Review Guidelines
	•	상태 전이 누락
	•	입력 충돌
	•	animation 타이밍 문제
	•	중복 호출
	•	cleanup 누락
	•	particle lifecycle

7. Testing Guidelines
	•	build 통과
	•	analyze/lint 통과
	•	state transition 검증
	•	interaction 충돌 테스트

### 역할별 프롬프트 작성

폴더 구조
/docs/harness/prompts/
  planner.md
  implementer.md
  reviewer.md
  fixer.md

📌 planner.md

역할:
	•	요구사항 해석
	•	영향 범위 분석
	•	상태 변화 정의
	•	구현 순서 제안
	•	테스트 포인트 제시

금지:
	•	코드 수정

⸻

📌 implementer.md

역할:
	•	planner 결과 기반 구현
	•	최소 범위 수정
	•	코드 일관성 유지
	•	build/lint 확인

금지:
	•	과도한 리팩터링

⸻

📌 reviewer.md

역할:
	•	diff 기반 검토
	•	결함 탐지

검토 기준:
	•	상태 전이
	•	입력 충돌
	•	타이밍 문제
	•	cleanup 누락

출력:
	•	must_fix
	•	should_fix

금지:
	•	스타일 리뷰

⸻

📌 fixer.md

역할:
	•	reviewer 결과 반영
	•	must_fix 우선 처리
	•	최소 수정 원칙


### 리뷰 출력 포맷 정의
파일 
/docs/harness/review_schema.json

구조
{
  "summary": "",
  "must_fix": [
    {
      "file": "",
      "issue": "",
      "reason": "",
      "suggested_fix": ""
    }
  ],
  "should_fix": [],
  "test_gaps": [],
  "risk": "low|medium|high"
}

### 품질 게이트 정의

실행 명령 정의

예 (Flutter 기준):
	•	format
	•	analyze
	•	test
	•	build

규칙
	•	하나라도 실패하면 다음 단계 진행 금지
	•	fixer 실행 후 반드시 재검증

### 실행 루프 (하네스) 구현
파일
/scripts/harness_runner.py

기본 흐름
task 입력

→ planner 실행
→ implementer 실행

→ build / lint / test 실행

→ reviewer 실행

if must_fix:
    → fixer 실행
    → 재검증

→ 최종 결과 출력

종료 조건
	•	must_fix == 0
	•	최대 수정 2회
	•	동일 오류 반복 시 종료
	•	build 실패 지속 시 중단


### 단계별 적용 전략

1단계

planner + implementer만 사용

2단계

reviewer 추가

3단계

fixer 추가

4단계

자동 루프 완성

### 📌 작업 유형별 적용 전략

작은 작업
	•	implementer만 사용

중간 작업
	•	implementer → reviewer → fixer

큰 작업
	•	planner → reviewer → implementer → fixer

###  중요 운영 원칙

1. 하네스는 점진적으로 확장한다

처음부터 완벽하게 만들지 않는다

2. reviewer는 “결함 탐지기”다

개선 제안자가 아니다

3. implementer는 “최소 수정자”다

리팩터러가 아니다

4. fixer는 “정밀 수정자”다

재구현자가 아니다


### 최종 목표

사용자는 다음만 수행하면 된다:
	1.	task 입력
	2.	결과 확인
	3.	실기기 테스트
	4.	commit / merge

### 시작

위 순서대로 다음 작업을 수행하라:
	1.	PROJECT_RULES.md 생성
	2.	prompts 폴더 생성 및 각 역할 문서 작성
	3.	review_schema.json 생성
	4.	harness_runner.py 생성

각 단계는 완료 후 다음 단계로 진행한다.
:::