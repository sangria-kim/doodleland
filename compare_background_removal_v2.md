# compare_background_removal_v2

## Summary

- samples: 4
- output root: `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output`
- default recommendation: `Case D. Directional Gap Repair + Base`
- fallback recommendation: `Case A. Base + Adaptive Conditional Restore`
- optional high-quality mode: `Case F. Region-based Restore`
- strict target status: `no hybrid case met leakage <= 1% with meaningful interior gain`

## Samples

- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare/input/Screenshot_20260401_011628.png`
- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare/input/Screenshot_20260401_011648.png`
- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare/input/Screenshot_20260401_012845.png`
- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare/input/Screenshot_20260401_013036.png`

## Contact Sheets

- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/contact_sheets/Screenshot_20260401_011628_contact_sheet.png`
- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/contact_sheets/Screenshot_20260401_011648_contact_sheet.png`
- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/contact_sheets/Screenshot_20260401_012845_contact_sheet.png`
- `/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/contact_sheets/Screenshot_20260401_013036_contact_sheet.png`

## Comparison Table

| Case | Branch | Stroke | Interior | Leakage | Edge Cleanliness | Texture | Avg Time (ms) | Composite |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Base. Reinforced Stroke + Edge Flood Fill | `feature/bg-removal-flood-fill-edge` | 100.0% | 53.6% | 0.1% | 91.4% | 66.6% | 79 | 0.811 |
| Case A. Base + Adaptive Conditional Restore | `feature/bg-removal-v2-case-a-adaptive-restore` | 100.0% | 53.6% | 0.1% | 91.4% | 66.6% | 193 | 0.806 |
| Case B. Base + Contour Interior Conditional Restore | `feature/bg-removal-v2-case-b-contour-restore` | 100.0% | 53.6% | 0.1% | 91.4% | 66.6% | 212 | 0.805 |
| Case C. Base + Dual Restore Voting | `feature/bg-removal-v2-case-c-dual-voting` | 100.0% | 53.6% | 0.1% | 91.4% | 66.6% | 244 | 0.805 |
| Case D. Directional Gap Repair + Base | `feature/bg-removal-v2-case-d-gap-repair` | 100.0% | 53.6% | 0.1% | 91.3% | 66.6% | 106 | 0.809 |
| Case E. Background Model Corrected Base | `feature/bg-removal-v2-case-e-background-model` | 100.0% | 43.9% | 2.2% | 95.7% | 60.3% | 109 | 0.781 |
| Case F. Region-based Restore | `feature/bg-removal-v2-case-f-region-restore` | 100.0% | 66.4% | 4.7% | 89.0% | 79.1% | 293 | 0.833 |

## Improvement vs Base

| Case | Interior Δ | Leakage Δ | Edge Δ | Texture Δ | Result |
| --- | ---: | ---: | ---: | ---: | --- |
| Case A. Base + Adaptive Conditional Restore | +0.0% | +0.0% | +0.0% | +0.0% | 누수 안정 |
| Case B. Base + Contour Interior Conditional Restore | +0.0% | +0.0% | +0.0% | +0.0% | 누수 안정 |
| Case C. Base + Dual Restore Voting | +0.0% | +0.0% | +0.0% | +0.0% | 누수 안정 |
| Case D. Directional Gap Repair + Base | +0.0% | +0.0% | -0.0% | +0.0% | 누수 안정 |
| Case E. Background Model Corrected Base | -9.8% | +2.1% | +4.4% | -6.3% | trade-off |
| Case F. Region-based Restore | +12.8% | +4.6% | -2.3% | +12.5% | 내부 보존 개선 |

## Case Analysis

### Case A. Base + Adaptive Conditional Restore

- 장점: 배경 누수가 1% 이하로 유지됨
- 단점: baseline보다 느림

### Case B. Base + Contour Interior Conditional Restore

- 장점: 배경 누수가 1% 이하로 유지됨
- 단점: baseline보다 느림

### Case C. Base + Dual Restore Voting

- 장점: 배경 누수가 1% 이하로 유지됨
- 단점: baseline보다 느림

### Case D. Directional Gap Repair + Base

- 장점: 배경 누수가 1% 이하로 유지됨, 질감 보존이 좋아짐
- 단점: baseline보다 느림, 경계가 다소 거칠어짐

### Case E. Background Model Corrected Base

- 장점: 경계가 더 안정적임
- 단점: 배경 누수가 목표치를 넘김, baseline보다 느림, 질감 보존이 baseline보다 약함

### Case F. Region-based Restore

- 장점: baseline 대비 내부 보존이 개선됨, 질감 보존이 좋아짐
- 단점: 배경 누수가 목표치를 넘김, baseline보다 느림, 경계가 다소 거칠어짐

## Parameters

### Base. Reinforced Stroke + Edge Flood Fill

- branch: `feature/bg-removal-flood-fill-edge`
- description: v1 기본 방식인 method 4를 그대로 다시 계산한 baseline입니다.
- parameter: base mask: reinforced stroke + edge flood fill
- parameter: gap repair: off
- parameter: background normalization: off

### Case A. Base + Adaptive Conditional Restore

- branch: `feature/bg-removal-v2-case-a-adaptive-restore`
- description: method 4 base 위에 adaptive threshold 후보를 영역 단위로 선별 복원합니다.
- parameter: candidate source: method 2 foreground only
- parameter: reject border-connected regions
- parameter: require area, variance, stroke support

### Case B. Base + Contour Interior Conditional Restore

- branch: `feature/bg-removal-v2-case-b-contour-restore`
- description: method 5의 내부 후보 중 닫힌 contour와 질감 지원이 있는 영역만 복원합니다.
- parameter: candidate source: method 5 extra foreground
- parameter: require contour interior or stroke proximity
- parameter: exclude large uniform white regions

### Case C. Base + Dual Restore Voting

- branch: `feature/bg-removal-v2-case-c-dual-voting`
- description: adaptive / contour 후보를 함께 보고 조건 2개 이상을 만족하는 영역만 복원합니다.
- parameter: candidate source: method 2 + method 5
- parameter: minimum votes: 2 of adaptive, contour, base-edge, variance, contour interior
- parameter: background leakage penalty: strict

### Case D. Directional Gap Repair + Base

- branch: `feature/bg-removal-v2-case-d-gap-repair`
- description: method 4 이전에 짧은 간격의 endpoint를 방향성 기준으로 연결해 base 자체를 보강합니다.
- parameter: endpoint gap distance: 18px
- parameter: endpoint angle delta: 34deg
- parameter: base mask: reinforced stroke + edge flood fill

### Case E. Background Model Corrected Base

- branch: `feature/bg-removal-v2-case-e-background-model`
- description: 가장자리 종이 샘플로 조명 그라디언트를 보정한 뒤 method 4를 수행합니다.
- parameter: edge paper sampling: multi-side median
- parameter: illumination normalize: on
- parameter: base mask: reinforced stroke + edge flood fill

### Case F. Region-based Restore

- branch: `feature/bg-removal-v2-case-f-region-restore`
- description: adaptive / contour 추가 영역을 feature 기반 rule classifier로 복원 여부를 결정합니다.
- parameter: candidate source: method 2 or method 5 extra regions
- parameter: features: area, border-touch, brightness, variance, stroke proximity
- parameter: rule-based restore classifier

## Output Paths

### Base. Reinforced Stroke + Edge Flood Fill

- `Screenshot_20260401_011628`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_011628.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_011628_preview.png`
- `Screenshot_20260401_011648`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_011648.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_011648_preview.png`
- `Screenshot_20260401_012845`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_012845.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_012845_preview.png`
- `Screenshot_20260401_013036`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_013036.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/base_method4/Screenshot_20260401_013036_preview.png`

### Case A. Base + Adaptive Conditional Restore

- `Screenshot_20260401_011628`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_011628.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_011628_preview.png`
- `Screenshot_20260401_011648`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_011648.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_011648_preview.png`
- `Screenshot_20260401_012845`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_012845.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_012845_preview.png`
- `Screenshot_20260401_013036`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_013036.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_a_adaptive_restore/Screenshot_20260401_013036_preview.png`

### Case B. Base + Contour Interior Conditional Restore

- `Screenshot_20260401_011628`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_011628.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_011628_preview.png`
- `Screenshot_20260401_011648`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_011648.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_011648_preview.png`
- `Screenshot_20260401_012845`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_012845.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_012845_preview.png`
- `Screenshot_20260401_013036`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_013036.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_b_contour_restore/Screenshot_20260401_013036_preview.png`

### Case C. Base + Dual Restore Voting

- `Screenshot_20260401_011628`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_011628.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_011628_preview.png`
- `Screenshot_20260401_011648`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_011648.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_011648_preview.png`
- `Screenshot_20260401_012845`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_012845.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_012845_preview.png`
- `Screenshot_20260401_013036`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_013036.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_c_dual_restore_voting/Screenshot_20260401_013036_preview.png`

### Case D. Directional Gap Repair + Base

- `Screenshot_20260401_011628`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_011628.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_011628_preview.png`
- `Screenshot_20260401_011648`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_011648.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_011648_preview.png`
- `Screenshot_20260401_012845`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_012845.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_012845_preview.png`
- `Screenshot_20260401_013036`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_013036.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_d_gap_repair_base/Screenshot_20260401_013036_preview.png`

### Case E. Background Model Corrected Base

- `Screenshot_20260401_011628`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_011628.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_011628_preview.png`
- `Screenshot_20260401_011648`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_011648.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_011648_preview.png`
- `Screenshot_20260401_012845`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_012845.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_012845_preview.png`
- `Screenshot_20260401_013036`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_013036.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_e_background_model/Screenshot_20260401_013036_preview.png`

### Case F. Region-based Restore

- `Screenshot_20260401_011628`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_011628.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_011628_preview.png`
- `Screenshot_20260401_011648`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_011648.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_011648_preview.png`
- `Screenshot_20260401_012845`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_012845.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_012845_preview.png`
- `Screenshot_20260401_013036`: `masked=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_013036.png`, `preview=/Users/sangjeongkim/dev/doodleland/experiments/background_removal_compare_v2/output/case_f_region_classifier/Screenshot_20260401_013036_preview.png`

## Recommendation

default는 `Case D. Directional Gap Repair + Base`입니다. 배경 누수 1% 근처를 유지하는 후보 중 내부 보존과 전체 안정성이 가장 높은 케이스를 선택했습니다.

fallback은 `Case A. Base + Adaptive Conditional Restore`입니다. 기본값보다 처리 속도나 노이즈 패턴이 다른 대안으로 두어 샘플 편차를 흡수하도록 추천합니다.

optional high-quality mode는 `Case F. Region-based Restore`입니다. 속도보다 내부 복원과 질감 보존을 우선할 때 사용하는 옵션입니다.

이번 샘플셋에서는 `배경 누수 <= 1%`와 `method 4 대비 의미 있는 내부 보존 개선`을 동시에 만족한 하이브리드 케이스는 없었습니다.

## Android First / iOS Reuse

Android 우선 구조에서는 Dart `image` 기반으로 규칙 기반 마스크 생성과 복원 규칙을 검증하고, iOS 확장 시에도 동일한 단계 정의를 유지한 채 구현만 Swift/C++/OpenCV로 치환할 수 있습니다.

재사용 가능한 처리 단계:
- multi-edge paper color sampling
- illumination normalization
- adaptive / contour / reinforced flood fill base mask generation
- endpoint detection and directional gap repair
- region feature extraction
- rule-based restore decision
- mask compositing, contact sheet rendering, markdown report generation



