# ucie-phy-dv
Modular SystemVerilog/UVM verification infrastructure for the UCIe 3.0 Physical Layer. Includes unit-level sub-IP testbenches, reusable UVCs, SVA assertions, and block-level integration environments.

---

## Layout
- `docs/`          spec notes, architecture, verification plans, reports
- `rtl/`           ip/ (leaf blocks), blocks/ (integration), top/, common/
- `verification/`  common/ (shared agents, pkg, scoreboards, sva, cov),
                   ip_level/, block_level/, system_level/
- `scripts/`       run and regression scripts
- `regress/`       test lists and results

## Conventions
- Names: `<ip>_agent`, `<ip>_env`, `<ip>_scoreboard`, `<ip>_base_test`
- Branch per IP, merge to `main` when its regression passes