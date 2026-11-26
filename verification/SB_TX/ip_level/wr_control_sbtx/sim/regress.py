#!/usr/bin/env python3
"""Production-Grade Python UVM Regression Runner for QuestaSim.

Features:
  - Compile once (vlib -> vlog -> vopt), simulate many in parallel.
  - Isolated per-job run directories with unique seeds and plusargs.
  - Pluggable RunnerBackend abstraction (local ThreadPoolExecutor by default;
    easy to extend for LSF/Slurm farm dispatch).
  - Automated log parsing with UVM/SVA failure signature bucketing.
  - One-command GUI/waveform repro generation for failing (test, seed) pairs.
  - Optional code/functional coverage collection, vcover merge, and reporting.
  - Machine-readable JSON summary report (summary.json) for CI integration.
"""

from __future__ import annotations

import abc
import argparse
import json
import logging
import random
import re
import shlex
import subprocess
import sys
import time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("uvm_regress")


# ---------------------------------------------------------------------------
# Data Models
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class SimJob:
    test_name: str
    seed: int
    plusargs: list[str] = field(default_factory=list)
    timeout_sec: int = 300


@dataclass(frozen=True)
class RegressionConfig:
    top_module: str
    compile_file: Path
    default_timeout_sec: int
    vlog_opts: list[str]
    vopt_opts: list[str]
    vsim_opts: list[str]
    jobs: list[SimJob]


@dataclass
class SimResult:
    job: SimJob
    status: str  # PASS | FAIL | TIMEOUT
    duration_sec: float
    log_path: Path
    ucdb_path: Path | None
    reason: str = ""
    failure_signature: str = ""
    repro_cmd: str = ""


# ---------------------------------------------------------------------------
# Configuration Loading
# ---------------------------------------------------------------------------


def load_config(
    config_path: Path,
    test_filter: str | None = None,
    seed_override: int | None = None,
) -> RegressionConfig:
    """Parse and validate the JSON regression testlist."""
    if not config_path.is_file():
        raise FileNotFoundError(f"Regression config not found: {config_path}")

    raw: dict[str, Any] = json.loads(config_path.read_text(encoding="utf-8"))

    for required_key in ("top_module", "compile_file", "tests"):
        if required_key not in raw:
            raise ValueError(f"Missing required key '{required_key}' in {config_path}")

    top_module: str = str(raw["top_module"])
    compile_file: Path = (config_path.parent / raw["compile_file"]).resolve()
    default_timeout: int = int(raw.get("default_timeout_sec", 300))

    if not compile_file.is_file():
        raise FileNotFoundError(f"Compile file list not found: {compile_file}")

    vlog_opts: list[str] = list(raw.get("vlog_opts", []))
    vopt_opts: list[str] = list(raw.get("vopt_opts", []))
    vsim_opts: list[str] = list(raw.get("vsim_opts", []))

    jobs: list[SimJob] = []
    for entry in raw.get("tests", []):
        name: str = str(entry["name"])
        if test_filter and test_filter not in name:
            continue

        plusargs: list[str] = list(entry.get("plusargs", []))
        timeout_sec: int = int(entry.get("timeout_sec", default_timeout))

        if seed_override is not None:
            seeds = [seed_override]
        else:
            seeds = [int(s) for s in entry.get("seeds", [])]
            num_rand = int(entry.get("num_random_seeds", 0))
            seeds.extend(random.randint(1, 2**31 - 1) for _ in range(num_rand))

        for seed in seeds:
            jobs.append(
                SimJob(
                    test_name=name,
                    seed=seed,
                    plusargs=plusargs,
                    timeout_sec=timeout_sec,
                )
            )

    if not jobs:
        raise ValueError("No simulation jobs matched your configuration/filter.")

    return RegressionConfig(
        top_module=top_module,
        compile_file=compile_file,
        default_timeout_sec=default_timeout,
        vlog_opts=vlog_opts,
        vopt_opts=vopt_opts,
        vsim_opts=vsim_opts,
        jobs=jobs,
    )


# ---------------------------------------------------------------------------
# Subprocess & Log Parsing Helpers
# ---------------------------------------------------------------------------


def run_cmd(
    cmd: list[str],
    cwd: Path,
    log_file: Path,
    timeout: int | None = None,
) -> int:
    """Execute a shell command and redirect combined stdout/stderr to log_file."""
    with log_file.open("w", encoding="utf-8") as fh:
        fh.write(f"# CMD: {shlex.join(cmd)}\n# CWD: {cwd}\n\n")
        fh.flush()
        proc = subprocess.run(
            cmd,
            cwd=cwd,
            stdout=fh,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            check=False,
        )
    return proc.returncode


SIGNATURE_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"^(UVM_FATAL\s+@\s*\S+\s*:\s*.*)$"),
    re.compile(r"^(UVM_ERROR\s+@\s*\S+\s*:\s*.*)$"),
    re.compile(r"^(\*\*\s*Fatal:.*)$"),
    re.compile(r"^(\*\*\s*Error(?:\s*\([^)]+\))?:.*)$"),
]


def normalize_signature(line: str) -> str:
    """Strip timestamps and volatile memory/cycle numbers so identical bugs bucket together."""
    cleaned = re.sub(r"@\s*[0-9]+(?:\.[0-9]+)?\s*(?:fs|ps|ns|us|ms|s)?", "@ <TIME>", line)
    cleaned = re.sub(r"\b0x[0-9a-fA-F]+\b", "<HEX>", cleaned)
    return cleaned.strip()


def extract_first_signature(text: str) -> str:
    """Return a normalized signature of the first error/fatal line in sim.log."""
    for raw_line in text.splitlines():
        line = raw_line.strip().lstrip("#").strip()
        for pattern in SIGNATURE_PATTERNS:
            if pattern.match(line):
                return normalize_signature(line)
    return "Unknown failure signature (inspect sim.log)"


def parse_uvm_log(log_path: Path) -> tuple[bool, str, str]:
    """Parse a QuestaSim UVM log and return (passed, reason, signature)."""
    if not log_path.is_file():
        return False, "Missing sim.log", "Missing sim.log"

    text = log_path.read_text(encoding="utf-8", errors="ignore")

    if "** Fatal:" in text or "** Error:" in text:
        return False, "Simulator Error/Fatal", extract_first_signature(text)

    err_match = re.search(r"UVM_ERROR\s*:\s*(\d+)", text)
    fat_match = re.search(r"UVM_FATAL\s*:\s*(\d+)", text)

    if not err_match or not fat_match:
        return (
            False,
            "Missing UVM report summary",
            extract_first_signature(text),
        )

    uvm_errors = int(err_match.group(1))
    uvm_fatals = int(fat_match.group(1))

    if uvm_errors > 0 or uvm_fatals > 0:
        return (
            False,
            f"UVM_ERROR={uvm_errors}, UVM_FATAL={uvm_fatals}",
            extract_first_signature(text),
        )

    return True, "OK", ""


def build_repro_cmd(
    job: SimJob,
    work_lib: Path,
    top_module: str,
    vsim_opts: list[str],
    gui: bool = True,
) -> str:
    """Build a copy-pasteable vsim command for waveform debugging."""
    mode_flag = "-gui" if gui else "-c"
    do_cmd = "log -r /*; run -all" if gui else "log -r /*; run -all; quit -f"
    cmd = [
        "vsim",
        mode_flag,
        "-lib",
        str(work_lib),
        f"{top_module}_opt",
        f"+UVM_TESTNAME={job.test_name}",
        "-sv_seed",
        str(job.seed),
        *vsim_opts,
        *job.plusargs,
        "-do",
        do_cmd,
    ]
    return shlex.join(cmd)


# ---------------------------------------------------------------------------
# Build Stage (Compile Once)
# ---------------------------------------------------------------------------


def compile_design(
    cfg: RegressionConfig,
    work_lib: Path,
    enable_cov: bool,
) -> None:
    """Run vlib, vlog, and vopt once into the shared work library."""
    work_lib.parent.mkdir(parents=True, exist_ok=True)
    vlib_log = work_lib.parent / "vlib.log"
    vlog_log = work_lib.parent / "compile.log"
    vopt_log = work_lib.parent / "vopt.log"

    if not work_lib.exists():
        log.info("Creating QuestaSim library: %s", work_lib)
        rc = run_cmd(["vlib", str(work_lib)], cwd=work_lib.parent, log_file=vlib_log)
        if rc != 0:
            raise RuntimeError(f"vlib failed (exit {rc}). Check {vlib_log}")

    vlog_cmd = [
        "vlog",
        "-sv",
        "-work",
        str(work_lib),
        "+acc",
        *cfg.vlog_opts,
        "-f",
        str(cfg.compile_file),
    ]
    if enable_cov:
        vlog_cmd.append("+cover=bcesft")

    log.info("Compiling design via %s", cfg.compile_file.name)
    rc = run_cmd(vlog_cmd, cwd=cfg.compile_file.parent, log_file=vlog_log)
    if rc != 0:
        raise RuntimeError(f"vlog failed (exit {rc}). Check {vlog_log}")

    vopt_cmd = [
        "vopt",
        "-work",
        str(work_lib),
        cfg.top_module,
        "+acc",
        *cfg.vopt_opts,
        "-o",
        f"{cfg.top_module}_opt",
    ]
    if enable_cov:
        vopt_cmd.append("+cover=bcesft")

    log.info("Optimizing snapshot %s_opt", cfg.top_module)
    rc = run_cmd(vopt_cmd, cwd=work_lib.parent, log_file=vopt_log)
    if rc != 0:
        raise RuntimeError(f"vopt failed (exit {rc}). Check {vopt_log}")


# ---------------------------------------------------------------------------
# Pluggable Runner Backends
# ---------------------------------------------------------------------------


class RunnerBackend(abc.ABC):
    """Abstract interface for dispatching simulation jobs (local, LSF, Slurm, etc.)."""

    @abc.abstractmethod
    def run_all(
        self,
        cfg: RegressionConfig,
        work_lib: Path,
        run_root: Path,
        enable_cov: bool,
        waves: bool,
        max_workers: int,
    ) -> list[SimResult]:
        """Execute all jobs and return their results."""


class LocalQuestaRunner(RunnerBackend):
    """Runs isolated QuestaSim vsim processes in parallel on the local machine."""

    def _run_one(
        self,
        job: SimJob,
        cfg: RegressionConfig,
        work_lib: Path,
        run_root: Path,
        enable_cov: bool,
        waves: bool,
    ) -> SimResult:
        run_dir = run_root / f"{job.test_name}_seed{job.seed}"
        run_dir.mkdir(parents=True, exist_ok=True)
        log_path = run_dir / "sim.log"
        ucdb_path = (run_dir / "cov.ucdb") if enable_cov else None

        do_steps: list[str] = []
        if waves:
            do_steps.append("log -r /*")
        if enable_cov:
            do_steps.append("coverage save -onexit cov.ucdb")
        do_steps.extend(["run -all", "quit -f"])
        do_str = "; ".join(do_steps)

        cmd = ["vsim", "-c"]
        if enable_cov:
            cmd.append("-coverage")
        cmd.extend(
            [
                "-lib",
                str(work_lib),
                f"{cfg.top_module}_opt",
                f"+UVM_TESTNAME={job.test_name}",
                "-sv_seed",
                str(job.seed),
                *cfg.vsim_opts,
                *job.plusargs,
                "-do",
                do_str,
            ]
        )

        repro_cmd = build_repro_cmd(job, work_lib, cfg.top_module, cfg.vsim_opts, gui=True)

        start = time.monotonic()
        try:
            rc = run_cmd(cmd, cwd=run_dir, log_file=log_path, timeout=job.timeout_sec)
            elapsed = time.monotonic() - start
        except subprocess.TimeoutExpired:
            elapsed = time.monotonic() - start
            return SimResult(
                job=job,
                status="TIMEOUT",
                duration_sec=elapsed,
                log_path=log_path,
                ucdb_path=None,
                reason=f"Exceeded {job.timeout_sec}s",
                failure_signature=f"TIMEOUT (> {job.timeout_sec}s)",
                repro_cmd=repro_cmd,
            )

        passed, reason, sig = parse_uvm_log(log_path)
        if rc != 0 and passed:
            passed = False
            reason = f"Non-zero exit code ({rc})"
            sig = f"vsim exited with code {rc}"

        return SimResult(
            job=job,
            status="PASS" if passed else "FAIL",
            duration_sec=elapsed,
            log_path=log_path,
            ucdb_path=ucdb_path if (ucdb_path and ucdb_path.is_file()) else None,
            reason=reason,
            failure_signature="" if passed else sig,
            repro_cmd="" if passed else repro_cmd,
        )

    def run_all(
        self,
        cfg: RegressionConfig,
        work_lib: Path,
        run_root: Path,
        enable_cov: bool,
        waves: bool,
        max_workers: int,
    ) -> list[SimResult]:
        results: list[SimResult] = []
        with ThreadPoolExecutor(max_workers=max_workers) as pool:
            futures = [
                pool.submit(self._run_one, job, cfg, work_lib, run_root, enable_cov, waves)
                for job in cfg.jobs
            ]
            for fut in as_completed(futures):
                res = fut.result()
                results.append(res)
                log.info(
                    "[%-7s] %s (seed=%d) in %.1fs",
                    res.status,
                    res.job.test_name,
                    res.job.seed,
                    res.duration_sec,
                )
        return results


# ---------------------------------------------------------------------------
# Coverage Merging & Reporting
# ---------------------------------------------------------------------------


def merge_coverage(results: list[SimResult], run_root: Path, html_report: bool) -> None:
    """Merge all .ucdb databases and generate text (and optional HTML) reports."""
    ucdbs = [str(r.ucdb_path) for r in results if r.ucdb_path is not None]
    if not ucdbs:
        log.warning("No .ucdb coverage files found to merge.")
        return

    merged_ucdb = run_root / "merged.ucdb"
    report_txt = run_root / "cov_report.txt"
    merge_log = run_root / "vcover.log"

    log.info("Merging %d coverage database(s) into %s", len(ucdbs), merged_ucdb)
    rc = run_cmd(["vcover", "merge", str(merged_ucdb), *ucdbs], cwd=run_root, log_file=merge_log)
    if rc != 0:
        log.error("vcover merge failed. Check %s", merge_log)
        return

    run_cmd(
        ["vcover", "report", "-details", "-output", str(report_txt), str(merged_ucdb)],
        cwd=run_root,
        log_file=merge_log,
    )
    log.info("Text coverage report written to %s", report_txt)

    if html_report:
        html_dir = run_root / "cov_html"
        run_cmd(
            ["vcover", "report", "-html", "-details", "-htmldir", str(html_dir), str(merged_ucdb)],
            cwd=run_root,
            log_file=merge_log,
        )
        log.info("HTML coverage report written to %s", html_dir / "index.html")

        cvg_html_dir = run_root / "cov_html_cvg"
        run_cmd(
            ["vcover", "report", "-html", "-details", "-cvg", "-htmldir", str(cvg_html_dir), str(merged_ucdb)],
            cwd=run_root,
            log_file=merge_log,
        )
        log.info("HTML functional (covergroup) report written to %s", cvg_html_dir / "index.html")


def write_json_summary(results: list[SimResult], run_root: Path) -> Path:
    """Write a machine-readable JSON summary for CI dashboards or post-processing."""
    summary_path = run_root / "summary.json"
    passed_cnt = sum(1 for r in results if r.status == "PASS")
    failed_cnt = len(results) - passed_cnt

    payload = {
        "total": len(results),
        "passed": passed_cnt,
        "failed": failed_cnt,
        "results": [
            {
                **asdict(r),
                "log_path": str(r.log_path),
                "ucdb_path": str(r.ucdb_path) if r.ucdb_path else None,
            }
            for r in results
        ],
    }
    summary_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return summary_path


def print_summary(results: list[SimResult], show_repro: bool) -> int:
    """Print pass/fail table, failure signature buckets, and optional repro commands."""
    print("\n" + "=" * 86)
    print(f"{'TEST NAME':<30} {'SEED':<12} {'STATUS':<8} {'TIME':<8} {'NOTES'}")
    print("-" * 86)

    failures: list[SimResult] = []
    for r in sorted(results, key=lambda x: (x.status == "PASS", x.job.test_name, x.job.seed)):
        if r.status != "PASS":
            failures.append(r)
        print(
            f"{r.job.test_name:<30} {r.job.seed:<12} {r.status:<8} "
            f"{r.duration_sec:>5.1f}s   {r.reason}"
        )

    print("=" * 86)
    print(
        f"Total: {len(results)} | Passed: {len(results) - len(failures)} | "
        f"Failed: {len(failures)}"
    )

    if failures:
        buckets: dict[str, list[SimResult]] = defaultdict(list)
        for fail in failures:
            buckets[fail.failure_signature].append(fail)

        print("\n--- Failure Signature Buckets ---")
        for idx, (sig, items) in enumerate(
            sorted(buckets.items(), key=lambda kv: -len(kv[1])), start=1
        ):
            print(f"  [{idx}] ({len(items)} hit(s)) {sig}")
            for item in items:
                print(f"       -> {item.job.test_name} (seed={item.job.seed}) | {item.log_path}")

        if show_repro:
            print("\n--- One-Command GUI Repro (Failing Runs) ---")
            for fail in failures:
                print(f"  # {fail.job.test_name} (seed={fail.job.seed})")
                print(f"  {fail.repro_cmd}\n")

    print()
    return 1 if failures else 0


# ---------------------------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------------------------


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Production-grade Python UVM Regression Runner for QuestaSim"
    )
    parser.add_argument(
        "-c",
        "--config",
        type=Path,
        default=Path("regress_list.json"),
        help="Path to declarative JSON testlist (default: regress_list.json)",
    )
    parser.add_argument(
        "-o",
        "--out-dir",
        type=Path,
        default=Path("sim_runs"),
        help="Output directory for work library, logs, and coverage (default: sim_runs)",
    )
    parser.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=4,
        help="Number of parallel vsim workers (default: 4)",
    )
    parser.add_argument(
        "-t",
        "--test",
        type=str,
        default=None,
        help="Run only tests whose name contains this substring",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Override all seeds and run each matched test once with this exact seed",
    )
    parser.add_argument(
        "--cov",
        action="store_true",
        help="Enable code & functional coverage collection and vcover merge",
    )
    parser.add_argument(
        "--html-cov",
        action="store_true",
        help="Also generate an HTML coverage report (implies --cov)",
    )
    parser.add_argument(
        "--waves",
        action="store_true",
        help="Log waveforms (vsim.wlf) for every run (not recommended for large regressions)",
    )
    parser.add_argument(
        "--skip-compile",
        action="store_true",
        help="Skip vlib/vlog/vopt and reuse the existing compiled work library",
    )
    parser.add_argument(
        "--no-repro",
        action="store_true",
        help="Suppress printing copy-pasteable GUI repro commands for failing runs",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate config and print planned simulation jobs without invoking QuestaSim",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    enable_cov = args.cov or args.html_cov

    if args.jobs < 1:
        log.error("--jobs must be >= 1")
        return 2

    try:
        cfg = load_config(args.config.resolve(), test_filter=args.test, seed_override=args.seed)
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as exc:
        log.error("Configuration error: %s", exc)
        return 2

    if args.dry_run:
        log.info("Dry-run validated %s (%d job(s)):", args.config, len(cfg.jobs))
        for j in cfg.jobs:
            print(f"  - {j.test_name:<30} seed={j.seed:<12} plusargs={' '.join(j.plusargs)}")
        return 0

    run_root = args.out_dir.resolve()
    work_lib = run_root / "work"

    if not args.skip_compile:
        try:
            compile_design(cfg, work_lib, enable_cov=enable_cov)
        except RuntimeError as exc:
            log.error("%s", exc)
            return 1
    elif not work_lib.exists():
        log.error("--skip-compile was set, but work library does not exist at %s", work_lib)
        return 2

    log.info(
        "Launching %d simulation(s) with %d parallel worker(s)...",
        len(cfg.jobs),
        args.jobs,
    )
    runner: RunnerBackend = LocalQuestaRunner()
    results = runner.run_all(
        cfg=cfg,
        work_lib=work_lib,
        run_root=run_root,
        enable_cov=enable_cov,
        waves=args.waves,
        max_workers=args.jobs,
    )

    if enable_cov:
        merge_coverage(results, run_root, html_report=args.html_cov)

    summary_json = write_json_summary(results, run_root)
    log.info("JSON summary written to %s", summary_json)

    return print_summary(results, show_repro=not args.no_repro)


if __name__ == "__main__":
    sys.exit(main())
