# 4-2. 성능/분석/출시 점검 체크리스트

## 1) Android 릴리즈 빌드
- 실행 명령: `flutter build apk`
- 결과: `build/app/outputs/flutter-apk/app-release.apk`
- 상태: PASS (2026-03-27)
- 비고: Gradle에서 source/target 8 관련 경고가 출력되나 빌드 결과물 생성은 정상

## 2) 품질 점검(요구사항 반영)
- `flutter analyze` 실행 및 경고 수치 관리
  - 목표: 경고 0건
  - 조치: 테스트 코드의 미사용 import 정리로 경고 0건 달성
  - 잔여: 기존 코드의 info는 선행 이슈로 별도 분리 관리
- `flutter test` 실행
  - 결과: PASS

## 3) 릴리즈 전 점검 항목
- APK 산출물 존재 확인: `build/app/outputs/flutter-apk/app-release.apk`
- 앱 버전 코드/네이밍 확인: 기존 값 유지(4-2는 성능/점검 작업, 기능 증분 없음)
- 배포 전 실행 체크: 4-1/4-2 범위 테스트 및 분석 기준 점검
