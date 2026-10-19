"""
XML -> UvmEnvSpec parsing and validation.

Validation philosophy: fail loudly and specifically before any file is
written. A generator that silently drops a bad reference and produces
plausible-looking-but-wrong SystemVerilog is worse than one that refuses
to run.
"""
from __future__ import annotations

import re
from pathlib import Path
from xml.etree import ElementTree as ET

from .model import DutPortSpec, DutSpec, EnvFlags, ParamSpec, SignalSpec, UvmEnvSpec

_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

_RESERVED_SIGNAL_NAMES = {"clk"}  # the clock is declared separately; don't let it collide


class SpecError(ValueError):
    """Raised for any structurally or semantically invalid config. Always carries
    enough context (what/where) for the user to fix the XML without guessing."""


def _require_identifier(value: str, what: str) -> str:
    if not value or not _IDENTIFIER_RE.match(value):
        raise SpecError(
            f"{what} must be a valid SystemVerilog identifier, got: {value!r}"
        )
    return value


def _text(node: ET.Element | None, tag: str, parent_desc: str) -> str:
    if node is None:
        raise SpecError(f"Missing required element <{tag}> under {parent_desc}")
    value = (node.text or "").strip()
    if not value:
        raise SpecError(f"<{tag}> under {parent_desc} is empty")
    return value


def parse_spec(xml_path: str | Path) -> UvmEnvSpec:
    xml_path = Path(xml_path)
    if not xml_path.exists():
        raise SpecError(f"Config file not found: {xml_path}")

    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as e:
        raise SpecError(f"Malformed XML in {xml_path}: {e}") from e

    root = tree.getroot()
    if root.tag != "uvm_env":
        raise SpecError(f"Root element must be <uvm_env>, got <{root.tag}>")

    agent_name = _require_identifier(root.get("name", ""), "uvm_env/@name")

    # ---- parameters ----
    parameters: list[ParamSpec] = []
    seen_params: set[str] = set()
    params_node = root.find("parameters")
    if params_node is not None:
        for p in params_node.findall("parameter"):
            pname = _require_identifier(p.get("name", ""), "parameter/@name")
            pvalue = p.get("value")
            if pvalue is None or not pvalue.strip():
                raise SpecError(f"parameter '{pname}' is missing a non-empty @value")
            if pname in seen_params:
                raise SpecError(f"Duplicate parameter name: '{pname}'")
            seen_params.add(pname)
            parameters.append(ParamSpec(name=pname, value=pvalue.strip()))

    # ---- clock ----
    clock_node = root.find("clock")
    if clock_node is None:
        raise SpecError("Missing required <clock name=\"...\"/> element")
    clock_name = _require_identifier(clock_node.get("name", ""), "clock/@name")

    # ---- signals ----
    signals: list[SignalSpec] = []
    seen_signals: set[str] = set()
    signals_node = root.find("signals")
    if signals_node is None or not list(signals_node.findall("signal")):
        raise SpecError("<signals> must contain at least one <signal>")

    for s in signals_node.findall("signal"):
        sname = _require_identifier(s.get("name", ""), "signal/@name")
        if sname in _RESERVED_SIGNAL_NAMES or sname == clock_name:
            raise SpecError(
                f"signal '{sname}' collides with the clock name '{clock_name}'"
            )
        if sname in seen_signals:
            raise SpecError(f"Duplicate signal name: '{sname}'")
        seen_signals.add(sname)

        width = s.get("width", "").strip()
        if not width:
            raise SpecError(f"signal '{sname}' is missing @width")
        if not (width.isdigit() or width in seen_params):
            raise SpecError(
                f"signal '{sname}' has width '{width}', which is neither an integer "
                f"literal nor a declared <parameter name=\"{width}\">"
            )
        if width.isdigit() and int(width) < 1:
            raise SpecError(f"signal '{sname}' has non-positive width literal: {width}")

        depth_raw = s.get("depth")
        depth: str | None = None
        if depth_raw is not None:
            depth = depth_raw.strip()
            if not (depth.isdigit() or depth in seen_params):
                raise SpecError(
                    f"signal '{sname}' has depth '{depth}', which is neither an integer "
                    f"literal nor a declared <parameter name=\"{depth}\">"
                )
            if depth.isdigit() and int(depth) < 1:
                raise SpecError(f"signal '{sname}' has non-positive depth literal: {depth}")

        direction = s.get("direction", "").strip()
        if direction not in ("drv", "mon"):
            raise SpecError(
                f"signal '{sname}' has direction '{direction}'; must be 'drv' or 'mon'"
            )

        signals.append(SignalSpec(name=sname, width=width, direction=direction, depth=depth))

    if not any(s.is_driven for s in signals):
        raise SpecError("At least one signal must have direction=\"drv\" (nothing to drive)")
    if not any(s.is_monitored for s in signals):
        raise SpecError("At least one signal must have direction=\"mon\" (nothing to sample)")

    signal_names = {s.name for s in signals}

    # ---- dut ----
    dut: DutSpec | None = None
    dut_node = root.find("dut")
    if dut_node is not None:
        module_name = _require_identifier(
            _text(dut_node.find("module_name"), "module_name", "<dut>"), "dut/module_name"
        )
        inst_node = dut_node.find("instance_name")
        instance_name = (
            _require_identifier(_text(inst_node, "instance_name", "<dut>"), "dut/instance_name")
            if inst_node is not None
            else "dut"
        )

        ports: list[DutPortSpec] = []
        seen_dut_ports: set[str] = set()
        port_nodes = dut_node.findall("port")
        if not port_nodes:
            raise SpecError("<dut> is present but declares no <port> elements")

        for p in port_nodes:
            dut_port = _require_identifier(p.get("dut_port", ""), "dut/port/@dut_port")
            sig_ref = _require_identifier(p.get("signal", ""), "dut/port/@signal")
            if dut_port in seen_dut_ports:
                raise SpecError(f"Duplicate DUT port mapping for '{dut_port}'")
            seen_dut_ports.add(dut_port)
            if sig_ref != clock_name and sig_ref not in signal_names:
                raise SpecError(
                    f"<dut> port '{dut_port}' references signal '{sig_ref}', which is "
                    f"neither the clock ('{clock_name}') nor a declared <signal>"
                )
            ports.append(DutPortSpec(dut_port=dut_port, signal=sig_ref))

        # Every driven/monitored signal should usually be wired to the DUT, but we only
        # warn-by-omission is not available here (no logging channel agreed), so we just
        # don't require full coverage -- partial port lists are valid (e.g. DUT has extra
        # unused ports). We DO require the reverse (above): every mapped signal must exist.

        dut = DutSpec(module_name=module_name, instance_name=instance_name, ports=ports)

    # ---- env flags ----
    env_flags = EnvFlags()
    env_node = root.find("env")
    if env_node is not None:
        has_sb_node = env_node.find("has_scoreboard")
        if has_sb_node is not None:
            val = (has_sb_node.text or "").strip().lower()
            if val not in ("true", "false"):
                raise SpecError(
                    f"<has_scoreboard> must be 'true' or 'false', got: {has_sb_node.text!r}"
                )
            env_flags.has_scoreboard = val == "true"

        has_sub_node = env_node.find("has_subscriber")
        if has_sub_node is not None:
            val = (has_sub_node.text or "").strip().lower()
            if val not in ("true", "false"):
                raise SpecError(
                    f"<has_subscriber> must be 'true' or 'false', got: {has_sub_node.text!r}"
                )
            env_flags.has_subscriber = val == "true"

    return UvmEnvSpec(
        name=agent_name,
        clock_name=clock_name,
        parameters=parameters,
        signals=signals,
        dut=dut,
        env=env_flags,
    )
