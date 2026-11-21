"""
XML -> MultiEnvSpec parsing and validation (multi-agent format).

Selected automatically by parse_spec() when the root <uvm_env> contains <agents>.
Same philosophy as the single-agent parser: validate everything, fail loudly with a
precise message before any file is written.
"""
from __future__ import annotations

from xml.etree import ElementTree as ET

from .model import DutSpec
from .multi_model import (AgentSpec, InterfaceSpec, MultiDutPortSpec, MultiEnvFlags,
                          MultiEnvSpec)
from .xml_parser import (SpecError, _require_identifier, _text, parse_bool, parse_parameters,
                         parse_signal)


def _parse_flag_attr(node: ET.Element, attr: str, default: bool, what: str) -> bool:
    raw = node.get(attr)
    if raw is None:
        return default
    val = raw.strip().lower()
    if val not in ("true", "false"):
        raise SpecError(f"{what} @{attr} must be 'true' or 'false', got: {raw!r}")
    return val == "true"


def parse_multi(root: ET.Element) -> MultiEnvSpec:
    env_name = _require_identifier(root.get("name", ""), "uvm_env/@name")
    parameters, localparams, consts = parse_parameters(root)

    # ---- clock ----
    clock_node = root.find("clock")
    if clock_node is None:
        raise SpecError("Missing required <clock name=\"...\"/> element")
    clock_name = _require_identifier(clock_node.get("name", ""), "clock/@name")

    # ---- interfaces ----
    ifs_node = root.find("interfaces")
    if ifs_node is None or not ifs_node.findall("interface"):
        raise SpecError("<interfaces> must contain at least one <interface name=\"...\">")

    interfaces: dict[str, InterfaceSpec] = {}
    for inode in ifs_node.findall("interface"):
        iname = _require_identifier(inode.get("name", ""), "interface/@name")
        if iname in interfaces:
            raise SpecError(f"Duplicate interface name: '{iname}'")
        where = f"interface '{iname}': "
        sig_nodes = inode.findall("signal")
        if not sig_nodes:
            raise SpecError(f"{where}must contain at least one <signal>")
        signals = []
        seen: set[str] = set()
        for s in sig_nodes:
            sig = parse_signal(s, consts, set(), clock_name, where)
            if sig.name in seen:
                raise SpecError(f"{where}duplicate signal name '{sig.name}'")
            seen.add(sig.name)
            signals.append(sig)
        interfaces[iname] = InterfaceSpec(name=iname, type_name=f"{env_name}_{iname}_if",
                                          signals=signals)

    # ---- env flags ----
    env_flags = MultiEnvFlags()
    env_node = root.find("env")
    if env_node is not None:
        env_flags.has_scoreboard = parse_bool(env_node.find("has_scoreboard"),
                                              "has_scoreboard", True)
        cov_node = env_node.find("has_coverage")
        if cov_node is None:
            cov_node = env_node.find("has_subscriber")  # accepted alias
        env_flags.has_coverage = parse_bool(cov_node, "has_coverage", True)

    # ---- agents ----
    agents_node = root.find("agents")
    agent_nodes = agents_node.findall("agent")
    if not agent_nodes:
        raise SpecError("<agents> must contain at least one <agent>")
    count_raw = agents_node.get("count")
    if count_raw is not None:
        if not count_raw.strip().isdigit():
            raise SpecError(f"<agents count=...> must be a positive integer, got {count_raw!r}")
        if int(count_raw) != len(agent_nodes):
            raise SpecError(
                f"<agents count=\"{count_raw}\"> but {len(agent_nodes)} <agent> element(s) "
                f"are declared"
            )

    agents: list[AgentSpec] = []
    seen_lower: dict[str, str] = {}
    used_ifs: set[str] = set()
    for anode in agent_nodes:
        aname = _require_identifier(anode.get("name", ""), "agent/@name")
        what = f"agent '{aname}'"
        if aname.lower() in seen_lower:
            raise SpecError(
                f"{what} clashes with agent '{seen_lower[aname.lower()]}' (agent names must be "
                f"unique ignoring case, they are used in lower case for ports and handles)"
            )
        seen_lower[aname.lower()] = aname

        iname = anode.get("interface", "").strip()
        if not iname:
            raise SpecError(f"{what} is missing @interface")
        if iname not in interfaces:
            raise SpecError(
                f"{what} references interface '{iname}', which is not declared in <interfaces> "
                f"(declared: {', '.join(interfaces)})"
            )
        used_ifs.add(iname)
        intf = interfaces[iname]

        mode = anode.get("mode", "active").strip().lower()
        if mode not in ("active", "passive"):
            raise SpecError(f"{what} has mode '{mode}'; must be 'active' or 'passive'")
        is_active = mode == "active"
        if is_active and not intf.driven_signals:
            raise SpecError(
                f"{what} is active but its interface '{iname}' has no direction=\"drv\" "
                f"signal (nothing to drive); make it mode=\"passive\""
            )

        agents.append(AgentSpec(
            name=aname,
            env_name=env_name,
            interface=intf,
            is_active=is_active,
            to_scoreboard=_parse_flag_attr(anode, "scoreboard", True, what),
            to_coverage=_parse_flag_attr(anode, "coverage", True, what),
        ))

    unused = [n for n in interfaces if n not in used_ifs]
    if unused:
        raise SpecError(f"interface(s) not used by any agent: {', '.join(unused)}")

    if env_flags.has_scoreboard and not any(a.to_scoreboard for a in agents):
        raise SpecError("<has_scoreboard> is true but no agent has scoreboard=\"true\"")
    if env_flags.has_coverage and not any(a.to_coverage for a in agents):
        raise SpecError("<has_coverage> is true but no agent has coverage=\"true\"")

    spec = MultiEnvSpec(
        name=env_name,
        clock_name=clock_name,
        parameters=parameters,
        localparams=localparams,
        interfaces=list(interfaces.values()),
        agents=agents,
        env=env_flags,
    )

    # package-side signal views: localparams substituted by their values
    lp_values = spec.localparam_values
    for a in agents:
        a.pkg_signals = [s.resolved(lp_values) for s in a.interface.signals]

    # ---- dut ----
    dut_node = root.find("dut")
    if dut_node is not None:
        module_name = _require_identifier(
            _text(dut_node.find("module_name"), "module_name", "<dut>"), "dut/module_name"
        )
        inst_node = dut_node.find("instance_name")
        instance_name = (
            _require_identifier(_text(inst_node, "instance_name", "<dut>"), "dut/instance_name")
            if inst_node is not None else "dut"
        )

        rtl_files = []
        for f in dut_node.findall("rtl_file"):
            rtl_files.append(_text(f, "rtl_file", "<dut>"))
        spec.rtl_files = rtl_files

        port_nodes = dut_node.findall("port")
        if not port_nodes:
            raise SpecError("<dut> is present but declares no <port> elements")
        agent_names = {a.name: a for a in agents}
        ports: list[MultiDutPortSpec] = []
        seen_ports: set[str] = set()
        for p in port_nodes:
            dut_port = _require_identifier(p.get("dut_port", ""), "dut/port/@dut_port")
            if dut_port in seen_ports:
                raise SpecError(f"Duplicate DUT port mapping for '{dut_port}'")
            seen_ports.add(dut_port)
            sig_ref = _require_identifier(p.get("signal", ""), "dut/port/@signal")
            agent_ref = p.get("agent")
            if agent_ref is None:
                if sig_ref != clock_name:
                    raise SpecError(
                        f"<dut> port '{dut_port}' has no @agent; only the clock "
                        f"('{clock_name}') may be connected without an agent"
                    )
                ports.append(MultiDutPortSpec(dut_port=dut_port, signal=sig_ref))
                continue
            agent_ref = agent_ref.strip()
            if agent_ref not in agent_names:
                raise SpecError(
                    f"<dut> port '{dut_port}' references agent '{agent_ref}', which is not "
                    f"declared in <agents>"
                )
            a = agent_names[agent_ref]
            if sig_ref not in {s.name for s in a.signals}:
                raise SpecError(
                    f"<dut> port '{dut_port}' references signal '{sig_ref}', which is not in "
                    f"interface '{a.interface.name}' of agent '{agent_ref}'"
                )
            ports.append(MultiDutPortSpec(dut_port=dut_port, signal=sig_ref, agent=agent_ref))

        spec.dut = DutSpec(module_name=module_name, instance_name=instance_name,
                           ports=ports)  # type: ignore[arg-type]

    return spec
