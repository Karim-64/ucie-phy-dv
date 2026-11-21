"""
Renders a UvmEnvSpec into the on-disk file tree, using the Jinja2 templates
under templates/. The output layout always mirrors the mem.zip reference:

  <out_dir>/<name>/
    cfg_obj/      <name>_drv_mon_cfg_obj.svh, <name>_agt_cfg_obj.svh, <name>_env_cfg_obj.svh
    sequences/    <name>_sequence_item.svh, <name>_base_sequence.svh
    components/   <name>_sequencer.svh, _driver.svh, _monitor.svh, _agent.svh,
                  [_scoreboard.svh], [_subscriber.svh], _environment.svh, _base_test.svh
    interfaces/   <name>_if.sv
    packages/     <name>_pkg.sv
    tb/           tb_top.sv
    sim/          run.do
"""
from __future__ import annotations

from pathlib import Path

from jinja2 import Environment, FileSystemLoader, StrictUndefined

from .model import UvmEnvSpec
from .multi_model import MultiEnvSpec

_TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"


def _make_jinja_env() -> Environment:
    env = Environment(
        loader=FileSystemLoader(str(_TEMPLATES_DIR)),
        undefined=StrictUndefined,  # fail loudly on any template typo referencing a missing attr
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )
    env.filters["suffix"] = lambda value, suffix: f"{value}{suffix}"
    return env


# (template path relative to templates/, output path relative to <out_dir>/<name>/, required-flag)
_FILES: list[tuple[str, str, str]] = [
    ("cfg_obj/drv_mon_cfg_obj.svh.j2", "cfg_obj/{name}_drv_mon_cfg_obj.svh", "always"),
    ("cfg_obj/agt_cfg_obj.svh.j2", "cfg_obj/{name}_agt_cfg_obj.svh", "always"),
    ("cfg_obj/env_cfg_obj.svh.j2", "cfg_obj/{name}_env_cfg_obj.svh", "always"),
    ("sequences/sequence_item.svh.j2", "sequences/{name}_sequence_item.svh", "always"),
    ("sequences/base_sequence.svh.j2", "sequences/{name}_base_sequence.svh", "always"),
    ("components/sequencer.svh.j2", "components/{name}_sequencer.svh", "always"),
    ("components/driver.svh.j2", "components/{name}_driver.svh", "always"),
    ("components/monitor.svh.j2", "components/{name}_monitor.svh", "always"),
    ("components/agent.svh.j2", "components/{name}_agent.svh", "always"),
    ("components/scoreboard.svh.j2", "components/{name}_scoreboard.svh", "has_scoreboard"),
    ("components/subscriber.svh.j2", "components/{name}_subscriber.svh", "has_subscriber"),
    ("components/environment.svh.j2", "components/{name}_environment.svh", "always"),
    ("components/base_test.svh.j2", "components/{name}_base_test.svh", "always"),
    ("interfaces/if.sv.j2", "interfaces/{name}_if.sv", "always"),
    ("packages/pkg.sv.j2", "packages/{name}_pkg.sv", "always"),
    ("tb/tb_top.sv.j2", "tb/tb_top.sv", "always"),
    ("sim/run.do.j2", "sim/run.do", "always"),
]


def render_spec(
    spec: UvmEnvSpec | MultiEnvSpec, out_dir: str | Path, *, dry_run: bool = False
) -> list[Path]:
    """Render every applicable file for `spec` under out_dir/<spec.name>/...

    Returns the list of output file paths that were (or, in dry-run mode,
    would be) written, in generation order.
    """
    if isinstance(spec, MultiEnvSpec):
        return render_multi_spec(spec, out_dir, dry_run=dry_run)

    jenv = _make_jinja_env()
    root = Path(out_dir) / spec.name
    written: list[Path] = []

    for template_rel, out_rel_template, requires in _FILES:
        if requires == "has_scoreboard" and not spec.env.has_scoreboard:
            continue
        if requires == "has_subscriber" and not spec.env.has_subscriber:
            continue

        out_rel = out_rel_template.format(name=spec.name)
        out_path = root / out_rel

        template = jenv.get_template(template_rel)
        content = template.render(spec=spec)

        if not dry_run:
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(content, encoding="utf-8")

        written.append(out_path)

    return written


# ---------------------------------------------------------------------------
# Multi-agent environment (Priority_Encoder_SBTX architecture)
#
#   <out_dir>/<name>/
#     cfg_obj/                      <name>_<AGT>_drv_mon_cfg_obj.svh, <name>_<AGT>_agt_cfg_obj.svh,
#                                   <name>_env_cfg_obj.svh
#     components/<AGT>_agent/       <name>_<AGT>_agent/_monitor[/_driver/_sequencer].svh
#     components/                   <name>_vseqr, [_scoreboard], [_coverage], _environment, _base_test
#     interfaces/                   <name>_<if>_if.sv (one per declared interface)
#     packages/                     <name>_pkg.sv
#     sequences/sequence_items/     <name>_<AGT>_sequence_item.svh
#     sequences/<AGT>_seqs/         <name>_<AGT>_base_seq.svh (active agents)
#     sequences/                    <name>_vseq.svh
#     tb/tb_top.sv, sim/run.do
# ---------------------------------------------------------------------------
def _render_jobs(spec: MultiEnvSpec) -> list[tuple[str, str, dict]]:
    """(template, output path relative to <out_dir>/<name>, extra context) for every file."""
    jobs: list[tuple[str, str, dict]] = []
    t = "multi/"
    for intf in spec.interfaces:
        jobs.append((t + "interfaces/if.sv.j2", f"interfaces/{intf.file_name}", {"intf": intf}))

    for a in spec.agents:
        ctx = {"agent": a}
        jobs.append((t + "cfg_obj/drv_mon_cfg_obj.svh.j2",
                     f"cfg_obj/{a.cls('drv_mon_cfg_obj')}.svh", ctx))
        jobs.append((t + "cfg_obj/agt_cfg_obj.svh.j2", f"cfg_obj/{a.cls('agt_cfg_obj')}.svh", ctx))
    jobs.append((t + "cfg_obj/env_cfg_obj.svh.j2", f"cfg_obj/{spec.name}_env_cfg_obj.svh", {}))

    for a in spec.agents:
        ctx = {"agent": a}
        jobs.append((t + "sequences/sequence_item.svh.j2",
                     f"sequences/sequence_items/{a.item}.svh", ctx))
        if a.is_active:
            jobs.append((t + "sequences/base_seq.svh.j2",
                         f"{a.seq_dir}/{a.cls('base_seq')}.svh", ctx))
            jobs.append((t + "components/agent/sequencer.svh.j2",
                         f"{a.comp_dir}/{a.cls('sequencer')}.svh", ctx))
            jobs.append((t + "components/agent/driver.svh.j2",
                         f"{a.comp_dir}/{a.cls('driver')}.svh", ctx))
        jobs.append((t + "components/agent/monitor.svh.j2",
                     f"{a.comp_dir}/{a.cls('monitor')}.svh", ctx))
        jobs.append((t + "components/agent/agent.svh.j2",
                     f"{a.comp_dir}/{a.cls('agent')}.svh", ctx))

    jobs.append((t + "sequences/vseq.svh.j2", f"sequences/{spec.name}_vseq.svh", {}))
    jobs.append((t + "components/vseqr.svh.j2", f"components/{spec.name}_vseqr.svh", {}))
    if spec.env.has_scoreboard:
        jobs.append((t + "components/scoreboard.svh.j2",
                     f"components/{spec.name}_scoreboard.svh", {}))
    if spec.env.has_coverage:
        jobs.append((t + "components/coverage.svh.j2", f"components/{spec.name}_coverage.svh", {}))
    jobs.append((t + "components/environment.svh.j2",
                 f"components/{spec.name}_environment.svh", {}))
    jobs.append((t + "components/base_test.svh.j2", f"components/{spec.name}_base_test.svh", {}))
    jobs.append((t + "packages/pkg.sv.j2", f"packages/{spec.name}_pkg.sv", {}))
    jobs.append((t + "tb/tb_top.sv.j2", "tb/tb_top.sv", {}))
    jobs.append((t + "sim/run.do.j2", "sim/run.do", {}))
    return jobs


def render_multi_spec(spec: MultiEnvSpec, out_dir: str | Path, *,
                      dry_run: bool = False) -> list[Path]:
    jenv = _make_jinja_env()
    root = Path(out_dir) / spec.name
    written: list[Path] = []
    for template_rel, out_rel, extra in _render_jobs(spec):
        content = jenv.get_template(template_rel).render(spec=spec, **extra)
        out_path = root / out_rel
        if not dry_run:
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_path.write_text(content, encoding="utf-8")
        written.append(out_path)
    return written
