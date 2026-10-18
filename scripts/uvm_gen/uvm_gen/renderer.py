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

_TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"


def _make_jinja_env() -> Environment:
    env = Environment(
        loader=FileSystemLoader(str(_TEMPLATES_DIR)),
        undefined=StrictUndefined,  # fail loudly on any template typo referencing a missing attr
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )
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


def render_spec(spec: UvmEnvSpec, out_dir: str | Path, *, dry_run: bool = False) -> list[Path]:
    """Render every applicable file for `spec` under out_dir/<spec.name>/...

    Returns the list of output file paths that were (or, in dry-run mode,
    would be) written, in generation order.
    """
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
