#!/usr/bin/env python3
"""DoodleLand Automation Harness Runner

4역할 기반 자동 루프: planner → implementer → 품질 게이트 → reviewer → fixer → 재검증

Usage:
    python scripts/harness_runner.py --agent claude --task "캐릭터 탭 시 사운드 재생 추가"
    python scripts/harness_runner.py --agent codex --task "설명" --steps planner,implementer
    python scripts/harness_runner.py --agent claude --task "설명" --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ─── 상수 ────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent
HARNESS_DIR = PROJECT_ROOT / "docs" / "harness"
PROMPTS_DIR = HARNESS_DIR / "prompts"
HISTORY_FILE = HARNESS_DIR / "harness_history.jsonl"

ALL_STEPS = ["planner", "implementer", "reviewer", "fixer"]

MAX_FIX_ROUNDS_DEFAULT = 2

QUALITY_GATES = [
    {
        "name": "format",
        "command": ["dart", "format", "--set-exit-if-changed", "lib/", "test/"],
        "fix_command": ["dart", "format", "lib/", "test/"],
        "auto_fixable": True,
    },
    {
        "name": "analyze",
        "command": ["flutter", "analyze"],
        "auto_fixable": False,
    },
    {
        "name": "test",
        "command": ["flutter", "test"],
        "auto_fixable": False,
    },
]


# ─── 실행 이력 ────────────────────────────────────────────────


class HarnessHistory:
    """하네스 실행 이력을 추적하고 JSONL 파일에 기록한다."""

    def __init__(self, agent: str, task: str, dry_run: bool = False):
        self.record = {
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "agent": agent,
            "task": task,
            "dry_run": dry_run,
            "roles": [],
            "quality_gates": [],
            "result": None,
        }

    def log_role(self, role: str, status: str, detail: Optional[str] = None):
        """역할 실행 결과를 기록한다. status: success / fail / dry-run"""
        entry = {
            "role": role,
            "status": status,
            "timestamp": datetime.now().isoformat(timespec="seconds"),
        }
        if detail:
            entry["detail"] = detail
        self.record["roles"].append(entry)

    def log_quality_gate(self, gate_name: str, passed: bool, auto_fixed: bool = False):
        """품질 게이트 결과를 기록한다."""
        self.record["quality_gates"].append({
            "gate": gate_name,
            "passed": passed,
            "auto_fixed": auto_fixed,
        })

    def set_result(self, status: str, must_fix: int = 0, should_fix: int = 0):
        """최종 결과를 기록한다. status: success / fail / aborted"""
        self.record["result"] = {
            "status": status,
            "must_fix": must_fix,
            "should_fix": should_fix,
        }

    def save(self):
        """이력을 JSONL 파일에 추가한다."""
        HISTORY_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(HISTORY_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(self.record, ensure_ascii=False) + "\n")
        print(f"\n📝 이력 저장: {HISTORY_FILE}")


# ─── 에이전트 CLI 매핑 ───────────────────────────────────────


class AgentType(Enum):
    CLAUDE = "claude"
    CODEX = "codex"


def build_agent_command(agent: AgentType, prompt: str) -> list[str]:
    """에이전트별 CLI 명령을 생성한다."""
    if agent == AgentType.CLAUDE:
        return ["claude", "-p", prompt, "--output-format", "text"]
    elif agent == AgentType.CODEX:
        return ["codex", "exec", "--full-auto", prompt]
    else:
        raise ValueError(f"Unknown agent: {agent}")


# ─── 유틸리티 ─────────────────────────────────────────────────


def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def run_command(
    cmd: list[str], cwd: Path | None = None, capture: bool = True
) -> subprocess.CompletedProcess:
    """명령을 실행하고 결과를 반환한다."""
    print(f"  $ {' '.join(cmd)}")
    return subprocess.run(
        cmd,
        cwd=cwd or PROJECT_ROOT,
        capture_output=capture,
        text=True,
        timeout=600,
    )


def extract_json_from_output(output: str) -> dict | None:
    """에이전트 출력에서 JSON 블록을 추출한다."""
    # ```json ... ``` 블록 추출
    match = re.search(r"```json\s*\n(.*?)\n\s*```", output, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass

    # 순수 JSON 시도
    try:
        return json.loads(output.strip())
    except json.JSONDecodeError:
        pass

    return None


def get_git_diff() -> str:
    """현재 작업 디렉토리의 git diff를 반환한다."""
    result = run_command(["git", "diff", "HEAD"])
    return result.stdout if result.returncode == 0 else ""


# ─── 품질 게이트 ──────────────────────────────────────────────


def run_quality_gates() -> tuple[bool, list[str]]:
    """품질 게이트를 순서대로 실행한다. (성공 여부, 실패 목록) 반환."""
    failures = []
    for gate in QUALITY_GATES:
        result = run_command(gate["command"])
        if result.returncode != 0:
            if gate.get("auto_fixable") and gate.get("fix_command"):
                print(f"  ⚠ {gate['name']} 실패 — 자동 수정 시도...")
                run_command(gate["fix_command"])
                # 재확인
                result2 = run_command(gate["command"])
                if result2.returncode != 0:
                    failures.append(gate["name"])
                    print(f"  ✗ {gate['name']} 자동 수정 후에도 실패")
                else:
                    print(f"  ✓ {gate['name']} 자동 수정 성공")
            else:
                failures.append(gate["name"])
                print(f"  ✗ {gate['name']} 실패")
                if result.stderr:
                    print(f"    {result.stderr[:500]}")
        else:
            print(f"  ✓ {gate['name']} 통과")

    return len(failures) == 0, failures


# ─── 역할 실행 ────────────────────────────────────────────────


def run_role(
    agent: AgentType,
    role: str,
    task_context: str,
    dry_run: bool = False,
) -> str:
    """역할별 프롬프트를 조합하여 에이전트를 실행하고 출력을 반환한다."""
    prompt_path = PROMPTS_DIR / f"{role}.md"
    if not prompt_path.exists():
        print(f"  ✗ 프롬프트 파일 없음: {prompt_path}")
        sys.exit(1)

    role_prompt = read_file(prompt_path)
    rules = read_file(HARNESS_DIR / "PROJECT_RULES.md")

    full_prompt = (
        f"{role_prompt}\n\n"
        f"---\n\n"
        f"## PROJECT_RULES (참조)\n\n{rules}\n\n"
        f"---\n\n"
        f"## Task Context\n\n{task_context}"
    )

    cmd = build_agent_command(agent, full_prompt)

    if dry_run:
        print(f"\n[DRY-RUN] {role} 명령:")
        print(f"  agent: {agent.value}")
        print(f"  prompt length: {len(full_prompt)} chars")
        print(f"  command: {cmd[0]} ... (prompt omitted)")
        return f"[dry-run: {role} output placeholder]"

    print(f"\n{'='*60}")
    print(f"▶ {role.upper()} 실행 중...")
    print(f"{'='*60}")

    result = run_command(cmd)

    if result.returncode != 0:
        print(f"  ✗ {role} 실행 실패 (exit code: {result.returncode})")
        if result.stderr:
            print(f"    {result.stderr[:500]}")
        sys.exit(1)

    output = result.stdout
    print(f"  ✓ {role} 완료 ({len(output)} chars)")
    return output


def check_same_issues(prev_issues: list[dict], curr_issues: list[dict]) -> bool:
    """이전/현재 must_fix를 비교하여 동일 이슈 반복 여부를 판단한다."""
    if not prev_issues or not curr_issues:
        return False

    prev_keys = {(i.get("file", ""), i.get("issue", "")) for i in prev_issues}
    curr_keys = {(i.get("file", ""), i.get("issue", "")) for i in curr_issues}
    overlap = prev_keys & curr_keys
    return len(overlap) > 0 and len(overlap) >= len(curr_keys)


# ─── 메인 루프 ────────────────────────────────────────────────


def run_harness(
    agent: AgentType,
    task: str,
    steps: list[str] | None = None,
    max_fix_rounds: int = MAX_FIX_ROUNDS_DEFAULT,
    dry_run: bool = False,
):
    """하네스 메인 루프를 실행한다."""
    active_steps = steps or ALL_STEPS
    history = HarnessHistory(agent=agent.value, task=task, dry_run=dry_run)

    print(f"\n{'#'*60}")
    print(f"# DoodleLand Harness Runner")
    print(f"# Agent: {agent.value}")
    print(f"# Steps: {', '.join(active_steps)}")
    print(f"# Task: {task[:80]}{'...' if len(task) > 80 else ''}")
    print(f"{'#'*60}")

    context = task

    # ── 1. Planner ──
    if "planner" in active_steps:
        planner_output = run_role(agent, "planner", context, dry_run)
        history.log_role("planner", "dry-run" if dry_run else "success")
        context = f"## Planner Output\n\n{planner_output}\n\n## Original Task\n\n{task}"

        if active_steps == ["planner"]:
            print("\n📋 Planner 결과:")
            print(planner_output)
            history.set_result("success")
            history.save()
            return

    # ── 2. Implementer ──
    if "implementer" in active_steps:
        implementer_output = run_role(agent, "implementer", context, dry_run)
        history.log_role("implementer", "dry-run" if dry_run else "success")

        if not dry_run:
            # 품질 게이트
            print("\n── 품질 게이트 (implementer 후) ──")
            passed, failures = run_quality_gates()
            _log_gate_results(history, passed, failures)
            if not passed:
                print(f"\n  ⚠ 게이트 실패: {', '.join(failures)}")
                print("  → implementer에게 오류 전달 후 재시도...")
                retry_context = (
                    f"{context}\n\n"
                    f"## Quality Gate Failures\n\n"
                    f"다음 품질 게이트가 실패했습니다: {', '.join(failures)}\n"
                    f"실패를 수정하세요."
                )
                implementer_output = run_role(agent, "implementer", retry_context)
                history.log_role("implementer", "success", detail="retry after gate failure")

                print("\n── 품질 게이트 재실행 ──")
                passed2, failures2 = run_quality_gates()
                _log_gate_results(history, passed2, failures2)
                if not passed2:
                    print(f"\n  ✗ 재시도 후에도 게이트 실패: {', '.join(failures2)}")
                    print("  → 하네스를 중단합니다.")
                    history.set_result("aborted")
                    history.save()
                    sys.exit(1)

    # ── 3. Reviewer ──
    if "reviewer" not in active_steps:
        print("\n✅ 하네스 완료 (reviewer 미포함)")
        history.set_result("success")
        history.save()
        return

    diff = get_git_diff() if not dry_run else "[dry-run diff]"
    reviewer_context = f"## Git Diff\n\n```diff\n{diff}\n```\n\n## Original Task\n\n{task}"
    reviewer_output = run_role(agent, "reviewer", reviewer_context, dry_run)
    history.log_role("reviewer", "dry-run" if dry_run else "success")

    if dry_run:
        print("\n✅ [DRY-RUN] 하네스 완료")
        history.set_result("success")
        history.save()
        return

    review_result = extract_json_from_output(reviewer_output)
    if review_result is None:
        print("\n  ⚠ reviewer 출력에서 JSON을 추출할 수 없습니다.")
        print("  Raw output (first 500 chars):")
        print(f"  {reviewer_output[:500]}")
        history.log_role("reviewer", "fail", detail="JSON parse error")
        history.set_result("aborted")
        history.save()
        return

    must_fix = review_result.get("must_fix", [])
    should_fix = review_result.get("should_fix", [])
    risk = review_result.get("risk", "unknown")

    print(f"\n── 리뷰 결과 ──")
    print(f"  Summary: {review_result.get('summary', 'N/A')}")
    print(f"  Risk: {risk}")
    print(f"  must_fix: {len(must_fix)}")
    print(f"  should_fix: {len(should_fix)}")

    # ── 4. Fix 루프 ──
    if "fixer" not in active_steps or not must_fix:
        if not must_fix:
            print("\n✅ must_fix 없음 — 하네스 완료!")
            history.set_result("success", must_fix=0, should_fix=len(should_fix))
        else:
            print(f"\n⚠ must_fix {len(must_fix)}건 남음 (fixer 미포함)")
            history.set_result("success", must_fix=len(must_fix), should_fix=len(should_fix))
        _print_final_report(review_result)
        history.save()
        return

    prev_must_fix = []
    final_status = "success"
    for fix_round in range(1, max_fix_rounds + 1):
        print(f"\n── Fix Round {fix_round}/{max_fix_rounds} ──")

        # 동일 이슈 반복 체크
        if check_same_issues(prev_must_fix, must_fix):
            print("  ✗ 동일 이슈가 반복됩니다. 하네스를 중단합니다.")
            final_status = "aborted"
            break

        prev_must_fix = must_fix

        # Fixer 실행
        fixer_context = (
            f"## Review Result\n\n```json\n{json.dumps(review_result, ensure_ascii=False, indent=2)}\n```\n\n"
            f"## Original Task\n\n{task}"
        )
        fixer_output = run_role(agent, "fixer", fixer_context)
        history.log_role("fixer", "success", detail=f"round {fix_round}")

        # 품질 게이트
        print("\n── 품질 게이트 (fixer 후) ──")
        passed, failures = run_quality_gates()
        _log_gate_results(history, passed, failures)
        if not passed:
            print(f"  ✗ fixer 후 게이트 실패: {', '.join(failures)}. 하네스를 중단합니다.")
            final_status = "aborted"
            break

        # Reviewer 재실행
        diff = get_git_diff()
        reviewer_context = f"## Git Diff\n\n```diff\n{diff}\n```\n\n## Original Task\n\n{task}"
        reviewer_output = run_role(agent, "reviewer", reviewer_context)
        history.log_role("reviewer", "success", detail=f"round {fix_round}")
        review_result = extract_json_from_output(reviewer_output)

        if review_result is None:
            print("  ⚠ reviewer 재실행 출력에서 JSON 추출 실패")
            final_status = "aborted"
            break

        must_fix = review_result.get("must_fix", [])
        should_fix = review_result.get("should_fix", [])
        print(f"  남은 must_fix: {len(must_fix)}")

        if not must_fix:
            print("\n✅ 모든 must_fix 해결 — 하네스 완료!")
            final_status = "success"
            break
    else:
        print(f"\n⚠ 최대 수정 횟수({max_fix_rounds}회) 도달. 하네스를 종료합니다.")
        final_status = "aborted"

    history.set_result(final_status, must_fix=len(must_fix), should_fix=len(should_fix))
    _print_final_report(review_result)
    history.save()


def _log_gate_results(history: HarnessHistory, passed: bool, failures: list[str]):
    """품질 게이트 결과를 이력에 기록한다."""
    gate_names = [g["name"] for g in QUALITY_GATES]
    for name in gate_names:
        history.log_quality_gate(name, passed=name not in failures)


def _print_final_report(review_result: dict | None):
    """최종 결과를 출력한다."""
    print(f"\n{'='*60}")
    print("📊 최종 결과")
    print(f"{'='*60}")

    if review_result:
        must_fix = review_result.get("must_fix", [])
        should_fix = review_result.get("should_fix", [])
        test_gaps = review_result.get("test_gaps", [])

        if must_fix:
            print(f"\n❌ 미해결 must_fix ({len(must_fix)}건):")
            for item in must_fix:
                print(f"  - [{item.get('file', '?')}] {item.get('issue', '?')}")

        if should_fix:
            print(f"\n⚠ should_fix ({len(should_fix)}건):")
            for item in should_fix:
                print(f"  - [{item.get('file', '?')}] {item.get('issue', '?')}")

        if test_gaps:
            print(f"\n📝 누락 테스트 ({len(test_gaps)}건):")
            for gap in test_gaps:
                print(f"  - {gap}")

        if not must_fix and not should_fix:
            print("\n✅ 모든 검토 항목 통과")
    else:
        print("\n⚠ 리뷰 결과 없음")

    print(f"\n{'='*60}")
    print("🔍 실기기 테스트를 수행하세요.")
    print(f"{'='*60}")


# ─── CLI ──────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="DoodleLand Automation Harness Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
examples:
  # --task 옵션으로 전달
  python scripts/harness_runner.py --agent claude --task "캐릭터 탭 시 사운드 재생"

  # 옵션 뒤에 따옴표 없이 바로 작성 (나머지를 모두 task로 인식)
  python scripts/harness_runner.py --agent codex 무대에 그림 10개가 추가됐을 때 안내 메시지 띄우기

  # 단계 지정
  python scripts/harness_runner.py --agent claude --steps planner --task "설명"

  # dry-run
  python scripts/harness_runner.py --agent claude --dry-run --task "설명"
        """,
    )
    parser.add_argument(
        "--agent",
        type=str,
        required=True,
        choices=["claude", "codex"],
        help="사용할 에이전트 (claude 또는 codex)",
    )
    parser.add_argument(
        "--task",
        type=str,
        default=None,
        help="수행할 작업 설명 (생략 시 나머지 인자를 task로 사용)",
    )
    parser.add_argument(
        "--steps",
        type=str,
        default=None,
        help=f"실행할 단계 (쉼표 구분, 기본: {','.join(ALL_STEPS)})",
    )
    parser.add_argument(
        "--max-fix-rounds",
        type=int,
        default=MAX_FIX_ROUNDS_DEFAULT,
        help=f"최대 fix 반복 횟수 (기본: {MAX_FIX_ROUNDS_DEFAULT})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="명령만 출력하고 실행하지 않음",
    )
    parser.add_argument(
        "remaining",
        nargs="*",
        help=argparse.SUPPRESS,
    )

    args = parser.parse_args()

    # --task가 없으면 나머지 인자를 합쳐서 task로 사용
    if args.task:
        task = args.task
    elif args.remaining:
        task = " ".join(args.remaining)
    else:
        parser.error("task를 입력하세요. --task \"설명\" 또는 옵션 뒤에 바로 작성")

    agent = AgentType(args.agent)
    steps = args.steps.split(",") if args.steps else None

    if steps:
        invalid = [s for s in steps if s not in ALL_STEPS]
        if invalid:
            print(f"✗ 알 수 없는 단계: {', '.join(invalid)}")
            print(f"  사용 가능: {', '.join(ALL_STEPS)}")
            sys.exit(1)

    run_harness(
        agent=agent,
        task=task,
        steps=steps,
        max_fix_rounds=args.max_fix_rounds,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()
