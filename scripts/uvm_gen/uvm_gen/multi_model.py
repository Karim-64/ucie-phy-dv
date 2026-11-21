"""
Data model for a MULTI-AGENT UVM environment spec.

The generated architecture mirrors verification/SB_TX/ip_level/Priority_Encoder_SBTX:
  - one agent per <agent> (abbreviation e.g. D2D / PHY / FIFO), each with its own
    sequence item, cfg objects, monitor and -- for active agents -- driver + sequencer
    (with the seqr_aport -> mon_aimp / mon_aport -> seqr_aexport feedback TLM paths)
  - interfaces are declared once and may be shared by several agents
  - a virtual sequencer / virtual sequence over all active agents
  - a scoreboard with one analysis export + TLM analysis FIFO per connected agent,
    run_phase / ref_model / check_results
  - a coverage collector (uvm_component) with one uvm_analysis_imp_decl port per
    connected agent, synchronised sampling once every connected monitor has written

Templates render only from these classes, never from raw XML.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from .model import DutSpec, ParamSpec, SignalSpec, _substitute


@dataclass
class InterfaceSpec:
    name: str                    # short name from the XML, e.g. "in"
    type_name: str               # SystemVerilog interface type, e.g. "pe_sbtx_in_if"
    signals: list[SignalSpec] = field(default_factory=list)

    @property
    def driven_signals(self) -> list[SignalSpec]:
        return [s for s in self.signals if s.is_driven]

    @property
    def monitored_signals(self) -> list[SignalSpec]:
        return [s for s in self.signals if s.is_monitored]

    @property
    def file_name(self) -> str:
        return f"{self.type_name}.sv"


@dataclass
class AgentSpec:
    name: str                    # abbreviation as written in the XML, e.g. "D2D"
    env_name: str                # environment prefix, e.g. "pe_sbtx"
    interface: InterfaceSpec
    is_active: bool = True       # XML mode="active" -> driver + sequencer are generated
    to_scoreboard: bool = True   # connect agt_aport to the scoreboard
    to_coverage: bool = True     # connect agt_aport to the coverage collector
    pkg_signals: list[SignalSpec] = field(default_factory=list)  # localparams inlined

    # ---- naming ----
    @property
    def lower(self) -> str:
        return self.name.lower()

    @property
    def upper(self) -> str:
        return self.name.upper()

    @property
    def prefix(self) -> str:
        """Class-name prefix, e.g. 'pe_sbtx_D2D'."""
        return f"{self.env_name}_{self.name}"

    def cls(self, suffix: str) -> str:
        """e.g. agent.cls('driver') -> 'pe_sbtx_D2D_driver'."""
        return f"{self.prefix}_{suffix}"

    @property
    def item(self) -> str:
        return self.cls("sequence_item")

    @property
    def inst(self) -> str:
        """Agent instance name inside the environment, e.g. 'D2D_agt'."""
        return f"{self.name}_agt"

    @property
    def vif(self) -> str:
        """Field name in env_cfg_obj, e.g. 'd2d_vif'."""
        return f"{self.lower}_vif"

    @property
    def if_inst(self) -> str:
        """Interface instance name in tb_top, e.g. 'd2d_if'."""
        return f"{self.lower}_if"

    @property
    def vif_key(self) -> str:
        """uvm_config_db key, e.g. 'PE_SBTX_D2D_VIF'."""
        return f"{self.env_name.upper()}_{self.upper}_VIF"

    @property
    def mode_enum(self) -> str:
        return "UVM_ACTIVE" if self.is_active else "UVM_PASSIVE"

    @property
    def comp_dir(self) -> str:
        return f"components/{self.name}_agent"

    @property
    def seq_dir(self) -> str:
        return f"sequences/{self.name}_seqs"

    # ---- signal views ----
    @property
    def signals(self) -> list[SignalSpec]:
        return self.interface.signals

    @property
    def driven_signals(self) -> list[SignalSpec]:
        return self.interface.driven_signals

    @property
    def monitored_signals(self) -> list[SignalSpec]:
        return self.interface.monitored_signals

    @property
    def pkg_driven_signals(self) -> list[SignalSpec]:
        return [s for s in self.pkg_signals if s.is_driven]

    @property
    def pkg_monitored_signals(self) -> list[SignalSpec]:
        return [s for s in self.pkg_signals if s.is_monitored]

    @property
    def helper_args(self) -> list[SignalSpec]:
        """Driven signals exposed as arguments of drive_<agt>_item() (unpacked arrays are
        left randomized because array-equality constraints are not portable)."""
        return [s for s in self.pkg_driven_signals if not s.is_unpacked]

    @property
    def checked_signals(self) -> list[SignalSpec]:
        """Signals the scoreboard compares against the expected item (DUT outputs)."""
        return self.pkg_monitored_signals


@dataclass
class MultiDutPortSpec:
    dut_port: str
    signal: str
    agent: str | None = None     # None -> the clock


@dataclass
class MultiEnvFlags:
    has_scoreboard: bool = True
    has_coverage: bool = True


@dataclass
class MultiEnvSpec:
    name: str
    clock_name: str
    parameters: list[ParamSpec] = field(default_factory=list)
    localparams: list[ParamSpec] = field(default_factory=list)
    interfaces: list[InterfaceSpec] = field(default_factory=list)
    agents: list[AgentSpec] = field(default_factory=list)
    dut: DutSpec | None = None           # ports are MultiDutPortSpec
    rtl_files: list[str] = field(default_factory=list)
    env: MultiEnvFlags = field(default_factory=MultiEnvFlags)

    is_multi: bool = True

    @property
    def upper(self) -> str:
        return self.name.upper()

    @property
    def localparam_values(self) -> dict[str, str]:
        values: dict[str, str] = {}
        for lp in self.localparams:
            values[lp.name] = _substitute(lp.value, values)
        return values

    # ---- parameter helpers ----
    @property
    def param_names(self) -> list[str]:
        return [p.name for p in self.parameters]

    @property
    def if_params(self) -> str:
        """'#(DATA_WIDTH)' for virtual interface types, or '' without parameters."""
        return f"#({', '.join(self.param_names)})" if self.parameters else ""

    @property
    def param_overrides(self) -> str:
        """'#(.DATA_WIDTH(DATA_WIDTH))' for instantiations, or ''."""
        if not self.parameters:
            return ""
        return "#(" + ", ".join(f".{n}({n})" for n in self.param_names) + ")"

    def vif_type(self, agent: AgentSpec) -> str:
        return f"virtual {agent.interface.type_name}{self.if_params}"

    # ---- agent views ----
    @property
    def active_agents(self) -> list[AgentSpec]:
        return [a for a in self.agents if a.is_active]

    @property
    def passive_agents(self) -> list[AgentSpec]:
        return [a for a in self.agents if not a.is_active]

    @property
    def sb_agents(self) -> list[AgentSpec]:
        return [a for a in self.agents if a.to_scoreboard] if self.env.has_scoreboard else []

    @property
    def sb_input_agents(self) -> list[AgentSpec]:
        """Scoreboard-connected active agents: the stimulus fed to ref_model()."""
        return [a for a in self.sb_agents if a.is_active]

    @property
    def sb_checked_agents(self) -> list[AgentSpec]:
        """Scoreboard-connected agents that carry DUT outputs to compare."""
        return [a for a in self.sb_agents if a.checked_signals]

    @property
    def cov_agents(self) -> list[AgentSpec]:
        return [a for a in self.agents if a.to_coverage] if self.env.has_coverage else []

    def agent(self, name: str) -> AgentSpec:
        for a in self.agents:
            if a.name == name:
                return a
        raise KeyError(name)
