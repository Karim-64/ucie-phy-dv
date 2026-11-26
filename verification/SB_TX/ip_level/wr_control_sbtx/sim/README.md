# UVM Python Regression Runner (QuestaSim)

A lightweight, production-style Python CLI regression runner for SystemVerilog / UVM testbenches using QuestaSim (`vlib`, `vlog`, `vopt`, `vsim`, `vcover`). It replaces Makefiles with a declarative JSON testlist and adds parallel execution, failure signature bucketing, one-command GUI repro, and automated coverage merging.

---

## 1. Prerequisites

* **Python 3.10+** (uses only the Python standard library — no `pip install` required).
* **Siemens QuestaSim** (`vlib`, `vlog`, `vopt`, `vsim`, `vcover`) available on your system `PATH`.

Verify both tools are reachable before running:

```bash
python --version
vsim -version
```

---

## 2. Package Contents

| File | Purpose |
| :--- | :--- |
| `regress.py` | Main CLI regression runner (compile once, run in parallel, parse logs, bucket failures, merge coverage). |
| `regress_list.json` | Declarative testlist defining `top_module`, `compile_file`, simulator options, tests, seeds, and plusargs. |
| `compile.f` | Template file list for `vlog -f compile.f` (uncomment and point to your packages, interfaces, RTL, and top TB). |
| `README.md` | This user guide. |

---

## 3. Quick Start

1. **Edit `compile.f`** to list your packages, interfaces, RTL files, and top-level testbench module (packages must appear before modules that `import` them).
2. **Edit `regress_list.json`** to match your `top_module` name and your UVM test class names (`+UVM_TESTNAME`).
3. **Validate your configuration** without launching QuestaSim:
   ```bash
   python regress.py --dry-run
   ```
4. **Run your first parallel regression** with 4 workers and coverage enabled:
   ```bash
   python regress.py -j 4 --cov
   ```

---

## 4. Configuring `regress_list.json`

```json
{
  "top_module": "top_tb",
  "compile_file": "compile.f",
  "default_timeout_sec": 300,
  "vlog_opts": [],
  "vopt_opts": [],
  "vsim_opts": ["-onfinish", "stop"],
  "tests": [
    {
      "name": "d2d_sanity_test",
      "seeds": [101],
      "plusargs": ["+UVM_VERBOSITY=UVM_MEDIUM"]
    },
    {
      "name": "d2d_back2back_test",
      "seeds": [201],
      "num_random_seeds": 4,
      "plusargs": ["+UVM_VERBOSITY=UVM_LOW"]
    },
    {
      "name": "d2d_parity_err_test",
      "num_random_seeds": 3,
      "plusargs": ["+UVM_VERBOSITY=UVM_LOW", "+ERR_RATE=20"],
      "timeout_sec": 180
    }
  ]
}
```

### Field Reference

* `top_module` *(required)*: Name of your top-level testbench module (e.g., `top_tb`).
* `compile_file` *(required)*: Path to your `.f` file list, resolved relative to the JSON config file.
* `default_timeout_sec` *(optional, default `300`)*: Wall-clock timeout per `vsim` job in seconds.
* `vlog_opts`, `vopt_opts`, `vsim_opts` *(optional)*: Extra simulator flags appended globally.
* `tests` *(required)*: Array of test entries:
  * `name`: Exact UVM test class name passed to `+UVM_TESTNAME=`.
  * `seeds`: Explicit list of deterministic integer seeds.
  * `num_random_seeds`: Number of additional random seeds generated per regression run.
  * `plusargs`: Test-specific runtime plusargs (e.g., `+UVM_VERBOSITY=UVM_LOW`, `+ERR_RATE=20`).
  * `timeout_sec`: Per-test override of `default_timeout_sec`.

---

## 5. CLI Reference

| Flag | Default | Description |
| :--- | :--- | :--- |
| `-c, --config PATH` | `regress_list.json` | Path to the JSON testlist. |
| `-o, --out-dir PATH` | `sim_runs` | Output directory for `work/`, per-job run folders, logs, and coverage. |
| `-j, --jobs N` | `4` | Number of parallel `vsim` workers. |
| `-t, --test SUBSTR` | `None` | Run only tests whose name contains `SUBSTR`. |
| `--seed INT` | `None` | Override all seeds and run each matched test once with this exact seed. |
| `--cov` | `False` | Compile with `+cover=bcesft`, save `cov.ucdb` per run, merge into `merged.ucdb`, and generate `cov_report.txt`. |
| `--html-cov` | `False` | Same as `--cov`, plus generates an interactive HTML report at `sim_runs/cov_html/index.html`. |
| `--waves` | `False` | Logs full waveforms (`log -r /*`) for every run. Keep off during large regressions to avoid disk I/O bottlenecks. |
| `--skip-compile` | `False` | Skips `vlib`/`vlog`/`vopt` and reuses the existing `sim_runs/work` library. |
| `--no-repro` | `False` | Hides the copy-pasteable GUI repro commands printed after failures. |
| `--dry-run` | `False` | Validates the JSON config and prints the planned job list without invoking QuestaSim. |

### Common Workflows

```bash
# 1. Full nightly regression with 6 workers + HTML coverage
python regress.py -j 6 --html-cov

# 2. Fast iteration: re-run only parity tests without recompiling
python regress.py --skip-compile -t parity -j 2

# 3. Reproduce one specific failing seed with waveforms
python regress.py --skip-compile -t d2d_parity_err_test --seed 14829104 --waves -j 1

# 4. Run a separate nightly testlist into a separate output directory
python regress.py -c nightly_list.json -o nightly_runs -j 8 --cov
```

---

## 6. Understanding the Output

After execution, `sim_runs/` contains:

```text
sim_runs/
├── work/                       # Shared compiled & optimized QuestaSim library
├── compile.log / vopt.log      # Build logs
├── <test>_seed<N>/
│   ├── sim.log                 # Full QuestaSim + UVM transcript for this job
│   └── cov.ucdb                # Per-run coverage database (when --cov is used)
├── merged.ucdb                 # Merged coverage database
├── cov_report.txt              # Detailed text coverage report
├── cov_html/index.html         # Interactive HTML coverage report (with --html-cov)
└── summary.json                # Machine-readable pass/fail summary for CI
```

### Failure Signature Bucketing & Repro
When tests fail, `regress.py` automatically:
1. Extracts the first `UVM_ERROR`, `UVM_FATAL`, or simulator error from each failing `sim.log`.
2. Normalizes timestamps and hex values so identical bugs across multiple seeds collapse into a single **Failure Signature Bucket**.
3. Prints a ready-to-paste `vsim -gui` command (with `log -r /*`) for each failing `(test, seed)` pair.

---

## 7. Extending to a Compute Farm (LSF / Slurm)

`regress.py` isolates execution behind the `RunnerBackend` abstract base class. To migrate from local workstation execution (`LocalQuestaRunner`) to a cluster scheduler, subclass `RunnerBackend` and override `run_all()` to submit `bsub` or `sbatch` jobs—your JSON testlist, log parser, failure bucketing, and coverage merger remain unchanged.

---

## 8. CI / CD Integration

`regress.py` returns standard exit codes:
* `0`: All simulation jobs passed.
* `1`: Compilation failed, or one or more simulations failed / timed out.
* `2`: Invalid CLI arguments or configuration file error.

This allows direct use in GitHub Actions, GitLab CI, or Jenkins pipelines.
